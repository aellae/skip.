import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/file_helper.dart';
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: skipTheme.cardBackground,
          borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 4),
          border: skipTheme.isY2K
              ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(aspectRatio: 1, child: _buildImage()),
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildImage() {
    final helper = fileHelper ?? FileHelper();
    return FutureBuilder<File>(
      future: helper.resolveImageFile(item.imagePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: Theme.of(context).colorScheme.surface);
        }
        return Image.file(
          snapshot.data!,
          fit: BoxFit.cover,
          cacheWidth: _cacheWidth,
          errorBuilder: (context, error, stackTrace) =>
              Container(color: Theme.of(context).colorScheme.surface),
        );
      },
    );
  }
}
