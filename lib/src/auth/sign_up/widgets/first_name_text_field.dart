import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/sign_up.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class FirstNameTextField extends StatefulWidget {
  const FirstNameTextField({super.key});

  @override
  State<FirstNameTextField> createState() => _FirstNameTextFieldState();
}

class _FirstNameTextFieldState extends State<FirstNameTextField>
    with BaseAuthTextFieldMixin {
  @override
  void onTextChanged(String value) {
    context.read<SignUpCubit>().onFirstNameChanged(value);
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    autofillHints: const [AutofillHints.givenName],
    autovalidateMode: AutovalidateMode.onUnfocus,
    validator: (value) => FirstName.dirty(value ?? '').errorMessage,
    decoration: InputDecoration(
      filled: true,
      hintText: context.l10n.firstNameHint,
      labelText: context.l10n.firstNameLabel,
      errorMaxLines: 3,
    ),
  );
}
