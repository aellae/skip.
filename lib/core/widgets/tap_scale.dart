import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps [child] with a subtle press-down scale animation and a light
/// haptic tick on release — the shared micro-interaction primitive behind
/// Phase 3's "smooth scale animations and haptic ticks" polish. Used for
/// grid cards and toggle/option buttons in both aesthetics; callers that
/// need their own haptic (e.g. a stronger impact for a celebratory choice)
/// can pass [haptic]: false and trigger their own via [onTap].
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = true,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Opaque so TapScale registers a hit anywhere in its bounds even when
      // wrapping a child that doesn't paint there itself (deferToChild, the
      // default, would silently swallow taps on such children).
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
