import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';

/// Static "support the developer" page: a single PayPal link, entirely
/// optional and disconnected from app functionality. Nothing is unlocked,
/// tracked, or changed by visiting it or sending money — see
/// [AppStrings.supportBody] for the exact wording shown to the user.
class SupportScreen extends StatefulWidget {
  static final Uri paypalUri = Uri.parse('https://paypal.me/eletarantino');

  /// Overrides how the PayPal link is actually opened. Defaults to
  /// `url_launcher`'s [launchUrl]; tests inject a fake so they never touch a
  /// real platform channel.
  final Future<bool> Function(Uri url)? launchUrlOverride;

  const SupportScreen({super.key, this.launchUrlOverride});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late final Future<bool> Function(Uri url) _launchUrl =
      widget.launchUrlOverride ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  bool _isBusy = false;

  Future<void> _openPaypal() async {
    setState(() => _isBusy = true);
    final launched = await _launchUrl(SupportScreen.paypalUri);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (launched) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<LocaleProvider>().strings.couldntOpenLink),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.watch<LocaleProvider>().strings;

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.supportSkip)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SkipCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '💜 ${strings.supportSkip}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(strings.supportBody, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _openPaypal,
                  icon: const Icon(Icons.favorite_outline),
                  label: Text(strings.supportButton),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.supportOpensExternally,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                if (_isBusy) ...[
                  const SizedBox(height: AppSpacing.md),
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
