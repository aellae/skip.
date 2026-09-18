import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_spacing.dart';
import '../localization/app_strings.dart';
import 'skip_card.dart';

/// Bottom sheet offering Camera/Gallery choices — and, when [onRemove] is
/// given, a "Remove photo" option — shared by the item entry and item
/// detail (edit) flows so both pick images the same way.
Future<void> showImageSourceSheet(
  BuildContext context, {
  required AppStrings strings,
  required ValueChanged<ImageSource> onPick,
  VoidCallback? onRemove,
}) {
  return showModalBottomSheet<void>(
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
              onTap: () {
                Navigator.of(sheetContext).pop();
                onPick(ImageSource.camera);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ImageSourceOption(
              icon: Icons.photo_library,
              label: strings.gallery,
              onTap: () {
                Navigator.of(sheetContext).pop();
                onPick(ImageSource.gallery);
              },
            ),
            if (onRemove != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _ImageSourceOption(
                icon: Icons.delete_outline,
                label: strings.removePhoto,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onRemove();
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
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
