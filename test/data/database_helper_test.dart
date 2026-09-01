import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/models/item_model.dart';

class _MockFileHelper extends Mock implements FileHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MockFileHelper mockFileHelper;
  late DatabaseHelper db;

  ItemModel makeItem({
    String title = 'Item',
    double price = 10.0,
    bool isSaved = true,
    String imagePath = 'skip_images/photo.jpg',
    String? category,
    DateTime? createdAt,
  }) {
    return ItemModel(
      title: title,
      price: price,
      imagePath: imagePath,
      isSaved: isSaved,
      category: category,
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
    );
  }

  setUp(() {
    mockFileHelper = _MockFileHelper();
    when(() => mockFileHelper.deleteImage(any())).thenAnswer((_) async {});
    // A unique in-memory database per test keeps tests fully isolated.
    db = DatabaseHelper(
      fileHelper: mockFileHelper,
      testDbPath: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('DatabaseHelper CRUD', () {
    test('insertItem assigns an id and getItemById returns the row', () async {
      final id = await db.insertItem(makeItem(title: 'Jacket'));

      final fetched = await db.getItemById(id);

      expect(fetched, isNotNull);
      expect(fetched!.title, 'Jacket');
      expect(fetched.id, id);
    });

    test('getItemById returns null for a missing id', () async {
      final fetched = await db.getItemById(999);

      expect(fetched, isNull);
    });

    test('getAllItems returns items most-recent-first', () async {
      await db.insertItem(
        makeItem(title: 'Oldest', createdAt: DateTime.utc(2026, 1, 1)),
      );
      await db.insertItem(
        makeItem(title: 'Newest', createdAt: DateTime.utc(2026, 3, 1)),
      );
      await db.insertItem(
        makeItem(title: 'Middle', createdAt: DateTime.utc(2026, 2, 1)),
      );

      final items = await db.getAllItems();

      expect(items.map((i) => i.title), ['Newest', 'Middle', 'Oldest']);
    });

    test('getAllItems filters by isSaved', () async {
      await db.insertItem(makeItem(title: 'Resisted', isSaved: true));
      await db.insertItem(makeItem(title: 'Bought', isSaved: false));

      final saved = await db.getAllItems(isSaved: true);
      final spent = await db.getAllItems(isSaved: false);

      expect(saved.map((i) => i.title), ['Resisted']);
      expect(spent.map((i) => i.title), ['Bought']);
    });

    test('updateItem persists changed fields', () async {
      final id = await db.insertItem(makeItem(price: 10, isSaved: true));
      final original = (await db.getItemById(id))!;

      await db.updateItem(original.copyWith(price: 25, isSaved: false));

      final updated = await db.getItemById(id);
      expect(updated!.price, 25);
      expect(updated.isSaved, isFalse);
    });

    test('updateItem throws for an item without an id', () async {
      expect(() => db.updateItem(makeItem()), throwsArgumentError);
    });

    test('deleteItem removes the row and deletes its image file', () async {
      final id = await db.insertItem(
        makeItem(imagePath: 'skip_images/to_delete.jpg'),
      );

      final rowsDeleted = await db.deleteItem(id);

      expect(rowsDeleted, 1);
      expect(await db.getItemById(id), isNull);
      verify(
        () => mockFileHelper.deleteImage('skip_images/to_delete.jpg'),
      ).called(1);
    });

    test(
      'deleteItem on a missing id deletes nothing and never touches the file system',
      () async {
        final rowsDeleted = await db.deleteItem(999);

        expect(rowsDeleted, 0);
        verifyNever(() => mockFileHelper.deleteImage(any()));
      },
    );

    test(
      'getTotalSaved and getTotalSpent sum only their own category',
      () async {
        await db.insertItem(makeItem(price: 30, isSaved: true));
        await db.insertItem(makeItem(price: 20, isSaved: true));
        await db.insertItem(makeItem(price: 15, isSaved: false));

        expect(await db.getTotalSaved(), 50);
        expect(await db.getTotalSpent(), 15);
      },
    );

    test('totals are zero with no items', () async {
      expect(await db.getTotalSaved(), 0.0);
      expect(await db.getTotalSpent(), 0.0);
    });

    test('category persists round-trip through insert/read', () async {
      final id = await db.insertItem(makeItem(category: 'Shoes'));

      final fetched = await db.getItemById(id);

      expect(fetched!.category, 'Shoes');
    });

    test('purchase_url persists round-trip through insert/read', () async {
      final id = await db.insertItem(
        ItemModel(
          price: 10,
          imagePath: 'a.jpg',
          isSaved: true,
          createdAt: DateTime.utc(2026, 1, 1),
          purchaseUrl: 'https://example.com/product',
        ),
      );

      final fetched = await db.getItemById(id);

      expect(fetched!.purchaseUrl, 'https://example.com/product');
    });

    test('purchase_url defaults to null when not provided', () async {
      final id = await db.insertItem(makeItem());

      final fetched = await db.getItemById(id);

      expect(fetched!.purchaseUrl, isNull);
    });
  });

  group('DatabaseHelper migration', () {
    test(
      'upgrading a v1 database adds purchase_url and keeps existing rows',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'skip_migration_test_',
        );
        final dbPath = p.join(tempDir.path, 'migration.db');
        try {
          final v1Db = await databaseFactory.openDatabase(
            dbPath,
            options: OpenDatabaseOptions(
              version: 1,
              onCreate: (rawDb, version) async {
                await rawDb.execute('''
                  CREATE TABLE items (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    title TEXT,
                    price REAL NOT NULL,
                    image_path TEXT NOT NULL,
                    is_saved INTEGER NOT NULL,
                    category TEXT,
                    created_at TEXT NOT NULL
                  )
                ''');
              },
            ),
          );
          final id = await v1Db.insert('items', {
            'title': 'Pre-migration item',
            'price': 42.0,
            'image_path': 'a.jpg',
            'is_saved': 1,
            'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
          });
          await v1Db.close();

          final upgraded = DatabaseHelper(
            fileHelper: mockFileHelper,
            testDbPath: dbPath,
          );
          final item = await upgraded.getItemById(id);

          expect(item, isNotNull);
          expect(item!.title, 'Pre-migration item');
          expect(item.purchaseUrl, isNull);

          await upgraded.close();
        } finally {
          await tempDir.delete(recursive: true);
        }
      },
    );
  });

  group('DatabaseHelper schema', () {
    test(
      'onCreate defines the items table with the documented columns',
      () async {
        final rawDb = await db.database;
        final columns = await rawDb.rawQuery('PRAGMA table_info(items)');
        final names = columns.map((c) => c['name']).toSet();

        expect(names, {
          'id',
          'title',
          'price',
          'image_path',
          'is_saved',
          'category',
          'created_at',
          'purchase_url',
        });
      },
    );

    test('onCreate defines indexes on created_at and is_saved', () async {
      final rawDb = await db.database;
      final indexes = await rawDb.rawQuery("PRAGMA index_list(items)");
      final indexNames = indexes.map((i) => i['name']).toSet();

      expect(
        indexNames,
        containsAll(['idx_items_created_at', 'idx_items_is_saved']),
      );
    });

    test('price and image_path are NOT NULL', () async {
      final rawDb = await db.database;
      expect(
        () => rawDb.rawInsert(
          "INSERT INTO items (image_path, is_saved, created_at) VALUES ('a.jpg', 1, '2026-01-01')",
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect(
        () => rawDb.rawInsert(
          "INSERT INTO items (price, is_saved, created_at) VALUES (10, 1, '2026-01-01')",
        ),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  // Phase 5 hardening: an index existing (see "onCreate defines indexes..."
  // above) doesn't guarantee the query planner actually uses it — confirmed
  // here via EXPLAIN QUERY PLAN against the exact SQL shapes the app's real
  // methods issue, per BUILD_PROMPT.md §5, before ticking that roadmap box.
  group('Query plan uses the declared indexes', () {
    Future<String> queryPlan(String sql, [List<Object?>? args]) async {
      final rawDb = await db.database;
      final rows = await rawDb.rawQuery('EXPLAIN QUERY PLAN $sql', args);
      return rows.map((r) => r['detail']).join(' | ');
    }

    test('getAllItems(isSaved: ...) uses idx_items_is_saved', () async {
      // Matches DatabaseHelper.getAllItems's compiled SQL when a filter is
      // passed. SQLite picks the is_saved index for the search and sorts
      // the (small, already-filtered) remainder in a temp b-tree rather
      // than also using idx_items_created_at — expected and fine at this
      // app's scale, not a missing-index problem.
      final plan = await queryPlan(
        'SELECT * FROM items WHERE is_saved = ? ORDER BY created_at DESC',
        [1],
      );
      expect(plan, contains('USING INDEX idx_items_is_saved'));
    });

    test('getAllItems() unfiltered uses idx_items_created_at', () async {
      final plan = await queryPlan(
        'SELECT * FROM items ORDER BY created_at DESC',
      );
      expect(plan, contains('USING INDEX idx_items_created_at'));
    });

    test('_sumPrice (Total Saved/Spent) uses idx_items_is_saved', () async {
      final plan = await queryPlan(
        'SELECT SUM(price) as total FROM items WHERE is_saved = ?',
        [1],
      );
      expect(plan, contains('USING INDEX idx_items_is_saved'));
    });
  });
}
