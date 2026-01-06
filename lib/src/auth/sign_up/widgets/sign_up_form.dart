import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/sign_up.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

/// {@template sign_up_form}
/// Sign up form that contains email and password fields.
/// {@endtemplate}
class SignUpForm extends StatelessWidget {
  /// {@macro sign_up_form}
  const SignUpForm({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return BlocListener<SignUpCubit, SignUpState>(
      listener: (context, state) {
        if (state.submissionStatus.isError) {
          final message = signUpSubmissionStatusMessage(
            l10n,
            state.submissionStatus,
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
      child: const AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: [
            EmailTextField(),
            FirstNameTextField(),
            LastNameTextField(),
            PasswordTextField(),
          ],
        ),
      ),
    );
  }
}
