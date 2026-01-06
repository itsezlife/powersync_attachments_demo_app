import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:styled_text/styled_text.dart';

enum SignUpNewAccountAction {
  changeAuth('CHANGE_AUTH');

  const SignUpNewAccountAction(this.action);

  final String action;
}

/// {@template sign_up_account_button}
/// Sign up widget that contains sign up button.
/// {@endtemplate}
class SignUpNewAccountButton extends StatelessWidget {
  /// {@macro sign_up_account_button}
  const SignUpNewAccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final cubit = context.read<AuthCubit>();

    return StyledText(
      text: context.l10n.signUpNewAccountLabel,
      style: textTheme.labelLarge,
      overflow: TextOverflow.visible,
      textAlign: TextAlign.center,
      tags: {
        'a': StyledTextActionTag(
          (text, attrs) {
            final action = SignUpNewAccountAction.values.firstWhere(
              (e) => e.action == attrs['action'],
            );
            return switch (action) {
              SignUpNewAccountAction.changeAuth => cubit.changeAuth(
                showLogin: false,
              ),
            };
          },
          style: textTheme.labelLarge!.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      },
    );
  }
}
