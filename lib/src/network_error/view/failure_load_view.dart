import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class FailureLoadView extends StatelessWidget {
  const FailureLoadView({
    this.title,
    this.description,
    super.key,
    this.onRetry,
    this.padding,
    this.iconColor,
  });

  final String? title;
  final String? description;
  final VoidCallback? onRetry;
  final EdgeInsets? padding;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final titleMedium = textTheme.titleMedium;

    return Center(
      child: Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: iconColor),
            gapH4,
            Text(
              title ?? l10n.genericErrorTitle,
              style: titleMedium,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              gapH4,
              Text(
                description!,
                style: textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              gapH16,
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgainLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
