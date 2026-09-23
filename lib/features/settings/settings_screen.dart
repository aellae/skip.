import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/app_currency.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/settings/sfx_provider.dart';
import '../../core/settings/wage_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/animated_count_up.dart';
import '../../core/widgets/entrance_fade.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';
import '../../core/widgets/tap_scale.dart';
import '../../data/items_provider.dart';
import '../trash/trash_screen.dart';
import 'privacy_policy_screen.dart';
import 'widgets/backup_section.dart';

/// Aesthetic switcher + language switcher + quick summary stats.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final sfxProvider = context.watch<SfxProvider>();
    final wageProvider = context.watch<WageProvider>();
    final itemsProvider = context.watch<ItemsProvider>();
    final strings = localeProvider.strings;

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.settingsTitle)),
      body: SafeArea(
        child: EntranceFade(
          beginScale: 1.0,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.aesthetic, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _AestheticSwitcher(
                aesthetic: themeProvider.aesthetic,
                onChanged: themeProvider.setAesthetic,
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.language, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _LanguageSwitcher(
                locale: localeProvider.locale,
                onChanged: localeProvider.setLocale,
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.currency, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _CurrencySwitcher(
                currency: currencyProvider.currency,
                onChanged: (newCurrency) => _changeCurrency(
                  context,
                  newCurrency: newCurrency,
                  hasItems: itemsProvider.items.isNotEmpty,
                  strings: strings,
                ),
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.costInHours, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _WageSection(
                hourlyWage: wageProvider.hourlyWage,
                currency: currencyProvider.currency,
                strings: strings,
                onTap: () => _editHourlyWage(
                  context,
                  currentWage: wageProvider.hourlyWage,
                  currency: currencyProvider.currency,
                  strings: strings,
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.sound, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _SoundToggle(
                enabled: sfxProvider.enabled,
                onChanged: sfxProvider.setEnabled,
                strings: strings,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.summary, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              _StatTile(
                label: strings.itemsResisted,
                value: itemsProvider.resistedCount.toDouble(),
                formatter: (v) => v.round().toString(),
                color: skipTheme.savedColor,
              ),
              const SizedBox(height: 12),
              _StatTile(
                label: strings.averageSavedPerItem,
                value: itemsProvider.averageSavedPerItem,
                formatter: (v) =>
                    formatCurrency(v, currency: currencyProvider.currency),
                color: skipTheme.savedColor,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(strings.data, style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              const BackupSection(),
              const SizedBox(height: 12),
              SkipCard(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const TrashScreen())),
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.trashSectionLabel,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              Text(
                strings.legalSectionLabel,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              SkipCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.privacyPolicy,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AestheticSwitcher extends StatelessWidget {
  final SkipAesthetic aesthetic;
  final ValueChanged<SkipAesthetic> onChanged;
  final AppStrings strings;

  const _AestheticSwitcher({
    required this.aesthetic,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AestheticOption(
            previewTheme: AppThemes.minimal,
            label: 'Skip!',
            description: strings.quietLuxury,
            selected: aesthetic == SkipAesthetic.minimal,
            onTap: () => onChanged(SkipAesthetic.minimal),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AestheticOption(
            previewTheme: AppThemes.y2k,
            label: 'Skip!',
            description: strings.baddieY2k,
            selected: aesthetic == SkipAesthetic.y2k,
            onTap: () => onChanged(SkipAesthetic.y2k),
          ),
        ),
      ],
    );
  }
}

/// Four-way language toggle, visually mirroring [_AestheticSwitcher] (same
/// ring-selected pill shape) but without a per-option theme preview —
/// language has no visual identity of its own to show off. Laid out as a
/// 2x2 grid (rather than one Row of four) so each pill stays comfortably
/// tappable at phone width.
class _LanguageSwitcher extends StatelessWidget {
  final AppLocale locale;
  final ValueChanged<AppLocale> onChanged;
  final AppStrings strings;

  const _LanguageSwitcher({
    required this.locale,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LanguageOption(
                flag: '🇬🇧',
                label: strings.english,
                selected: locale == AppLocale.en,
                onTap: () => onChanged(AppLocale.en),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LanguageOption(
                flag: '🇮🇹',
                label: strings.italian,
                selected: locale == AppLocale.it,
                onTap: () => onChanged(AppLocale.it),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _LanguageOption(
                flag: '🇫🇷',
                label: strings.french,
                selected: locale == AppLocale.fr,
                onTap: () => onChanged(AppLocale.fr),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LanguageOption(
                flag: '🇩🇪',
                label: strings.german,
                selected: locale == AppLocale.de,
                onTap: () => onChanged(AppLocale.de),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
        decoration: BoxDecoration(
          color: skipTheme.isY2K ? null : skipTheme.cardBackground,
          gradient: skipTheme.isY2K && selected
              ? skipTheme.accentGradient
              : null,
          borderRadius: BorderRadius.circular(skipTheme.cardRadius),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (skipTheme.isY2K
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.2)),
            width: selected || skipTheme.isY2K ? 2 : 1.5,
          ),
          boxShadow: selected ? skipTheme.glowShadow : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: skipTheme.isY2K && selected
                      ? Colors.white
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-way currency toggle — set independently of [_LanguageSwitcher], since
/// a user may want e.g. USD pricing under an Italian UI or vice versa.
/// Reuses [_LanguageOption]'s pill styling with the currency symbol standing
/// in for a flag.
class _CurrencySwitcher extends StatelessWidget {
  final AppCurrency currency;
  final ValueChanged<AppCurrency> onChanged;
  final AppStrings strings;

  const _CurrencySwitcher({
    required this.currency,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LanguageOption(
            flag: '\$',
            label: strings.usDollar,
            selected: currency == AppCurrency.usd,
            onTap: () => onChanged(AppCurrency.usd),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LanguageOption(
            flag: '€',
            label: strings.euro,
            selected: currency == AppCurrency.eur,
            onTap: () => onChanged(AppCurrency.eur),
          ),
        ),
      ],
    );
  }
}

/// Each option always previews its *own* theme's font/colors/gradient,
/// regardless of which aesthetic is currently active app-wide — so picking
/// "Skip!" is an informed choice, not a guess. The "selected" ring reads
/// off the *ambient* theme (via [Theme.of], outside the nested [Theme]
/// scope below) so the pick signal itself stays legible in both states.
class _AestheticOption extends StatelessWidget {
  final ThemeData previewTheme;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _AestheticOption({
    required this.previewTheme,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ambientTheme = Theme.of(context);
    final ambientSkip = ambientTheme.extension<SkipThemeExtension>()!;

    return TapScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ambientSkip.cardRadius + 3),
          border: Border.all(
            color: selected
                ? ambientTheme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: selected ? ambientSkip.glowShadow : null,
        ),
        child: Theme(
          data: previewTheme,
          child: Builder(
            builder: (previewContext) {
              final theme = Theme.of(previewContext);
              final skipTheme = theme.extension<SkipThemeExtension>()!;
              final textColor = skipTheme.isY2K
                  ? Colors.white
                  : theme.colorScheme.onSurface;

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: skipTheme.isY2K ? null : skipTheme.cardBackground,
                  gradient: skipTheme.isY2K ? skipTheme.accentGradient : null,
                  borderRadius: BorderRadius.circular(skipTheme.cardRadius),
                  border: skipTheme.isY2K
                      ? Border.all(
                          color: theme.colorScheme.onSurface,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String Function(double) formatter;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyLarge),
          AnimatedCountUp(
            value: value,
            formatter: formatter,
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Switches the display currency, warning first if there are already saved
/// items — the switch is display-only (no exchange-rate conversion, since
/// the app is fully offline), so a $1 item will simply show as €1 after.
Future<void> _changeCurrency(
  BuildContext context, {
  required AppCurrency newCurrency,
  required bool hasItems,
  required AppStrings strings,
}) async {
  final currencyProvider = context.read<CurrencyProvider>();
  if (newCurrency == currencyProvider.currency) return;

  if (hasItems) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.currencyChangeWarningTitle),
        content: Text(strings.currencyChangeWarningContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.continueAction),
          ),
        ],
      ),
    );
    if (!context.mounted || confirmed != true) return;
  }

  currencyProvider.setCurrency(newCurrency);
}

/// Opens the hourly-wage dialog and persists the result — `null` means the
/// dialog was cancelled (no change); a [_WageResult] with a `null` wage
/// means "Remove" was tapped.
Future<void> _editHourlyWage(
  BuildContext context, {
  required double? currentWage,
  required AppCurrency currency,
  required AppStrings strings,
}) async {
  final result = await showDialog<_WageResult>(
    context: context,
    builder: (dialogContext) => _HourlyWageDialog(
      currentWage: currentWage,
      currency: currency,
      strings: strings,
    ),
  );
  if (!context.mounted || result == null) return;
  await context.read<WageProvider>().setHourlyWage(result.hourlyWage);
}

/// Entry point for the optional "cost in hours worked" reframe — tapping
/// opens [_HourlyWageDialog] to set or clear the hourly wage, mirroring
/// [SettingsScreen]'s "Support SKIP" row shape.
class _WageSection extends StatelessWidget {
  final double? hourlyWage;
  final AppCurrency currency;
  final AppStrings strings;
  final VoidCallback onTap;

  const _WageSection({
    required this.hourlyWage,
    required this.currency,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.hourlyWageLabel, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  hourlyWage == null
                      ? strings.hourlyWageNotSet
                      : strings.hourlyWageValue(
                          formatCurrency(hourlyWage!, currency: currency),
                        ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Result of [_HourlyWageDialog]: `null` overall means cancelled; a
/// non-null result with a `null` [hourlyWage] means "Remove" was tapped.
class _WageResult {
  final double? hourlyWage;

  const _WageResult(this.hourlyWage);
}

/// Add/edit dialog for the optional hourly wage, structurally identical to
/// item_detail_screen's `_PurchaseLinkDialog`/`_EditDetailsDialog` — a
/// dedicated StatefulWidget so its TextEditingController is disposed by
/// Flutter itself at the right point in the dialog's exit transition.
class _HourlyWageDialog extends StatefulWidget {
  final double? currentWage;
  final AppCurrency currency;
  final AppStrings strings;

  const _HourlyWageDialog({
    required this.currentWage,
    required this.currency,
    required this.strings,
  });

  @override
  State<_HourlyWageDialog> createState() => _HourlyWageDialogState();
}

class _HourlyWageDialogState extends State<_HourlyWageDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.currentWage == null
        ? ''
        : widget.currentWage!.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) return widget.strings.enterPrice;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return widget.strings.enterValidNumber;
    if (parsed <= 0) return widget.strings.priceGreaterThanZero;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEuro = isEuroCurrency(widget.currency);
    return AlertDialog(
      title: Text(widget.strings.hourlyWageDialogTitle),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: widget.strings.hourlyWageLabel,
            prefixText: isEuro ? null : '\$ ',
            suffixText: isEuro ? '€' : null,
          ),
          validator: _validate,
        ),
      ),
      actions: [
        if (widget.currentWage != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(const _WageResult(null)),
            child: Text(widget.strings.remove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.strings.cancel),
        ),
        TextButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.of(context).pop(
              _WageResult(double.parse(_controller.text.replaceAll(',', '.'))),
            );
          },
          child: Text(widget.strings.save),
        ),
      ],
    );
  }
}

/// A single switch row muting/unmuting Y2K's sound effects, independent of
/// the active theme so the choice sticks even after switching aesthetics.
class _SoundToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final AppStrings strings;

  const _SoundToggle({
    required this.enabled,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(strings.soundEffects, style: theme.textTheme.bodyLarge),
          ),
          Switch(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}
