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

  test('playResisted swallows errors when no SFX asset is bundled', () async {
    final sfx = SkipSfxPlayer();
    await expectLater(sfx.playResisted(), completes);
    sfx.dispose();
  });
}
