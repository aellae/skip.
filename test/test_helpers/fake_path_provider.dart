import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Points `path_provider` at a caller-supplied directory (a temp dir in
/// tests) instead of the real platform application-documents directory,
/// which isn't available on the host test runner.
class FakePathProviderPlatform extends PathProviderPlatform {
  FakePathProviderPlatform(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}
