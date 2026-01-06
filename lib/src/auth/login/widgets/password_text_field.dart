import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/auth/login/login.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class PasswordTextField extends StatefulWidget {
  const PasswordTextField({super.key});

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField>
    with BaseAuthTextFieldMixin {
  late ValueNotifier<bool> _showPassword;

  @override
  void initState() {
    super.initState();
    _showPassword = ValueNotifier(false);
  }

  @override
  void onTextChanged(String value) {
    context.read<LoginCubit>().onPasswordChanged(value);
  }

  @override
  void dispose() {
    _showPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: _showPassword,
    builder: (context, showPassword, child) => TextFormField(
      controller: controller,
      obscureText: !showPassword,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) {
        TextInput.finishAutofillContext();
        context.read<LoginCubit>().onSubmit();
      },
      autovalidateMode: AutovalidateMode.onUnfocus,
      validator: (value) => Password.dirty(value ?? '').errorMessage,
      decoration: InputDecoration(
        filled: true,
        hintText: context.l10n.passwordHint,
        labelText: context.l10n.passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(!showPassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => _showPassword.value = !_showPassword.value,
        ),
        suffixIconConstraints: const BoxConstraints(),
      ),
    ),
  );
}
