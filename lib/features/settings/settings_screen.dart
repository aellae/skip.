import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';

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
      appBar: AppBar(title: const Text('Settings')),
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
            const SizedBox(height: 32),
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
            label: 'skip.',
            description: 'Quiet Luxury',
            selected: aesthetic == SkipAesthetic.minimal,
            onTap: () => onChanged(SkipAesthetic.minimal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AestheticOption(
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

class _AestheticOption extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _AestheticOption({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : skipTheme.cardBackground,
          borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 2),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
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
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: skipTheme.cardBackground,
        borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 4),
        border: skipTheme.isY2K
            ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
            : null,
      ),
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
