import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/app_currency.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/currency_provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/settings/sfx_provider.dart';
import 'package:skip/core/settings/wage_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/item_entry/item_entry_screen.dart';
import 'package:skip/features/item_entry/widgets/decision_toggle.dart';

import '../../test_helpers/widget_test_env.dart';

/// Returns a fixed 1x1 PNG so the entry flow can "pick" an image without
/// touching the real camera/gallery platform channels.
class _FakeImagePicker extends ImagePicker {
  final File file;

  /// Records the constraints passed on the most recent [pickImage] call so
  /// tests can assert the app requests a capped, compressed image rather
  /// than the raw camera/gallery original.
  double? lastMaxWidth;
  double? lastMaxHeight;
  int? lastImageQuality;

  _FakeImagePicker(this.file);

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastMaxWidth = maxWidth;
    lastMaxHeight = maxHeight;
    lastImageQuality = imageQuality;
    return XFile(file.path);
  }
}

const _onePixelPng = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

void main() {
  late Directory sourceDir;
  late File sourceImage;
  late _FakeImagePicker fakePicker;

  setUpAll(() => setUpWidgetTestEnvironment());

  setUp(() async {
    sourceDir = await Directory.systemTemp.createTemp('skip_entry_source_');
    sourceImage = File('${sourceDir.path}/pick.png')
      ..writeAsBytesSync(_onePixelPng);
  });

  tearDown(() async {
    if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
  });

  Future<void> pumpEntryScreen(
    WidgetTester tester,
    ItemsProvider itemsProvider, {
    AppLocale locale = AppLocale.en,
    AppCurrency currency = AppCurrency.usd,
    double? hourlyWage,
    XFile? recoveredImage,
  }) async {
    fakePicker = _FakeImagePicker(sourceImage);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(initial: locale),
          ),
          ChangeNotifierProvider(
            create: (_) => CurrencyProvider(initial: currency),
          ),
          ChangeNotifierProvider(create: (_) => SfxProvider()),
          ChangeNotifierProvider(
            create: (_) => WageProvider(initial: hourlyWage),
          ),
        ],
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: ItemEntryScreen(
            imagePicker: fakePicker,
            recoveredImage: recoveredImage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickAPhoto(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.add_a_photo));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
  }

  // The form is taller than the default 800x600 test viewport, so buttons
  // below the fold need to be scrolled into view before tapping.
  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.pumpAndSettle();
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'requests a resolution-capped, compressed image from the picker',
    (tester) async {
      final itemsProvider = buildTestItemsProvider();
      await pumpEntryScreen(tester, itemsProvider);
      await pickAPhoto(tester);

      // Guards against a full-res camera photo landing on disk uncompressed
      // (Phase 5 hardening) — Image.file's cacheWidth elsewhere only bounds
      // the display-time decode, not what actually gets stored in
      // skip_images/.
      expect(fakePicker.lastMaxWidth, 2000);
      expect(fakePicker.lastMaxHeight, 2000);
      expect(fakePicker.lastImageQuality, 85);
    },
  );

  testWidgets(
    'a photo recovered after process death is copied in and saved with the item',
    (tester) async {
      final itemsProvider = buildTestItemsProvider();
      await pumpEntryScreen(
        tester,
        itemsProvider,
        recoveredImage: XFile(sourceImage.path),
      );

      expect(find.byType(Image), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '5');
      await tapText(tester, 'Resisted!');

      final imagePath = itemsProvider.items.single.imagePath;
      expect(imagePath, startsWith('skip_images/'));
      expect(imagePath, isNot(sourceImage.path));
    },
  );

  testWidgets('rejects a non-numeric price', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    // The field's input formatter only allows digits/decimal, so non-numeric
    // text can't actually be typed — set the controller directly to
    // exercise the validator's own not-a-number rejection.
    final field = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Price'),
    );
    field.controller!.text = 'abc';
    await tapText(tester, 'Resisted!');

    expect(find.text('Enter a valid number.'), findsOneWidget);
    expect(itemsProvider.items, isEmpty);
  });

  testWidgets('rejects a negative price', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    // The field's input formatter only allows digits/decimal, so a leading
    // '-' can't be typed — set the controller text directly to exercise the
    // validator's own negative-price rejection.
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '5');
    final field = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Price'),
    );
    field.controller!.text = '-5';
    await tapText(tester, 'Resisted!');

    expect(find.text('Price must be greater than zero.'), findsOneWidget);
    expect(itemsProvider.items, isEmpty);
  });

  testWidgets('rejects an empty price', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tapText(tester, 'Resisted!');

    expect(find.text('Enter a price.'), findsOneWidget);
    expect(itemsProvider.items, isEmpty);
  });

  testWidgets('saves without a photo — it is optional at entry time', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '12.50',
    );
    await tapText(tester, 'Resisted!');

    expect(itemsProvider.items, hasLength(1));
    expect(itemsProvider.items.single.imagePath, isNull);
  });

  testWidgets('tapping Resisted! saves immediately as Resisted', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '19.99',
    );
    await tapText(tester, 'Resisted!');

    expect(itemsProvider.items, hasLength(1));
    expect(itemsProvider.items.single.price, 19.99);
    expect(itemsProvider.items.single.isSaved, isTrue);
  });

  testWidgets('tapping Bought It saves immediately as Bought', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '4.50');
    await tapText(tester, 'Bought It');

    expect(itemsProvider.items, hasLength(1));
    expect(itemsProvider.items.single.isSaved, isFalse);
  });

  testWidgets('saves a valid product link alongside the item', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '19.99',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product link (optional)'),
      'https://example.com/product',
    );
    await tapText(tester, 'Resisted!');

    expect(itemsProvider.items, hasLength(1));
    expect(
      itemsProvider.items.single.purchaseUrl,
      'https://example.com/product',
    );
  });

  testWidgets('leaving the product link blank saves it as null', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '19.99',
    );
    await tapText(tester, 'Resisted!');

    expect(itemsProvider.items.single.purchaseUrl, isNull);
  });

  testWidgets('price field shows a dollar prefix for USD', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);

    expect(find.text('\$ '), findsOneWidget);
    expect(find.text('€'), findsNothing);
  });

  testWidgets('price field shows a euro suffix for EUR', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider, currency: AppCurrency.eur);

    expect(find.text('€'), findsOneWidget);
    expect(find.text('\$ '), findsNothing);
  });

  testWidgets(
    'currency and language are independent — Italian UI can still price in USD',
    (tester) async {
      final itemsProvider = buildTestItemsProvider();
      await pumpEntryScreen(
        tester,
        itemsProvider,
        locale: AppLocale.it,
        currency: AppCurrency.usd,
      );

      expect(find.text('Prezzo'), findsOneWidget);
      expect(find.text('\$ '), findsOneWidget);
      expect(find.text('€'), findsNothing);
    },
  );

  testWidgets(
    'shows a live hours-of-work preview under the price when an hourly wage is set',
    (tester) async {
      final itemsProvider = buildTestItemsProvider();
      await pumpEntryScreen(tester, itemsProvider, hourlyWage: 20);

      expect(find.textContaining('hrs of work'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Price'),
        '100',
      );
      await tester.pumpAndSettle();

      expect(find.text('≈ 5.0 hrs of work'), findsOneWidget);
    },
  );

  testWidgets('rejects an invalid product link', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpEntryScreen(tester, itemsProvider);
    await pickAPhoto(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price'),
      '19.99',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product link (optional)'),
      'not-a-link',
    );
    await tapText(tester, 'Resisted!');

    expect(find.text('Enter a valid link (https://…).'), findsOneWidget);
    expect(itemsProvider.items, isEmpty);
  });

  testWidgets(
    'quantity buttons and the picked photo have screen-reader labels',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEntryScreen(tester, buildTestItemsProvider());

      expect(find.bySemanticsLabel('Decrease quantity'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase quantity'), findsOneWidget);
      expect(find.bySemanticsLabel('Photo, tap to change'), findsNothing);

      await pickAPhoto(tester);

      expect(find.bySemanticsLabel('Photo, tap to change'), findsOneWidget);
      semantics.dispose();
    },
  );

  group('leaving the screen after a decision', () {
    /// Opens the entry form on top of a placeholder route, so a pop is
    /// observable.
    Future<void> pumpPushedEntry(
      WidgetTester tester,
      ItemsProvider itemsProvider,
      ThemeData theme,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: itemsProvider),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
            ChangeNotifierProvider(create: (_) => SfxProvider()),
            ChangeNotifierProvider(create: (_) => WageProvider()),
          ],
          child: MaterialApp(
            theme: theme,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ItemEntryScreen()),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '5');
      await tester.ensureVisible(find.text('Resisted!'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Y2K Resisted! stays on screen for the celebration, then pops once',
      (tester) async {
        final itemsProvider = buildTestItemsProvider();
        await pumpPushedEntry(tester, itemsProvider, AppThemes.y2k);

        await tester.tap(find.text('Resisted!'));
        await tester.pump(const Duration(milliseconds: 600));
        // Mid-celebration: the form is still up and further taps are ignored.
        expect(find.byType(ItemEntryScreen), findsOneWidget);
        await tester.tap(find.text('Resisted!'), warnIfMissed: false);

        await tester.pump(DecisionToggle.celebrationDuration);
        await tester.pumpAndSettle();

        expect(find.byType(ItemEntryScreen), findsNothing);
        expect(itemsProvider.items, hasLength(1));
      },
    );

    testWidgets('Minimal pops as soon as the item is saved', (tester) async {
      final itemsProvider = buildTestItemsProvider();
      await pumpPushedEntry(tester, itemsProvider, AppThemes.minimal);

      await tester.tap(find.text('Resisted!'));
      // Well under the celebration hold: frame by frame through the insert
      // and the route's exit transition.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(find.byType(ItemEntryScreen), findsNothing);
      expect(itemsProvider.items, hasLength(1));
    });
  });
}
