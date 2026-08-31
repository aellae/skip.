import 'dart:convert';

import 'package:csv/csv.dart';

import 'database_helper.dart';
import 'models/item_model.dart';

/// Thrown by [BackupService.parseJsonBackup] when the given content isn't a
/// well-formed SKIP backup. Carries a user-facing [message] so callers can
/// surface a clear error instead of silently accepting malformed data or
/// crashing on a raw parse exception (BUILD_PROMPT.md §7-8).
class BackupFormatException implements Exception {
  final String message;

  const BackupFormatException(this.message);

  @override
  String toString() => message;
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

  final DatabaseHelper _db;

  BackupService({DatabaseHelper? databaseHelper})
    : _db = databaseHelper ?? DatabaseHelper.instance;

  Future<String> buildJsonBackup() async {
    final items = await _db.getAllItems();
    final payload = {
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<String> buildCsvBackup() async {
    final items = await _db.getAllItems();
    final rows = <List<dynamic>>[
      ['title', 'price', 'image_path', 'is_saved', 'category', 'created_at'],
      for (final item in items)
        [
          item.title ?? '',
          item.price,
          item.imagePath,
          item.isSaved ? 1 : 0,
          item.category ?? '',
          item.createdAt.toIso8601String(),
        ],
    ];
    return Csv().encode(rows);
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
      throw const BackupFormatException("That file isn't valid JSON.");
    }

    if (decoded is! Map || decoded['items'] is! List) {
      throw const BackupFormatException(
        "That file doesn't look like a SKIP backup.",
      );
    }

    final itemsRaw = decoded['items'] as List;
    return itemsRaw.map((raw) {
      if (raw is! Map) {
        throw const BackupFormatException(
          'The backup contains an invalid item entry.',
        );
      }
      try {
        return ItemModel.fromMap(Map<String, Object?>.from(raw));
      } catch (_) {
        throw const BackupFormatException(
          'The backup contains an item with missing or invalid fields.',
        );
      }
    }).toList();
  }

  /// Inserts [items] as new rows. Import is additive: existing data is
  /// never cleared or overwritten. Returns the number of items imported.
  Future<int> importItems(List<ItemModel> items) async {
    for (final item in items) {
      await _db.insertItem(item);
    }
    return items.length;
  }
}
