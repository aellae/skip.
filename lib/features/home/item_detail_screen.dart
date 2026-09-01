import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../core/utils/url_validator.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../data/items_provider.dart';
import '../../data/models/item_model.dart';
import '../item_entry/widgets/decision_toggle.dart';

/// Full detail view for a single logged item: full image, date, price,
/// retroactive status change, and delete (with image cleanup).
class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;
  final FileHelper? fileHelper;

  /// Overrides how a product link is actually opened. Defaults to
  /// `url_launcher`'s [launchUrl]; tests inject a fake so they never touch a
  /// real platform channel.
  final Future<bool> Function(Uri url)? launchUrlOverride;

  const ItemDetailScreen({
    super.key,
    required this.item,
    this.fileHelper,
    this.launchUrlOverride,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final FileHelper _fileHelper = widget.fileHelper ?? FileHelper();
  late final Future<bool> Function(Uri url) _launchUrl =
      widget.launchUrlOverride ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
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
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
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

  Future<void> _openPurchaseUrl(String rawUrl) async {
    final uri = parseHttpUrl(rawUrl);
    if (uri == null) return;
    final launched = await _launchUrl(uri);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Couldn't open that link.")));
  }

  Future<void> _editPurchaseLink(String? currentUrl) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _PurchaseLinkDialog(currentUrl: currentUrl),
    );
    if (!mounted) return;
    if (result == null || widget.item.id == null) return;

    setState(() => _isBusy = true);
    await context.read<ItemsProvider>().setPurchaseUrl(
      widget.item.id!,
      result.isEmpty ? null : result,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
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
      appBar: SkipAppBar(
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _confirmDelete,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
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
                  borderRadius: BorderRadius.circular(skipTheme.cardRadius),
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surface,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            size: 48,
                          ),
                        ),
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
              const SizedBox(height: 24),
              Text('Product Link', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (item.purchaseUrl != null && item.purchaseUrl!.isNotEmpty)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isBusy
                            ? null
                            : () => _openPurchaseUrl(item.purchaseUrl!),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Visit product page'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isBusy
                          ? null
                          : () => _editPurchaseLink(item.purchaseUrl),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit link',
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _editPurchaseLink(null),
                  icon: const Icon(Icons.add_link),
                  label: const Text('Add product link'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add/edit dialog for an item's optional purchase link. A dedicated
/// StatefulWidget (rather than a controller built in the caller) so its
/// TextEditingController is disposed by Flutter itself at the right point
/// in the dialog's exit-transition lifecycle — disposing a controller
/// manually right after `showDialog` resolves races the still-animating
/// dialog route and crashes with "used after being disposed".
class _PurchaseLinkDialog extends StatefulWidget {
  final String? currentUrl;

  const _PurchaseLinkDialog({this.currentUrl});

  @override
  State<_PurchaseLinkDialog> createState() => _PurchaseLinkDialogState();
}

class _PurchaseLinkDialogState extends State<_PurchaseLinkDialog> {
  late final _controller = TextEditingController(text: widget.currentUrl ?? '');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return parseHttpUrl(value) == null
        ? 'Enter a valid link (https://…).'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.currentUrl == null ? 'Add product link' : 'Edit link'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'https://…'),
          validator: _validate,
        ),
      ),
      actions: [
        if (widget.currentUrl != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
