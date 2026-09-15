import 'package:flutter/material.dart';

/// Fades (and optionally scales) [child] in, once, on first build.
///
/// The [AnimationController] is created once via a `late final` field, so a
/// parent rebuild (e.g. a `context.watch` update) does not restart the
/// animation — only a genuine remount does. When used in a list, give each
/// instance a stable [Key] (e.g. an item's id) so Flutter doesn't reuse an
/// Element by position and replay the animation on an unrelated reorder.
class EntranceFade extends StatefulWidget {
  final Widget child;
  final Duration duration;

  /// Starting scale for the entrance. 1.0 disables the scale (fade-only) —
  /// useful for wrapping a full screen, where scaling from a page-wide
  /// pivot can look different than scaling a small grid tile.
  final double beginScale;

  const EntranceFade({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 260),
    this.beginScale = 0.92,
  });

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: widget.beginScale == 1.0
          ? widget.child
          : ScaleTransition(
              scale: Tween(begin: widget.beginScale, end: 1.0).animate(_curve),
              child: widget.child,
            ),
    );
  }
}
