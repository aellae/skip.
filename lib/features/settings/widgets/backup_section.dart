import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/file_helper.dart';
import '../../../data/backup_service.dart';
import '../../../data/items_provider.dart';

/// Export item records to JSON/CSV (shared via the system share sheet) and
/// import a previously exported JSON backup (via the file picker).
///
/// [pickJsonFile] and [shareFile] wrap the `file_picker`/`share_plus`
/// platform calls behind injectable functions, the same seam
/// [ItemEntryScreen] uses for `image_picker`, so widget tests can exercise
/// the full flow without touching real platform channels.
class BackupSection extends StatefulWidget {
  final FileHelper? fileHelper;
  final Future<String?> Function()? pickJsonFile;
  final Future<void> Function(String path, String subject)? shareFile;

  const BackupSection({
    super.key,
    this.fileHelper,
    this.pickJsonFile,
    this.shareFile,
  });

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  late final FileHelper _fileHelper = widget.fileHelper ?? FileHelper();
  bool _isBusy = false;

  Future<String?> _pickJsonFile() {
    if (widget.pickJsonFile != null) return widget.pickJsonFile!();
    return _defaultPickJsonFile();
  }

  Future<String?> _defaultPickJsonFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    return file?.path;
  }

  Future<void> _shareFile(String path, String subject) {
    if (widget.shareFile != null) return widget.shareFile!(path, subject);
    return SharePlus.instance
        .share(ShareParams(files: [XFile(path)], subject: subject))
        .then((_) {});
  }

  Future<void> _export(String format) async {
    setState(() => _isBusy = true);
    try {
      final itemsProvider = context.read<ItemsProvider>();
      final content = format == 'json'
          ? await itemsProvider.buildJsonBackup()
          : await itemsProvider.buildCsvBackup();
      final fileName =
          'skip_backup_${DateTime.now().millisecondsSinceEpoch}.$format';
      final file = await _fileHelper.writeExportFile(fileName, content);
      await _shareFile(file.path, 'SKIP backup');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't export backup.")));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _import() async {
    setState(() => _isBusy = true);
    try {
      final path = await _pickJsonFile();
      if (!mounted || path == null) return;

      final String content;
      try {
        content = await File(path).readAsString();
      } catch (_) {
        throw const BackupFormatException("Couldn't read that file.");
      }
      if (!mounted) return;

      final count = await context.read<ItemsProvider>().importJsonBackup(
        content,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $count item${count == 1 ? '' : 's'}.'),
        ),
      );
    } on BackupFormatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showExportSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _export('json');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _export('csv');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: skipTheme.cardBackground,
        borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 4),
        border: skipTheme.isY2K
            ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Photos stay on this device — backups cover item records only.",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _showExportSheet,
            icon: const Icon(Icons.ios_share),
            label: const Text('Export backup'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _isBusy ? null : _import,
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Import backup'),
          ),
        ],
      ),
    );
  }
}
