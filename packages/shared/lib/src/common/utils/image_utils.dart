import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:shared/shared.dart';

/// Generates a minithumbnail from an image file
/// Similar to Telegram's approach - creates a very small (max 40px) JPEG
Minithumbnail? generateMinithumbnail(
  Map<String, dynamic> data,
) {
  try {
    final buffer = data['image'] as Uint8List;
    final image = img.decodeImage(buffer);
    if (image == null) return null;

    // Calculate dimensions (max 40px on longest side)
    const maxDimension = 40;
    final ratio = math.min(
      maxDimension / image.width,
      maxDimension / image.height,
    );

    final newWidth = (image.width * ratio).round();
    final newHeight = (image.height * ratio).round();

    // Resize the image to tiny dimensions
    final thumbnail = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.average,
    );

    // Encode as JPEG with low quality for minimal size
    final jpegBytes = img.encodeJpg(thumbnail, quality: 30);

    // Convert to base64
    final base64Data = base64Encode(jpegBytes);

    return Minithumbnail(
      width: newWidth,
      height: newHeight,
      data: base64Data,
    );
  } on Object catch (error, stackTrace) {
    dev.log(
      'Failed to generate minithumbnail',
      name: 'ImageUtils',
      error: error,
      stackTrace: stackTrace,
    );
    return null;
  }
}

/// {@template image_utils}
/// A class that provides methods to pick images and videos from the gallery.
/// {@endtemplate}
class ImageUtils {
  /// {@macro image_utils}
  factory ImageUtils() => _internal;

  /// {@macro image_utils}
  ImageUtils._();

  static final ImageUtils _internal = ImageUtils._();

  /// Picks an image from the gallery.
  Future<image_picker.XFile?> pickImageFromPicker({
    image_picker.ImageSource source = image_picker.ImageSource.gallery,
  }) => image_picker.ImagePicker().pickImage(source: source);

  /// Picks an image file from the gallery. If compress is true, the image will
  /// be compressed.
  Future<File?> pickImageFileFromPicker({
    image_picker.XFile? file,
    bool compress = true,
    bool crop = false,
    Size cropSize = const Size(1000, 1000),
    image_picker.ImageSource source = image_picker.ImageSource.gallery,
  }) async {
    File? fileFromPicker;
    try {
      final pickedFile = file ?? await pickImageFromPicker(source: source);
      if (pickedFile == null) return null;

      final imageFile = File(pickedFile.path);
      if (!compress && !crop) return imageFile;

      if (crop) {
        // Encode the cropped image to a file
        fileFromPicker = await cropImage(imageFile, cropSize);
      } else {
        fileFromPicker = imageFile;
      }
      if (compress) {
        final compressedFile = await compressImage(fileFromPicker);
        fileFromPicker = compressedFile;
      }
      return fileFromPicker;
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        Exception('Failed to pick image: $error'),
        stackTrace,
      );
    }
  }

  /// Crops the image to the specified size.
  Future<File> cropImage(File imageFile, Size cropSize) async {
    final image = img.decodeImage(await imageFile.readAsBytes());
    if (image == null) return imageFile;

    final cropOffset = Offset(
      (image.width - cropSize.width) / 2,
      (image.height - cropSize.height) / 2,
    );
    final cropRect = Rect.fromPoints(
      cropOffset,
      cropOffset.translate(cropSize.width, cropSize.height),
    );

    // Crop the image
    final croppedImage = img.copyCrop(
      image,
      x: cropRect.left.toInt(),
      y: cropRect.top.toInt(),
      width: cropSize.width.toInt(),
      height: cropSize.height.toInt(),
    );

    // Encode the cropped image to a file
    return imageFile.writeAsBytes(img.encodeJpg(croppedImage));
  }

  /// Compresses the image to the specified size.
  Future<File> compressImage(File imageFile, {int quality = 50}) async {
    final compressed = await ImageCompresser.compressFile(
      imageFile,
      quality: quality,
    );
    if (compressed == null) {
      dev.log('Compressed image returned null', name: 'ImageUtils');
      return imageFile;
    }
    final compressedFile = File(compressed.path);
    return compressedFile;
  }

  /// Reads image as bytes.
  Future<Uint8List> imageBytes({required File file}) =>
      compute((file) => file.readAsBytes(), file);
}
