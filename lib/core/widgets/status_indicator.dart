import 'package:flutter/material.dart';

import '../theme/app_themes.dart';
import 'fit_words_text.dart';

/// Saved/spent status as an icon (+ optional label), not just a color.
///
/// The palette's saved/spent tones are intentionally soft (pale sage/dusty
/// pink in Minimal, so the semantics must not depend on color alone —
/// [Icons.check_circle_rounded] vs [Icons.shopping_bag_rounded] plus a
/// weight difference carry the distinction even for a viewer who can't
/// easily tell the two tones apart.
class StatusIndicator extends StatelessWidget {
  final bool? isSaved;
  final String? label;
  final TextStyle? labelStyle;

  const StatusIndicator({
    super.key,
    required this.isSaved,
    this.label,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final color = switch (isSaved) {
      true => skipTheme.savedColor,
      false => skipTheme.spentColor,
      null => skipTheme.ponderingColor,
    };
    final icon = switch (isSaved) {
      true => Icons.check_circle_rounded,
      false => Icons.shopping_bag_rounded,
      null => Icons.hourglass_top_rounded,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        if (label != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: FitWordsText(
              label!,
              style: (labelStyle ?? theme.textTheme.bodyMedium)?.copyWith(
                color: color,
                fontWeight: isSaved == false
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
