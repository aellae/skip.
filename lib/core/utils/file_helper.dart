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
  static const String imagesSubdir = 'skip_images';

  Future<Directory> imagesDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docsDir.path, imagesSubdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
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
    await sourceFile.copy(destPath);
    return p.join(imagesSubdir, fileName);
  }

  /// Resolves a relative path (as stored in the database) to an absolute
  /// [File] for the current install, suitable for `Image.file()`.
  Future<File> resolveImageFile(String relativePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, relativePath));
  }

  /// Deletes the image at [relativePath] if it exists. A no-op if the file
  /// is already gone, so callers never need to check existence first.
  Future<void> deleteImage(String relativePath) async {
    final file = await resolveImageFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
