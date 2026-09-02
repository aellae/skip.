import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
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

  Future<void> pumpDetail(
    WidgetTester tester, {
    String? purchaseUrl,
    Future<bool> Function(Uri url)? launchUrlOverride,
  }) async {
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/to_delete.jpg',
      isSaved: true,
      purchaseUrl: purchaseUrl,
    );
    final item = itemsProvider.items.single;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: ItemDetailScreen(
            item: item,
            launchUrlOverride: launchUrlOverride,
          ),
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

  testWidgets('status can be switched back and forth repeatedly', (
    tester,
  ) async {
    await pumpDetail(tester);
    expect(itemsProvider.items.single.isSaved, isTrue);

    await tester.ensureVisible(find.text('Bought It'));
    await tester.tap(find.text('Bought It'));
    await tester.pumpAndSettle();
    expect(itemsProvider.items.single.isSaved, isFalse);

    await tester.tap(find.text('Resisted!'));
    await tester.pumpAndSettle();
    expect(itemsProvider.items.single.isSaved, isTrue);

    await tester.tap(find.text('Bought It'));
    await tester.pumpAndSettle();
    expect(itemsProvider.items.single.isSaved, isFalse);
  });

  testWidgets('shows "Add product link" when no link is set', (tester) async {
    await pumpDetail(tester);

    expect(find.text('Add product link'), findsOneWidget);
    expect(find.text('Visit product page'), findsNothing);
  });

  testWidgets('adding a valid product link persists it', (tester) async {
    await pumpDetail(tester);

    await tester.ensureVisible(find.text('Add product link'));
    await tester.tap(find.text('Add product link'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'https://example.com/product',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      itemsProvider.items.single.purchaseUrl,
      'https://example.com/product',
    );
    expect(find.text('Visit product page'), findsOneWidget);
  });

  testWidgets('an invalid product link is rejected in the dialog', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.ensureVisible(find.text('Add product link'));
    await tester.tap(find.text('Add product link'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'not-a-link');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid link (https://…).'), findsOneWidget);
    expect(itemsProvider.items.single.purchaseUrl, isNull);
  });

  testWidgets('tapping Visit product page launches the stored link', (
    tester,
  ) async {
    Uri? launchedUri;
    await pumpDetail(
      tester,
      purchaseUrl: 'https://example.com/product',
      launchUrlOverride: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    await tester.ensureVisible(find.text('Visit product page'));
    await tester.tap(find.text('Visit product page'));
    await tester.pumpAndSettle();

    expect(launchedUri, Uri.parse('https://example.com/product'));
  });

  testWidgets('shows an error snackbar when the link fails to launch', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      purchaseUrl: 'https://example.com/product',
      launchUrlOverride: (uri) async => false,
    );

    await tester.ensureVisible(find.text('Visit product page'));
    await tester.tap(find.text('Visit product page'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open that link."), findsOneWidget);
  });

  testWidgets('removing an existing product link clears it', (tester) async {
    await pumpDetail(tester, purchaseUrl: 'https://example.com/product');

    await tester.ensureVisible(find.byIcon(Icons.edit_outlined));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(itemsProvider.items.single.purchaseUrl, isNull);
    expect(find.text('Add product link'), findsOneWidget);
  });
}
