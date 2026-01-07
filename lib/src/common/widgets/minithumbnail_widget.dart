import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared/shared.dart';

/// {@template minithumbnail_widget}
/// Widget for displaying a minithumbnail.
/// {@endtemplate}
class MinithumbnailWidget extends StatelessWidget {
  /// {@macro minithumbnail_widget}
  const MinithumbnailWidget({
    required this.minithumbnail,
    this.fit = BoxFit.fill,
    super.key,
  });

  /// The minithumbnail data to display.
  final MinithumbnailData minithumbnail;

  /// The fit of the minithumbnail.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 10,
        sigmaY: 10,
        tileMode: TileMode.mirror,
      ),
      child: Image.memory(minithumbnail.data!, gaplessPlayback: true, fit: fit),
    ),
  );
}
