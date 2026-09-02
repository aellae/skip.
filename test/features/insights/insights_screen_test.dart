import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/insights/insights_screen.dart';

import '../../test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  Future<void> pumpInsights(
    WidgetTester tester,
    ItemsProvider itemsProvider, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          theme: theme ?? AppThemes.minimal,
          home: const InsightsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows this month totals computed from seeded items', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(price: 20, imagePath: 'a.jpg', isSaved: true);
    await itemsProvider.addItem(price: 5, imagePath: 'b.jpg', isSaved: false);

    await pumpInsights(tester, itemsProvider);

    expect(find.text("This Month's Savings"), findsOneWidget);
    expect(find.text("This Month's Spent"), findsOneWidget);
    expect(find.text('\$20.00'), findsOneWidget);
    expect(find.text('\$5.00'), findsOneWidget);
  });

  testWidgets('shows zero totals with no items and still renders the chart', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();

    await pumpInsights(tester, itemsProvider);

    expect(find.text('\$0.00'), findsNWidgets(2));
    expect(find.text('Last 6 Months'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Spent'), findsOneWidget);
  });

  testWidgets('renders in the Y2K theme without error', (tester) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(price: 20, imagePath: 'a.jpg', isSaved: true);

    await pumpInsights(tester, itemsProvider, theme: AppThemes.y2k);

    expect(find.text("This Month's Savings"), findsOneWidget);
  });
}
