import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/file_helper.dart';
import '../../core/utils/url_validator.dart';
import '../../core/widgets/skip_app_bar.dart';
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

  String? _relativeImagePath;
  File? _previewFile;
  bool _isPickingImage = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _priceController.dispose();
    _titleController.dispose();
    _purchaseUrlController.dispose();
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
    final accent = Theme.of(context).colorScheme.primary;
    final strings = context.read<LocaleProvider>().strings;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TapScale(
              onTap: () => _pickImage(ImageSource.camera),
              child: ListTile(
                leading: Icon(Icons.camera_alt, color: accent),
                title: Text(strings.camera),
              ),
            ),
            TapScale(
              onTap: () => _pickImage(ImageSource.gallery),
              child: ListTile(
                leading: Icon(Icons.photo_library, color: accent),
                title: Text(strings.gallery),
              ),
            ),
          ],
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

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.logAnItem)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
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
                    prefixText: '\$ ',
                  ),
                  validator: (value) => _validatePrice(value, strings),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: strings.titleOptionalLabel,
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _purchaseUrlController,
                  decoration: InputDecoration(
                    labelText: strings.productLinkOptionalLabel,
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: (value) => _validatePurchaseUrl(value, strings),
                ),
                const SizedBox(height: 20),
                Text(
                  strings.tapOneToLogIt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
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
