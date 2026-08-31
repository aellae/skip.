import 'package:audioplayers/audioplayers.dart';

/// Thin wrapper around [AudioPlayer] for SKIP's Y2K sound effects.
///
/// Only ever plays a bundled local asset — never a network URL — per
/// CLAUDE.md's offline rule. No SFX asset is bundled yet (Phase 3 shipped
/// without one; see BUILD_PROMPT.md §9 — real audio can't be fabricated),
/// so [playResisted] currently has nothing to load and fails silently.
/// Once a real file lands at `assets/sfx/resisted.mp3` and is declared in
/// pubspec.yaml, this starts playing it with no other code changes needed.
class SkipSfxPlayer {
  final AudioPlayer _player;

  SkipSfxPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static const String _resistedAsset = 'sfx/resisted.mp3';

  /// Fire-and-forget: swallows any error so a missing asset or platform
  /// playback failure never interrupts the interaction it's attached to.
  Future<void> playResisted() async {
    try {
      await _player.play(AssetSource(_resistedAsset));
    } catch (_) {
      // No bundled SFX yet, or playback failed — celebration continues
      // silently via confetti/haptics instead.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
