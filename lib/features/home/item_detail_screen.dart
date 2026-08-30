import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../data/items_provider.dart';
import '../../data/models/item_model.dart';
import '../item_entry/widgets/decision_toggle.dart';

/// Full detail view for a single logged item: full image, date, price,
/// retroactive status change, and delete (with image cleanup).
class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;
  final FileHelper? fileHelper;

  const ItemDetailScreen({super.key, required this.item, this.fileHelper});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final FileHelper _fileHelper = widget.fileHelper ?? FileHelper();
  bool _isBusy = false;

  Future<void> _changeStatus(bool isSaved) async {
    if (widget.item.id == null || isSaved == widget.item.isSaved) return;
    setState(() => _isBusy = true);
    await context.read<ItemsProvider>().setSavedStatus(
      widget.item.id!,
      isSaved,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this item?'),
        content: const Text('This removes it and its photo permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true || widget.item.id == null) return;

    setState(() => _isBusy = true);
    await context.read<ItemsProvider>().deleteItem(widget.item.id!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final item = context.select<ItemsProvider, ItemModel>(
      (provider) => provider.items.firstWhere(
        (i) => i.id == widget.item.id,
        orElse: () => widget.item,
      ),
    );
    final statusColor = item.isSaved
        ? skipTheme.savedColor
        : skipTheme.spentColor;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 4),
                  child: FutureBuilder<File>(
                    future: _fileHelper.resolveImageFile(item.imagePath),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(color: theme.colorScheme.surface);
                      }
                      return Image.file(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        cacheWidth: 1200,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (item.title != null && item.title!.isNotEmpty) ...[
                Text(item.title!, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
              ],
              Text(
                formatCurrency(item.price),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatDate(item.createdAt),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text('Status', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DecisionToggle(
                isSaved: item.isSaved,
                onChanged: _isBusy ? (_) {} : _changeStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
