import 'package:flutter/material.dart';

import '../theme/app_themes.dart';

/// Shared app bar: Minimal renders a plain flat bar plus a barely-there
/// hairline divider for quiet definition; Y2K renders a transparent bar
/// over a diagonal brand gradient — an [AppBar] can't take a gradient
/// background through [ThemeData] alone, only a per-instance
/// `flexibleSpace` can paint one.
class SkipAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool? centerTitle;

  const SkipAppBar({super.key, this.title, this.actions, this.centerTitle});

  static const double _hairlineHeight = 1;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + _hairlineHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return AppBar(
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: skipTheme.isY2K ? Colors.transparent : null,
      elevation: skipTheme.isY2K ? 0 : null,
      flexibleSpace: skipTheme.isY2K
          ? Container(
              decoration: BoxDecoration(gradient: skipTheme.accentGradient),
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_hairlineHeight),
        child: skipTheme.isY2K
            ? const SizedBox.shrink()
            : Container(
                height: _hairlineHeight,
                color: theme.dividerTheme.color,
              ),
      ),
    );
  }
}
