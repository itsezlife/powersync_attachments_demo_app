import 'package:flutter/material.dart';
import 'package:throttling/throttling.dart';

mixin BaseAuthTextFieldMixin<T extends StatefulWidget> on State<T> {
  Debouncing<void> get _debouncing =>
      Debouncing<void>(duration: debounceDuration);

  Duration get debounceDuration => const Duration(milliseconds: 150);

  final controller = TextEditingController();

  @protected
  @mustCallSuper
  @override
  void initState() {
    super.initState();
    controller.addListener(_onTextChanged);
  }

  @protected
  void onTextChanged(String value);

  void _onTextChanged() {
    _debouncing.debounce(() => onTextChanged(controller.text));
  }

  @protected
  @mustCallSuper
  @override
  void dispose() {
    _debouncing.close();
    controller
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }
}
