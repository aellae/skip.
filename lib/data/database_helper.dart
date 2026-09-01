import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../core/utils/file_helper.dart';
import 'models/item_model.dart';

/// Singleton SQLite gateway for the `items` table.
///
/// Owns the database connection lifecycle and every query the app needs.
/// [deleteItem] also removes the item's backing image file so no orphaned
/// files are left behind (CLAUDE.md: "Always clean up local stored image
/// files when an item record is deleted from SQLite").
class DatabaseHelper {
  static const String dbName = 'skip.db';
  static const int dbVersion = 2;
  static const String tableItems = 'items';

  static final DatabaseHelper instance = DatabaseHelper();

  final FileHelper fileHelper;

  /// Overrides the database path (e.g. `inMemoryDatabasePath`). Only ever
  /// set by tests so each test gets an isolated database instead of sharing
  /// the app's real `skip.db`.
  final String? testDbPath;

  Database? _db;

  DatabaseHelper({FileHelper? fileHelper, this.testDbPath})
    : fileHelper = fileHelper ?? FileHelper();

  Future<Database> get database async {
    return _db ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = testDbPath ?? p.join(await getDatabasesPath(), dbName);
    return openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // sqflite caches open connections by path and reuses them, which is
      // exactly wrong for tests: every test passes the same literal
      // ':memory:' path, so without this every DatabaseHelper in a test run
      // would silently share one database instead of getting its own.
      singleInstance: testDbPath == null,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        price REAL NOT NULL,
        image_path TEXT NOT NULL,
        is_saved INTEGER NOT NULL,
        category TEXT,
        created_at TEXT NOT NULL,
        purchase_url TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_items_created_at ON $tableItems(created_at)',
    );
    await db.execute(
      'CREATE INDEX idx_items_is_saved ON $tableItems(is_saved)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $tableItems ADD COLUMN purchase_url TEXT');
    }
  }

  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    return db.insert(tableItems, item.toMap()..remove('id'));
  }

  Future<int> updateItem(ItemModel item) async {
    if (item.id == null) {
      throw ArgumentError('Cannot update an ItemModel without an id.');
    }
    final db = await database;
    return db.update(
      tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<ItemModel?> getItemById(int id) async {
    final db = await database;
    final rows = await db.query(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ItemModel.fromMap(rows.first);
  }

  /// Returns all items, most recent first. Pass [isSaved] to filter to only
  /// resisted (`true`) or purchased (`false`) items.
  Future<List<ItemModel>> getAllItems({bool? isSaved}) async {
    final db = await database;
    final rows = await db.query(
      tableItems,
      where: isSaved == null ? null : 'is_saved = ?',
      whereArgs: isSaved == null ? null : [isSaved ? 1 : 0],
      orderBy: 'created_at DESC',
    );
    return rows.map(ItemModel.fromMap).toList();
  }

  /// Deletes the item row and its backing image file. Returns the number
  /// of rows deleted (0 if no item existed with that id).
  Future<int> deleteItem(int id) async {
    final existing = await getItemById(id);
    final db = await database;
    final rowsDeleted = await db.delete(
      tableItems,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (existing != null && rowsDeleted > 0) {
      await fileHelper.deleteImage(existing.imagePath);
    }
    return rowsDeleted;
  }

  Future<double> getTotalSaved() => _sumPrice(isSaved: true);

  Future<double> getTotalSpent() => _sumPrice(isSaved: false);

  Future<double> _sumPrice({required bool isSaved}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(price) as total FROM $tableItems WHERE is_saved = ?',
      [isSaved ? 1 : 0],
    );
    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
