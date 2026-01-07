import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    this.title,
    this.titleWidget,
    this.icon,
    this.description,
    this.descriptionWidget,
    this.child,
    super.key,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  final Icon? icon;
  final String? title;
  final Widget? titleWidget;
  final String? description;
  final Widget? descriptionWidget;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final bodyLarge = textTheme.bodyLarge;
    final bodyMedium = textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xlg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          gapH24,
          icon ?? const Icon(Icons.search_off_rounded, size: 48),
          gapH16,
          titleWidget ??
              Text(
                title!,
                style: bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
          if (description != null || descriptionWidget != null) ...[
            gapH4,
            descriptionWidget ??
                Text(
                  description!,
                  style: bodyMedium,
                  textAlign: TextAlign.center,
                ),
          ],
          if (child case final child?) ...[gapH16, child],
        ],
      ),
    );
  }
}
