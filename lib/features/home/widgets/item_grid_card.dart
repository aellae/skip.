import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/currency_provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/settings/wage_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/file_helper.dart';
import '../../../core/utils/wage_formatter.dart';
import '../../../core/widgets/item_image_placeholder.dart';
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
    final currency = context.watch<CurrencyProvider>().currency;
    final strings = context.watch<LocaleProvider>().strings;
    final hourlyWage = context.watch<WageProvider>().hourlyWage;
    final hours = hoursOfWork(item.totalPrice, hourlyWage);
    final statusColor = switch (item.isSaved) {
      true => skipTheme.savedColor,
      false => skipTheme.spentColor,
      null => skipTheme.ponderingColor,
    };

    return SkipCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Hero(
                tag: 'item-image-${item.id}',
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildImage(skipTheme),
                ),
              ),
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
                      boxShadow: skipTheme.glowShadow,
                    ),
                    child: Icon(
                      switch (item.isSaved) {
                        true => Icons.bolt_rounded,
                        false => Icons.shopping_bag_rounded,
                        null => Icons.hourglass_top_rounded,
                      },
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
                    // Scaled down rather than ellipsized: a cut-off amount
                    // ("50,0…") is unreadable.
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          item.quantity > 1
                              ? '${formatCurrency(item.totalPrice, currency: currency)} (×${item.quantity})'
                              : formatCurrency(
                                  item.totalPrice,
                                  currency: currency,
                                ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: statusColor,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hours != null)
                  Text(
                    strings.hoursOfWork(hours),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(SkipThemeExtension skipTheme) {
    final imagePath = item.imagePath;
    if (imagePath == null) return const ItemImagePlaceholder();

    final helper = fileHelper ?? FileHelper();
    return FutureBuilder<File>(
      future: helper.resolveImageFile(imagePath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(color: skipTheme.cardBackground);
        }
        return Image.file(
          snapshot.data!,
          fit: BoxFit.cover,
          cacheWidth: _cacheWidth,
          errorBuilder: (context, error, stackTrace) =>
              const ItemImagePlaceholder(),
        );
      },
    );
  }
}
