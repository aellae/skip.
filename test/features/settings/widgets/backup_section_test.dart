import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/settings/widgets/backup_section.dart';

import '../../../test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('skip_backup_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> pumpSection(
    WidgetTester tester, {
    required ItemsProvider itemsProvider,
    Future<String?> Function()? pickJsonFile,
    Future<void> Function(String path, String subject)? shareFile,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: itemsProvider,
        child: MaterialApp(
          theme: AppThemes.minimal,
          home: Scaffold(
            body: BackupSection(
              pickJsonFile: pickJsonFile,
              shareFile: shareFile,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('export sheet offers JSON and CSV, and shares the built file', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(price: 10, imagePath: 'a.jpg', isSaved: true);

    String? sharedPath;
    String? sharedSubject;
    await pumpSection(
      tester,
      itemsProvider: itemsProvider,
      shareFile: (path, subject) async {
        sharedPath = path;
        sharedSubject = subject;
      },
    );

    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();

    expect(find.text('Export as JSON'), findsOneWidget);
    expect(find.text('Export as CSV'), findsOneWidget);

    await tester.tap(find.text('Export as JSON'));
    await tester.pumpAndSettle();

    expect(sharedPath, isNotNull);
    expect(sharedPath, endsWith('.json'));
    expect(sharedSubject, 'SKIP backup');
    // Sync read — see the comment on BackupSection._import for why real
    // async dart:io calls don't resolve inside testWidgets.
    final content = File(sharedPath!).readAsStringSync();
    expect(jsonDecode(content)['items'], hasLength(1));
  });

  testWidgets('import success shows the imported count and refreshes items', (
    tester,
  ) async {
    final backupFile = File('${tempDir.path}/backup.json')
      ..writeAsStringSync(
        jsonEncode({
          'items': [
            {
              'title': 'Restored',
              'price': 15,
              'image_path': 'restored.jpg',
              'is_saved': 1,
              'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
            },
          ],
        }),
      );

    final itemsProvider = buildTestItemsProvider();
    await pumpSection(
      tester,
      itemsProvider: itemsProvider,
      pickJsonFile: () async => backupFile.path,
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(find.text('Imported 1 item.'), findsOneWidget);
    expect(itemsProvider.items.single.title, 'Restored');
  });

  testWidgets('import failure surfaces a clear error and imports nothing', (
    tester,
  ) async {
    final backupFile = File('${tempDir.path}/bad.json')
      ..writeAsStringSync('not valid json');

    final itemsProvider = buildTestItemsProvider();
    await pumpSection(
      tester,
      itemsProvider: itemsProvider,
      pickJsonFile: () async => backupFile.path,
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(find.text("That file isn't valid JSON."), findsOneWidget);
    expect(itemsProvider.items, isEmpty);
  });

  testWidgets('import does nothing when the file picker is cancelled', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await pumpSection(
      tester,
      itemsProvider: itemsProvider,
      pickJsonFile: () async => null,
    );

    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();

    expect(itemsProvider.items, isEmpty);
    expect(find.textContaining('Imported'), findsNothing);
  });
}
