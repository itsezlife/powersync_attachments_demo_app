import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/sign_up.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_constrained_scroll_view.dart';
import 'package:powersync_attachments_example/src/common/widgets/gap.dart';
import 'package:powersync_attachments_example/src/common/widgets/scaffold_padding.dart';
import 'package:user_repository/user_repository.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => SignUpCubit(userRepository: context.read<UserRepository>()),
    child: const SignUpView(),
  );
}

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();

  // Uint8List? _imageBytes;
  File? _avatarFile;

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaffoldPadding.widget(
    context,
    horizontalPadding: AppSpacing.xlg,
    child: AppConstrainedScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          const Gap.v(AppSpacing.xxxlg + AppSpacing.xlg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Align(
                //   child: AvatarImagePicker(
                //     imageBytes: _imageBytes,
                //     onUpload: (imageBytes, file) {
                //       setState(() {
                //         _imageBytes = imageBytes;
                //         _avatarFile = file;
                //       });
                //     },
                //   ),
                // ),
                gapH12,
                Form(key: _formKey, child: const SignUpForm()),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xlg),
                  child: Align(
                    child: SignUpButton(
                      onPressed: () {
                        final isValid = _formKey.currentState?.validate();
                        if (!(isValid ?? false)) return;
                        context.read<SignUpCubit>().onSubmit(
                          avatarFile: _avatarFile,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SignInIntoAccountButton(),
        ],
      ),
    ),
  );
}
