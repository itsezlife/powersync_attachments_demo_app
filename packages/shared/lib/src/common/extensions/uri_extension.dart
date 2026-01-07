import 'dart:io';

/// {@template uri_extension}
/// Extension methods for the Uri class.
/// {@endtemplate}
extension UriExtension on String {
  /// Returns the path of the uri.
  String resolveFilePath(String path) {
    final relativePath = this;
    final isWindows = Platform.isWindows;
    return Uri.file(relativePath).resolve(path).toFilePath(windows: isWindows);
  }
}
