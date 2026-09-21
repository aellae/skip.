import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Shared app bar: Minimal renders a plain flat bar plus a barely-there
/// hairline divider for quiet definition; Y2K renders a transparent bar
/// over a flat [SkipThemeExtension.cardBackground] surface — the same deep
/// surface color as cards — so every screen's header reads as one uniform
/// chrome instead of a standalone brand moment. The louder magenta/violet
/// [SkipThemeExtension.accentGradient] stays reserved for CTAs and badges,
/// where it functions as emphasis rather than wallpaper.
class SkipAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;

  /// Overrides the default [kToolbarHeight], for screens whose title needs
  /// more vertical room (e.g. Home's enlarged logo).
  final double? toolbarHeight;

  const SkipAppBar({
    super.key,
    this.title,
    this.actions,
    this.centerTitle,
    this.toolbarHeight,
  });

  static const double _hairlineHeight = 1;

  @override
  Size get preferredSize =>
      Size.fromHeight((toolbarHeight ?? kToolbarHeight) + _hairlineHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return AppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      toolbarHeight: toolbarHeight,
      backgroundColor: skipTheme.isY2K ? Colors.transparent : null,
      elevation: skipTheme.isY2K ? 0 : null,
      flexibleSpace: skipTheme.isY2K
          ? Container(
              decoration: BoxDecoration(color: skipTheme.cardBackground),
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_hairlineHeight),
        child: Container(
          height: _hairlineHeight,
          color: skipTheme.isY2K
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : theme.dividerTheme.color,
        ),
      ),
    );
  }
}
