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
  static const int dbVersion = 6;
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
    // is_saved is nullable: NULL means "pondering" (not decided yet), 1 is
    // Resisted/saved, 0 is Bought/spent.
    await db.execute('''
      CREATE TABLE $tableItems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        image_path TEXT,
        is_saved INTEGER,
        category TEXT,
        created_at TEXT NOT NULL,
        purchase_url TEXT,
        deleted_at TEXT
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
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE $tableItems ADD COLUMN deleted_at TEXT');
    }
    if (oldVersion < 4) {
      // SQLite can't relax a column's NOT NULL with ALTER TABLE, so rebuild
      // the table to make is_saved nullable (NULL = pondering/deciding).
      await db.execute('DROP INDEX IF EXISTS idx_items_is_saved');
      await db.execute('DROP INDEX IF EXISTS idx_items_created_at');
      await db.execute('ALTER TABLE $tableItems RENAME TO ${tableItems}_old');
      await db.execute('''
        CREATE TABLE $tableItems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          price REAL NOT NULL,
          image_path TEXT NOT NULL,
          is_saved INTEGER,
          category TEXT,
          created_at TEXT NOT NULL,
          purchase_url TEXT,
          deleted_at TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO $tableItems (
          id, title, price, image_path, is_saved, category, created_at,
          purchase_url, deleted_at
        )
        SELECT id, title, price, image_path, is_saved, category, created_at,
          purchase_url, deleted_at
        FROM ${tableItems}_old
      ''');
      await db.execute('DROP TABLE ${tableItems}_old');
      await db.execute(
        'CREATE INDEX idx_items_created_at ON $tableItems(created_at)',
      );
      await db.execute(
        'CREATE INDEX idx_items_is_saved ON $tableItems(is_saved)',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE $tableItems ADD COLUMN quantity INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 6) {
      // SQLite can't relax a column's NOT NULL with ALTER TABLE, so rebuild
      // the table to make image_path nullable — a photo is now optional at
      // entry time.
      await db.execute('DROP INDEX IF EXISTS idx_items_is_saved');
      await db.execute('DROP INDEX IF EXISTS idx_items_created_at');
      await db.execute('ALTER TABLE $tableItems RENAME TO ${tableItems}_old');
      await db.execute('''
        CREATE TABLE $tableItems (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          price REAL NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          image_path TEXT,
          is_saved INTEGER,
          category TEXT,
          created_at TEXT NOT NULL,
          purchase_url TEXT,
          deleted_at TEXT
        )
      ''');
      await db.execute('''
        INSERT INTO $tableItems (
          id, title, price, quantity, image_path, is_saved, category,
          created_at, purchase_url, deleted_at
        )
        SELECT id, title, price, quantity, image_path, is_saved, category,
          created_at, purchase_url, deleted_at
        FROM ${tableItems}_old
      ''');
      await db.execute('DROP TABLE ${tableItems}_old');
      await db.execute(
        'CREATE INDEX idx_items_created_at ON $tableItems(created_at)',
      );
      await db.execute(
        'CREATE INDEX idx_items_is_saved ON $tableItems(is_saved)',
      );
    }
  }

  Future<int> insertItem(ItemModel item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return db.insert(tableItems, map);
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

  /// Returns all non-trashed items, most recent first. Pass [isSaved] to
  /// filter to only resisted (`true`) or purchased (`false`) items, or
  /// [pondering] to filter to undecided items (`is_saved IS NULL`).
  Future<List<ItemModel>> getAllItems({
    bool? isSaved,
    bool pondering = false,
  }) async {
    final db = await database;
    final conditions = ['deleted_at IS NULL'];
    final args = <Object?>[];
    if (pondering) {
      conditions.add('is_saved IS NULL');
    } else if (isSaved != null) {
      conditions.add('is_saved = ?');
      args.add(isSaved ? 1 : 0);
    }
    final rows = await db.query(
      tableItems,
      where: conditions.join(' AND '),
      whereArgs: args,
      orderBy: 'created_at DESC',
    );
    return rows.map(ItemModel.fromMap).toList();
  }

  /// Returns trashed items, most recently trashed first.
  Future<List<ItemModel>> getTrashedItems() async {
    final db = await database;
    final rows = await db.query(
      tableItems,
      where: 'deleted_at IS NOT NULL',
      orderBy: 'deleted_at DESC',
    );
    return rows.map(ItemModel.fromMap).toList();
  }

  /// Returns every item regardless of trash status — used by backup import
  /// dedup, which needs to recognize an already-trashed item as "already
  /// present" rather than re-inserting it as a live duplicate.
  Future<List<ItemModel>> getAllItemsIncludingTrashed() async {
    final db = await database;
    final rows = await db.query(tableItems);
    return rows.map(ItemModel.fromMap).toList();
  }

  /// Soft-deletes the item: marks it trashed (`deleted_at` set) without
  /// removing the row or its image file yet — recoverable via [restoreItem]
  /// until [purgeExpiredTrash] catches up with it. Returns the number of
  /// rows affected (0 if no such item existed).
  Future<int> deleteItem(int id) => _setDeletedAt(id, DateTime.now());

  /// Clears `deleted_at`, moving a trashed item back into the live set.
  /// Returns the number of rows affected (0 if no such item existed).
  Future<int> restoreItem(int id) => _setDeletedAt(id, null);

  Future<int> _setDeletedAt(int id, DateTime? deletedAt) async {
    final db = await database;
    return db.update(
      tableItems,
      {'deleted_at': deletedAt?.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Permanently removes items trashed more than [retention] ago: deletes
  /// both the row and its backing image file (CLAUDE.md's image-cleanup
  /// rule, deferred until purge rather than applied at soft-delete time).
  /// Returns the number of items purged.
  Future<int> purgeExpiredTrash({
    Duration retention = const Duration(days: 30),
    DateTime? now,
  }) async {
    final db = await database;
    final cutoff = (now ?? DateTime.now()).subtract(retention);
    final rows = await db.query(
      tableItems,
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoff.toIso8601String()],
    );

    var purged = 0;
    for (final row in rows) {
      final item = ItemModel.fromMap(row);
      final rowsDeleted = await db.delete(
        tableItems,
        where: 'id = ?',
        whereArgs: [item.id],
      );
      if (rowsDeleted > 0) {
        if (item.imagePath != null) {
          await fileHelper.deleteImage(item.imagePath!);
        }
        purged++;
      }
    }
    return purged;
  }

  /// Deletes files in the images directory that no row — live or trashed —
  /// references, e.g. a photo copied in by an entry form that never saved
  /// because the process was killed. Matches by file name (unique per copy)
  /// so a row can never lose its photo over a path-format difference, and
  /// skips files younger than [minAge] so a photo an entry form is holding
  /// right now isn't swept out from under it. Returns the number deleted.
  Future<int> purgeOrphanedImages({
    Duration minAge = const Duration(hours: 1),
    DateTime? now,
  }) async {
    final db = await database;
    final rows = await db.query(
      tableItems,
      columns: ['image_path'],
      where: 'image_path IS NOT NULL',
    );
    final referenced = {
      for (final row in rows) p.basename(row['image_path'] as String),
    };
    final cutoff = (now ?? DateTime.now()).subtract(minAge);

    var deleted = 0;
    for (final file in await fileHelper.listImageFiles()) {
      if (referenced.contains(p.basename(file.path))) continue;
      final stat = file.statSync();
      // A copy can keep its source's mtime; ctime ("changed") can't be
      // carried over, so the later of the two is when it landed here.
      final landedAt = stat.changed.isAfter(stat.modified)
          ? stat.changed
          : stat.modified;
      if (landedAt.isAfter(cutoff)) continue;
      file.deleteSync();
      deleted++;
    }
    return deleted;
  }

  Future<double> getTotalSaved() => _sumPrice(isSaved: true);

  Future<double> getTotalSpent() => _sumPrice(isSaved: false);

  Future<double> _sumPrice({required bool isSaved}) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(price * quantity) as total FROM $tableItems '
      'WHERE is_saved = ? AND deleted_at IS NULL',
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
