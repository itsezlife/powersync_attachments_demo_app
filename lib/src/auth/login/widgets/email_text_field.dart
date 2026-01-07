import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/auth/login/cubit/login_cubit.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class EmailTextField extends StatefulWidget {
  const EmailTextField({super.key});

  @override
  State<EmailTextField> createState() => _EmailTextFieldState();
}

class _EmailTextFieldState extends State<EmailTextField>
    with BaseAuthTextFieldMixin {
  @override
  void onTextChanged(String value) {
    context.read<LoginCubit>().onEmailChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autovalidateMode: AutovalidateMode.onUnfocus,
      validator: (value) => Email.dirty(value ?? '').errorMessage,
      decoration: InputDecoration(
        filled: true,
        labelText: l10n.emailLabel,
        hintText: l10n.emailHint,
      ),
    );
  } 
}
