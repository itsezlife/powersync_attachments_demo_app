import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';

/// {@template show_snackbar_extension}
/// Extension for showing snackbars.
/// {@endtemplate}
extension ShowSnackbarExtension on BuildContext {
  /// Shows a snackbar as a response to an occured error.
  void showErrorSnackBar({
    Object? error,
    SnackBarAction? action,
    Widget? content,
    TextStyle? textStyle,
    SnackBarLength length = SnackBarLength.long,
  }) {
    HapticFeedback.mediumImpact();
    showSnackBar(
      message: error?.toString(),
      length: length,
      action: action,
      content: content,
      textStyle: textStyle,
    );
  }

  /// Shows a snackbar with a message.
  void showSnackBar({
    Key? key,
    String? message,
    SnackBar? customSnackBar,
    Widget? content,
    TextStyle? textStyle,
    SnackBarAction? action,
    SnackBarLength length = SnackBarLength.short,
    Duration? duration,
    EdgeInsets? padding,
  }) {
    final theme = this.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
    //   Fluttertoast.cancel();
    //   Fluttertoast.showToast(
    //     msg: message ?? '',
    //     backgroundColor: theme.colorScheme.surfaceContainerHighest,
    //     textColor: theme.colorScheme.onSurfaceVariant,
    //     timeInSecForIosWeb: length.seconds,
    //     gravity: ToastGravity.BOTTOM,
    //   );
    // } else {
    final snackBar =
        customSnackBar ??
        SnackBar(
          key: key,
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          padding: padding,
          content: DefaultTextStyle(
            style:
                textStyle ??
                textTheme.bodyMedium!.apply(
                  color: colorScheme.onInverseSurface,
                ),
            child:
                content ??
                Text(
                  message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
          duration: duration ?? Duration(seconds: length.seconds),
          action: action,
        );
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(snackBar);
    // }
  }

  /// Shows a snackbar with a message and an action.
  void showSnackBarWithAction({
    required String title,
    required String actionLabel,
    required VoidCallback callback,
    TextStyle? actionTextStyle,
    String? subtitle,
    Duration? duration,
    EdgeInsets? padding,
    SnackBarLength length = SnackBarLength.long,
  }) {
    final theme = this.theme;
    final textTheme = theme.textTheme;
    final bodyMedium = textTheme.bodyMedium;
    final bodySmall = textTheme.bodySmall;
    final colorScheme = theme.colorScheme;

    showSnackBar(
      padding: padding ?? EdgeInsets.zero,
      duration: duration,
      length: length,
      content: ListTile(
        contentPadding: const EdgeInsets.only(
          left: AppSpacing.lg,
        ),
        visualDensity: VisualDensity.compact,
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        titleTextStyle: bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        subtitleTextStyle: bodySmall?.copyWith(
          color: colorScheme.onInverseSurface.withValues(alpha: 0.8),
        ),
        trailing: TextButton(
          style: FilledButton.styleFrom(
            overlayColor: colorScheme.onInverseSurface.withValues(alpha: 0.1),
            foregroundColor: colorScheme.onInverseSurface,
          ),
          onPressed: () {
            callback();
            ScaffoldMessenger.of(this).hideCurrentSnackBar(
              reason: SnackBarClosedReason.action,
            );
          },
          child: Text(
            actionLabel.toUpperCase(),
            style:
                actionTextStyle ??
                const TextStyle(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

/// {@template snack_bar_length}
/// The duration of the snackbar in seconds.
/// {@endtemplate}
enum SnackBarLength {
  /// The snackbar will be shown for 3 second.
  short(3),

  /// The snackbar will be shown for 5 seconds.
  long(5);

  /// {@macro snack_bar_length}
  const SnackBarLength(this.seconds);

  /// The duration of the snackbar in seconds.
  final int seconds;
}
