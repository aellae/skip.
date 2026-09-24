import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/currency_provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/core/utils/file_helper.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/trash/trash_screen.dart';
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
      // No debounce timer: the fake test clock fails on a pending one.
      autoBackupDebounce: null,
    );
  });

  Future<void> pumpTrash(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
        ],
        child: MaterialApp(theme: AppThemes.minimal, home: const TrashScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows an empty message with no trashed items', (tester) async {
    await pumpTrash(tester);

    expect(find.text('Trash is empty.'), findsOneWidget);
  });

  testWidgets('lists a trashed item with its price and a restore action', (
    tester,
  ) async {
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/a.jpg',
      isSaved: true,
    );
    final id = itemsProvider.items.single.id!;
    await itemsProvider.deleteItem(id);

    await pumpTrash(tester);

    expect(find.text('Jacket'), findsOneWidget);
    expect(find.text('\$120.00'), findsOneWidget);
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Trash is empty.'), findsNothing);
  });

  testWidgets('tapping Restore moves the item back into the live set', (
    tester,
  ) async {
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/a.jpg',
      isSaved: true,
    );
    final id = itemsProvider.items.single.id!;
    await itemsProvider.deleteItem(id);

    await pumpTrash(tester);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(itemsProvider.trashedItems, isEmpty);
    expect(itemsProvider.items, hasLength(1));
    expect(find.text('Trash is empty.'), findsOneWidget);
  });
}
