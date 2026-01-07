import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/widgets/local_file_image.dart';
import 'package:powersync_attachments_example/src/common/widgets/minithumbnail_widget.dart';
import 'package:shared/shared.dart';

/// {@template cached_network_image_with_minithumbnail}
/// A widget that displays a cached network image with minithumbnail
/// placeholder.
/// Shows the minithumbnail while the full image is being downloaded.
/// {@endtemplate}
class CachedNetworkImageWithMinithumbnail extends StatelessWidget {
  /// {@macro cached_network_image_with_minithumbnail}
  const CachedNetworkImageWithMinithumbnail({
    required this.file,
    required this.minithumbnail,
    this.url,
    this.fit,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.scale = 1.0,
    this.headers,
    this.gaplessPlayback = false,
    this.debug = true,
    super.key,
  });

  /// The URL to fetch the image from
  final String? url;

  /// The local file to cache the image
  final File file;

  /// Optional minithumbnail to show while loading
  final MinithumbnailData? minithumbnail;

  /// How to inscribe the image into the space
  final BoxFit? fit;

  /// Optional width
  final double? width;

  /// Optional height
  final double? height;

  /// Optional cache width
  final int? cacheWidth;

  /// Optional cache height
  final int? cacheHeight;

  /// Scale for the image
  final double scale;

  /// Whether to enable gapless playback
  final bool gaplessPlayback;

  /// Optional HTTP headers
  final Map<String, String>? headers;

  /// Whether to show debug information
  final bool debug;

  @override
  Widget build(BuildContext context) {
    final imageProvider = ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      NetworkToFileImage(
        file: file,
        url: url,
        scale: scale,
        headers: headers,
        debug: debug,
      ),
    );

    return ExtendedImage(
      image: imageProvider,
      fit: fit,
      width: width,
      height: height,
      gaplessPlayback: gaplessPlayback,
      loadStateChanged: (state) => switch (state.extendedImageLoadState) {
        LoadState.completed => state.completedWidget,
        _ => _MinithumbnailWidget(minithumbnail: minithumbnail),
      },
    );
  }
}

class _MinithumbnailWidget extends StatelessWidget {
  const _MinithumbnailWidget({required this.minithumbnail});

  final MinithumbnailData? minithumbnail;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: minithumbnail != null
        ? MinithumbnailWidget(fit: BoxFit.cover, minithumbnail: minithumbnail!)
        : ColoredBox(color: context.theme.colorScheme.surfaceContainerHighest),
  );
}
