import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skip/core/audio/sfx_player.dart';

class _MockAudioPlayer extends Mock implements AudioPlayer {}

class _FakeSource extends Fake implements Source {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSource());
  });

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
  // Same reasoning as the global channel above, but for the per-instance
  // channel AudioPlayer's constructor also eagerly calls into (its own
  // "create" message) — without this, that dangling unawaited future can
  // reject after this test has already moved on to another one.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
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

  test(
    'playResisted never touches the player when isEnabled returns false',
    () async {
      final mockPlayer = _MockAudioPlayer();
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});
      when(() => mockPlayer.dispose()).thenAnswer((_) async {});
      final sfx = SkipSfxPlayer(player: mockPlayer, isEnabled: () => false);

      await sfx.playResisted();

      verifyNever(() => mockPlayer.play(any()));
      sfx.dispose();
    },
  );

  test('playResisted plays when isEnabled returns true', () async {
    final mockPlayer = _MockAudioPlayer();
    when(() => mockPlayer.play(any())).thenAnswer((_) async {});
    when(() => mockPlayer.dispose()).thenAnswer((_) async {});
    final sfx = SkipSfxPlayer(player: mockPlayer, isEnabled: () => true);

    await sfx.playResisted();

    verify(() => mockPlayer.play(any())).called(1);
    sfx.dispose();
  });
}
