import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/file_helper.dart';
import '../../../core/widgets/skip_card.dart';
import '../../../core/widgets/status_indicator.dart';
import '../../../data/models/item_model.dart';

/// A single card in the home dashboard's moodboard grid.
///
/// Images are decoded at a capped [cacheWidth] regardless of the source
/// photo's resolution, so a grid full of high-res camera photos doesn't
/// blow up memory (CLAUDE.md: use `Image.file()` with cache bounds in grid
/// views).
class ItemGridCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback? onTap;
  final FileHelper? fileHelper;

  static const int _cacheWidth = 400;

  const ItemGridCard({
    super.key,
    required this.item,
    this.onTap,
    this.fileHelper,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final statusColor = item.isSaved
        ? skipTheme.savedColor
        : skipTheme.spentColor;

    return SkipCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(aspectRatio: 1, child: _buildImage(skipTheme)),
              if (skipTheme.isY2K)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: skipTheme.accentGradient,
                      border: Border.all(
                        color: theme.colorScheme.onSurface,
                        width: 1.5,
                      ),
                      boxShadow: skipTheme.glowShadow,
                    ),
                    child: Icon(
                      item.isSaved
                          ? Icons.bolt_rounded
                          : Icons.shopping_bag_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.title != null && item.title!.isNotEmpty)
                  Text(
                    item.title!,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    StatusIndicator(isSaved: item.isSaved),
                    const SizedBox(width: 6),
                    Text(
                      formatCurrency(item.price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(SkipThemeExtension skipTheme) {
    final helper = fileHelper ?? FileHelper();
    return FutureBuilder<File>(
      future: helper.resolveImageFile(item.imagePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: skipTheme.cardBackground);
        }
        return Image.file(
          snapshot.data!,
          fit: BoxFit.cover,
          cacheWidth: _cacheWidth,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: skipTheme.cardBackground),
        );
      },
    );
  }
}
