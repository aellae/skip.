import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/theme/app_themes.dart';

/// Skeleton placeholder shown while the first load of items is in flight.
///
/// Mirrors the real content's outer padding/gaps so the swap to the loaded
/// grid doesn't jump. Uses the same [Shimmer.fromColors] recipe already
/// proven on the Y2K "Resisted!" toggle (see `decision_toggle.dart`).
class HomeLoadingSkeleton extends StatelessWidget {
  const HomeLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final skipTheme = Theme.of(context).extension<SkipThemeExtension>()!;

    return Shimmer.fromColors(
      baseColor: skipTheme.cardBackground,
      highlightColor: skipTheme.accentHighlight,
      period: const Duration(milliseconds: 1400),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SkeletonBlock(
                    height: 90,
                    radius: skipTheme.cardRadius,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _SkeletonBlock(
                    height: 90,
                    radius: skipTheme.cardRadius,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            MasonryGridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              itemCount: 6,
              itemBuilder: (context, index) => _SkeletonBlock(
                height: index.isEven ? 220 : 170,
                radius: skipTheme.cardRadius,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final double radius;

  const _SkeletonBlock({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
