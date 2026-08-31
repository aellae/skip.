import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/audio/sfx_player.dart';

void main() {
  // Plain `test()`, not `testWidgets()`: this runs on the real event loop
  // rather than Flutter's fake-clock test zone, so the platform-channel
  // call underneath AudioPlayer.play() can actually reject asynchronously
  // instead of risking the dart:io-style hang widget tests are prone to
  // (see test/test_helpers/widget_test_env.dart's doc comment). AudioPlayer
  // still talks to ServicesBinding on construction, so the binding needs
  // initializing even without a widget tree.
  TestWidgetsFlutterBinding.ensureInitialized();

  // AudioPlayer's constructor eagerly kicks off a shared "global audio
  // scope" init call that our code never awaits (only playResisted()'s own
  // play() call is awaited/caught), so an unmocked channel here would throw
  // as an unhandled async error unrelated to what this test checks. On a
  // real device the platform side answers it normally; mocking it just
  // neutralizes that test-harness-only gap.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (call) async => null,
      );

  test(
    'playResisted swallows errors (no real audio plugin in tests)',
    () async {
      final sfx = SkipSfxPlayer();
      await expectLater(sfx.playResisted(), completes);
      sfx.dispose();
    },
  );
}
