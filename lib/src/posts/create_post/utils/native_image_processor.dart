// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:insta_assets_crop/insta_assets_crop.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

class ProcessedAsset extends Equatable {
  const ProcessedAsset({
    required this.asset,
    required this.displayBytes,
    required this.targetWidth,
    required this.targetHeight,
    required this.originalWidth,
    required this.originalHeight,
    this.cropRect,
  });

  final AssetEntity asset;
  final Uint8List displayBytes;
  final int targetWidth;
  final int targetHeight;
  final int originalWidth;
  final int originalHeight;
  final Rect? cropRect;

  Map<String, double>? get cropRectNormalized {
    final rect = cropRect;
    if (rect == null) return null;
    return {
      'left': rect.left,
      'top': rect.top,
      'right': rect.right,
      'bottom': rect.bottom,
    };
  }

  @override
  List<Object?> get props => [
    asset,
    displayBytes,
    targetWidth,
    targetHeight,
    originalWidth,
    originalHeight,
    cropRect,
  ];

  ProcessedAsset copyWith({
    AssetEntity? asset,
    Uint8List? displayBytes,
    int? targetWidth,
    int? targetHeight,
    int? originalWidth,
    int? originalHeight,
    Rect? cropRect,
  }) => ProcessedAsset(
    asset: asset ?? this.asset,
    displayBytes: displayBytes ?? this.displayBytes,
    targetWidth: targetWidth ?? this.targetWidth,
    targetHeight: targetHeight ?? this.targetHeight,
    originalWidth: originalWidth ?? this.originalWidth,
    originalHeight: originalHeight ?? this.originalHeight,
    cropRect: cropRect ?? this.cropRect,
  );
}

/// Native image processor that leverages insta_assets_crop for high-quality image processing
class NativeImageProcessor {
  /// {@macro native_image_processor}
  const NativeImageProcessor._();

  /// Process image for single mode display
  /// - Maintains aspect ratio
  /// - Scales down large images while preserving quality
  /// - Uses native processing for best quality
  static Future<ProcessedAsset?> processSingleModeImage(
    AssetEntity asset, {
    double maxWidth = 400.0,
    double devicePixelRatio = 3.0,
  }) async {
    try {
      log('NativeImageProcessor: Processing single mode image ${asset.id}');

      final originalWidth = asset.orientatedWidth;
      final originalHeight = asset.orientatedHeight;

      // Calculate target dimensions for high quality
      final targetMaxWidth = (maxWidth * devicePixelRatio).clamp(600.0, 1200.0);

      if (originalWidth >= originalHeight) {
        final targetHeight = originalHeight > 800 ? 800 : originalHeight;
        log(
          'NativeImageProcessor: Using original size for single mode '
          '${targetMaxWidth.round()}x$targetHeight',
        );
        final thumbnailData = await _processWithNativeResize(
          asset,
          targetWidth: targetMaxWidth.round(),
          targetHeight: targetHeight,
        );
        return ProcessedAsset(
          asset: asset,
          displayBytes: thumbnailData!,
          targetWidth: targetMaxWidth.round(),
          targetHeight: targetHeight,
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      }

      final scale = targetMaxWidth / originalWidth;
      final targetHeight = (originalHeight * scale).round();
      log(
        'NativeImageProcessor: Scaling single mode image to ${targetMaxWidth.round()}x$targetHeight',
      );
      final thumbnailData = await _processWithNativeResize(
        asset,
        targetWidth: targetMaxWidth.round(),
        targetHeight: targetHeight,
      );
      return ProcessedAsset(
        asset: asset,
        displayBytes: thumbnailData!,
        targetWidth: targetMaxWidth.round(),
        targetHeight: targetHeight,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
      );

      // For vertical images over 800px height, apply fixed height of 500
      // if (originalHeight > originalWidth && originalHeight > 800) {
      //   log('NativeImageProcessor: Applying vertical image fixed height');
      //   final aspectRatio = originalWidth / originalHeight;
      //   final targetWidth = (600 * aspectRatio).round();
      //   final targetHeight = (maxHeight * devicePixelRatio).round();
      //   final thumbnailData = await _processWithNativeResize(
      //     asset,
      //     targetWidth: targetWidth,
      //     targetHeight: targetHeight,
      //   );
      //   return PostProcessData(
      //     thumbnailData: thumbnailData!,
      //     targetWidth: targetWidth,
      //     targetHeight: targetHeight,
      //   );
      // }

      // For normal images, scale only if needed
      // if (originalWidth <= targetMaxWidth) {
      //   log('NativeImageProcessor: Using original size for single mode');
      //   final thumbnailData = await asset.originBytes;
      //   return PostProcessData(
      //     thumbnailData: thumbnailData!,
      //     targetWidth: originalWidth,
      //     targetHeight: originalHeight,
      //   );
      // } else {
      //   final scale = targetMaxWidth / originalWidth;
      //   final targetHeight = (originalHeight * scale).round();
      //   log(
      //     'NativeImageProcessor: Scaling single mode image to ${targetMaxWidth.round()}x$targetHeight',
      //   );
      //   final thumbnailData = await _processWithNativeResize(
      //     asset,
      //     targetWidth: targetMaxWidth.round(),
      //     targetHeight: targetHeight,
      //   );
      //   return PostProcessData(
      //     thumbnailData: thumbnailData!,
      //     targetWidth: targetMaxWidth.round(),
      //     targetHeight: targetHeight,
      //   );
      // }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'NativeImageProcessor',
          context: ErrorDescription('Failed to process single mode image'),
        ),
      );
      return null;
    }
  }

  /// Process image for multiple mode display with proper cropping/scaling
  /// - Fixed height with proper cropping for wider images
  /// - Upscaling for shorter images
  /// - Uses native processing for best quality
  static Future<ProcessedAsset?> processMultipleModeImage(
    AssetEntity asset, {
    double height = 300.0,
    double maxWidth = 400.0,
    double devicePixelRatio = 3.0,
  }) async {
    try {
      log('NativeImageProcessor: Processing multiple mode image ${asset.id}');

      final originalWidth = asset.orientatedWidth;
      final originalHeight = asset.orientatedHeight;

      final aspectRatio = originalWidth / originalHeight;

      // Calculate target dimensions
      final targetHeight = (height * devicePixelRatio).clamp(400.0, 900.0);
      final targetMaxWidth = (maxWidth * devicePixelRatio).clamp(600.0, 1200.0);

      // Calculate scaling to fit height
      final heightScale = targetHeight / originalHeight;
      final scaledWidth = originalWidth * heightScale;

      if (aspectRatio == 1) {
        final thumbnailData = await _processWithNativeResize(
          asset,
          targetWidth: targetHeight.round(),
          targetHeight: targetHeight.round(),
        );
        return ProcessedAsset(
          asset: asset,
          displayBytes: thumbnailData!,
          targetWidth: targetHeight.round(),
          targetHeight: targetHeight.round(),
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      }

      // If image is taller than wide, we need to crop and resize
      if (originalHeight >= originalWidth) {
        log(
          'NativeImageProcessor: Simple resize for multiple mode: ${scaledWidth.round()}x${targetHeight.round()}',
        );
        final result = await _processWithNativeCropAndResize(
          asset,
          targetWidth: (scaledWidth * 1.5).round(),
          targetHeight: targetHeight.round(),
        );
        return ProcessedAsset(
          asset: asset,
          displayBytes: result!.displayBytes,
          cropRect: result.cropRect,
          targetWidth: (scaledWidth * 1.5).round(),
          targetHeight: targetHeight.round(),
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      } else {
        // Image is wider than tall, use target max width
        log(
          'NativeImageProcessor: Cropping wide image for multiple mode '
          'for ${asset.id}: targetWidth: ${targetMaxWidth.round()}, targetHeight: ${targetHeight.round()}',
        );
        final result = await _processWithNativeCropAndResize(
          asset,
          targetWidth: targetMaxWidth.round(),
          targetHeight: targetHeight.round(),
        );
        return ProcessedAsset(
          asset: asset,
          displayBytes: result!.displayBytes,
          cropRect: result.cropRect,
          targetWidth: targetMaxWidth.round(),
          targetHeight: targetHeight.round(),
          originalWidth: originalWidth,
          originalHeight: originalHeight,
        );
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'NativeImageProcessor',
          context: ErrorDescription('Failed to process multiple mode image'),
        ),
      );
      return null;
    }
  }

  /// Resize image using native processing
  static Future<Uint8List?> _processWithNativeResize(
    AssetEntity asset, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    try {
      // Get the original file
      final file = await asset.originFile;
      if (file == null) {
        log('NativeImageProcessor: Could not get origin file');
        return null;
      }

      log(
        'NativeImageProcessor: Resizing ${file.path} to ${targetWidth}x$targetHeight',
      );

      // Use insta_assets_crop native resizing
      final resizedFile = await InstaAssetsCrop.sampleImage(
        file: file,
        preferredWidth: targetWidth,
        preferredHeight: targetHeight,
      );

      // Read the processed file
      final bytes = await resizedFile.readAsBytes();

      // Clean up temporary file
      await resizedFile.delete();

      log(
        'NativeImageProcessor: Successfully resized image, output size: ${bytes.length} bytes',
      );
      return bytes;
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'NativeImageProcessor',
          context: ErrorDescription('Failed to resize image'),
        ),
      );
      return null;
    }
  }

  /// Crop and resize image using native processing
  static Future<({Uint8List displayBytes, Rect cropRect})?>
  _processWithNativeCropAndResize(
    AssetEntity asset, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    try {
      // Get the original file
      final file = await asset.originFile;
      if (file == null) {
        log('NativeImageProcessor: Could not get origin file for cropping');
        return null;
      }

      final originalWidth = asset.orientatedWidth;
      final originalHeight = asset.orientatedHeight;

      // Calculate crop area to center the image
      final aspectRatio = targetWidth / targetHeight;
      final originalAspectRatio = originalWidth / originalHeight;

      Rect cropArea;
      if (originalAspectRatio > aspectRatio) {
        // Image is wider - crop horizontally
        final cropWidth = originalHeight * aspectRatio;
        final cropLeft = (originalWidth - cropWidth) / 2 / originalWidth;
        cropArea = Rect.fromLTWH(cropLeft, 0, cropWidth / originalWidth, 1);
      } else {
        // Image is taller - crop vertically
        final cropHeight = originalWidth / aspectRatio;
        final cropTop = (originalHeight - cropHeight) / 2 / originalHeight;
        cropArea = Rect.fromLTWH(0, cropTop, 1, cropHeight / originalHeight);
      }

      log('NativeImageProcessor: Cropping with area: $cropArea');

      // First, crop the image
      final croppedFile = await InstaAssetsCrop.cropImage(
        file: file,
        area: cropArea,
      );

      // Then resize to target dimensions
      final finalFile = await InstaAssetsCrop.sampleImage(
        file: croppedFile,
        preferredWidth: targetWidth,
        preferredHeight: targetHeight,
      );

      // Read the processed file
      final bytes = await finalFile.readAsBytes();

      // Clean up temporary files
      await croppedFile.delete();
      await finalFile.delete();

      log(
        'NativeImageProcessor: Successfully cropped and resized image, output size: ${bytes.length} bytes',
      );
      return (displayBytes: bytes, cropRect: cropArea);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'NativeImageProcessor',
          context: ErrorDescription('Failed to crop and resize image'),
        ),
      );
      return null;
    }
  }
}
