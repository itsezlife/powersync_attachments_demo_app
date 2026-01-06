// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/extensions/show_dialog_extension.dart';
import 'package:powersync_attachments_example/src/common/extensions/show_snackbar_extension.dart';
import 'package:powersync_attachments_example/src/media_picker/media_picker.dart';
import 'package:shared/shared.dart';

typedef InstaAssetsPickerOnUpload =
    void Function(List<File> assetsFiles, [List<Uint8List>? assetsBytes]);

typedef InstaAssetsPickerOnCompleted =
    void Function(Stream<InstaAssetsExportDetails> details);

mixin InstaPickerInterfaceMixin on Widget {
  ThemeData _getPickerTheme(BuildContext context) => context.theme;

  void showFailedToAssetImageSnackBar(BuildContext context) {
    if (!context.mounted) return;
    context.showErrorSnackBar(error: 'Failed to pick image'.hardcoded);
  }

  Never _throwFailedToPickImageException(
    BuildContext context, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    showFailedToAssetImageSnackBar(context);
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error ?? Exception('Failed to pick image'),
        stack: stackTrace ?? StackTrace.current,
        library: 'InstaPickerInterface',
        context: ErrorDescription('Failed to pick image'),
      ),
    );
    return Error.throwWithStackTrace(
      Exception('Failed to pick image: $error'),
      stackTrace ?? StackTrace.current,
    );
  }

  Future<void> pickAssets(
    BuildContext context, {
    required int maxAssets,
    required bool compress,
    RequestType requestType = RequestType.common,
    List<AssetEntity>? selectedAssets,
    InstaAssetsPickerOnUpload? onUpload,
    InstaAssetsPickerOnCompleted? onCompleted,
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),
    bool closeOnComplete = false,
  }) async {
    Never throwError(Object? error, StackTrace? stackTrace) {
      _throwFailedToPickImageException(context, error, stackTrace);
    }

    final usePicker = Config.isDesktop || kIsWeb;
    if (usePicker) {
      final picker = image_picker.ImagePicker();
      image_picker.XFile? pickedImage;
      try {
        pickedImage = await picker
            .pickImage(source: image_picker.ImageSource.gallery)
            .timeout(const Duration(seconds: 10));
      } catch (error, stackTrace) {
        throwError(error, stackTrace);
      }

      if (pickedImage == null) return;

      void Function()? closeLoadingDialog;

      if (context.mounted) {
        closeLoadingDialog = context.showLoadingDialog(
          text: 'Compressing image...'.hardcoded,
        );
      }

      try {
        final imageFile = await ImageUtils().pickImageFileFromPicker(
          file: pickedImage,
          compress: compress,
        );
        if (imageFile == null) {
          closeLoadingDialog?.call();
          throwError('Picked image is null', null);
        }
        final bytes = await ImageUtils().imageBytes(file: imageFile);
        onUpload?.call([imageFile], [bytes]);
      } catch (error, stackTrace) {
        throwError(error, stackTrace);
      } finally {
        closeLoadingDialog?.call();
      }
      return;
    }
    await InstaAssetPicker.pickAssets(
      context,
      pageRouteBuilder: (picker) =>
          SharedAxisPageRoute<List<AssetEntity>>(builder: (_) => picker),
      selectedAssets: selectedAssets,
      pickerConfig: InstaAssetPickerConfig(
        closeOnComplete: closeOnComplete,
        pickerTheme: _getPickerTheme(context),
        cropDelegate: cropDelegate,
        textDelegate: Localizations.localeOf(context).languageCode == 'es'
            ? const SpanishAssetPickerTextDelegate()
            : null,
        // skipCropOnComplete: true, // to test ffmpeg crop image
        // previewThumbnailSize: const ThumbnailSize(240, 240), // to improve thumbnails speed in crop view
      ),
      requestType: requestType,
      maxAssets: maxAssets,
      onCompleted: (exportDetails) async {
        if (onCompleted != null) {
          onCompleted.call(exportDetails);
          return;
        }
        late InstaAssetsExportDetails instaAssetsExportDetails;
        await for (final detail in exportDetails) {
          instaAssetsExportDetails = detail;
        }
        final details = instaAssetsExportDetails.data;
        if (details.isEmpty) return;

        void Function()? closeLoadingDialog;

        if (context.mounted) {
          closeLoadingDialog = context.showLoadingDialog(
            text: 'Compressing image...'.hardcoded,
          );
        }

        try {
          final assetsFiles = await Future.wait(
            details.map((detail) async => detail.croppedFile!),
          );
          log('Assets: ${assetsFiles.map((e) => e.path).toList()}');
          final compressedFiles = await Future.wait(
            assetsFiles.map((file) async {
              final compressed = await ImageCompresser.compressFile(file);
              return compressed == null ? file : File(compressed.path);
            }),
          );
          onUpload?.call(compressedFiles);
        } catch (error, stackTrace) {
          throwError(error, stackTrace);
        } finally {
          closeLoadingDialog?.call();
        }
      },
    );
  }

  Future<void> pickVideo(
    BuildContext context, {
    InstaAssetsPickerOnCompleted? onCompleted,
  }) => pickAssets(
    context,
    maxAssets: 1,
    compress: false,
    cropDelegate: const InstaAssetCropDelegate(
      cropRatios: [4 / 5],
      preferredSize: 1920,
    ),
    requestType: RequestType.video,
    onCompleted: onCompleted,
  );
}

mixin InstaPickerInterfaceStateMixin<T extends StatefulWidget> on State<T> {
  ThemeData _getPickerTheme() => context.theme;

  void showFailedToAssetImageSnackBar() {
    if (!mounted) return;
    context.showErrorSnackBar(error: 'Failed to pick image'.hardcoded);
  }

  Never _throwFailedToPickImageException([
    Object? error,
    StackTrace? stackTrace,
  ]) => Error.throwWithStackTrace(
    Exception('Failed to pick image: $error'),
    stackTrace ?? StackTrace.current,
  );

  Future<void> pickAssets({
    required int maxAssets,
    required bool compress,
    RequestType requestType = RequestType.common,
    InstaAssetsPickerOnUpload? onUpload,
    List<AssetEntity>? selectedAssets,
    InstaAssetsPickerOnCompleted? onCompleted,
    InstaAssetCropDelegate cropDelegate = const InstaAssetCropDelegate(),
    bool closeOnComplete = false,
    bool skipCropOnComplete = false,
  }) async {
    Never throwError(Object? error, StackTrace? stackTrace) {
      _throwFailedToPickImageException(error, stackTrace);
    }

    try {
      final useNativeImagePicker = Config.isDesktop || kIsWeb;
      if (useNativeImagePicker) {
        final picker = image_picker.ImagePicker();
        image_picker.XFile? pickedImage;
        try {
          pickedImage = await picker.pickImage(
            source: image_picker.ImageSource.gallery,
          );
        } catch (error, stackTrace) {
          throwError(error, stackTrace);
        }

        if (pickedImage == null) return;

        void Function()? closeLoadingDialog;

        if (mounted) {
          closeLoadingDialog = context.showLoadingDialog(
            text: 'Compressing image...'.hardcoded,
          );
        }

        try {
          final imageFile = await ImageUtils().pickImageFileFromPicker(
            file: pickedImage,
            compress: compress,
          );
          if (imageFile == null) {
            closeLoadingDialog?.call();
            throwError('Picked image is null', null);
          }
          final bytes = await ImageUtils().imageBytes(file: imageFile);
          onUpload?.call([imageFile], [bytes]);
        } catch (error, stackTrace) {
          throwError(error, stackTrace);
        } finally {
          closeLoadingDialog?.call();
        }
        return;
      }

      await InstaAssetPicker.pickAssets(
        context,
        pageRouteBuilder: (picker) =>
            SharedAxisPageRoute<List<AssetEntity>>(builder: (_) => picker),
        selectedAssets: selectedAssets,
        pickerConfig: InstaAssetPickerConfig(
          closeOnComplete: closeOnComplete,
          pickerTheme: _getPickerTheme(),
          cropDelegate: cropDelegate,
          textDelegate: Localizations.localeOf(context).languageCode == 'es'
              ? const SpanishAssetPickerTextDelegate()
              : null,
          skipCropOnComplete: skipCropOnComplete, // to test ffmpeg crop image
          // previewThumbnailSize: const ThumbnailSize(240, 240), // to improve thumbnails speed in crop view
        ),
        requestType: requestType,
        maxAssets: maxAssets,
        onCompleted: (exportDetails) async {
          if (onCompleted != null) {
            onCompleted.call(exportDetails);
            return;
          }
          late InstaAssetsExportDetails instaAssetsExportDetails;
          await for (final detail in exportDetails) {
            instaAssetsExportDetails = detail;
          }
          final details = instaAssetsExportDetails.data;
          if (details.isEmpty) return;

          void Function()? closeLoadingDialog;

          if (mounted) {
            closeLoadingDialog = context.showLoadingDialog(
              text: 'Compressing image...'.hardcoded,
            );
          }

          try {
            final assetsFiles = await Future.wait(
              details.map((detail) async => detail.croppedFile!),
            );
            log('Assets: ${assetsFiles.map((e) => e.path).toList()}');
            final compressedFiles = await Future.wait(
              assetsFiles.map((file) async {
                final compressed = await ImageCompresser.compressFile(file);
                return compressed == null ? file : File(compressed.path);
              }),
            );
            onUpload?.call(compressedFiles);
          } catch (error, stackTrace) {
            throwError(error, stackTrace);
          } finally {
            closeLoadingDialog?.call();
          }
        },
      );
    } catch (error, stackTrace) {
      showFailedToAssetImageSnackBar();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'InstaPickerStatefulInterface',
          context: ErrorDescription('Failed to pick image: $error'),
        ),
      );
    }
  }
}
