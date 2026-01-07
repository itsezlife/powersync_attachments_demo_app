import 'package:flutter/material.dart';

/// {@template gap}
/// A widget that creates a gap between widgets.
/// {@endtemplate}
class Gap extends StatelessWidget {
  /// {@macro gap.h}
  const Gap.h(
    double width, {
    super.key,
    double? height,
    this.color,
  }) : _width = width,
       _height = height;

  /// {@macro gap.v}
  const Gap.v(
    double height, {
    super.key,
    double? width,
    this.color,
  }) : _width = width,
       _height = height;

  final double? _width;
  final double? _height;

  /// The color of the gap.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget w = SizedBox(width: _width, height: _height);
    if (color != null) {
      w = ColoredBox(color: color!, child: w);
    }
    return w;
  }
}

/// {@template sliver_gap}
/// A widget that creates a gap between widgets in a Sliver.
/// {@endtemplate}
class SliverGap extends StatelessWidget {
  /// {@macro sliver_gap.h}
  const SliverGap.h(
    double width, {
    super.key,
    double? height,
    this.color,
  }) : _width = width,
       _height = height;

  /// {@macro sliver_gap.v}
  const SliverGap.v(
    double height, {
    super.key,
    double? width,
    this.color,
  }) : _width = width,
       _height = height;

  final double? _width;
  final double? _height;

  /// The color of the gap.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final width = _width;
    final height = _height;
    Widget child;
    if (width != null) {
      child = Gap.h(width, height: height, color: color);
    } else if (height != null) {
      child = Gap.v(height, width: width, color: color);
    } else {
      child = const SizedBox.shrink();
    }
    return SliverToBoxAdapter(child: child);
  }
}
