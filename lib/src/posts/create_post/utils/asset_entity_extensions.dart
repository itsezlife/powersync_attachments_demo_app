import 'dart:io';

import 'package:insta_assets_picker/insta_assets_picker.dart';

extension AssetEntityExtensions on AssetEntity {
  /// Converts AssetEntity to File for upload purposes
  Future<File?> toFile({bool isOriginal = false}) async {
    if (isOriginal) {
      return originFile;
    }
    return file;
  }
}

extension AssetEntityListExtensions on List<AssetEntity> {
  /// Converts a list of AssetEntity to a list of Files
  Future<List<File>> toFiles({bool isOriginal = false}) async {
    final files = <File>[];
    for (final asset in this) {
      final file = await asset.toFile(isOriginal: isOriginal);
      if (file != null) {
        files.add(file);
      }
    }
    return files;
  }
}
