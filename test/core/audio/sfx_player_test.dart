import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/audio/sfx_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });

  setUp(calls.clear);

  test(
    'playResisted swallows errors (no real platform channel in tests)',
    () async {
      final sfx = SkipSfxPlayer();
      await expectLater(sfx.playResisted(), completes);
      sfx.dispose();
    },
  );

  test(
    'playResisted never plays the system sound when isEnabled returns false',
    () async {
      final sfx = SkipSfxPlayer(isEnabled: () => false);

      await sfx.playResisted();

      expect(calls.where((c) => c.method == 'SystemSound.play'), isEmpty);
      sfx.dispose();
    },
  );

  test(
    'playResisted plays the system sound when isEnabled returns true',
    () async {
      final sfx = SkipSfxPlayer(isEnabled: () => true);

      await sfx.playResisted();

      expect(calls.where((c) => c.method == 'SystemSound.play'), hasLength(1));
      sfx.dispose();
    },
  );
}
