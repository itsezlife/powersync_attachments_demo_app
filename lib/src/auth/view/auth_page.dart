import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/auth/login/login.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/sign_up.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

/// {@template auth_page}
/// Auth page. Shows login or signup page depending on the state of `AuthCubit`.
/// {@endtemplate}
class AuthPage extends StatelessWidget {
  /// {@macro auth_page}
  const AuthPage({super.key, this.showLogin = true});

  final bool showLogin;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AuthCubit(showLogin: showLogin),
    child: const AuthView(),
  );
}

/// {@template auth_view}
/// Auth view. Shows login or signup page depending on the state of [AuthCubit].
/// {@endtemplate}
class AuthView extends StatelessWidget {
  /// {@macro auth_view}
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final showLogin = context.select<AuthCubit, bool>((b) => b.state);
    final l10n = context.l10n;

    return AppScaffold(
      releaseFocus: true,
      appBar: AppBar(
        title: showLogin
            ? Text(l10n.signInButtonLabel)
            : Text(l10n.signUpButtonLabel),
        titleTextStyle: context.theme.textTheme.headlineSmall,
      ),
      body: PageTransitionSwitcher(
        reverse: showLogin,
        transitionBuilder: (child, animation, secondaryAnimation) =>
            SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            ),
        child: showLogin ? const LoginPage() : const SignUpPage(),
      ),
    );
  }
}
