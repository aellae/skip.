import 'package:flutter/foundation.dart';

import 'backup_service.dart';
import 'database_helper.dart';
import 'models/item_model.dart';
import 'models/monthly_total.dart';
import 'monthly_totals.dart';

/// Single reactive source of truth for items, shared across the home
/// dashboard, item entry, and item detail screens via [Provider].
///
/// Wraps [DatabaseHelper] and keeps an in-memory copy of the item list plus
/// the running saved/spent totals, so every screen reads consistent data
/// and only re-fetches from SQLite when something actually changed.
class ItemsProvider extends ChangeNotifier {
  final DatabaseHelper _db;
  late final BackupService _backupService;

  ItemsProvider({DatabaseHelper? databaseHelper, BackupService? backupService})
    : _db = databaseHelper ?? DatabaseHelper.instance {
    _backupService = backupService ?? BackupService(databaseHelper: _db);
  }

  List<ItemModel> _items = [];
  List<ItemModel> _trashedItems = [];
  double _totalSaved = 0;
  double _totalSpent = 0;
  bool _isLoading = false;

  // The calendar month "this month" totals were last shown for, so a month
  // boundary passing while the app is open or backgrounded can be detected
  // (see [checkMonthRollover]).
  DateTime _currentMonth = _monthOf(DateTime.now());

  // Throttles the local safety-net backup so it writes at most this often,
  // rather than after every single load() call.
  static const Duration _autoBackupInterval = Duration(minutes: 10);
  DateTime? _lastAutoBackupAt;

  List<ItemModel> get items => List.unmodifiable(_items);
  List<ItemModel> get trashedItems => List.unmodifiable(_trashedItems);
  double get totalSaved => _totalSaved;
  double get totalSpent => _totalSpent;
  bool get isLoading => _isLoading;

  int get resistedCount => _items.where((item) => item.isSaved == true).length;

  int get ponderingCount => _items.where((item) => item.isPondering).length;

  double get averageSavedPerItem =>
      resistedCount == 0 ? 0 : _totalSaved / resistedCount;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _items = await _db.getAllItems();
    _trashedItems = await _db.getTrashedItems();
    _totalSaved = await _db.getTotalSaved();
    _totalSpent = await _db.getTotalSpent();

    _isLoading = false;
    notifyListeners();

    // Never overwrite the safety-net backup with an empty snapshot: an empty
    // database at launch is exactly the case the backup exists to recover.
    final hasData = _items.isNotEmpty || _trashedItems.isNotEmpty;
    final now = DateTime.now();
    if (hasData &&
        (_lastAutoBackupAt == null ||
            now.difference(_lastAutoBackupAt!) >= _autoBackupInterval)) {
      _lastAutoBackupAt = now;
      await _backupService.writeAutoBackup();
    }
  }

  /// Restores from the local safety-net backup (see [BackupService.
  /// writeAutoBackup]) — additive, existing data is kept. Guards against
  /// re-importing the same snapshot twice (e.g. a double tap on the restore
  /// button), which would otherwise duplicate every item.
  Future<AutoBackupRestoreResult> restoreFromAutoBackup() async {
    final content = await _backupService.readAutoBackup();
    if (content == null) return const AutoBackupRestoreResult.notFound();

    final exportedAt = _backupService.readExportedAt(content);
    if (exportedAt != null &&
        await _backupService.isAutoBackupAlreadyRestored(exportedAt)) {
      return const AutoBackupRestoreResult.alreadyRestored();
    }

    final count = await importJsonBackup(content);
    if (exportedAt != null) {
      await _backupService.markAutoBackupRestored(exportedAt);
    }
    return AutoBackupRestoreResult.restored(count);
  }

  Future<void> addItem({
    String? title,
    required double price,
    int quantity = 1,
    String? imagePath,
    required bool? isSaved,
    String? category,
    String? purchaseUrl,
  }) async {
    await _db.insertItem(
      ItemModel(
        title: title,
        price: price,
        quantity: quantity,
        imagePath: imagePath,
        isSaved: isSaved,
        category: category,
        createdAt: DateTime.now(),
        purchaseUrl: purchaseUrl,
      ),
    );
    await load();
  }

  /// Sets the decision on an existing item — pass `null` to move it back to
  /// "pondering" (undecided).
  Future<void> setSavedStatus(int id, bool? isSaved) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    await _db.updateItem(
      _items[index].copyWith(isSaved: isSaved, clearIsSaved: isSaved == null),
    );
    await load();
  }

  /// Updates the title and price on an existing item — the only fields a
  /// typo'd entry needs fixing without deleting and re-adding it (status and
  /// purchase link already have their own setters below). Uses a fresh
  /// [ItemModel] rather than [ItemModel.copyWith] because copyWith's `??`
  /// pattern can't express "clear the title".
  Future<void> updateDetails(
    int id, {
    required String? title,
    required double price,
    int? quantity,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _items[index];
    await _db.updateItem(
      ItemModel(
        id: current.id,
        title: title,
        price: price,
        quantity: quantity ?? current.quantity,
        imagePath: current.imagePath,
        isSaved: current.isSaved,
        category: current.category,
        createdAt: current.createdAt,
        purchaseUrl: current.purchaseUrl,
      ),
    );
    await load();
  }

  /// Sets or clears (pass `null`) an existing item's photo — used when the
  /// user adds/changes/removes a photo from the edit flow rather than at
  /// entry time. Unlike [deleteItem]'s soft-delete, a replaced photo isn't
  /// recoverable from Trash, so the old file is deleted immediately once the
  /// DB write succeeds rather than deferred to [purgeExpiredTrash].
  Future<void> setImagePath(int id, String? imagePath) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _items[index];
    final oldImagePath = current.imagePath;
    await _db.updateItem(
      ItemModel(
        id: current.id,
        title: current.title,
        price: current.price,
        quantity: current.quantity,
        imagePath: imagePath,
        isSaved: current.isSaved,
        category: current.category,
        createdAt: current.createdAt,
        purchaseUrl: current.purchaseUrl,
      ),
    );
    await load();
    if (oldImagePath != null && oldImagePath != imagePath) {
      await _db.fileHelper.deleteImage(oldImagePath);
    }
  }

  /// Sets or clears (pass `null`) the retroactive purchase link on an
  /// existing item. Uses a fresh [ItemModel] rather than [ItemModel.copyWith]
  /// because `copyWith`'s `??` pattern can't express "clear this field".
  Future<void> setPurchaseUrl(int id, String? purchaseUrl) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = _items[index];
    await _db.updateItem(
      ItemModel(
        id: current.id,
        title: current.title,
        price: current.price,
        quantity: current.quantity,
        imagePath: current.imagePath,
        isSaved: current.isSaved,
        category: current.category,
        createdAt: current.createdAt,
        purchaseUrl: purchaseUrl,
      ),
    );
    await load();
  }

  /// Moves an item to Trash (recoverable via [restoreItem]) — does not
  /// touch its image file. Permanent removal happens later, via
  /// [purgeExpiredTrash].
  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await load();
  }

  /// Moves a trashed item back into the live set.
  Future<void> restoreItem(int id) async {
    await _db.restoreItem(id);
    await load();
  }

  /// Permanently removes items trashed more than [retention] ago, deleting
  /// their image files too, then sweeps photos no row references at all
  /// (see [DatabaseHelper.purgeOrphanedImages]). Safe to call on every app
  /// start.
  Future<void> purgeExpiredTrash({
    Duration retention = const Duration(days: 30),
  }) async {
    final purged = await _db.purgeExpiredTrash(retention: retention);
    if (purged > 0) await load();
    await _db.purgeOrphanedImages();
  }

  /// Parses [jsonContent] as a SKIP backup and imports its items (additive
  /// — existing data is kept), then refreshes state. Throws
  /// [BackupFormatException] if [jsonContent] isn't a valid backup; the
  /// caller should show that message to the user rather than swallow it.
  Future<int> importJsonBackup(String jsonContent) async {
    final items = _backupService.parseJsonBackup(jsonContent);
    final count = await _backupService.importItems(items);
    await load();
    return count;
  }

  /// Monthly saved/spent totals for the Insights bar chart, oldest first.
  List<MonthlyTotal> monthlyTotals({int monthsBack = 6}) =>
      computeMonthlyTotals(_items, now: DateTime.now(), monthsBack: monthsBack);

  double get totalSavedThisMonth => monthlyTotals(monthsBack: 1).single.saved;

  double get totalSpentThisMonth => monthlyTotals(monthsBack: 1).single.spent;

  /// "This month" is derived from the clock rather than stored, so nothing
  /// notifies listeners when a new month starts. Call this when the app
  /// resumes (or at the month boundary) so screens showing monthly totals
  /// rebuild and the home-screen widget is re-synced. Returns whether the
  /// month changed.
  bool checkMonthRollover({DateTime? now}) {
    final month = _monthOf(now ?? DateTime.now());
    if (month == _currentMonth) return false;
    _currentMonth = month;
    notifyListeners();
    return true;
  }

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);
}
