import 'package:flutter/material.dart';

import '../theme/app_themes.dart';
import 'tap_scale.dart';

/// Shared card surface: theme-driven radius, background, Y2K border, and
/// depth (soft ambient shadow in Minimal, colored glow in Y2K).
///
/// Shadow and clipping are deliberately split across two layers — an outer
/// [Container] paints [boxShadow] unclipped, wrapping an inner [ClipRRect]
/// that clips [child] to the same radius. Giving a single [Container] both
/// a [BoxDecoration.boxShadow] and a `clipBehavior` clips the shadow itself
/// away, since the clip applies to everything the decoration paints.
class SkipCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Use the stronger [SkipThemeExtension.glowShadow] instead of the
  /// ambient [SkipThemeExtension.cardShadow] for a lifted/emphasized look.
  final bool emphasized;

  const SkipCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return TapScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(skipTheme.cardRadius),
          boxShadow: emphasized ? skipTheme.glowShadow : skipTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(skipTheme.cardRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: skipTheme.cardBackground,
              border: skipTheme.isY2K
                  ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
                  : null,
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
