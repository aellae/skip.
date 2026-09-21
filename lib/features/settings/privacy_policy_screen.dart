import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/skip_card.dart';

/// Static privacy summary + a link to the full [PRIVACY_POLICY.md], hosted
/// on GitHub since the app itself has no server to serve it from. See
/// [AppStrings.privacyPolicyBody] for the exact wording shown to the user.
class PrivacyPolicyScreen extends StatefulWidget {
  static final Uri policyUri = Uri.parse(
    'https://github.com/aellae/skip./blob/master/PRIVACY_POLICY.md',
  );

  /// Overrides how the policy link is actually opened. Defaults to
  /// `url_launcher`'s [launchUrl]; tests inject a fake so they never touch a
  /// real platform channel.
  final Future<bool> Function(Uri url)? launchUrlOverride;

  const PrivacyPolicyScreen({super.key, this.launchUrlOverride});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final Future<bool> Function(Uri url) _launchUrl =
      widget.launchUrlOverride ??
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
  bool _isBusy = false;

  Future<void> _openPolicy() async {
    setState(() => _isBusy = true);
    final launched = await _launchUrl(PrivacyPolicyScreen.policyUri);
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
      appBar: SkipAppBar(title: Text(strings.privacyPolicy)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SkipCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '🔒 ${strings.privacyPolicy}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.privacyPolicyBody,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _isBusy ? null : _openPolicy,
                  icon: const Icon(Icons.open_in_new),
                  label: Text(strings.privacyPolicyButton),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  strings.privacyPolicyOpensExternally,
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
