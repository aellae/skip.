import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Runs around every test file. Gives each test fresh in-memory
/// SharedPreferences: anything that saves an item touches prefs (the
/// auto-backup throttle), and without a mock the real plugin channel never
/// answers under the test binding. Per-file setUps that seed specific
/// values still run after this one and win.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  await testMain();
}
