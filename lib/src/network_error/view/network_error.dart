import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:styled_text/styled_text.dart';

enum NetworkErrorViewType {
  /// A page-level error view.
  regular,

  /// An inline error view.
  inline,
}

/// {@template network_error}
/// A network error alert.
/// {@endtemplate}
class NetworkError extends StatelessWidget {
  /// {@macro network_error}
  const NetworkError({
    super.key,
    this.onRetry,
    this.type = NetworkErrorViewType.regular,
  });

  /// {@macro network_error}
  const NetworkError.inline({super.key, this.onRetry})
    : type = NetworkErrorViewType.inline;

  /// The type of error view to display.
  final NetworkErrorViewType type;

  /// An optional callback which is invoked when the retry button is pressed.
  final VoidCallback? onRetry;

  /// Route constructor to display the widget inside [AppScaffold].
  static Widget page({VoidCallback? onRetry}) => AppScaffold(
    appBar: AppBar(),
    body: Center(child: NetworkError(onRetry: onRetry)),
  );

  @override
  Widget build(BuildContext context) => switch (type) {
    NetworkErrorViewType.regular => NetworkErrorView(onRetry: onRetry),
    NetworkErrorViewType.inline => NetworkErrorInlineView(onRetry: onRetry),
  };
}

class NetworkErrorView extends StatelessWidget {
  const NetworkErrorView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
          const Icon(Icons.error_outline, size: 48),
          gapH16,
          Text(
            l10n.networkErrorTitle,
            style: bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          gapH4,
          Text(
            l10n.networkErrorDescription,
            style: bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry case final onRetry?) ...[
            gapH16,
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgainLabel),
            ),
          ],
          gapH24,
        ],
      ),
    );
  }
}

class NetworkErrorInlineView extends StatelessWidget {
  const NetworkErrorInlineView({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final bodyLarge = textTheme.bodyLarge;
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onRetry,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xlg,
          vertical: AppSpacing.lg,
        ),
        child: StyledText(
          text: l10n.genericErrorReloadLabel,
          style: bodyLarge,
          textAlign: TextAlign.center,
          tags: {
            'b': StyledTextTag(
              style: bodyLarge?.copyWith(color: colorScheme.primary),
            ),
          },
        ),
      ),
    );
  }
}

class SectionErrorView extends StatelessWidget {
  const SectionErrorView({
    this.icon,
    this.title,
    this.subtitle,
    this.onRetry,
    super.key,
  });

  final Icon? icon;
  final String? title;
  final Widget? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, gapH8],
            Text(
              title ?? l10n.genericErrorTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            gapH8,
            subtitle ??
                Text(
                  l10n.genericErrorDescription,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            if (onRetry != null) ...[
              gapH12,
              FilledButton(onPressed: onRetry, child: Text(l10n.refreshLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
