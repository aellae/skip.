import 'package:audioplayers/audioplayers.dart';

/// Thin wrapper around [AudioPlayer] for SKIP's Y2K sound effects.
///
/// Only ever plays a bundled local asset — never a network URL — per
/// CLAUDE.md's offline rule. The "Resisted!" cue is a user-supplied clip
/// bundled at `assets/sfx/resisted.m4a` and declared in pubspec.yaml.
class SkipSfxPlayer {
  final AudioPlayer _player;

  SkipSfxPlayer({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  static const String _resistedAsset = 'sfx/resisted.m4a';

  /// Fire-and-forget: swallows any error so a platform playback failure
  /// never interrupts the interaction it's attached to.
  Future<void> playResisted() async {
    try {
      await _player.play(AssetSource(_resistedAsset));
    } catch (_) {
      // Playback failed — celebration continues silently via
      // confetti/haptics instead.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
