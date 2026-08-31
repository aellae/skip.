import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/backup_service.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/models/item_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockFileHelper extends Mock implements FileHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MockFileHelper mockFileHelper;
  late DatabaseHelper db;
  late BackupService backup;

  setUp(() {
    mockFileHelper = _MockFileHelper();
    when(() => mockFileHelper.deleteImage(any())).thenAnswer((_) async {});
    db = DatabaseHelper(
      fileHelper: mockFileHelper,
      testDbPath: inMemoryDatabasePath,
    );
    backup = BackupService(databaseHelper: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('buildJsonBackup / parseJsonBackup round trip', () {
    test('round-trips item fields through JSON', () async {
      await db.insertItem(
        ItemModel(
          title: 'Jacket',
          price: 120,
          imagePath: 'skip_images/a.jpg',
          isSaved: true,
          category: 'Clothes',
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final json = await backup.buildJsonBackup();
      final parsed = backup.parseJsonBackup(json);

      expect(parsed, hasLength(1));
      expect(parsed.single.title, 'Jacket');
      expect(parsed.single.price, 120);
      expect(parsed.single.isSaved, isTrue);
      expect(parsed.single.category, 'Clothes');
    });

    test('builds an empty items list when there are no items', () async {
      final json = await backup.buildJsonBackup();
      final parsed = backup.parseJsonBackup(json);

      expect(parsed, isEmpty);
      expect(jsonDecode(json)['version'], BackupService.formatVersion);
    });
  });

  group('parseJsonBackup validation', () {
    test('rejects invalid JSON', () {
      expect(
        () => backup.parseJsonBackup('not json'),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects JSON that is not a SKIP backup shape', () {
      expect(
        () => backup.parseJsonBackup(jsonEncode({'foo': 'bar'})),
        throwsA(isA<BackupFormatException>()),
      );
      expect(
        () => backup.parseJsonBackup(jsonEncode([1, 2, 3])),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an item entry that is not an object', () {
      expect(
        () => backup.parseJsonBackup(
          jsonEncode({
            'items': ['not-an-object'],
          }),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an item missing required fields', () {
      expect(
        () => backup.parseJsonBackup(
          jsonEncode({
            'items': [
              {'title': 'Missing price and image_path'},
            ],
          }),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });

    test('rejects an item with an unparseable created_at', () {
      expect(
        () => backup.parseJsonBackup(
          jsonEncode({
            'items': [
              {
                'price': 10,
                'image_path': 'a.jpg',
                'is_saved': 1,
                'created_at': 'not-a-date',
              },
            ],
          }),
        ),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });

  group('importItems', () {
    test('inserts items as new rows without clearing existing data', () async {
      await db.insertItem(
        ItemModel(
          price: 1,
          imagePath: 'existing.jpg',
          isSaved: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final count = await backup.importItems([
        ItemModel(
          title: 'Imported',
          price: 25,
          imagePath: 'imported.jpg',
          isSaved: false,
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      ]);

      final all = await db.getAllItems();
      expect(count, 1);
      expect(all, hasLength(2));
      expect(
        all.map((i) => i.imagePath),
        containsAll(['existing.jpg', 'imported.jpg']),
      );
    });
  });

  group('buildCsvBackup', () {
    test('includes a header row and one row per item', () async {
      await db.insertItem(
        ItemModel(
          title: 'Shoes',
          price: 50,
          imagePath: 'shoes.jpg',
          isSaved: true,
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );

      final csv = await backup.buildCsvBackup();
      final lines = csv.trim().split('\r\n');

      expect(lines, hasLength(2));
      expect(lines.first, contains('title'));
      expect(lines.first, contains('price'));
      expect(lines[1], contains('Shoes'));
      expect(lines[1], contains('50'));
    });
  });
}
