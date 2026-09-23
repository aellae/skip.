import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final Random _random = Random();

/// Copies picked images into the app's local documents directory and
/// manages their lifecycle on disk.
///
/// Images are referenced in the database by a path *relative* to the app
/// documents directory (e.g. `skip_images/172930...123.jpg`), never an
/// absolute path — the sandboxed container path is not guaranteed stable
/// across app reinstalls/updates (notably on iOS), so an absolute path
/// stored today can silently point nowhere after an update.
class FileHelper {
  /// [systemTemp] overrides [Directory.systemTemp], for tests only.
  FileHelper({Directory Function()? systemTemp})
    : _systemTemp = systemTemp ?? (() => Directory.systemTemp);

  static const String imagesSubdir = 'skip_images';
  static const String exportsSubdir = 'skip_exports';

  final Directory Function() _systemTemp;

  Future<String>? _docsPathFuture;

  /// The app documents directory path, resolved once and cached — a grid of
  /// items resolves many image paths and the platform channel round trip
  /// isn't free.
  Future<String> _documentsPath() {
    return _docsPathFuture ??= getApplicationDocumentsDirectory().then(
      (dir) => dir.path,
    );
  }

  // Deliberately synchronous dart:io calls below (existsSync/createSync/
  // copySync/deleteSync), not their async counterparts. Real async dart:io
  // I/O depends on the actual OS event loop, which Flutter widget tests
  // don't pump (they run on a fake clock) — an awaited File.copy()/delete()
  // triggered from a widget's event handler simply never completes inside
  // `testWidgets`. Sync calls resolve via the current call stack instead,
  // so they work the same in the app and in tests; a picked photo is small
  // enough that blocking briefly is not a real UX cost.

  Future<Directory> imagesDirectory() async {
    final docsPath = await _documentsPath();
    final dir = Directory(p.join(docsPath, imagesSubdir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Every file currently in the images directory, referenced or not.
  Future<List<File>> listImageFiles() async {
    final dir = await imagesDirectory();
    return dir.listSync().whereType<File>().toList();
  }

  /// Copies [sourceFile] into the app documents directory and returns the
  /// path relative to that directory for storage in the database.
  Future<String> saveImage(File sourceFile) async {
    final dir = await imagesDirectory();
    final ext = p.extension(sourceFile.path);
    final unique =
        '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 32)}';
    final fileName = '$unique$ext';
    final destPath = p.join(dir.path, fileName);
    sourceFile.copySync(destPath);
    return p.join(imagesSubdir, fileName);
  }

  /// Deletes [path], image_picker's temporary copy of a picked photo, once
  /// it has been copied into app documents (or the copy failed). Only a
  /// file inside the app's own temp/cache directories is ever removed;
  /// anything elsewhere (an original in the gallery, a stored photo in
  /// [imagesSubdir]) is left alone. Best-effort: never throws.
  Future<void> deletePickerTempFile(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) return;
      // Compare real paths: iOS reports the same container under both
      // /var and /private/var, and `..` segments must not escape the check.
      final target = file.resolveSymbolicLinksSync();
      final images = (await imagesDirectory()).resolveSymbolicLinksSync();
      if (p.isWithin(images, target)) return;
      final docsDir = Directory(await _documentsPath());
      final allowed = await _pickerTempDirectories(docsDir);
      if (!allowed.any((dir) => p.isWithin(dir, target))) return;
      file.deleteSync();
    } catch (_) {
      // Leftover temp files are private and OS-evictable; not worth
      // interrupting the pick over.
    }
  }

  /// Real paths of the directories image_picker writes its copies to: the
  /// app cache dir (Android) and, on iOS, `NSTemporaryDirectory()` — the
  /// container's `tmp/`, a sibling of `Library/` rather than inside the
  /// `Library/Caches` that [getTemporaryDirectory] returns. The system temp
  /// dir only counts when it sits in the app's own container, next to the
  /// documents directory.
  Future<List<String>> _pickerTempDirectories(Directory docsDir) async {
    final dirs = [(await getTemporaryDirectory()).resolveSymbolicLinksSync()];
    final systemTemp = _systemTemp();
    if (systemTemp.existsSync()) {
      final temp = systemTemp.resolveSymbolicLinksSync();
      final container = docsDir.parent.resolveSymbolicLinksSync();
      if (p.equals(p.dirname(temp), container)) dirs.add(temp);
    }
    return dirs;
  }

  /// Resolves a relative path (as stored in the database) to an absolute
  /// [File] for the current install, suitable for `Image.file()`.
  Future<File> resolveImageFile(String relativePath) async {
    final docsPath = await _documentsPath();
    return File(p.join(docsPath, relativePath));
  }

  /// Deletes the image at [relativePath] if it exists. A no-op if the file
  /// is already gone, so callers never need to check existence first.
  Future<void> deleteImage(String relativePath) async {
    final file = await resolveImageFile(relativePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<Directory> exportsDirectory() async {
    final docsPath = await _documentsPath();
    final dir = Directory(p.join(docsPath, exportsSubdir));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Writes [content] to [fileName] inside the exports directory
  /// (overwriting any existing file with that name) and returns the
  /// resulting file, ready to hand to the system share sheet.
  Future<File> writeExportFile(String fileName, String content) async {
    final dir = await exportsDirectory();
    final file = File(p.join(dir.path, fileName));
    file.writeAsStringSync(content);
    return file;
  }
}
