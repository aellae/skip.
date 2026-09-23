import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/file_helper.dart';
import 'database_helper.dart';
import 'models/item_model.dart';

/// Identifies *why* a backup failed to parse, independent of any display
/// language — the UI layer maps this to a localized string, since this data
/// layer has no access to the active [AppLocale].
enum BackupFormatError {
  invalidJson,
  notASkipBackup,
  invalidItemEntry,
  invalidItemFields,
  fileReadError,
}

/// Thrown by [BackupService.parseJsonBackup] when the given content isn't a
/// well-formed SKIP backup. Carries a [code] so callers can look up a
/// localized message, plus an English [message] fallback (used by
/// [toString] for logs/debugging) instead of silently accepting malformed
/// data or crashing on a raw parse exception (BUILD_PROMPT.md §7-8).
class BackupFormatException implements Exception {
  final BackupFormatError code;
  final String message;

  const BackupFormatException(this.code, this.message);

  @override
  String toString() => message;
}

/// Outcome of [ItemsProvider.restoreFromAutoBackup].
sealed class AutoBackupRestoreResult {
  const AutoBackupRestoreResult();

  const factory AutoBackupRestoreResult.restored(int count) =
      AutoBackupRestored;
  const factory AutoBackupRestoreResult.alreadyRestored() =
      AutoBackupAlreadyRestored;
  const factory AutoBackupRestoreResult.notFound() = AutoBackupNotFound;
}

/// The auto-backup snapshot was imported; [count] items were added.
class AutoBackupRestored extends AutoBackupRestoreResult {
  final int count;
  const AutoBackupRestored(this.count);
}

/// Every item in the auto-backup snapshot is already in the database, so
/// nothing was imported.
class AutoBackupAlreadyRestored extends AutoBackupRestoreResult {
  const AutoBackupAlreadyRestored();
}

/// No auto-backup file exists yet.
class AutoBackupNotFound extends AutoBackupRestoreResult {
  const AutoBackupNotFound();
}

/// Builds and parses SKIP's data backups.
///
/// JSON is the round-trippable format used for import; CSV is export-only,
/// meant for opening in a spreadsheet. Both only cover item records, not
/// the photos themselves — there's no archive/zip dependency in this app,
/// so a restored item's image may be missing on the receiving device until
/// re-added. The grid and detail views already fall back to a blank tile
/// for a missing image file, so this degrades gracefully.
class BackupService {
  static const int formatVersion = 1;

  /// File name for the automatic local safety-net backup (distinct from
  /// user-triggered exports, which get a timestamped name).
  static const String autoBackupFileName = 'skip_autobackup.json';

  /// SharedPreferences key holding when [writeAutoBackup] last ran, so its
  /// throttle survives app restarts instead of rewriting on every launch.
  static const String _lastAutoBackupAtKey = 'skip_last_auto_backup_at';

  final DatabaseHelper _db;
  final FileHelper _fileHelper;

  BackupService({DatabaseHelper? databaseHelper, FileHelper? fileHelper})
    : _db = databaseHelper ?? DatabaseHelper.instance,
      _fileHelper = fileHelper ?? FileHelper();

  /// Overwrites the local safety-net backup with the current item set.
  /// 100% offline — written to Application Documents via [FileHelper], never
  /// sent anywhere. Not a substitute for a user-triggered export: this is
  /// only meant to recover from an unexplained empty/corrupt database.
  Future<void> writeAutoBackup({DateTime? now}) async {
    final content = await buildJsonBackup();
    await _fileHelper.writeExportFile(autoBackupFileName, content);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastAutoBackupAtKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  /// Whether at least [interval] has passed since [writeAutoBackup] last
  /// ran, in this launch or an earlier one. A recorded time in the future
  /// (the clock was set back) also counts as due, so backups can't stall.
  Future<bool> isAutoBackupDue(Duration interval, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final last = DateTime.tryParse(prefs.getString(_lastAutoBackupAtKey) ?? '');
    if (last == null) return true;
    final current = now ?? DateTime.now();
    return last.isAfter(current) || current.difference(last) >= interval;
  }

  /// Reads the local safety-net backup written by [writeAutoBackup], or
  /// `null` if none exists yet.
  Future<String?> readAutoBackup() async {
    final dir = await _fileHelper.exportsDirectory();
    final file = File(p.join(dir.path, autoBackupFileName));
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  Future<String> buildJsonBackup() async {
    final items = await _db.getAllItems();
    final payload = {
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Parses [content] as a SKIP JSON backup, returning the items it
  /// contains. Throws [BackupFormatException] — never a raw exception — if
  /// [content] isn't valid JSON, isn't shaped like a SKIP backup, or
  /// contains an item with missing/invalid fields.
  List<ItemModel> parseJsonBackup(String content) {
    Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      throw const BackupFormatException(
        BackupFormatError.invalidJson,
        "That file isn't valid JSON.",
      );
    }

    if (decoded is! Map || decoded['items'] is! List) {
      throw const BackupFormatException(
        BackupFormatError.notASkipBackup,
        "That file doesn't look like a Skip! backup.",
      );
    }

    final itemsRaw = decoded['items'] as List;
    return itemsRaw.map((raw) {
      if (raw is! Map) {
        throw const BackupFormatException(
          BackupFormatError.invalidItemEntry,
          'The backup contains an invalid item entry.',
        );
      }
      try {
        return ItemModel.fromMap(Map<String, Object?>.from(raw));
      } catch (_) {
        throw const BackupFormatException(
          BackupFormatError.invalidItemFields,
          'The backup contains an item with missing or invalid fields.',
        );
      }
    }).toList();
  }

  /// Inserts [items] as new rows. Import is additive: existing data is
  /// never cleared or overwritten. Items that already match an existing
  /// item — trashed or not — on every field but [ItemModel.id] (which is
  /// reassigned on insert and so can't be used to recognize a re-import)
  /// are skipped so re-importing the same backup doesn't duplicate rows.
  /// Matching against trashed items too matters: without it, restoring a
  /// backup snapshot taken before you deleted an item would resurrect it
  /// as a brand-new live row alongside the one still sitting in Trash.
  /// Returns the number of items actually inserted.
  Future<int> importItems(List<ItemModel> items) async {
    final existingSignatures = (await _db.getAllItemsIncludingTrashed())
        .map(_dedupeSignature)
        .toSet();
    var imported = 0;
    for (final item in items) {
      final signature = _dedupeSignature(item);
      if (existingSignatures.contains(signature)) continue;
      await _db.insertItem(item);
      existingSignatures.add(signature);
      imported++;
    }
    return imported;
  }

  /// A key identifying [item] independent of its (reassigned-on-insert)
  /// `id`, used by [importItems] to recognize items already present.
  String _dedupeSignature(ItemModel item) => [
    item.title,
    item.price,
    item.quantity,
    item.imagePath,
    item.isSaved,
    item.category,
    item.createdAt.toIso8601String(),
    item.purchaseUrl,
  ].join('\u0000');
}
