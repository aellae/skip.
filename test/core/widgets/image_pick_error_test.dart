import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/app_strings.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/core/widgets/image_source_sheet.dart';

void main() {
  Future<void> showError(WidgetTester tester, Object error) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.minimal,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showImagePickError(
                context,
                error,
                const AppStrings(AppLocale.de),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  const strings = AppStrings(AppLocale.de);

  testWidgets('camera access denied says so, localized', (tester) async {
    await showError(tester, PlatformException(code: 'camera_access_denied'));
    expect(find.text(strings.cameraAccessOff), findsOneWidget);
    expect(find.text(strings.somethingWentWrong), findsNothing);
  });

  testWidgets('photo access denied says so, localized', (tester) async {
    await showError(tester, PlatformException(code: 'photo_access_denied'));
    expect(find.text(strings.photoAccessOff), findsOneWidget);
  });

  testWidgets('any other error keeps the generic message', (tester) async {
    await showError(tester, PlatformException(code: 'invalid_image'));
    expect(find.text(strings.somethingWentWrong), findsOneWidget);

    await showError(tester, const FileSystemException('copy failed'));
    expect(find.text(strings.somethingWentWrong), findsWidgets);
  });

  testWidgets('shows the camera option off iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.minimal,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showImageSourceSheet(
                context,
                strings: strings,
                onPick: (_) {},
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(strings.camera), findsOneWidget);
    expect(find.text(strings.gallery), findsOneWidget);
  });
}
