import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets(
    'SkipApp shows the minimal logo by default and switches to SKIP! on toggle',
    (tester) async {
      await tester.pumpWidget(const SkipApp());
      await tester.pumpAndSettle();

      expect(find.text('skip.'), findsOneWidget);
      expect(find.text('SKIP!'), findsNothing);

      final context = tester.element(find.text('skip.'));
      context.read<ThemeProvider>().toggle();
      await tester.pumpAndSettle();

      expect(find.text('SKIP!'), findsOneWidget);
      expect(find.text('skip.'), findsNothing);
    },
  );
}
