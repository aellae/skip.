import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:skip/core/utils/file_helper.dart';

import '../../test_helpers/fake_path_provider.dart';

void main() {
  late Directory tempDocsDir;
  late Directory sourceDir;
  late FileHelper fileHelper;

  setUp(() async {
    tempDocsDir = await Directory.systemTemp.createTemp('skip_docs_');
    sourceDir = await Directory.systemTemp.createTemp('skip_source_');
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDocsDir.path);
    fileHelper = FileHelper();
  });

  tearDown(() async {
    if (await tempDocsDir.exists()) await tempDocsDir.delete(recursive: true);
    if (await sourceDir.exists()) await sourceDir.delete(recursive: true);
  });

  group('FileHelper', () {
    test(
      'saveImage copies the file into the app documents images subdir',
      () async {
        final source = File(p.join(sourceDir.path, 'photo.jpg'))
          ..writeAsBytesSync([1, 2, 3, 4]);

        final relativePath = await fileHelper.saveImage(source);

        expect(relativePath, startsWith('${FileHelper.imagesSubdir}/'));
        expect(relativePath, endsWith('.jpg'));
        final copied = File(p.join(tempDocsDir.path, relativePath));
        expect(await copied.exists(), isTrue);
        expect(await copied.readAsBytes(), [1, 2, 3, 4]);
      },
    );

    test('saveImage leaves the original source file untouched', () async {
      final source = File(p.join(sourceDir.path, 'photo.png'))
        ..writeAsBytesSync([9, 9, 9]);

      await fileHelper.saveImage(source);

      expect(await source.exists(), isTrue);
    });

    test(
      'resolveImageFile reconstructs an absolute path from a relative one',
      () async {
        final source = File(p.join(sourceDir.path, 'photo.jpg'))
          ..writeAsBytesSync([1]);
        final relativePath = await fileHelper.saveImage(source);

        final resolved = await fileHelper.resolveImageFile(relativePath);

        expect(resolved.path, p.join(tempDocsDir.path, relativePath));
        expect(await resolved.exists(), isTrue);
      },
    );

    test('deleteImage removes an existing file', () async {
      final source = File(p.join(sourceDir.path, 'photo.jpg'))
        ..writeAsBytesSync([1]);
      final relativePath = await fileHelper.saveImage(source);

      await fileHelper.deleteImage(relativePath);

      final resolved = await fileHelper.resolveImageFile(relativePath);
      expect(await resolved.exists(), isFalse);
    });

    test('deleteImage is a no-op when the file does not exist', () async {
      await expectLater(
        fileHelper.deleteImage('${FileHelper.imagesSubdir}/never_existed.jpg'),
        completes,
      );
    });

    test('two saves of the same source produce distinct filenames', () async {
      final source = File(p.join(sourceDir.path, 'photo.jpg'))
        ..writeAsBytesSync([1]);

      final first = await fileHelper.saveImage(source);
      final second = await fileHelper.saveImage(source);

      expect(first, isNot(equals(second)));
    });

    test('writeExportFile writes content into the exports subdir', () async {
      final file = await fileHelper.writeExportFile('backup.json', '{"a":1}');

      expect(
        file.path,
        p.join(tempDocsDir.path, FileHelper.exportsSubdir, 'backup.json'),
      );
      expect(await file.readAsString(), '{"a":1}');
    });

    test('writeExportFile overwrites a file with the same name', () async {
      await fileHelper.writeExportFile('backup.json', 'first');
      final file = await fileHelper.writeExportFile('backup.json', 'second');

      expect(await file.readAsString(), 'second');
    });
  });
}
