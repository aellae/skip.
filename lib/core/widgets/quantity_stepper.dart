import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import '../theme/app_themes.dart';

/// Compact +/- stepper for an item's quantity. Deliberately small and
/// unobtrusive — quantity defaults to 1 and most items never need it
/// touched, so this must never read as a required field.
class QuantityStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final AppStrings strings;

  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.strings,
    this.min = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove,
          label: strings.decreaseQuantity,
          onTap: value > min ? () => onChanged(value - 1) : null,
          skipTheme: skipTheme,
        ),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall,
          ),
        ),
        _StepButton(
          icon: Icons.add,
          label: strings.increaseQuantity,
          onTap: () => onChanged(value + 1),
          skipTheme: skipTheme,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final SkipThemeExtension skipTheme;

  const _StepButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.skipTheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(
                alpha: onTap == null ? 0.15 : 0.4,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onTap == null
                ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
