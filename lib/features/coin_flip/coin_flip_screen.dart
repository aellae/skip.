import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/skip_app_bar.dart';

enum _CoinFace { yes, no }

/// A standalone "flip a coin" tool for when the user can't decide whether to
/// buy something. Purely momentary — nothing here reads or writes
/// [ItemsProvider]/the database; the result exists only for the length of
/// this screen's session.
class CoinFlipScreen extends StatefulWidget {
  const CoinFlipScreen({super.key});

  @override
  State<CoinFlipScreen> createState() => _CoinFlipScreenState();
}

class _CoinFlipScreenState extends State<CoinFlipScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..addStatusListener(_onFlipStatus);
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  // Number of half-turns (pi radians each) the disc spins through before
  // landing. Its parity is what actually decides which face ends up facing
  // the viewer — see _flip — the base count is just for visual flair.
  int _totalHalfFlips = 8;
  _CoinFace? _pendingResult;
  _CoinFace? _result;

  // Re-keys _ResultReveal so a repeat flip restarts its entrance animation
  // instead of no-op'ing against an already-mounted instance.
  int _resultKey = 0;

  // Y2K celebration on landing, same shape as DecisionToggle's: a confetti
  // burst plus a bounded shimmer sweep over the coin that switches itself
  // back off (Shimmer.fromColors loops forever while mounted).
  late final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(milliseconds: 400),
  );
  Timer? _shimmerTimer;
  bool _shimmering = false;

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _shimmerTimer?.cancel();
    super.dispose();
  }

  void _flip() {
    if (_controller.isAnimating) return;
    final target = _random.nextBool() ? _CoinFace.yes : _CoinFace.no;
    setState(() {
      _pendingResult = target;
      _result = null;
      // Always an even base (a whole number of full spins) plus one extra
      // half-turn when the target is "no" — that parity is what lands the
      // correct face, the base count just adds a couple more visible spins.
      _totalHalfFlips = 8 + (target == _CoinFace.no ? 1 : 0);
    });
    HapticFeedback.selectionClick();
    _controller.forward(from: 0);
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    final skipTheme = Theme.of(context).extension<SkipThemeExtension>()!;
    setState(() {
      _result = _pendingResult;
      _resultKey++;
    });
    if (skipTheme.isY2K) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
      _shimmerTimer?.cancel();
      setState(() => _shimmering = true);
      _shimmerTimer = Timer(const Duration(milliseconds: 1300), () {
        if (mounted) setState(() => _shimmering = false);
      });
    } else {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.coinFlipTitle)),
      body: SafeArea(
        child: EntranceFade(
          beginScale: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  strings.coinFlipSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),
                Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _curve,
                      builder: (context, _) {
                        final angle = _curve.value * pi * _totalHalfFlips;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(angle),
                          child: _CoinDisc(
                            skipTheme: skipTheme,
                            theme: theme,
                            shimmering: skipTheme.isY2K && _shimmering,
                          ),
                        );
                      },
                    ),
                    if (skipTheme.isY2K)
                      ConfettiWidget(
                        confettiController: _confettiController,
                        blastDirectionality: BlastDirectionality.explosive,
                        shouldLoop: false,
                        numberOfParticles: 18,
                        gravity: 0.4,
                        createParticlePath: (size) {
                          final radius = size.width / 2;
                          return Path()..addOval(
                            Rect.fromCircle(
                              center: Offset(radius, radius),
                              radius: radius,
                            ),
                          );
                        },
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                          skipTheme.accentHighlight,
                          Colors.white,
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 64,
                  child: Center(
                    child: _result == null
                        ? const SizedBox.shrink()
                        : _ResultReveal(
                            key: ValueKey(_resultKey),
                            child: Text(
                              _result == _CoinFace.yes
                                  ? strings.coinFlipYes
                                  : strings.coinFlipNo,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _controller.isAnimating ? null : _flip,
                  child: Text(
                    _result == null
                        ? strings.flipButtonLabel
                        : strings.flipAgainLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The decorative disc itself — purely presentational, no text on its face.
/// The actual yes/no wording is revealed separately by [_ResultReveal] once
/// the coin lands, so a fast Y-axis spin never has to render (and
/// un-mirror) text mid-flip.
class _CoinDisc extends StatelessWidget {
  final SkipThemeExtension skipTheme;
  final ThemeData theme;
  final bool shimmering;

  const _CoinDisc({
    required this.skipTheme,
    required this.theme,
    required this.shimmering,
  });

  @override
  Widget build(BuildContext context) {
    const diameter = 140.0;

    Widget disc = Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: skipTheme.isY2K ? null : skipTheme.cardBackground,
        gradient: skipTheme.isY2K ? skipTheme.accentGradient : null,
        border: Border.all(
          color: skipTheme.isY2K
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: skipTheme.isY2K ? 2 : 1.5,
        ),
        boxShadow: skipTheme.cardShadow,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.monetization_on_rounded,
        size: 56,
        color: skipTheme.isY2K
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );

    if (shimmering) {
      disc = ClipOval(
        child: Shimmer.fromColors(
          baseColor: skipTheme.accentHighlight,
          highlightColor: Colors.white,
          period: const Duration(milliseconds: 1100),
          child: disc,
        ),
      );
    }

    return disc;
  }
}

/// Fade-and-scale entrance for the landed result — Minimal's own quiet
/// equivalent of Y2K's louder confetti+shimmer combo, and what both
/// aesthetics use to reveal the result text itself. Re-keyed by the caller
/// on every flip so a repeat result restarts the animation instead of
/// no-op'ing against an already-mounted instance.
class _ResultReveal extends StatefulWidget {
  final Widget child;

  const _ResultReveal({super.key, required this.child});

  @override
  State<_ResultReveal> createState() => _ResultRevealState();
}

class _ResultRevealState extends State<_ResultReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.elasticOut,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
