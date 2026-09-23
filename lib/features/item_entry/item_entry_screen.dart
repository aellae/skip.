import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/settings/wage_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/file_helper.dart';
import '../../core/utils/url_validator.dart';
import '../../core/utils/wage_formatter.dart';
import '../../core/widgets/image_source_sheet.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';
import 'widgets/decision_toggle.dart';

/// Quick-add flow: snap/pick a photo, enter a price and optional title,
/// then decide Resisted! or Bought It.
class ItemEntryScreen extends StatefulWidget {
  final ImagePicker? imagePicker;
  final FileHelper? fileHelper;

  /// A photo the picker returned after Android killed the app mid-pick
  /// (see `ImagePicker.retrieveLostData`), attached as if just picked.
  final XFile? recoveredImage;

  const ItemEntryScreen({
    super.key,
    this.imagePicker,
    this.fileHelper,
    this.recoveredImage,
  });

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

  /// While the Y2K "Resisted!" celebration plays out before the pop: the
  /// toggle stays blocked but isn't dimmed, so the effect shows at full
  /// strength.
  bool _isCelebrating = false;

  /// The option tapped, shown selected while the save runs. Nothing is
  /// selected until the user picks.
  bool _hasDecision = false;
  bool? _decision;

  /// Off until the first failed save, then live — so an error message
  /// clears as soon as the input is fixed instead of lingering.
  var _autovalidateMode = AutovalidateMode.disabled;
  bool _didSave = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final recovered = widget.recoveredImage;
    if (recovered != null) {
      _isPickingImage = true;
      _attachPickedFile(recovered);
    }
  }

  @override
  void dispose() {
    // A photo copied in but never attached to a saved item (the user backed
    // out) would otherwise sit in app documents forever.
    final unused = _relativeImagePath;
    if (!_didSave && unused != null) _fileHelper.deleteImage(unused).ignore();
    _priceController.dispose();
    _titleController.dispose();
    _purchaseUrlController.dispose();
    _priceFocus.dispose();
    _titleFocus.dispose();
    _purchaseUrlFocus.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
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
      if (picked == null) {
        if (mounted) setState(() => _isPickingImage = false);
        return;
      }
      await _attachPickedFile(picked);
    } catch (_) {
      // e.g. camera/photo permission denied.
      if (mounted) setState(() => _isPickingImage = false);
      _showError();
    }
  }

  /// Copies [picked] into app documents and shows it as the preview —
  /// shared by a normal pick and a photo recovered after process death.
  Future<void> _attachPickedFile(XFile picked) async {
    try {
      // Copy into app documents immediately; never keep the picker's temp
      // file reference (CLAUDE.md image-pipeline rule).
      final relativePath = await _fileHelper.saveImage(File(picked.path));
      final resolved = await _fileHelper.resolveImageFile(relativePath);
      if (!mounted) {
        await _fileHelper.deleteImage(relativePath);
        return;
      }
      // Replacing a previous pick: its copy is no longer referenced.
      final replaced = _relativeImagePath;
      setState(() {
        _relativeImagePath = relativePath;
        _previewFile = resolved;
      });
      if (replaced != null) await _fileHelper.deleteImage(replaced);
    } catch (_) {
      _showError();
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _showImageSourceSheet() {
    final strings = context.read<LocaleProvider>().strings;
    showImageSourceSheet(context, strings: strings, onPick: _pickImage);
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<LocaleProvider>().strings.somethingWentWrong,
        ),
      ),
    );
  }

  /// Validates the form ahead of a decision tap, so the toggle can skip its
  /// "Resisted!" celebration when the save would be rejected anyway.
  bool _canSave() {
    if (_isSaving) return false;
    // Force any in-flight IME edit (e.g. a paste still being committed) to
    // land in the controllers before reading their text below.
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid && _autovalidateMode == AutovalidateMode.disabled) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    }
    return valid;
  }

  Future<void> _saveWithDecision(bool? isSaved) async {
    if (!_canSave()) return;

    // Only Y2K + Resisted plays an effect worth holding the screen for;
    // every other decision pops as soon as the insert lands.
    final celebrate =
        isSaved == true &&
        Theme.of(context).extension<SkipThemeExtension>()!.isY2K;
    setState(() {
      _isSaving = true;
      _isCelebrating = celebrate;
      _hasDecision = true;
      _decision = isSaved;
    });
    final price = double.parse(_normalizedPrice(_priceController.text));
    final title = _titleController.text.trim();
    final purchaseUrl = parseHttpUrl(_purchaseUrlController.text)?.toString();
    try {
      await Future.wait([
        context.read<ItemsProvider>().addItem(
          title: title.isEmpty ? null : title,
          price: price,
          quantity: _quantity,
          imagePath: _relativeImagePath,
          isSaved: isSaved,
          purchaseUrl: purchaseUrl,
        ),
        if (celebrate) Future<void>.delayed(DecisionToggle.celebrationDuration),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _isCelebrating = false;
          _hasDecision = false;
        });
      }
      _showError();
      return;
    }
    _didSave = true;
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  String _normalizedPrice(String value) => value.replaceAll(',', '.');

  String? _validatePrice(String? value, AppStrings strings) {
    if (value == null || value.trim().isEmpty) return strings.enterPrice;
    final parsed = double.tryParse(_normalizedPrice(value));
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
    final hourlyWage = context.watch<WageProvider>().hourlyWage;

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.logAnItem)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TapScale(
                  onTap: _isPickingImage ? null : _showImageSourceSheet,
                  semanticLabel: _previewFile != null
                      ? strings.photoTapToChange
                      : null,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _ThemedFocusField(
                        focusNode: _priceFocus,
                        child: TextFormField(
                          controller: _priceController,
                          focusNode: _priceFocus,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _priceFocus.unfocus(),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[.,]?\d{0,2}'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: strings.priceLabel,
                            prefixText: isEuro ? null : '\$ ',
                            suffixText: isEuro ? '€' : null,
                            // The decimal numeric keypad has no native
                            // return key on iOS, so give the field its own
                            // dismiss affordance instead of relying on
                            // scrolling to a button below the fold.
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: strings.doneLabel,
                              onPressed: _priceFocus.unfocus,
                            ),
                          ),
                          validator: (value) => _validatePrice(value, strings),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    QuantityStepper(
                      strings: strings,
                      value: _quantity,
                      onChanged: (value) => setState(() => _quantity = value),
                    ),
                  ],
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _priceController,
                  builder: (context, value, _) {
                    final price = double.tryParse(_normalizedPrice(value.text));
                    if (price == null) return const SizedBox.shrink();
                    final totalPrice = price * _quantity;
                    final hours = hourlyWage == null
                        ? null
                        : hoursOfWork(totalPrice, hourlyWage);
                    final showTotal = _quantity > 1;
                    if (!showTotal && hours == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showTotal)
                            Text(
                              strings.totalForQuantity(
                                formatCurrency(totalPrice, currency: currency),
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                          if (hours != null)
                            Text(
                              strings.hoursOfWork(hours),
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ),
                    );
                  },
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
                    opacity: _isSaving && !_isCelebrating ? 0.5 : 1,
                    child: DecisionToggle(
                      isSaved: _decision,
                      hasSelection: _hasDecision,
                      canSelect: _canSave,
                      onChanged: _saveWithDecision,
                    ),
                  ),
                ),
                if (_isSaving && !_isCelebrating) ...[
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
