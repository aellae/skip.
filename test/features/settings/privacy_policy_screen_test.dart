import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/features/settings/privacy_policy_screen.dart';

import '../../test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  Future<void> pumpPrivacyPolicy(
    WidgetTester tester, {
    Future<bool> Function(Uri url)? launchUrlOverride,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => LocaleProvider())],
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: PrivacyPolicyScreen(launchUrlOverride: launchUrlOverride),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the button opens the policy link externally', (
    tester,
  ) async {
    Uri? launchedUri;
    await pumpPrivacyPolicy(
      tester,
      launchUrlOverride: (uri) async {
        launchedUri = uri;
        return true;
      },
    );

    await tester.tap(find.text('Read the full policy'));
    await tester.pumpAndSettle();

    expect(launchedUri, PrivacyPolicyScreen.policyUri);
    expect(
      launchedUri.toString(),
      'https://github.com/aellae/skip./blob/master/PRIVACY_POLICY.md',
    );
  });

  testWidgets('shows an error snackbar when the link fails to open', (
    tester,
  ) async {
    await pumpPrivacyPolicy(tester, launchUrlOverride: (uri) async => false);

    await tester.tap(find.text('Read the full policy'));
    await tester.pumpAndSettle();

    expect(find.text("Couldn't open that link."), findsOneWidget);
  });
}
