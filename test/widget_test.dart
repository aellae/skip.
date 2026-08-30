import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/main.dart';

import 'test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  testWidgets(
    'SkipApp shows the minimal logo by default and switches to SKIP! on toggle',
    (tester) async {
      final themeProvider = ThemeProvider();
      final itemsProvider = buildTestItemsProvider();

      await tester.pumpWidget(
        SkipApp(
          themeProviderOverride: themeProvider,
          itemsProviderOverride: itemsProvider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('skip.'), findsOneWidget);
      expect(find.text('SKIP!'), findsNothing);

      themeProvider.toggle();
      await tester.pumpAndSettle();

      expect(find.text('SKIP!'), findsOneWidget);
      expect(find.text('skip.'), findsNothing);
    },
  );
}
