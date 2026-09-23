import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/currency_provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/settings/sfx_provider.dart';
import 'package:skip/core/settings/wage_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/home/home_screen.dart';
import 'package:skip/features/item_entry/item_entry_screen.dart';

import '../../test_helpers/widget_test_env.dart';

/// Answers `retrieveLostData` with a fixed response, standing in for a
/// photo Android handed back after killing the app mid-pick.
class _LostDataImagePicker extends ImagePicker {
  final LostDataResponse response;

  _LostDataImagePicker(this.response);

  @override
  Future<LostDataResponse> retrieveLostData() async => response;
}

Widget _buildApp(
  ItemsProvider provider, {
  ThemeData? theme,
  double? hourlyWage,
  ImagePicker? imagePicker,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ChangeNotifierProvider(create: (_) => SfxProvider()),
      ChangeNotifierProvider(create: (_) => WageProvider(initial: hourlyWage)),
    ],
    child: MaterialApp(
      theme: theme ?? AppThemes.minimal,
      home: HomeScreen(imagePicker: imagePicker),
    ),
  );
}

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  testWidgets('shows Total Saved / Total Spent computed from seeded items', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/a.jpg',
      isSaved: true,
    );
    await itemsProvider.addItem(
      title: 'Coffee',
      price: 5,
      imagePath: 'skip_images/b.jpg',
      isSaved: false,
    );
    await itemsProvider.addItem(
      title: 'Snack',
      price: 3,
      imagePath: 'skip_images/d.jpg',
      isSaved: false,
    );
    await itemsProvider.addItem(
      price: 30,
      imagePath: 'skip_images/c.jpg',
      isSaved: true,
    );

    await tester.pumpWidget(_buildApp(itemsProvider));
    await tester.pumpAndSettle();

    expect(find.text('\$150.00'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
    expect(find.text('Total Saved'), findsOneWidget);
    expect(find.text('Total Spent'), findsOneWidget);
  });

  testWidgets('shows an empty-state message and zero totals with no items', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();

    await tester.pumpWidget(_buildApp(itemsProvider));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nothing logged yet'), findsOneWidget);
    expect(find.text('\$0.00'), findsNWidgets(2));
  });

  testWidgets('shows hours of work on each card when an hourly wage is set', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(
      title: 'Jacket',
      price: 120,
      imagePath: 'skip_images/a.jpg',
      isSaved: true,
    );

    await tester.pumpWidget(_buildApp(itemsProvider, hourlyWage: 20));
    await tester.pumpAndSettle();

    expect(find.text('≈ 6.0 hrs of work'), findsOneWidget);
  });

  testWidgets('shows the dynamic logo text from the active theme', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();

    await tester.pumpWidget(_buildApp(itemsProvider, theme: AppThemes.y2k));
    await tester.pumpAndSettle();

    // The logo is a themed PNG wordmark, labelled with logoText for a11y.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image == const AssetImage('assets/images/logo_y2k.png') &&
            w.semanticLabel == 'Skip!',
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the insights icon opens the Insights screen', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();

    await tester.pumpWidget(_buildApp(itemsProvider));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Insights'), findsOneWidget);
    expect(
      find.text(
        'No trends to show yet.\nLog a few items to see your monthly breakdown.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'reopens the entry form with a photo recovered after process death',
    (tester) async {
      final sourceDir = Directory.systemTemp.createTempSync('skip_lost_');
      addTearDown(() => sourceDir.deleteSync(recursive: true));
      final lost = File('${sourceDir.path}/lost.jpg')..writeAsBytesSync([0]);

      await tester.pumpWidget(
        _buildApp(
          buildTestItemsProvider(),
          imagePicker: _LostDataImagePicker(
            LostDataResponse(file: XFile(lost.path), type: RetrieveType.image),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(ItemEntryScreen), findsOneWidget);
      final entry = tester.widget<ItemEntryScreen>(
        find.byType(ItemEntryScreen),
      );
      expect(entry.recoveredImage?.path, lost.path);
    },
  );

  testWidgets('stays on home when there is no lost photo to recover', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        buildTestItemsProvider(),
        imagePicker: _LostDataImagePicker(LostDataResponse.empty()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItemEntryScreen), findsNothing);
  });

  testWidgets('the add FAB has a screen-reader label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_buildApp(buildTestItemsProvider()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Log an item'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('keeps the body clear of a landscape display cutout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(left: 128 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildApp(buildTestItemsProvider()));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Total Saved')).dx,
      greaterThanOrEqualTo(128),
    );
  });
}
