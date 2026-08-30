import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';

/// "Resisted! / Skip" vs. "Bought It / Spent" decision toggle.
class DecisionToggle extends StatelessWidget {
  final bool isSaved;
  final ValueChanged<bool> onChanged;

  const DecisionToggle({
    super.key,
    required this.isSaved,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return Row(
      children: [
        Expanded(
          child: _ToggleOption(
            label: 'Resisted!',
            selected: isSaved,
            color: skipTheme.savedColor,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ToggleOption(
            label: 'Bought It',
            selected: !isSaved,
            color: skipTheme.spentColor,
            onTap: () => onChanged(false),
          ),
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

  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : skipTheme.cardBackground,
          borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 2),
          border: Border.all(
            color: selected
                ? color
                : theme.colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: selected
                ? (skipTheme.isY2K ? Colors.white : theme.colorScheme.surface)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
