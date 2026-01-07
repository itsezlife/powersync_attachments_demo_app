import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_fields/form_fields.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/auth/sign_up/sign_up.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class LastNameTextField extends StatefulWidget {
  const LastNameTextField({super.key});

  @override
  State<LastNameTextField> createState() => _LastNameTextFieldState();
}

class _LastNameTextFieldState extends State<LastNameTextField>
    with BaseAuthTextFieldMixin {
  @override
  void onTextChanged(String value) {
    context.read<SignUpCubit>().onLastNameChanged(value);
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    autofillHints: const [AutofillHints.familyName],
    autovalidateMode: AutovalidateMode.onUnfocus,
    validator: (value) => LastName.dirty(value ?? '').errorMessage,
    decoration: InputDecoration(
      filled: true,
      hintText: context.l10n.lastNameHint,
      labelText: context.l10n.lastNameLabel,
      errorMaxLines: 3,
    ),
  );
}
