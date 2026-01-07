import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

/// Custom page route that implements SharedAxis transition animation
class SharedAxisPageRoute<T> extends AssetPickerPageRoute<T> {
  /// {@macro shared_axis_page_route}
  SharedAxisPageRoute({
    required super.builder,
    super.transitionDuration = const Duration(milliseconds: 300),
    this.transitionType = SharedAxisTransitionType.vertical,
    super.barrierColor,
    super.barrierDismissible = false,
    super.barrierLabel,
    super.maintainState = true,
    super.opaque = true,
  });

  /// The type of transition to use.
  final SharedAxisTransitionType transitionType;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => SharedAxisTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    transitionType: transitionType,
    child: child,
  );
}
