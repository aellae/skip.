import 'package:flutter/services.dart';

/// Thin wrapper around the platform's system sound for SKIP's "Resisted!"
/// cue.
///
/// Plays the OS's standard UI click sound rather than a bundled custom clip
/// — a placeholder until a dedicated "Resisted!" sound effect is ready.
class SkipSfxPlayer {
  /// Checked on every [playResisted] call (not just once) so a mute toggled
  /// mid-session takes effect immediately. Defaults to always-enabled when
  /// omitted, e.g. in tests that construct a bare [SkipSfxPlayer].
  final bool Function()? isEnabled;

  SkipSfxPlayer({this.isEnabled});

  /// Fire-and-forget: swallows any error so a platform playback failure
  /// never interrupts the interaction it's attached to.
  Future<void> playResisted() async {
    if (isEnabled != null && !isEnabled!()) return;
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Playback failed — celebration continues silently via
      // confetti/haptics instead.
    }
  }

  void dispose() {}
}
