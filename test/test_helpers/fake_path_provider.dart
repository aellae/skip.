import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Points `path_provider` at a caller-supplied directory (a temp dir in
/// tests) instead of the real platform application-documents directory,
/// which isn't available on the host test runner.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.documentsPath, {String? temporaryPath})
    : temporaryPath = temporaryPath ?? '$documentsPath/cache';

  /// Lays the dirs out like an iOS app container: `Documents/` and
  /// `Library/Caches/` (what `getTemporaryDirectory()` returns), with the
  /// container's `tmp/` — where image_picker_ios writes — as a sibling.
  FakePathProviderPlatform.iosContainer(String containerPath)
    : this(
        '$containerPath/Documents',
        temporaryPath: '$containerPath/Library/Caches',
      );

  final String documentsPath;

  /// Stands in for the app cache dir, where image_picker leaves its copies.
  final String temporaryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}
