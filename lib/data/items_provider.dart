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
  late final BackupService _backupService = BackupService(databaseHelper: _db);

  ItemsProvider({DatabaseHelper? databaseHelper})
    : _db = databaseHelper ?? DatabaseHelper.instance;

  List<ItemModel> _items = [];
  double _totalSaved = 0;
  double _totalSpent = 0;
  bool _isLoading = false;

  List<ItemModel> get items => List.unmodifiable(_items);
  double get totalSaved => _totalSaved;
  double get totalSpent => _totalSpent;
  bool get isLoading => _isLoading;

  int get resistedCount => _items.where((item) => item.isSaved).length;

  double get averageSavedPerItem =>
      resistedCount == 0 ? 0 : _totalSaved / resistedCount;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _items = await _db.getAllItems();
    _totalSaved = await _db.getTotalSaved();
    _totalSpent = await _db.getTotalSpent();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem({
    String? title,
    required double price,
    required String imagePath,
    required bool isSaved,
    String? category,
    String? purchaseUrl,
  }) async {
    await _db.insertItem(
      ItemModel(
        title: title,
        price: price,
        imagePath: imagePath,
        isSaved: isSaved,
        category: category,
        createdAt: DateTime.now(),
        purchaseUrl: purchaseUrl,
      ),
    );
    await load();
  }

  Future<void> setSavedStatus(int id, bool isSaved) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    await _db.updateItem(_items[index].copyWith(isSaved: isSaved));
    await load();
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
        imagePath: current.imagePath,
        isSaved: current.isSaved,
        category: current.category,
        createdAt: current.createdAt,
        purchaseUrl: purchaseUrl,
      ),
    );
    await load();
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteItem(id);
    await load();
  }

  Future<String> buildJsonBackup() => _backupService.buildJsonBackup();

  Future<String> buildCsvBackup() => _backupService.buildCsvBackup();

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
}
