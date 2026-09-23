import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_currency.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/settings/wage_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../core/utils/url_validator.dart';
import '../../core/utils/wage_formatter.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/item_image_placeholder.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';
import '../../data/models/item_model.dart';
import '../coin_flip/coin_flip_screen.dart';
import '../item_entry/widgets/decision_toggle.dart';

/// Full detail view for a single logged item: full image, date, price,
/// retroactive status change, and delete (with image cleanup).
class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;
  final FileHelper? fileHelper;
  final ImagePicker? imagePicker;

  /// Overrides how a product link is actually opened. Defaults to
  /// `url_launcher`'s [launchUrl]; tests inject a fake so they never touch a
  /// real platform channel.
  final Future<bool> Function(Uri url)? launchUrlOverride;

  const ItemDetailScreen({
    super.key,
    required this.item,
    this.fileHelper,
    this.imagePicker,
    this.launchUrlOverride,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final FileHelper _fileHelper = widget.fileHelper ?? FileHelper();
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();
  late final Future<bool> Function(Uri url) _launchUrl =
      widget.launchUrlOverride ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  bool _isBusy = false;
  bool _isPickingImage = false;
  String? _cachedImagePath;
  late Future<File> _imageFuture;

  /// Caches the resolved-image future by path so it's only recreated when
  /// the image actually changes, instead of on every rebuild (an inline
  /// `future:` in [FutureBuilder] would otherwise flash back to the loading
  /// placeholder every time this screen rebuilds, e.g. on each status/edit
  /// change).
  Future<File> _resolveImageFuture(String path) {
    if (_cachedImagePath != path) {
      _cachedImagePath = path;
      _imageFuture = _fileHelper.resolveImageFile(path);
    }
    return _imageFuture;
  }

  /// Runs [action] under the busy spinner, resetting it afterwards even if
  /// [action] throws, and surfaces a snackbar on failure instead of leaving
  /// the screen stuck busy with no feedback.
  Future<void> _runBusy(Future<void> Function() action) async {
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.read<LocaleProvider>().strings.somethingWentWrong,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _changeStatus(bool? isSaved, bool? currentIsSaved) async {
    if (widget.item.id == null || isSaved == currentIsSaved) return;
    await _runBusy(
      () => context.read<ItemsProvider>().setSavedStatus(
        widget.item.id!,
        isSaved,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final strings = context.read<LocaleProvider>().strings;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(strings.deleteItemTitle),
        content: Text(strings.deleteItemContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              strings.delete,
              style: Theme.of(dialogContext).textTheme.labelLarge?.copyWith(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true || widget.item.id == null) return;

    await _runBusy(() async {
      await context.read<ItemsProvider>().deleteItem(widget.item.id!);
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _openPurchaseUrl(String rawUrl) async {
    final uri = parseHttpUrl(rawUrl);
    if (uri == null) return;
    final launched = await _launchUrl(uri);
    if (!mounted || launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<LocaleProvider>().strings.couldntOpenLink),
      ),
    );
  }

  Future<void> _editPurchaseLink(String? currentUrl) async {
    final strings = context.read<LocaleProvider>().strings;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _PurchaseLinkDialog(currentUrl: currentUrl, strings: strings),
    );
    if (!mounted) return;
    if (result == null || widget.item.id == null) return;

    await _runBusy(
      () => context.read<ItemsProvider>().setPurchaseUrl(
        widget.item.id!,
        result.isEmpty ? null : result,
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (widget.item.id == null) return;
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (picked == null) return;

      // Copy into app documents immediately; never keep the picker's temp
      // file reference (CLAUDE.md image-pipeline rule).
      final relativePath = await _fileHelper.saveImage(File(picked.path));
      if (!mounted) {
        await _fileHelper.deleteImage(relativePath);
        return;
      }
      try {
        await context.read<ItemsProvider>().setImagePath(
          widget.item.id!,
          relativePath,
        );
      } catch (_) {
        await _fileHelper.deleteImage(relativePath);
        rethrow;
      }
    } catch (_) {
      // e.g. camera/photo permission denied.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.read<LocaleProvider>().strings.somethingWentWrong,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _removeImage() async {
    if (widget.item.id == null) return;
    await _runBusy(
      () => context.read<ItemsProvider>().setImagePath(widget.item.id!, null),
    );
  }

  void _showImageSourceSheet({required bool hasImage}) {
    final strings = context.read<LocaleProvider>().strings;
    showImageSourceSheet(
      context,
      strings: strings,
      onPick: _pickImage,
      onRemove: hasImage ? _removeImage : null,
    );
  }

  Future<void> _editDetails(ItemModel item) async {
    final strings = context.read<LocaleProvider>().strings;
    final currency = context.read<CurrencyProvider>().currency;
    final result = await showDialog<_ItemDetailsEdit>(
      context: context,
      builder: (dialogContext) => _EditDetailsDialog(
        currentTitle: item.title,
        currentPrice: item.price,
        currentQuantity: item.quantity,
        currency: currency,
        strings: strings,
      ),
    );
    if (!mounted) return;
    if (result == null || widget.item.id == null) return;

    await _runBusy(
      () => context.read<ItemsProvider>().updateDetails(
        widget.item.id!,
        title: result.title,
        price: result.price,
        quantity: result.quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    final currency = context.watch<CurrencyProvider>().currency;
    final hourlyWage = context.watch<WageProvider>().hourlyWage;
    final item = context.select<ItemsProvider, ItemModel>(
      (provider) => provider.items.firstWhere(
        (i) => i.id == widget.item.id,
        orElse: () => widget.item,
      ),
    );
    final statusColor = switch (item.isSaved) {
      true => skipTheme.savedColor,
      false => skipTheme.spentColor,
      null => skipTheme.ponderingColor,
    };

    return Scaffold(
      appBar: SkipAppBar(
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _confirmDelete,
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: strings.delete,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Hero(
                tag: 'item-image-${item.id}',
                child: TapScale(
                  onTap: _isBusy || _isPickingImage
                      ? null
                      : () => _showImageSourceSheet(
                          hasImage: item.imagePath != null,
                        ),
                  semanticLabel: item.imagePath != null
                      ? strings.photoTapToChange
                      : strings.tapToAddPhoto,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              skipTheme.cardRadius,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: _isPickingImage
                                  ? Container(
                                      key: const ValueKey('loading'),
                                      color: theme.colorScheme.surface,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : item.imagePath == null
                                  ? ItemImagePlaceholder(
                                      key: const ValueKey('placeholder'),
                                      showLabel: true,
                                      label: strings.noPhotoLabel,
                                    )
                                  : FutureBuilder<File>(
                                      key: ValueKey(item.imagePath),
                                      future: _resolveImageFuture(
                                        item.imagePath!,
                                      ),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return Container(
                                            color: theme.colorScheme.surface,
                                          );
                                        }
                                        return Image.file(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          cacheWidth: 1200,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                color:
                                                    theme.colorScheme.surface,
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.broken_image_outlined,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.4),
                                                  size: 48,
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: _PhotoEditBadge(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.title != null && item.title!.isNotEmpty) ...[
                          Text(
                            item.title!,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              formatCurrency(
                                item.totalPrice,
                                currency: currency,
                              ),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: statusColor,
                              ),
                            ),
                            if (item.quantity > 1) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(${formatCurrency(item.price, currency: currency)} × ${item.quantity})',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                        if (hoursOfWork(item.totalPrice, hourlyWage)
                            case final hours?)
                          Text(
                            strings.hoursOfWork(hours),
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isBusy ? null : () => _editDetails(item),
                    icon: const Icon(Icons.edit),
                    tooltip: strings.editDetailsTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formatDate(item.createdAt, localeProvider.locale),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.status, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              DecisionToggle(
                isSaved: item.isSaved,
                onChanged: _isBusy
                    ? (_) {}
                    : (newValue) => _changeStatus(newValue, item.isSaved),
              ),
              const SizedBox(height: 12),
              _CoinFlipButton(
                label: strings.coinFlipTooltip,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CoinFlipScreen()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.productLink, style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: item.purchaseUrl != null && item.purchaseUrl!.isNotEmpty
                    ? Row(
                        key: const ValueKey('link'),
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isBusy
                                  ? null
                                  : () => _openPurchaseUrl(item.purchaseUrl!),
                              icon: const Icon(Icons.open_in_new),
                              label: Text(strings.visitProductPage),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _isBusy
                                ? null
                                : () => _editPurchaseLink(item.purchaseUrl),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: strings.editLinkTooltip,
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey('no-link'),
                        onPressed: _isBusy
                            ? null
                            : () => _editPurchaseLink(null),
                        icon: const Icon(Icons.add_link),
                        label: Text(strings.addProductLink),
                      ),
              ),
              if (_isBusy) ...[
                const SizedBox(height: 16),
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small badge overlaid on the item photo signalling it can be tapped to
/// add/change/remove the photo — otherwise nothing on the detail screen
/// hints that the (previously add-only) photo is now editable there too.
class _PhotoEditBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: skipTheme.cardBackground,
        shape: BoxShape.circle,
        border: skipTheme.isY2K
            ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
            : null,
        boxShadow: skipTheme.isY2K
            ? skipTheme.glowShadow
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Icon(Icons.camera_alt, size: 18, color: theme.colorScheme.primary),
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
  final AppStrings strings;

  const _PurchaseLinkDialog({this.currentUrl, required this.strings});

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
    return parseHttpUrl(value) == null ? widget.strings.invalidLinkError : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(
        widget.currentUrl == null
            ? widget.strings.addProductLink
            : widget.strings.editLinkDialogTitle,
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(hintText: widget.strings.linkHint),
          validator: _validate,
        ),
      ),
      actions: [
        if (widget.currentUrl != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(widget.strings.remove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(_controller.text.trim());
          },
          child: Text(widget.strings.save),
        ),
      ],
    );
  }
}

/// Result of [_EditDetailsDialog]: the title/price/quantity to persist.
class _ItemDetailsEdit {
  final String? title;
  final double price;
  final int quantity;

  const _ItemDetailsEdit({
    required this.title,
    required this.price,
    required this.quantity,
  });
}

/// Edit dialog for an item's title, price, and quantity — the fields that
/// otherwise require deleting and re-adding the item to fix a typo.
class _EditDetailsDialog extends StatefulWidget {
  final String? currentTitle;
  final double currentPrice;
  final int currentQuantity;
  final AppCurrency currency;
  final AppStrings strings;

  const _EditDetailsDialog({
    required this.currentTitle,
    required this.currentPrice,
    required this.currentQuantity,
    required this.currency,
    required this.strings,
  });

  @override
  State<_EditDetailsDialog> createState() => _EditDetailsDialogState();
}

class _EditDetailsDialogState extends State<_EditDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _priceController = TextEditingController(
    text: widget.currentPrice.toStringAsFixed(2),
  );
  late final _titleController = TextEditingController(
    text: widget.currentTitle ?? '',
  );
  late int _quantity = widget.currentQuantity;

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return widget.strings.enterPrice;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return widget.strings.enterValidNumber;
    if (parsed <= 0) return widget.strings.priceGreaterThanZero;
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _titleController.text.trim();
    Navigator.of(context).pop(
      _ItemDetailsEdit(
        title: title.isEmpty ? null : title,
        price: double.parse(_priceController.text.replaceAll(',', '.')),
        quantity: _quantity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEuro = isEuroCurrency(widget.currency);
    return AlertDialog(
      scrollable: true,
      title: Text(widget.strings.editDetailsDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: widget.strings.priceLabel,
                      prefixText: isEuro ? null : '\$ ',
                      suffixText: isEuro ? '€' : null,
                      // The decimal numeric keypad has no native return key
                      // on iOS, so give the field its own submit affordance
                      // instead of relying on scrolling to the dialog's
                      // Save button below the fold.
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        tooltip: widget.strings.doneLabel,
                        onPressed: _save,
                      ),
                    ),
                    validator: _validatePrice,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                QuantityStepper(
                  strings: widget.strings,
                  value: _quantity,
                  onChanged: (value) => setState(() => _quantity = value),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: widget.strings.titleOptionalLabel,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        TextButton(onPressed: _save, child: Text(widget.strings.save)),
      ],
    );
  }
}

/// Prominent entry point to the coin-flip tool, shown right under the
/// decision toggle so it's easy to find while an item is being weighed up.
class _CoinFlipButton extends StatelessWidget {
  const _CoinFlipButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final radius = BorderRadius.circular(skipTheme.cardRadius);
    final foreground = skipTheme.isY2K ? Colors.white : skipTheme.savedColor;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: skipTheme.isY2K
              ? null
              : skipTheme.savedColor.withValues(alpha: 0.15),
          gradient: skipTheme.isY2K ? skipTheme.accentGradient : null,
          boxShadow: skipTheme.isY2K ? skipTheme.glowShadow : null,
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on_outlined, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
