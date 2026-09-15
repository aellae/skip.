import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/features/settings/support_screen.dart';

import '../../test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  Future<void> pumpSupport(
    WidgetTester tester, {
    Future<bool> Function(Uri url)? launchUrlOverride,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => LocaleProvider())],
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: SupportScreen(launchUrlOverride: launchUrlOverride),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the button opens the PayPal link externally', (
    tester,
  ) async {
    Uri? launchedUri;
    await pumpSupport(
      tester,
      launchUrlOverride: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    await tester.tap(find.text('Support the developer'));
    await tester.pumpAndSettle();

    expect(launchedUri, SupportScreen.paypalUri);
    expect(launchedUri.toString(), 'https://paypal.me/eletarantino');
  });

  testWidgets('shows an error snackbar when the link fails to open', (
    tester,
  ) async {
    await pumpSupport(tester, launchUrlOverride: (uri) async => false);

    await tester.tap(find.text('Support the developer'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open that link."), findsOneWidget);
  });
}
