import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/cubit/sign_up_cubit.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class SignUpButton extends StatelessWidget {
  const SignUpButton({required this.onPressed, super.key, this.avatarFile});

  final File? avatarFile;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<SignUpCubit, bool>(
      (bloc) => bloc.state.submissionStatus.isLoading,
    );
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? Transform.scale(scale: .6, child: const CircularProgressIndicator())
          : const Icon(Icons.person_add),
      label: Text(
        isLoading
            ? context.l10n.signUpInProgressLabel
            : context.l10n.signUpButtonLabel,
      ),
    );
  }
}
