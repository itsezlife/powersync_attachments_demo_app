// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:shared/shared.dart';

/// The signature for the callback that uses the [BuildContext].
typedef BuildContextCallback = void Function(BuildContext context);

/// The signature for the callback that closes the dialog.
typedef CloseDialogCallback = void Function();

/// The result of the confirmation dialog.
enum ConfirmationDialogResult {
  /// The dialog was canceled by the user.
  canceled,

  /// The dialog was confirmed by the user.
  confirmed,

  /// The dialog was dismissed by the user.
  dismissed;

  /// Whether the dialog was confirmed by the user.
  bool get isConfirmed => this == confirmed;

  /// Whether the dialog was dismissed by the user.
  bool get isDismissed => this == dismissed;

  /// Whether the dialog was canceled by the user.
  bool get isCanceledOrDismissed => this == canceled || this == dismissed;
}

/// {@template i_text_processor}
/// The interface for processing text.
/// {@endtemplate}
abstract interface class ITextProcessor {
  /// {@macro i_text_processor}
  const ITextProcessor();

  /// Processes the text.
  String process(String text);
}

/// {@template text_processor}
/// The interface for processing text.
/// {@endtemplate}
class TextProcessor extends ITextProcessor {
  /// {@macro text_processor}
  const TextProcessor();

  @override
  String process(String text) => text;
}

/// {@template uppercase_text_processor}
/// The implementation of the [ITextProcessor] that converts the text to
/// uppercase.
/// {@endtemplate}
class UppercaseTextProcessor extends ITextProcessor {
  /// {@macro uppercase_text_processor}
  const UppercaseTextProcessor();

  @override
  String process(String text) => text.toUpperCase();
}

/// {@template show_dialog_extension}
/// Dialog extension that shows dialog with optional `title`,
/// `content` and `actions`.
/// {@endtemplate}
extension DialogExtension on BuildContext {
  /// Shows a loading dialog with the provided `text`.
  ///
  /// * The dialog will automatically close after 10 seconds if not closed
  /// manually.
  CloseDialogCallback showLoadingDialog({
    required String text,
    bool isDismissible = false,
    Duration? autoCloseDuration,
  }) {
    final dialog = AlertDialog.adaptive(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator.adaptive(),
          gapH8,
          Text(text),
        ],
      ),
    );

    showAdaptiveDialog<void>(
      barrierDismissible: isDismissible,
      builder: (_) => dialog,
    );

    if (isDismissible) return () => Navigator.pop(this);
    if (autoCloseDuration == null) return () => Navigator.pop(this);

    final timer = Timer(autoCloseDuration, () {
      if (mounted) {
        Navigator.pop(this);
      }
    });

    return () {
      timer.cancel();
      Navigator.pop(this);
    };
  }

  /// Shows a general loading dialog.
  ///
  /// * The dialog will automatically close after 10 seconds if not closed
  /// manually.
  CloseDialogCallback showGeneralLoadingDialog({
    bool isDismissible = false,
    Duration? autoCloseDuration,
  }) {
    showGeneralDialog(
      context: this,
      useRootNavigator: false,
      barrierLabel: '',
      barrierDismissible: isDismissible,
      transitionBuilder: (_, anim, _, child) {
        Tween<double> tween;
        if (anim.status == AnimationStatus.reverse) {
          tween = Tween(begin: 0.9, end: 1);
        } else {
          tween = Tween(begin: 0.95, end: 1);
        }
        return ScaleTransition(
          scale: tween.animate(
            CurvedAnimation(parent: anim, curve: Curves.easeInOutQuart),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (_, _, _) => WillPopScope(
        onWillPop: () async => isDismissible,
        child: Center(
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            margin: EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.md,
              top: MediaQuery.paddingOf(this).top,
              bottom: MediaQuery.paddingOf(this).bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadiusDirectional.circular(25),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      ),
    );

    if (isDismissible) return () => Navigator.pop(this);
    if (autoCloseDuration == null) return () => Navigator.pop(this);

    final timer = Timer(autoCloseDuration, () {
      if (mounted) {
        Navigator.pop(this);
      }
    });

    return () {
      timer.cancel();
      Navigator.pop(this);
    };
  }

  /// Shows the bottom sheet with the confirmation of the `action`.
  Future<bool?> showConfirmationBottomSheet({
    required String title,
    required String okText,
    Widget? icon,
    String? question,
    String? cancelText,
  }) => showModalBottomSheet(
    context: this,
    builder: (sheetContext) {
      final theme = sheetContext.theme;
      final textTheme = theme.textTheme;
      final colorScheme = theme.colorScheme;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          gapH24,
          ?icon,
          gapH24,
          Text(
            title,
            style: textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          gapH8,
          if (question != null) Text(question, textAlign: TextAlign.center),
          gapH32,
          const Divider(),
          Row(
            children: [
              if (cancelText != null)
                Flexible(
                  child: Container(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(this, false);
                      },
                      child: Text(
                        cancelText,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => Navigator.pop(this, true),
                    child: Text(
                      okText,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  /// Shows adaptive dialog with provided `title`, `content` and `actions`
  /// (if provided). If `barrierDismissible` is `true` (default), dialog can't
  /// be dismissed by tapping outside of the dialog.
  Future<T?> showAdaptiveDialog<T>({
    String? content,
    String? title,
    List<Widget> Function(BuildContext dialogContext)? actions,
    bool barrierDismissible = true,
    Widget Function(BuildContext context)? builder,
    TextStyle? titleTextStyle,
    bool fullscreenDialog = false,
  }) {
    assert(
      actions != null || builder != null,
      'Either actions or builder must be provided',
    );
    assert(
      title != null || builder != null,
      'Either title or builder must be provided',
    );
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      fullscreenDialog: fullscreenDialog,
      builder:
          builder ??
          (context) {
            final actionWidgets = actions?.call(context) ?? [];
            if (debugReversePlatform) {
              return Config.isMaterial
                  ? AlertDialog(
                      actionsAlignment: MainAxisAlignment.end,
                      title: Text(title!),
                      titleTextStyle: titleTextStyle,
                      content: content == null ? null : Text(content),
                      actions: actionWidgets,
                    )
                  : CupertinoAlertDialog(
                      title: Text(title!),
                      content: content == null ? null : Text(content),
                      actions: actionWidgets,
                    );
            }
            return AlertDialog.adaptive(
              actionsAlignment: MainAxisAlignment.end,
              title: Text(title!),
              titleTextStyle: titleTextStyle,
              content: content == null ? null : Text(content),
              actions: actionWidgets,
            );
          },
    );
  }

  /// Shows bottom modal.
  Future<T?> showBottomModal<T>({
    Widget Function(BuildContext context)? builder,
    String? title,
    Color? titleColor,
    WidgetBuilder? content,
    Color? backgroundColor,
    Color? barrierColor,
    ShapeBorder? shape,
    bool isDismissible = true,
    bool isScrollControlled = false,
    bool enableDrag = true,
    bool useSafeArea = true,
    bool showDragHandle = true,
  }) => showModalBottomSheet<T>(
    context: this,
    shape: shape,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    useRootNavigator: true,
    builder:
        builder ??
        (sheetContext) {
          final theme = sheetContext.theme;
          final textTheme = theme.textTheme;

          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(color: titleColor),
                    ),
                  ),
                  const Divider(),
                ],
                if (content != null) content.call(sheetContext),
              ],
            ),
          );
        },
  );

  /// Opens the modal bottom sheet for a comments page builder.
  Future<void> showScrollableModal({
    required Widget Function(
      BuildContext context,
      ScrollController scrollController,
      DraggableScrollableController draggableScrollController,
    )
    pageBuilder,
    MaterialConfiguration materialConfiguration = const MaterialConfiguration(),
    bool showFullSized = false,
    Color? backgroundColor,
  }) => showBottomModal<void>(
    isScrollControlled: true,
    backgroundColor: backgroundColor,
    builder: (context) {
      final controller =
          materialConfiguration.controller ?? DraggableScrollableController();
      final config = materialConfiguration;

      return DraggableScrollableSheet(
        controller: controller,
        expand: config.expand,
        snap: config.snap,
        snapSizes: !config.snap ? null : config.snapSizes,
        initialChildSize: showFullSized
            ? config.maxChildSize
            : config.initialChildSize,
        minChildSize: config.minChildSize,
        maxChildSize: config.maxChildSize,
        shouldCloseOnMinExtent: config.shouldCloseOnMinExtent,
        builder: (context, scrollController) =>
            pageBuilder.call(context, scrollController, controller),
      );
    },
  );

  /// Shows the confirmation dialog and upon confirmation executes provided
  /// [onConfirmed].
  Future<void> confirmAction({
    required VoidCallback onConfirmed,
    required String title,
    List<DialogButtonType> buttons = const [
      DialogButtonType.cancel,
      DialogButtonType.confirm,
    ],
    Map<DialogButtonType, DialogButtonConfig>? configs,
    String? content,
    bool barrierDismissible = true,
  }) async {
    final result = await showConfirmationDialog(
      title: title,
      content: content,
      buttons: buttons,
      configs: configs,
      barrierDismissible: barrierDismissible,
    );
    if (result.isCanceledOrDismissed) {
      return;
    }
    onConfirmed.call();
  }

  /// Shows a dialog that alerts user that they are about to do distractive
  /// action.
  Future<ConfirmationDialogResult> showConfirmationDialog({
    required String title,
    List<DialogButtonType> buttons = const [
      DialogButtonType.cancel,
      DialogButtonType.confirm,
    ],
    ITextProcessor? actionTextProcessor,
    Map<DialogButtonType, DialogButtonConfig>? configs,
    String? content,
    bool barrierDismissible = true,
  }) async {
    final ITextProcessor textProcessor;
    if (actionTextProcessor == null) {
      textProcessor = Config.isMaterial
          ? const UppercaseTextProcessor()
          : const TextProcessor();
    } else {
      textProcessor = actionTextProcessor;
    }

    final l10n = MaterialLocalizations.of(this);
    configs ??= {
      DialogButtonType.cancel: DialogButtonConfig.cancel(
        text: l10n.cancelButtonLabel,
      ),
      DialogButtonType.confirm: DialogButtonConfig.confirm(
        text: l10n.okButtonLabel,
      ),
    };

    for (final button in buttons) {
      if (configs[button] == null) {
        configs[button] = switch (button) {
          DialogButtonType.confirm => DialogButtonConfig.confirm(
            text: l10n.okButtonLabel,
          ),
          DialogButtonType.cancel => DialogButtonConfig.cancel(
            text: l10n.cancelButtonLabel,
          ),
        };
      }
    }

    // Assert that no config can be both default and destructive
    for (final config in configs.values) {
      if (config.text == null) {
        configs[config.type] = switch (config.type) {
          DialogButtonType.confirm => config.copyWith(text: l10n.okButtonLabel),
          DialogButtonType.cancel => config.copyWith(
            text: l10n.cancelButtonLabel,
          ),
        };
      }
    }

    // Assert that at most one config can be default
    final defaultConfigs = configs.values.where(
      (config) => config.isDefaultAction,
    );
    assert(
      defaultConfigs.length <= 1,
      'Only one dialog button can be marked as default',
    );

    // Assert that at most one config can be destructive
    final destructiveConfigs = configs.values.where(
      (config) => config.isDestructiveAction,
    );
    assert(
      destructiveConfigs.length <= 1,
      'Only one dialog button can be marked as destructive',
    );

    final theme = this.theme;
    final textTheme = theme.textTheme;

    final result = await showAdaptiveDialog<ConfirmationDialogResult>(
      title: title,
      content: content,
      barrierDismissible: barrierDismissible,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      actions: (dialogContext) => buttons.map((button) {
        final config = configs![button]!;
        return DialogButton(
          isDefaultAction: config.isDefaultAction,
          isDestructiveAction: config.isDestructiveAction,
          onPressed: () => config.onPressed != null
              ? config.onPressed!(dialogContext)
              : Navigator.maybePop(dialogContext, config.result),
          text: textProcessor.process(config.text!),
          textStyle: config.textStyle,
        );
      }).toList(),
    );
    return result ?? ConfirmationDialogResult.dismissed;
  }

  /// Opens a dialog where shows a preview of an image in a circular avatar.
  Future<void> showImagePreview(String imageUrl) => showDialog<void>(
    context: this,
    builder: (sheetContext) => Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: 3,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            image: DecorationImage(
              image: NetworkImage(imageUrl),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    ),
  );

  /// Show modal action sheet, whose appearance is adaptive according to
  /// platform.
  ///
  /// The [isDismissible] parameter only works for material style and it
  /// specifies whether the bottom sheet will be dismissed when user taps on
  /// the scrim.
  @useResult
  Future<T?> showModalActionSheet<T>({
    String? title,
    String? message,
    List<SheetAction<T>> actions = const [],
    String? cancelText,
    bool isDismissible = true,
    bool useRootNavigator = true,
    MaterialConfiguration? materialConfiguration,
    bool canPop = true,
    PopInvokedWithResultCallback<T>? onPopInvokedWithResult,
    Widget Function(BuildContext context, Widget sheet)? builder,
    RouteSettings? routeSettings,
    bool showDragHandle = true,
  }) => Config.isMaterial
      ? showModalBottomSheet<T>(
          context: this,
          isScrollControlled: materialConfiguration != null,
          isDismissible: isDismissible,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          showDragHandle: showDragHandle,
          builder: (context) {
            final sheet = MaterialModalActionSheet<T>(
              onPressed: (key) => Navigator.maybePop(context, key),
              title: title,
              message: message,
              actions: actions,
              materialConfiguration: materialConfiguration,
              canPop: canPop,
              onPopInvokedWithResult: onPopInvokedWithResult,
            );
            return builder == null ? sheet : builder(context, sheet);
          },
        )
      : showCupertinoModalPopup<T>(
          context: this,
          useRootNavigator: useRootNavigator,
          routeSettings: routeSettings,
          builder: (context) {
            final sheet = CupertinoModalActionSheet<T>(
              onPressed: (key) => Navigator.maybePop(context, key),
              title: title,
              message: message,
              actions: actions,
              cancelText: cancelText,
              canPop: canPop,
              onPopInvokedWithResult: onPopInvokedWithResult,
            );
            return builder == null ? sheet : builder(context, sheet);
          },
        );
}

/// The type of the button.
enum DialogButtonType {
  /// The cancel button.
  cancel,

  /// The confirm button.
  confirm,
}

/// The configuration of the dialog button.
class DialogButtonConfig {
  /// {@macro dialog_button_config}
  const DialogButtonConfig.raw({
    required this.type,
    required this.isDefaultAction,
    required this.isDestructiveAction,
    this.buttonStyle,
    this.text,
    this.textStyle,
    this.onPressed,
  });

  /// {@macro dialog_button_config}
  const DialogButtonConfig.cancel({
    this.text,
    this.textStyle,
    this.buttonStyle,
    this.onPressed,
    bool? isDefaultAction,
    bool? isDestructiveAction,
  }) : type = DialogButtonType.cancel,
       isDefaultAction = isDefaultAction ?? false,
       isDestructiveAction = isDestructiveAction ?? false;

  /// {@macro dialog_button_config}
  const DialogButtonConfig.confirm({
    this.text,
    this.textStyle,
    this.buttonStyle,
    this.onPressed,
    bool? isDefaultAction,
    bool? isDestructiveAction,
  }) : type = DialogButtonType.confirm,
       isDefaultAction = isDefaultAction ?? true,
       isDestructiveAction = isDestructiveAction ?? false;

  /// The type of the button.
  final DialogButtonType type;

  /// The text of the button.
  final String? text;

  /// The style of the button.
  final TextStyle? textStyle;

  /// The style of the button.
  final ButtonStyle? buttonStyle;

  /// The function to be called when the button is pressed.
  final BuildContextCallback? onPressed;

  /// Whether the button is the default action.
  final bool isDefaultAction;

  /// Whether the button is the destructive action.
  final bool isDestructiveAction;

  /// The result of the button press.
  ConfirmationDialogResult get result => switch (type) {
    DialogButtonType.confirm => ConfirmationDialogResult.confirmed,
    DialogButtonType.cancel => ConfirmationDialogResult.canceled,
  };

  /// Copies the button config with the new values.
  DialogButtonConfig copyWith({
    DialogButtonType? type,
    String? text,
    ButtonStyle? buttonStyle,
    TextStyle? textStyle,
    BuildContextCallback? onPressed,
    bool? isDefaultAction,
    bool? isDestructiveAction,
  }) => DialogButtonConfig.raw(
    type: type ?? this.type,
    text: text ?? this.text,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    textStyle: textStyle ?? this.textStyle,
    onPressed: onPressed ?? this.onPressed,
    isDefaultAction: isDefaultAction ?? this.isDefaultAction,
    isDestructiveAction: isDestructiveAction ?? this.isDestructiveAction,
  );
}

/// {@template dialog_button}
/// A custom dialog button widget.
/// {@endtemplate}
class DialogButton extends StatelessWidget {
  /// {@macro dialog_button}
  const DialogButton({
    required this.text,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
    super.key,
    this.onPressed,
    this.style,
    this.textStyle,
  });

  /// Function to be called when the button is pressed.
  final void Function()? onPressed;

  /// The text to be displayed on the button.
  final String text;

  /// The style of the button.
  final ButtonStyle? style;

  /// The style of the text on the button.
  final TextStyle? textStyle;

  /// The flag to indicate if the button is the default action in a dialog.
  final bool isDefaultAction;

  /// The flag to indicate if the button is the destructive action in a dialog.
  final bool isDestructiveAction;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;

    if (Config.isCupertino) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDefaultAction: isDefaultAction,
        isDestructiveAction: isDestructiveAction,
        textStyle: textStyle,
        child: Text(text, style: textStyle),
      );
    }
    if (isDefaultAction) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isDestructiveAction
              ? colorScheme.error
              : colorScheme.primary,
          foregroundColor: isDestructiveAction
              ? colorScheme.onError
              : colorScheme.onPrimary,
        ),
        child: Text(text),
      );
    }
    return TextButton(
      style: (style ?? const ButtonStyle()).copyWith(
        overlayColor: WidgetStateProperty.all(
          isDestructiveAction
              ? colorScheme.error.withValues(alpha: 0.1)
              : colorScheme.onSurface.withValues(alpha: 0.1),
        ),
        foregroundColor: WidgetStateProperty.all(
          isDestructiveAction ? colorScheme.error : null,
        ),
        textStyle: WidgetStateProperty.all(textStyle),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

/// {@template sheet_action}
/// The action to be displayed in the sheet.
/// {@endtemplate}
class SheetAction<T> {
  /// {@macro sheet_action}
  const SheetAction({
    required this.label,
    this.textStyle,
    this.key,
    this.content,
    this.widgetBuilder,
    this.icon,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  /// Used for checking selection result
  final T? key;

  /// The label of the action.
  final String label;

  /// The widget to be displayed in the action.
  final Widget Function(BuildContext context, SheetAction<T> action)?
  widgetBuilder;

  /// The widget to be displayed in the action.
  final Widget? content;

  /// Only works for Material Style
  final Widget? icon;

  /// Whether the action is the default action.
  final bool isDefaultAction;

  /// Whether the action is destructive.
  final bool isDestructiveAction;

  /// The text style of the action.
  final TextStyle? textStyle;
}

/// {@template cupertino_modal_action_sheet}
/// A cupertino modal action sheet.
/// {@endtemplate}
class CupertinoModalActionSheet<T> extends StatelessWidget {
  /// {@macro cupertino_modal_action_sheet}
  const CupertinoModalActionSheet({
    required this.onPressed,
    required this.actions,
    required this.canPop,
    required this.onPopInvokedWithResult,
    super.key,
    this.title,
    this.message,
    this.cancelText,
  });

  /// The function to be called when an action is pressed.
  final void Function(T? key) onPressed;

  /// The list of actions to be displayed in the sheet.
  final List<SheetAction<T>> actions;

  /// The title of the sheet.
  final String? title;

  /// The message of the sheet.
  final String? message;

  /// The text of the cancel button.
  final String? cancelText;

  /// Whether the sheet can be popped.
  final bool canPop;

  /// The function to be called when the sheet is popped.
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  @override
  Widget build(BuildContext context) {
    final title = this.title;
    final message = this.message;

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        child: CupertinoActionSheet(
          title: title == null ? null : Text(title),
          message: message == null ? null : Text(message),
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: !actions.any((a) => a.isDefaultAction),
            onPressed: () => onPressed(null),
            child: Text(
              cancelText ??
                  MaterialLocalizations.of(
                    context,
                  ).cancelButtonLabel.capitalizedForce,
              style: TextStyle(color: context.theme.colorScheme.onSurface),
            ),
          ),
          actions: actions.map((a) {
            if (a.widgetBuilder != null) {
              return a.widgetBuilder!(context, a);
            }

            return CupertinoActionSheetAction(
              isDestructiveAction: a.isDestructiveAction,
              isDefaultAction: a.isDefaultAction,
              onPressed: () => onPressed(a.key),
              child:
                  a.content ??
                  Text(
                    a.label,
                    style:
                        a.textStyle ??
                        TextStyle(
                          color: a.isDestructiveAction
                              ? context.theme.colorScheme.error
                              : context.theme.colorScheme.onSurface,
                        ),
                  ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// {@template material_modal_action_sheet}
/// A material modal action sheet.
/// {@endtemplate}
class MaterialModalActionSheet<T> extends StatelessWidget {
  /// {@macro material_modal_action_sheet}
  const MaterialModalActionSheet({
    required this.onPressed,
    required this.actions,
    required this.canPop,
    required this.onPopInvokedWithResult,
    super.key,
    this.title,
    this.message,
    this.materialConfiguration,
  });

  /// The function to be called when an action is pressed.
  final void Function(T? key) onPressed;

  /// The list of actions to be displayed in the sheet.
  final List<SheetAction<T>> actions;

  /// The title of the sheet.
  final String? title;

  /// The message of the sheet.
  final String? message;

  /// The configuration of the sheet.
  final MaterialConfiguration? materialConfiguration;

  /// Whether the sheet can be popped.
  final bool canPop;

  /// The function to be called when the sheet is popped.
  final PopInvokedWithResultCallback<T>? onPopInvokedWithResult;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final title = this.title;
    final message = this.message;
    final materialConfiguration = this.materialConfiguration;

    final header = () {
      if (title != null && message != null) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          titleTextStyle: theme.textTheme.titleLarge,
          subtitleTextStyle: theme.textTheme.bodyMedium,
          title: Text(title),
          subtitle: Text(message),
        );
      }
      return null;
    }();

    final children = [
      for (final a in actions)
        () {
          final icon = a.icon;
          final textColor = a.isDestructiveAction ? colorScheme.error : null;

          final iconColor = a.isDestructiveAction ? colorScheme.error : null;

          final splashColor = a.isDestructiveAction
              ? colorScheme.error.withValues(alpha: 0.4)
              : null;

          if (a.widgetBuilder != null) {
            return a.widgetBuilder!(context, a);
          }

          return ListTile(
            leading: icon,
            iconColor: iconColor,
            splashColor: splashColor,
            textColor: textColor,
            title: a.content ?? Text(a.label, style: a.textStyle),
            onTap: () => onPressed(a.key),
          );
        }(),
    ];
    final body = materialConfiguration == null
        ? SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [?header, const Divider(), ...children],
            ),
          )
        : DraggableScrollableSheet(
            expand: materialConfiguration.expand,
            controller: materialConfiguration.controller,
            initialChildSize: materialConfiguration.initialChildSize,
            minChildSize: materialConfiguration.minChildSize,
            maxChildSize: materialConfiguration.maxChildSize,
            snap: materialConfiguration.snap,
            snapSizes: materialConfiguration.snapSizes,
            shouldCloseOnMinExtent:
                materialConfiguration.shouldCloseOnMinExtent,
            builder: (context, controller) => SafeArea(
              child: header == null
                  ? SingleChildScrollView(
                      controller: controller,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    )
                  : Material(
                      color: context.theme.bottomSheetTheme.backgroundColor,
                      child: Column(
                        children: [
                          Material(
                            color:
                                context.theme.bottomSheetTheme.backgroundColor,
                            child: header,
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              controller: controller,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: onPopInvokedWithResult,
      child: body,
    );
  }
}

/// {@template material_configuration}
/// The configuration for the material modal action sheet.
/// {@endtemplate}
class MaterialConfiguration {
  /// {@macro material_configuration}
  const MaterialConfiguration({
    this.initialChildSize = .5,
    this.minChildSize = .25,
    this.maxChildSize = .9,
    this.snap = true,
    this.expand = false,
    this.snapSizes,
    this.shouldCloseOnMinExtent = true,
    this.controller,
  });

  /// The initial child size of the sheet.
  final double initialChildSize;

  /// The minimum child size of the sheet.
  final double minChildSize;

  /// The maximum child size of the sheet.
  final double maxChildSize;

  /// Whether the sheet can be snapped.
  final bool snap;

  /// Whether the sheet should expand to the full size of the screen.
  final bool expand;

  /// The snap sizes of the sheet.
  final List<double>? snapSizes;

  /// Whether the sheet should close when the user taps outside of it.
  final bool shouldCloseOnMinExtent;

  /// The controller of the sheet.
  final DraggableScrollableController? controller;

  /// Creates a new [MaterialConfiguration] with the given values.
  MaterialConfiguration copyWith({
    double? initialChildSize,
    double? minChildSize,
    double? maxChildSize,
    bool? snap,
    List<double>? snapSizes,
  }) => MaterialConfiguration(
    initialChildSize: initialChildSize ?? this.initialChildSize,
    minChildSize: minChildSize ?? this.minChildSize,
    maxChildSize: maxChildSize ?? this.maxChildSize,
    snap: snap ?? this.snap,
    snapSizes: snapSizes ?? this.snapSizes,
  );
}
