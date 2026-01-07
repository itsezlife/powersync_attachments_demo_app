import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/login/login.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({required this.onPressed, super.key, this.avatarFile});

  final File? avatarFile;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<LoginCubit, bool>(
      (bloc) => bloc.state.status.isLoading,
    );
    final isDisabled =
        context.select<LoginCubit, bool>(
          (bloc) =>
              bloc.state.status.isLoading ||
              bloc.state.status.isGoogleAuthInProgress,
        ) ||
        isLoading;
    return FilledButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: isLoading
          ? Transform.scale(scale: .6, child: const CircularProgressIndicator())
          : const Icon(Icons.login),
      label: Text(
        isLoading
            ? context.l10n.signInWithEmailButtonLabel
            : context.l10n.signInWithEmailButtonLabel,
      ),
    );
  }
}
