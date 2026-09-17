import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/audio/sfx_player.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/settings/sfx_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/theme/contrast.dart';
import '../../../core/widgets/tap_scale.dart';

/// "Resisted! / Pondering / Bought It" decision toggle. `isSaved`/`onChanged`
/// are `null` for the undecided "Pondering" state.
///
/// Selecting "Resisted!" in the Y2K aesthetic triggers a confetti burst, a
/// stronger haptic impact, and an SFX cue; every other selection just gets
/// the shared [TapScale] press animation and a light haptic tick.
class DecisionToggle extends StatefulWidget {
  final bool? isSaved;
  final ValueChanged<bool?> onChanged;
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
    duration: const Duration(milliseconds: 1200),
  );
  late final SkipSfxPlayer _sfx =
      widget.sfxPlayer ??
      SkipSfxPlayer(isEnabled: () => context.read<SfxProvider>().enabled);

  // Y2K shimmer sweep: on for a bounded window after "Resisted!", then off
  // again — Shimmer.fromColors loops forever while enabled, so this must be
  // switched back off itself rather than left running.
  Timer? _shimmerTimer;
  bool _shimmering = false;

  // Minimal confirmation pulse: re-keyed on every "Resisted!" tap so a
  // repeat selection restarts the animation instead of no-op'ing against an
  // already-mounted instance.
  int _pulseKey = 0;
  bool _showMinimalPulse = false;

  @override
  void dispose() {
    _confettiController.dispose();
    _sfx.dispose();
    _shimmerTimer?.cancel();
    super.dispose();
  }

  void _selectResisted(bool isY2K) {
    if (isY2K) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
      _sfx.playResisted();
      _shimmerTimer?.cancel();
      setState(() => _shimmering = true);
      _shimmerTimer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _shimmering = false);
      });
    } else {
      HapticFeedback.selectionClick();
      _confettiController.play();
      setState(() {
        _pulseKey++;
        _showMinimalPulse = true;
      });
    }
    widget.onChanged(true);
  }

  void _selectBought() {
    HapticFeedback.selectionClick();
    widget.onChanged(false);
  }

  void _selectPondering() {
    HapticFeedback.selectionClick();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        DecoratedBox(
          // Matches the scaffold background (not skipTheme.cardBackground,
          // which is a visibly different tone) so the 12px gap between the
          // two pills — and the unselected pill's own idle fill below —
          // reads as part of the page instead of a mismatched block sitting
          // on top of it.
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(skipTheme.buttonRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ToggleOption(
                  label: strings.resisted,
                  selected: widget.isSaved == true,
                  color: skipTheme.savedColor,
                  onTap: () => _selectResisted(skipTheme.isY2K),
                  shimmer:
                      skipTheme.isY2K &&
                      widget.isSaved == true &&
                      _shimmering,
                  pulseKey: _showMinimalPulse ? _pulseKey : null,
                  onPulseDone: () {
                    if (mounted) setState(() => _showMinimalPulse = false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleOption(
                  label: strings.pondering,
                  selected: widget.isSaved == null,
                  color: skipTheme.ponderingColor,
                  onTap: _selectPondering,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToggleOption(
                  label: strings.boughtIt,
                  selected: widget.isSaved == false,
                  color: skipTheme.spentColor,
                  onTap: _selectBought,
                ),
              ),
            ],
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: skipTheme.isY2K ? 18 : 12,
          gravity: 0.25,
          particleDrag: 0.08,
          minimumSize: skipTheme.isY2K
              ? const Size(5, 5)
              : const Size(4, 4),
          maximumSize: skipTheme.isY2K
              ? const Size(10, 10)
              : const Size(6, 6),
          // Y2K gets round particles to match its circular badges/pills;
          // Minimal keeps confetti's default square particles, just smaller
          // and quieter to match its restrained aesthetic.
          createParticlePath: skipTheme.isY2K
              ? (size) {
                  final radius = size.width / 2;
                  return Path()..addOval(
                    Rect.fromCircle(
                      center: Offset(radius, radius),
                      radius: radius,
                    ),
                  );
                }
              : null,
          colors: skipTheme.isY2K
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  skipTheme.savedColor,
                  skipTheme.accentHighlight,
                  Colors.white,
                ]
              : [
                  skipTheme.savedColor,
                  skipTheme.accentHighlight,
                  theme.colorScheme.primary,
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
  final bool shimmer;
  final int? pulseKey;
  final VoidCallback? onPulseDone;

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.shimmer = false,
    this.pulseKey,
    this.onPulseDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final glossy = selected && skipTheme.isY2K;

    final radius = BorderRadius.circular(skipTheme.buttonRadius);

    // The glow shadow is painted on its own outer layer, separate from the
    // gradient fill below. On-device (Impeller) rendering was observed to
    // paint the gradient as a plain rectangle — ignoring borderRadius —
    // whenever a gradient and a boxShadow live in the same BoxDecoration;
    // the border still drew rounded, so the corners showed background
    // instead of the fill color. Splitting them, plus an explicit ClipRRect
    // on the fill, avoids that combination entirely.
    Widget fill = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutQuart,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: selected ? skipTheme.glowShadow : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutQuart,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: glossy
                ? null
                : (selected ? color : theme.scaffoldBackgroundColor),
            gradient: glossy
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: 0.35), color],
                    stops: const [0.0, 0.65],
                  )
                : null,
            borderRadius: radius,
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
                  ? bestOnColor(color)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );

    if (shimmer) {
      // Same reasoning as the ClipRRect above: Shimmer's ShaderMask sweep is
      // an extra paint layer on top of the already-clipped fill, and needs
      // its own explicit clip or it can paint over the rounded corners too.
      fill = ClipRRect(
        borderRadius: radius,
        child: Shimmer.fromColors(
          baseColor: color,
          highlightColor: skipTheme.accentHighlight,
          period: const Duration(milliseconds: 1100),
          child: fill,
        ),
      );
    }

    return TapScale(
      onTap: onTap,
      haptic: false,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          fill,
          if (pulseKey != null)
            _MinimalConfirmPulse(
              key: ValueKey(pulseKey),
              color: skipTheme.accentHighlight,
              onDone: onPulseDone!,
            ),
        ],
      ),
    );
  }
}

/// A small scale-in-then-fade checkmark — Minimal's own equivalent of Y2K's
/// confetti burst for confirming "Resisted!", just quieter. Re-keyed by the
/// caller on every tap so repeat selections restart the animation.
class _MinimalConfirmPulse extends StatefulWidget {
  final Color color;
  final VoidCallback onDone;

  const _MinimalConfirmPulse({
    super.key,
    required this.color,
    required this.onDone,
  });

  @override
  State<_MinimalConfirmPulse> createState() => _MinimalConfirmPulseState();
}

class _MinimalConfirmPulseState extends State<_MinimalConfirmPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..addStatusListener(_onStatus);
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _opacity = Tween<double>(begin: 1, end: 0)
      .animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
        ),
      );

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.onDone();
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
