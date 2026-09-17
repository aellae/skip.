import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Decorative fallback shown wherever an item's photo would normally sit,
/// for items logged without one (the photo is optional at entry time).
///
/// Themed like everything else: a soft tinted surface in Minimal, a
/// gradient-glow icon in Y2K. [showLabel] adds a caption below the icon —
/// meant for larger tiles (detail screen); small thumbnails (grid, trash)
/// should leave it off.
class ItemImagePlaceholder extends StatelessWidget {
  final bool showLabel;
  final String? label;

  const ItemImagePlaceholder({super.key, this.showLabel = false, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return Container(
      color: skipTheme.cardBackground,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (skipTheme.isY2K)
            ShaderMask(
              shaderCallback: (bounds) =>
                  skipTheme.accentGradient!.createShader(bounds),
              child: const Icon(
                Icons.shopping_bag_rounded,
                size: 40,
                color: Colors.white,
              ),
            )
          else
            Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          if (showLabel && label != null) ...[
            const SizedBox(height: 8),
            Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
