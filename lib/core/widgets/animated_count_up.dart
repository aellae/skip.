import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';

/// Animates [value] counting up/down to its new total whenever it changes,
/// formatted via [formatCurrency].
///
/// Deliberately keeps its own [AnimationController] rather than using
/// `TweenAnimationBuilder(tween: Tween(begin: 0, end: value))` — `Tween`
/// doesn't override `==`, so a fresh `Tween` literal is a different identity
/// on every rebuild, which would restart the count from 0 on any unrelated
/// rebuild rather than only on a real value change.
class AnimatedCountUp extends StatefulWidget {
  final double value;
  final TextStyle? style;

  const AnimatedCountUp({super.key, required this.value, this.style});

  @override
  State<AnimatedCountUp> createState() => _AnimatedCountUpState();
}

class _AnimatedCountUpState extends State<AnimatedCountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late Animation<double> _animation;
  late double _lastValue;

  Animation<double> _buildAnimation(double begin, double end) {
    return Tween(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void initState() {
    super.initState();
    _lastValue = widget.value;
    _animation = _buildAnimation(widget.value, widget.value);
  }

  @override
  void didUpdateWidget(covariant AnimatedCountUp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _lastValue) {
      _animation = _buildAnimation(_lastValue, widget.value);
      _lastValue = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) =>
          Text(formatCurrency(_animation.value), style: widget.style),
    );
  }
}
