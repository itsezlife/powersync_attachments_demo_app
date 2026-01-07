import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// {@template skeletonizer_container_theme_override}
/// This is useful when you want to use the app theme for the container
/// of [Skeletonizer] and not the default theme.
/// {@endtemplate}
class SkeletonizerContainerThemeOverride extends StatelessWidget {
  /// {@macro skeletonizer_container_theme_override}
  const SkeletonizerContainerThemeOverride({
    required this.child,
    this.containersColor,
    super.key,
  });

  /// The child widget to be wrapped.
  final Widget child;

  /// The color of the containers.
  final Color? containersColor;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    return Theme(
      data: theme.copyWith(
        extensions: [
          ...theme.extensions.values,
          SkeletonizerConfigData(
            effect: ShimmerEffect(
              baseColor: colorScheme.surfaceContainerHighest,
              highlightColor: colorScheme.surfaceContainerHigh,
            ),
            containersColor: containersColor,
          ),
        ],
      ),
      child: child,
    );
  }
}
