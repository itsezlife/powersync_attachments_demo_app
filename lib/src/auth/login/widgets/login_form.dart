import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/login/login.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

/// {@template login_form}
/// Login form that contains email and password fields.
/// {@endtemplate}
class LoginForm extends StatelessWidget {
  /// {@macro login_form}
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.status.isError) {
          final message = loginSubmissionStatusMessage(
            l10n,
            state.status,
            error: state.error,
          );
          if (message case final message?) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.xs,
                  children: [
                    Text(
                      message.title,
                      style: textTheme.bodyMedium?.apply(
                        color: colorScheme.onInverseSurface,
                      ),
                    ),
                    if (message.description case final description?)
                      Text(
                        description,
                        style: textTheme.bodySmall?.apply(
                          color: colorScheme.onInverseSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                  ],
                ),
              ),
            );
          }
        }
      },
      listenWhen: (p, c) => p.status != c.status,
      child: const AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [EmailTextField(), PasswordTextField()],
        ),
      ),
    );
  }
}
