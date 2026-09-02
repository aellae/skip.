import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/home/home_screen.dart';

import '../../test_helpers/widget_test_env.dart';

Widget _buildApp(ItemsProvider provider, {ThemeData? theme}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: provider),
      ChangeNotifierProvider(create: (_) => LocaleProvider()),
    ],
    child: MaterialApp(
      theme: theme ?? AppThemes.minimal,
      home: const HomeScreen(),
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

  testWidgets('shows the dynamic logo text from the active theme', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();

    await tester.pumpWidget(_buildApp(itemsProvider, theme: AppThemes.y2k));
    await tester.pumpAndSettle();

    expect(find.text('SKIP!'), findsOneWidget);
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
    expect(find.text('Last 6 Months'), findsOneWidget);
  });
}
