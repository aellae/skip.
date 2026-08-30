import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/home/item_detail_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../test_helpers/widget_test_env.dart';

class _MockFileHelper extends Mock implements FileHelper {}

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  late _MockFileHelper mockFileHelper;
  late ItemsProvider itemsProvider;

  setUp(() {
    mockFileHelper = _MockFileHelper();
    when(() => mockFileHelper.deleteImage(any())).thenAnswer((_) async {});
    itemsProvider = ItemsProvider(
      databaseHelper: DatabaseHelper(
        fileHelper: mockFileHelper,
        testDbPath: inMemoryDatabasePath,
      ),
    );
  });

  Future<void> pumpDetail(WidgetTester tester) async {
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/to_delete.jpg',
      isSaved: true,
    );
    final item = itemsProvider.items.single;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: itemsProvider,
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: ItemDetailScreen(item: item),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'delete removes the item from the DB and deletes its image file',
    (tester) async {
      await pumpDetail(tester);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(itemsProvider.items, isEmpty);
      verify(
        () => mockFileHelper.deleteImage('skip_images/to_delete.jpg'),
      ).called(1);
    },
  );

  testWidgets('cancelling the delete dialog deletes nothing', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(itemsProvider.items, hasLength(1));
    verifyNever(() => mockFileHelper.deleteImage(any()));
  });

  testWidgets('changing status to Bought It updates the item retroactively', (
    tester,
  ) async {
    await pumpDetail(tester);
    expect(itemsProvider.items.single.isSaved, isTrue);

    await tester.ensureVisible(find.text('Bought It'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bought It'));
    await tester.pumpAndSettle();

    expect(itemsProvider.items.single.isSaved, isFalse);
  });
}
