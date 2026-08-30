import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/items_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockFileHelper extends Mock implements FileHelper {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MockFileHelper mockFileHelper;
  late ItemsProvider provider;

  setUp(() {
    mockFileHelper = _MockFileHelper();
    when(() => mockFileHelper.deleteImage(any())).thenAnswer((_) async {});
    provider = ItemsProvider(
      databaseHelper: DatabaseHelper(
        fileHelper: mockFileHelper,
        testDbPath: inMemoryDatabasePath,
      ),
    );
  });

  test('starts empty with zero totals and not loading', () {
    expect(provider.items, isEmpty);
    expect(provider.totalSaved, 0);
    expect(provider.totalSpent, 0);
    expect(provider.isLoading, isFalse);
  });

  test('load populates items and totals from the database', () async {
    await provider.addItem(price: 10, imagePath: 'a.jpg', isSaved: true);
    await provider.addItem(price: 5, imagePath: 'b.jpg', isSaved: false);

    await provider.load();

    expect(provider.items, hasLength(2));
    expect(provider.totalSaved, 10);
    expect(provider.totalSpent, 5);
  });

  test('addItem inserts the item and refreshes state', () async {
    await provider.addItem(
      title: 'Shoes',
      price: 80,
      imagePath: 'shoes.jpg',
      isSaved: true,
    );

    expect(provider.items, hasLength(1));
    expect(provider.items.single.title, 'Shoes');
    expect(provider.totalSaved, 80);
  });

  test('setSavedStatus flips a specific item and refreshes totals', () async {
    await provider.addItem(price: 50, imagePath: 'x.jpg', isSaved: true);
    final id = provider.items.single.id!;

    await provider.setSavedStatus(id, false);

    expect(provider.items.single.isSaved, isFalse);
    expect(provider.totalSaved, 0);
    expect(provider.totalSpent, 50);
  });

  test('setSavedStatus is a no-op for an unknown id', () async {
    await provider.addItem(price: 50, imagePath: 'x.jpg', isSaved: true);

    await provider.setSavedStatus(999, false);

    expect(provider.items.single.isSaved, isTrue);
  });

  test('deleteItem removes it from state and deletes its image file', () async {
    await provider.addItem(
      price: 50,
      imagePath: 'to_delete.jpg',
      isSaved: true,
    );
    final id = provider.items.single.id!;

    await provider.deleteItem(id);

    expect(provider.items, isEmpty);
    verify(() => mockFileHelper.deleteImage('to_delete.jpg')).called(1);
  });

  test('items list is unmodifiable', () async {
    await provider.addItem(price: 50, imagePath: 'x.jpg', isSaved: true);

    expect(
      () => provider.items.add(provider.items.first),
      throwsUnsupportedError,
    );
  });

  test('notifies listeners on load', () async {
    var notifications = 0;
    provider.addListener(() => notifications++);

    await provider.load();

    expect(
      notifications,
      greaterThanOrEqualTo(2),
    ); // isLoading=true, then false
  });
}
