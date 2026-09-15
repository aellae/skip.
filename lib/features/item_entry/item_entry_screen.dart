import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../core/utils/url_validator.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';
import 'widgets/decision_toggle.dart';

/// Quick-add flow: snap/pick a photo, enter a price and optional title,
/// then decide Resisted! or Bought It.
class ItemEntryScreen extends StatefulWidget {
  final ImagePicker? imagePicker;
  final FileHelper? fileHelper;

  const ItemEntryScreen({super.key, this.imagePicker, this.fileHelper});

  @override
  State<ItemEntryScreen> createState() => _ItemEntryScreenState();
}

class _ItemEntryScreenState extends State<ItemEntryScreen> {
  late final ImagePicker _picker = widget.imagePicker ?? ImagePicker();
  late final FileHelper _fileHelper = widget.fileHelper ?? FileHelper();
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _titleController = TextEditingController();
  final _purchaseUrlController = TextEditingController();
  final _priceFocus = FocusNode();
  final _titleFocus = FocusNode();
  final _purchaseUrlFocus = FocusNode();

  String? _relativeImagePath;
  File? _previewFile;
  bool _isPickingImage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    _purchaseUrlController.dispose();
    _priceFocus.dispose();
    _titleFocus.dispose();
    _purchaseUrlFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // close the source picker sheet
    setState(() => _isPickingImage = true);
    try {
      // Cap the stored resolution (not just the display-time decode bound
      // already applied via Image.file's cacheWidth/cacheHeight elsewhere)
      // so a full-res camera photo never lands on disk uncompressed —
      // 2000px on the long edge comfortably covers the largest cacheWidth
      // used anywhere in the app (item_detail_screen's 1200) with headroom.
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
      final resolved = await _fileHelper.resolveImageFile(relativePath);
      if (!mounted) return;
      setState(() {
        _relativeImagePath = relativePath;
        _previewFile = resolved;
      });
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    final strings = context.read<LocaleProvider>().strings;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ImageSourceOption(
                icon: Icons.camera_alt,
                label: strings.camera,
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ImageSourceOption(
                icon: Icons.photo_library,
                label: strings.gallery,
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveWithDecision(bool isSaved) async {
    if (_isSaving) return;
    if (_relativeImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LocaleProvider>().strings.addPhotoFirst),
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    final price = double.parse(_priceController.text);
    final title = _titleController.text.trim();
    final purchaseUrl = parseHttpUrl(_purchaseUrlController.text)?.toString();
    await context.read<ItemsProvider>().addItem(
      title: title.isEmpty ? null : title,
      price: price,
      imagePath: _relativeImagePath!,
      isSaved: isSaved,
      purchaseUrl: purchaseUrl,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String? _validatePrice(String? value, AppStrings strings) {
    if (value == null || value.trim().isEmpty) return strings.enterPrice;
    final parsed = double.tryParse(value);
    if (parsed == null) return strings.enterValidNumber;
    if (parsed <= 0) return strings.priceGreaterThanZero;
    return null;
  }

  String? _validatePurchaseUrl(String? value, AppStrings strings) {
    if (value == null || value.trim().isEmpty) return null;
    if (parseHttpUrl(value) == null) return strings.invalidLinkError;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;
    final currency = context.watch<CurrencyProvider>().currency;
    final isEuro = isEuroCurrency(currency);

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.logAnItem)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TapScale(
                  onTap: _isPickingImage ? null : _showImageSourceSheet,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: skipTheme.cardBackground,
                        borderRadius: BorderRadius.circular(
                          skipTheme.cardRadius,
                        ),
                        border: skipTheme.isY2K
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 1.5,
                              )
                            : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _isPickingImage
                            ? const Center(
                                key: ValueKey('loading'),
                                child: CircularProgressIndicator(),
                              )
                            : _previewFile != null
                            ? Image.file(
                                _previewFile!,
                                key: ValueKey(_previewFile!.path),
                                fit: BoxFit.cover,
                                cacheWidth: 800,
                              )
                            : Center(
                                key: const ValueKey('placeholder'),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_a_photo, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      strings.tapToAddPhoto,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ThemedFocusField(
                  focusNode: _priceFocus,
                  child: TextFormField(
                    controller: _priceController,
                    focusNode: _priceFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: strings.priceLabel,
                      prefixText: isEuro ? null : '\$ ',
                      suffixText: isEuro ? '€' : null,
                    ),
                    validator: (value) => _validatePrice(value, strings),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ThemedFocusField(
                  focusNode: _titleFocus,
                  child: TextFormField(
                    controller: _titleController,
                    focusNode: _titleFocus,
                    decoration: InputDecoration(
                      labelText: strings.titleOptionalLabel,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _ThemedFocusField(
                  focusNode: _purchaseUrlFocus,
                  child: TextFormField(
                    controller: _purchaseUrlController,
                    focusNode: _purchaseUrlFocus,
                    decoration: InputDecoration(
                      labelText: strings.productLinkOptionalLabel,
                    ),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    validator: (value) => _validatePurchaseUrl(value, strings),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  strings.tapOneToLogIt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                IgnorePointer(
                  ignoring: _isSaving,
                  child: Opacity(
                    opacity: _isSaving ? 0.5 : 1,
                    child: DecisionToggle(
                      isSaved: true,
                      onChanged: _saveWithDecision,
                    ),
                  ),
                ),
                if (_isSaving) ...[
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
      ),
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Themed focus indicator around a form field: a colored glow in Y2K, an
/// animated bottom-border draw-in in Minimal. Owns [focusNode]'s listener
/// only — the caller still creates/disposes the [FocusNode] and passes it
/// to both this wrapper and the wrapped field.
class _ThemedFocusField extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const _ThemedFocusField({required this.focusNode, required this.child});

  @override
  State<_ThemedFocusField> createState() => _ThemedFocusFieldState();
}

class _ThemedFocusFieldState extends State<_ThemedFocusField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(skipTheme.buttonRadius),
        boxShadow: skipTheme.isY2K && _focused ? skipTheme.glowShadow : null,
        border: skipTheme.isY2K
            ? null
            : Border(
                bottom: BorderSide(
                  color: _focused
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
      ),
      child: widget.child,
    );
  }
}
