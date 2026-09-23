import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_currency.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/item_image_placeholder.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';
import '../../data/items_provider.dart';
import '../../data/models/item_model.dart';

/// Lists soft-deleted items (§3j) with a restore action. Permanent removal
/// happens automatically, via [ItemsProvider.purgeExpiredTrash] on app
/// start — this screen never deletes anything itself.
class TrashScreen extends StatelessWidget {
  final FileHelper? fileHelper;

  const TrashScreen({super.key, this.fileHelper});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    final currency = context.watch<CurrencyProvider>().currency;
    final trashedItems = context.watch<ItemsProvider>().trashedItems;

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.trashSectionLabel)),
      body: SafeArea(
        child: trashedItems.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.delete_outline,
                  message: strings.emptyTrashMessage,
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Text(
                      strings.trashRetentionNotice,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: trashedItems.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final item = trashedItems[index];
                        return EntranceFade(
                          key: ValueKey(item.id),
                          child: _TrashedItemTile(
                            item: item,
                            currency: currency,
                            fileHelper: fileHelper,
                            restoreLabel: strings.restore,
                            locale: localeProvider.locale,
                            onRestore: () => context
                                .read<ItemsProvider>()
                                .restoreItem(item.id!),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TrashedItemTile extends StatelessWidget {
  final ItemModel item;
  final AppCurrency currency;
  final FileHelper? fileHelper;
  final String restoreLabel;
  final AppLocale locale;
  final VoidCallback onRestore;

  const _TrashedItemTile({
    required this.item,
    required this.currency,
    required this.fileHelper,
    required this.restoreLabel,
    required this.locale,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final helper = fileHelper ?? FileHelper();

    return SkipCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(skipTheme.cardRadius),
            child: SizedBox(
              width: 56,
              height: 56,
              child: FutureBuilder<File>(
                future: item.imagePath == null
                    ? null
                    : helper.resolveImageFile(item.imagePath!),
                builder: (context, snapshot) {
                  if (item.imagePath == null) {
                    return const ItemImagePlaceholder();
                  }
                  if (!snapshot.hasData) {
                    return Container(color: skipTheme.cardBackground);
                  }
                  return Image.file(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    cacheWidth: 112,
                    errorBuilder: (context, error, stackTrace) =>
                        const ItemImagePlaceholder(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
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
                Text(
                  formatCurrency(item.totalPrice, currency: currency),
                  style: theme.textTheme.bodyMedium,
                ),
                if (item.deletedAt != null)
                  Text(
                    formatDate(item.deletedAt!, locale),
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onRestore, child: Text(restoreLabel)),
        ],
      ),
    );
  }
}
