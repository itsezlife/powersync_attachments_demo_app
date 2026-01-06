import 'dart:developer';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/posts/create_post/utils/native_image_processor.dart';

class MultiModeProcessedAsset {
  MultiModeProcessedAsset({
    required this.processedAsset,
    required this.singleModeThumbnail,
    required this.multipleModeThumbnail,
    required this.singleModeTargetWidth,
    required this.multipleModeTargetWidth,
    required this.singleModeTargetHeight,
    required this.multipleModeTargetHeight,
  });

  final ProcessedAsset processedAsset;
  final Uint8List singleModeThumbnail;
  final Uint8List multipleModeThumbnail;
  final int singleModeTargetWidth;
  final int multipleModeTargetWidth;
  final int singleModeTargetHeight;
  final int multipleModeTargetHeight;
}

/// A widget that displays media in a Threads-like dynamic layout
/// - Single media: Max width 400px, maintains aspect ratio
/// - Multiple media: Fixed height 200px, max width 400px per item
class DynamicMediaDisplay extends StatefulWidget {
  const DynamicMediaDisplay({
    required this.assets,
    required this.onAssetRemoved,
    required this.onAssetTapped,
    required this.onProcessedAssetsChanged,
    super.key,
    this.multiMediaMaxWidth = 280.0,
    this.singleMediaMaxWidth = 158.0,
    this.singleMediaMaxHeight = 200.0,
    this.multiMediaHeight = 240.0,
  });

  final List<AssetEntity> assets;
  final void Function(AssetEntity asset, int index) onAssetRemoved;
  final void Function(AssetEntity asset, int index) onAssetTapped;
  final double multiMediaMaxWidth;
  final double singleMediaMaxWidth;
  final double multiMediaHeight;
  final double singleMediaMaxHeight;
  final void Function(List<MultiModeProcessedAsset> processedAssets)
  onProcessedAssetsChanged;

  @override
  State<DynamicMediaDisplay> createState() => _DynamicMediaDisplayState();
}

class _DynamicMediaDisplayState extends State<DynamicMediaDisplay> {
  final _media = <MultiModeProcessedAsset>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedia();
    });
  }

  @override
  void didUpdateWidget(covariant DynamicMediaDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<String>().equals(
      oldWidget.assets.map((e) => e.id).toList(),
      widget.assets.map((e) => e.id).toList(),
    )) {
      _updateMedia();
    }
  }

  Future<void> _updateMedia() async {
    final currentAssets = widget.assets;
    final existingAssets = _media
        .map((media) => media.processedAsset.asset)
        .toList();

    // Remove media for assets that no longer exist
    _media.removeWhere(
      (media) => !currentAssets.contains(media.processedAsset.asset),
    );

    widget.onProcessedAssetsChanged(_media);

    // Find new assets that need to be processed
    final newAssets = currentAssets
        .where((asset) => !existingAssets.contains(asset))
        .toList();

    if (newAssets.isNotEmpty) {
      await _loadNewAssets(newAssets);
    } else {
      setState(() {});
    }
  }

  Future<void> _loadMedia() async {
    _media.clear();
    await _loadNewAssets(widget.assets);
  }

  Future<void> _loadNewAssets(List<AssetEntity> assets) async {
    try {
      final thumbnails = assets.map((asset) {
        final singleModeThumbnail = _loadThumbnail(
          asset,
          MediaDisplayMode.single,
          widget.singleMediaMaxWidth,
          widget.singleMediaMaxHeight,
        );
        final multipleModeThumbnail = _loadThumbnail(
          asset,
          MediaDisplayMode.multiple,
          widget.multiMediaMaxWidth,
          widget.multiMediaHeight,
        );
        return Future.wait([singleModeThumbnail, multipleModeThumbnail]);
      });
      final results = await Future.wait(thumbnails);

      for (final result in results) {
        _media.add(
          MultiModeProcessedAsset(
            processedAsset: result[0],
            singleModeThumbnail: result[0].displayBytes,
            multipleModeThumbnail: result[1].displayBytes,
            singleModeTargetWidth: result[0].targetWidth,
            multipleModeTargetWidth: result[1].targetWidth,
            singleModeTargetHeight: result[0].targetHeight,
            multipleModeTargetHeight: result[1].targetHeight,
          ),
        );
      }

      widget.onProcessedAssetsChanged(_media);

      setState(() {});
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'DynamicMediaDisplay',
          context: ErrorDescription('Error loading media for $assets'),
        ),
      );
    }
  }

  Future<ProcessedAsset> _loadThumbnail(
    AssetEntity asset,
    MediaDisplayMode mode,
    double maxWidth,
    double height,
  ) async {
    final devicePixelRatio = context.devicePixelRatio;
    ProcessedAsset? data;

    if (mode == MediaDisplayMode.single) {
      data = await NativeImageProcessor.processSingleModeImage(
        asset,
        maxWidth: maxWidth,
        devicePixelRatio: devicePixelRatio,
      );
    } else {
      data = await NativeImageProcessor.processMultipleModeImage(
        asset,
        height: height,
        maxWidth: maxWidth,
        devicePixelRatio: devicePixelRatio,
      );
    }

    if (data == null) {
      Error.throwWithStackTrace(
        Exception('Failed to process image for ${asset.id} mode: $mode'),
        StackTrace.current,
      );
    }

    log(
      '_MediaThumbnail: Successfully processed image with native code '
      'for ${asset.id} mode: $mode '
      'size: ${data.displayBytes.length} bytes, '
      'targetWidth: ${data.targetWidth}, targetHeight: ${data.targetHeight}',
    );

    log(
      '_MediaThumbnail: original file size: '
      '${(await data.asset.file)?.readAsBytesSync().length} bytes',
    );

    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_media.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSingle = _media.length == 1;

    return isSingle
        ? _buildSingleMedia(context, _media.first, 0)
        : _buildMultipleMedia(context, _media);
  }

  Widget _buildSingleMedia(
    BuildContext context,
    MultiModeProcessedAsset data,
    int index,
  ) {
    final devicePixelRatio = context.devicePixelRatio;
    final maxHeight = (widget.singleMediaMaxHeight * devicePixelRatio).clamp(
      200.0,
      500.0,
    );

    final maxWidth =
        (widget.singleMediaMaxWidth * devicePixelRatio).clamp(158.0, 368.0) -
        AppSpacing.lg;

    log('Target width: ${data.singleModeTargetWidth}');
    log('Target height: ${data.singleModeTargetHeight}');

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.lg),
      constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
      child: _MediaThumbnail(
        asset: data.processedAsset.asset,
        thumbnail: data.singleModeThumbnail,
        index: index,
        onRemove: widget.onAssetRemoved,
        onTap: widget.onAssetTapped,
      ),
    );
  }

  Widget _buildMultipleMedia(
    BuildContext context,
    List<MultiModeProcessedAsset> data,
  ) => SizedBox(
    height: widget.multiMediaHeight,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: data.length,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemBuilder: (context, index) {
        final mediaData = data[index];
        return Padding(
          padding: EdgeInsets.only(
            right: index < data.length - 1 ? AppSpacing.lg : 0,
          ),
          child: _MediaThumbnail(
            asset: mediaData.processedAsset.asset,
            thumbnail: mediaData.multipleModeThumbnail,
            index: index,
            height: widget.multiMediaHeight,
            onRemove: widget.onAssetRemoved,
            onTap: widget.onAssetTapped,
          ),
        );
      },
    ),
  );
}

enum MediaDisplayMode { single, multiple }

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.asset,
    required this.index,
    required this.onRemove,
    required this.onTap,
    required this.thumbnail,
    this.height,
  });

  final AssetEntity asset;
  final int index;
  final Uint8List thumbnail;
  final double? height;
  final void Function(AssetEntity asset, int index) onRemove;
  final void Function(AssetEntity asset, int index) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final borderColor = colorScheme.surfaceContainerHighest;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return GestureDetector(
      onTap: () => onTap(asset, index),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(height: height, child: Image.memory(thumbnail)),
          ),
          _RemoveButton(onRemove: () => onRemove(asset, index)),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onRemove});

  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final buttonColor = colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.6,
    );

    return Positioned(
      top: AppSpacing.xs,
      right: AppSpacing.xs,
      child: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close, size: 16),
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: buttonColor,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}
