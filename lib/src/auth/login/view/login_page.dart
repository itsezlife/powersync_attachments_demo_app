import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/login/login.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_constrained_scroll_view.dart';
import 'package:powersync_attachments_example/src/common/widgets/gap.dart';
import 'package:powersync_attachments_example/src/common/widgets/scaffold_padding.dart';
import 'package:user_repository/user_repository.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LoginCubit(userRepository: context.read<UserRepository>()),
    child: const LoginView(),
  );
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

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
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap.v(AppSpacing.xxxlg * 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(key: _formKey, child: const LoginForm()),
                gapH24,
                Align(
                  child: SignInButton(
                    onPressed: () {
                      final isValid = _formKey.currentState?.validate();
                      if (!(isValid ?? false)) return;
                      context.read<LoginCubit>().onSubmit();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SignUpNewAccountButton(),
        ],
      ),
    ),
  );
}
