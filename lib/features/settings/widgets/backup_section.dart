import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/widgets/skip_card.dart';
import '../../../data/backup_service.dart';
import '../../../data/items_provider.dart';

/// Restore the automatic local safety-net backup.
class BackupSection extends StatefulWidget {
  const BackupSection({super.key});

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _isBusy = false;

  Future<void> _restoreFromAutoBackup() async {
    setState(() => _isBusy = true);
    final strings = context.read<LocaleProvider>().strings;
    try {
      final result = await context
          .read<ItemsProvider>()
          .restoreFromAutoBackup();
      if (!mounted) return;
      final message = switch (result) {
        AutoBackupNotFound() => strings.noAutoBackupFound,
        AutoBackupAlreadyRestored() => strings.autoBackupAlreadyRestored,
        AutoBackupRestored(:final count) => strings.importedItems(count),
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on BackupFormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.backupErrorMessage(e.code))),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.watch<LocaleProvider>().strings;

    return SkipCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.photosStayOnDevice, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _isBusy ? null : _restoreFromAutoBackup,
            icon: const Icon(Icons.settings_backup_restore),
            label: Text(strings.restoreAutoBackup),
          ),
          if (_isBusy) ...[
            const SizedBox(height: 12),
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
    );
  }
}
