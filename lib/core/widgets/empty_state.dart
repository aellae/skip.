import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../theme/app_themes.dart';
import 'entrance_fade.dart';

/// Themed "nothing here yet" placeholder: an icon in a theme-flavored badge
/// (Y2K: gradient fill + glow; Minimal: soft card fill + ambient shadow)
/// above a message, fading/scaling in once on mount.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return EntranceFade(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: skipTheme.isY2K ? null : skipTheme.cardBackground,
                gradient: skipTheme.isY2K ? skipTheme.accentGradient : null,
                boxShadow: skipTheme.isY2K
                    ? skipTheme.glowShadow
                    : skipTheme.cardShadow,
              ),
              child: Icon(
                icon,
                size: 32,
                color: skipTheme.isY2K
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
