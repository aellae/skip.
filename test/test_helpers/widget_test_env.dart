import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:skip/data/database_helper.dart';
import 'package:skip/data/items_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_path_provider.dart';

/// Common setup for widget tests that render a screen backed by
/// [ItemsProvider]: points sqflite at an ffi factory that won't spawn a
/// background isolate (Flutter's fake-async test clock can deadlock waiting
/// on that isolate — see widget_test.dart), and fakes path_provider onto a
/// temp dir.
///
/// Call once from `setUpAll`. Returns the temp docs dir so callers can clean
/// it up in `tearDownAll` if desired.
Future<Directory> setUpWidgetTestEnvironment() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  final tempDir = await Directory.systemTemp.createTemp(
    'skip_widget_test_docs_',
  );
  PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);
  return tempDir;
}

/// A fresh, isolated [ItemsProvider] backed by an in-memory database —
/// safe to use per-test without leaking state between tests.
ItemsProvider buildTestItemsProvider() {
  return ItemsProvider(
    databaseHelper: DatabaseHelper(testDbPath: inMemoryDatabasePath),
  );
}
