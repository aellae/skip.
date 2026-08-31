import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/audio/sfx_player.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/tap_scale.dart';

/// "Resisted! / Skip" vs. "Bought It / Spent" decision toggle.
///
/// Selecting "Resisted!" in the Y2K aesthetic triggers a confetti burst, a
/// stronger haptic impact, and an SFX cue; every other selection just gets
/// the shared [TapScale] press animation and a light haptic tick.
class DecisionToggle extends StatefulWidget {
  final bool isSaved;
  final ValueChanged<bool> onChanged;
  final SkipSfxPlayer? sfxPlayer;

  const DecisionToggle({
    super.key,
    required this.isSaved,
    required this.onChanged,
    this.sfxPlayer,
  });

  @override
  State<DecisionToggle> createState() => _DecisionToggleState();
}

class _DecisionToggleState extends State<DecisionToggle> {
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 400),
  );
  late final SkipSfxPlayer _sfx = widget.sfxPlayer ?? SkipSfxPlayer();

  @override
  void dispose() {
    _confettiController.dispose();
    _sfx.dispose();
    super.dispose();
  }

  void _selectResisted(bool isY2K) {
    if (isY2K) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
      _sfx.playResisted();
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onChanged(true);
  }

  void _selectBought() {
    HapticFeedback.selectionClick();
    widget.onChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleOption(
                label: 'Resisted!',
                selected: widget.isSaved,
                color: skipTheme.savedColor,
                onTap: () => _selectResisted(skipTheme.isY2K),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ToggleOption(
                label: 'Bought It',
                selected: !widget.isSaved,
                color: skipTheme.spentColor,
                onTap: _selectBought,
              ),
            ),
          ],
        ),
        if (skipTheme.isY2K)
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 18,
            gravity: 0.4,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.secondary,
              skipTheme.savedColor,
              Colors.white,
            ],
          ),
      ],
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final glossy = selected && skipTheme.isY2K;

    return TapScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: glossy ? null : (selected ? color : skipTheme.cardBackground),
          gradient: glossy
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white.withValues(alpha: 0.35), color],
                  stops: const [0.0, 0.65],
                )
              : null,
          borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 2),
          border: Border.all(
            color: skipTheme.isY2K
                ? theme.colorScheme.onSurface
                : (selected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            width: skipTheme.isY2K ? 2 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: selected
                ? (skipTheme.isY2K ? Colors.white : theme.colorScheme.surface)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
