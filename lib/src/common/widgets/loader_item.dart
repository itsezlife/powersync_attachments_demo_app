import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';

/// {@template loader_item}
/// Renders a widget containing a progress indicator that calls
/// [onPresented] when the item becomes visible, with enhanced visuals.
/// {@endtemplate}
class LoaderItem extends StatefulWidget {
  /// {@macro loader_item}
  const LoaderItem({super.key, this.onPresented, this.description});

  /// A callback performed when the widget is presented.
  final VoidCallback? onPresented;

  /// The description of the loader item.
  final String? description;

  @override
  State<LoaderItem> createState() => _LoaderItemState();
}

class _LoaderItemState extends State<LoaderItem> {
  @override
  void initState() {
    super.initState();
    // Call the callback when the widget is presented
    widget.onPresented?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          if (widget.description != null) ...[
            gapH8,
            Text(
              widget.description!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
