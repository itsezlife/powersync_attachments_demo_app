import 'dart:io';

import 'package:path/path.dart' as path;

/// {@template file_extension}
/// Extension on [File] to check if it is a video file.
/// {@endtemplate}
extension FileExtension on File {
  /// Returns [File] extension in `.xxx` format
  String getFileExtension({bool removeDot = true}) => path
      .extension(this.path)
      .toLowerCase()
      .replaceFirst(removeDot ? '.' : '', '');
}
