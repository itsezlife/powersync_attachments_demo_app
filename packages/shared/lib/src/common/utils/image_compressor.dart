import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart';

/// {@template image_compresser}
/// Allows compressing image files and bytes.
/// {@endtemplate}
class ImageCompresser {
  const ImageCompresser._();

  /// Compress image byte.
  static Future<Uint8List> compressBytes(Uint8List file) async {
    if (file.lengthInBytes > 200_000) {
      final result = await FlutterImageCompress.compressWithList(
        file,
        quality: file.lengthInBytes > 4_000_000 ? 90 : 72,
      );
      return result;
    } else {
      return file;
    }
  }

  /// Compresses file bytes and writes into file.
  static Future<File> compressBytesAndWriteFile(
    Uint8List file, {
    required Directory tempDir,
    required String fileExtension,
  }) async {
    final bytes = await compute(compressBytes, file);
    final newFile = await compute(
      (list) => writeToFile(
        list[0] as ByteData,
        tempDir: list[1] as Directory,
        fileExtension: list[2] as String,
      ),
      [ByteData.view(bytes.buffer), tempDir, fileExtension],
    );
    return newFile;
  }

  /// Writes to the file `ByteData` with [fileExtension].
  static Future<File> writeToFile(
    ByteData data, {
    required Directory tempDir,
    required String fileExtension,
  }) async {
    final buffer = data.buffer;
    final tempPath = tempDir.path;
    final filePath = '$tempPath/${DateTime.now()}.$fileExtension';
    return File(filePath).writeAsBytes(
      buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Compress image file.
  static Future<XFile?> compressFile(
    File file, {
    int quality = 50,
  }) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp('.png|.jp'));
    if (lastIndex == -1) return null;
    final splitted = filePath.substring(0, lastIndex);
    final outPath = '${splitted}_out${filePath.substring(lastIndex)}';

    final format = lastIndex == filePath.lastIndexOf(RegExp('.png'))
        ? CompressFormat.png
        : CompressFormat.jpeg;

    final compressedImage = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      minWidth: 1000,
      minHeight: 1000,
      quality: quality,
      format: format,
    );
    return compressedImage;
  }

  /// Compresses image bytes.
  static Future<Uint8List?> compressImage(
    Uint8List imageBytes, {
    required int quality,
    required bool autofillPng,
    (int r, int g, int b)? autofillColor,
  }) async {
    final image = decodeImage(imageBytes);
    if (image == null) return null;

    // Check if the image has an alpha channel
    final hasAlpha = image.numChannels == 4;

    // Compress while preserving transparency if it has alpha channel
    final compressedBytes = await FlutterImageCompress.compressWithList(
      imageBytes,
      quality: quality,
      format: hasAlpha && autofillPng
          ? CompressFormat.png
          : CompressFormat.jpeg,
      keepExif: true,
    );

    return Uint8List.fromList(compressedBytes);
  }
}
