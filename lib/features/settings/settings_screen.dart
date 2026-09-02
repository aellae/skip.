import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';
import 'widgets/backup_section.dart';

/// Aesthetic switcher + quick summary stats.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final itemsProvider = context.watch<ItemsProvider>();

    return Scaffold(
      appBar: SkipAppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Aesthetic', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            _AestheticSwitcher(
              aesthetic: themeProvider.aesthetic,
              onChanged: themeProvider.setAesthetic,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('Summary', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            _StatTile(
              label: 'Items resisted',
              value: '${itemsProvider.resistedCount}',
              color: skipTheme.savedColor,
            ),
            const SizedBox(height: 12),
            _StatTile(
              label: 'Average saved per item',
              value: formatCurrency(itemsProvider.averageSavedPerItem),
              color: skipTheme.savedColor,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text('Data', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            const BackupSection(),
          ],
        ),
      ),
    );
  }
}

class _AestheticSwitcher extends StatelessWidget {
  final SkipAesthetic aesthetic;
  final ValueChanged<SkipAesthetic> onChanged;

  const _AestheticSwitcher({required this.aesthetic, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AestheticOption(
            previewTheme: AppThemes.minimal,
            label: 'skip.',
            description: 'Quiet Luxury',
            selected: aesthetic == SkipAesthetic.minimal,
            onTap: () => onChanged(SkipAesthetic.minimal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AestheticOption(
            previewTheme: AppThemes.y2k,
            label: 'SKIP!',
            description: 'Bratz Y2K',
            selected: aesthetic == SkipAesthetic.y2k,
            onTap: () => onChanged(SkipAesthetic.y2k),
          ),
        ),
      ],
    );
  }
}

/// Each option always previews its *own* theme's font/colors/gradient,
/// regardless of which aesthetic is currently active app-wide — so picking
/// "SKIP!" is an informed choice, not a guess. The "selected" ring reads
/// off the *ambient* theme (via [Theme.of], outside the nested [Theme]
/// scope below) so the pick signal itself stays legible in both states.
class _AestheticOption extends StatelessWidget {
  final ThemeData previewTheme;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _AestheticOption({
    required this.previewTheme,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ambientTheme = Theme.of(context);
    final ambientSkip = ambientTheme.extension<SkipThemeExtension>()!;

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ambientSkip.cardRadius + 3),
          border: Border.all(
            color: selected
                ? ambientTheme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? ambientSkip.glowShadow : null,
        ),
        child: Theme(
          data: previewTheme,
          child: Builder(
            builder: (previewContext) {
              final theme = Theme.of(previewContext);
              final skipTheme = theme.extension<SkipThemeExtension>()!;
              final textColor = skipTheme.isY2K
                  ? Colors.white
                  : theme.colorScheme.onSurface;

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: skipTheme.isY2K ? null : skipTheme.cardBackground,
                  gradient: skipTheme.isY2K ? skipTheme.accentGradient : null,
                  borderRadius: BorderRadius.circular(skipTheme.cardRadius),
                  border: skipTheme.isY2K
                      ? Border.all(
                          color: theme.colorScheme.onSurface,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
