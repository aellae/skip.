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
    group('deletePickerTempFile', () {
      test('deletes a picker copy inside the app cache dir', () async {
        final cacheDir = Directory(p.join(tempDocsDir.path, 'cache'))
          ..createSync();
        final cached = File(p.join(cacheDir.path, 'scaled_1.jpg'))
          ..writeAsBytesSync([1]);

        await fileHelper.deletePickerTempFile(cached.path);

        expect(cached.existsSync(), isFalse);
      });

      test('never deletes a file outside the app cache dir', () async {
        final original = File(p.join(sourceDir.path, 'gallery.jpg'))
          ..writeAsBytesSync([1]);

        await fileHelper.deletePickerTempFile(original.path);

        expect(original.existsSync(), isTrue);
      });

      test('is a no-op for a path that no longer exists', () async {
        await fileHelper.deletePickerTempFile(
          p.join(tempDocsDir.path, 'cache', 'gone.jpg'),
        );
      });

      group('in an iOS-style container', () {
        late Directory container;
        late Directory docs;
        late Directory tmp;
        late Directory caches;

        setUp(() {
          container = Directory(p.join(sourceDir.path, 'container'));
          docs = Directory(p.join(container.path, 'Documents'))
            ..createSync(recursive: true);
          caches = Directory(p.join(container.path, 'Library', 'Caches'))
            ..createSync(recursive: true);
          tmp = Directory(p.join(container.path, 'tmp'))..createSync();
          PathProviderPlatform.instance = FakePathProviderPlatform.iosContainer(
            container.path,
          );
          fileHelper = FileHelper(systemTemp: () => tmp);
        });

        File write(String path) => File(path)
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync([1]);

        test('deletes a picker copy in the container tmp dir', () async {
          final copy = write(p.join(tmp.path, 'image_picker_ABC.jpg'));

          await fileHelper.deletePickerTempFile(copy.path);

          expect(copy.existsSync(), isFalse);
        });

        test('deletes a picker copy in Library/Caches', () async {
          final copy = write(p.join(caches.path, 'image_picker_ABC.jpg'));

          await fileHelper.deletePickerTempFile(copy.path);

          expect(copy.existsSync(), isFalse);
        });

        test('never deletes a stored photo in skip_images', () async {
          final stored = write(
            p.join(docs.path, FileHelper.imagesSubdir, 'kept.jpg'),
          );

          await fileHelper.deletePickerTempFile(stored.path);

          expect(stored.existsSync(), isTrue);
        });

        test('never deletes a file elsewhere in the container', () async {
          final other = write(p.join(container.path, 'Library', 'prefs.jpg'));

          await fileHelper.deletePickerTempFile(other.path);

          expect(other.existsSync(), isTrue);
        });

        test('`..` segments cannot escape the allow-list', () async {
          final stored = write(
            p.join(docs.path, FileHelper.imagesSubdir, 'kept.jpg'),
          );
          final outside = write(p.join(sourceDir.path, 'gallery.jpg'));

          await fileHelper.deletePickerTempFile(
            p.join(
              tmp.path,
              '..',
              'Documents',
              FileHelper.imagesSubdir,
              'kept.jpg',
            ),
          );
          await fileHelper.deletePickerTempFile(
            p.join(tmp.path, '..', '..', 'gallery.jpg'),
          );

          expect(stored.existsSync(), isTrue);
          expect(outside.existsSync(), isTrue);
        });

        test('resolves a symlinked path to the same tmp dir', () async {
          final copy = write(p.join(tmp.path, 'image_picker_ABC.jpg'));
          final alias = Link(p.join(sourceDir.path, 'alias'))
            ..createSync(container.path);

          await fileHelper.deletePickerTempFile(
            p.join(alias.path, 'tmp', 'image_picker_ABC.jpg'),
          );

          expect(copy.existsSync(), isFalse);
        });

        test('ignores a system temp dir outside the app container', () async {
          final foreignTmp = Directory(p.join(sourceDir.path, 'foreign_tmp'))
            ..createSync();
          fileHelper = FileHelper(systemTemp: () => foreignTmp);
          final copy = write(p.join(foreignTmp.path, 'image_picker_ABC.jpg'));

          await fileHelper.deletePickerTempFile(copy.path);

          expect(copy.existsSync(), isTrue);
        });
      });
    });

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
