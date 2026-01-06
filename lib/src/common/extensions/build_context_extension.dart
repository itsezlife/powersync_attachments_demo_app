import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Provides values of current device screen `width` and `height` by provided
/// context.
extension BuildContextExtension on BuildContext {
  /// Returns [ThemeData] from [Theme.of].
  ThemeData get theme => Theme.of(this);

  /// Defines [MediaQueryData] based on provided context.
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Defines [MediaQueryData] based on provided context.
  Size get size => MediaQuery.sizeOf(this);

  /// Defines value of device current height based on [size].
  double get height => MediaQuery.heightOf(this);

  /// Defines value of device current width based on [size].
  double get width => MediaQuery.widthOf(this);

  /// Defines view insets from [MediaQuery] with current [BuildContext].
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  /// Defines view padding of from [MediaQuery] with current [BuildContext].
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Defines padding of from [MediaQuery] with current [BuildContext].
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  /// Defines value of current device pixel ratio.
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  /// Defines the platform brightness of the current device.
  Brightness get platformBrightness => MediaQuery.platformBrightnessOf(this);

  /// Defines the brightness of the current theme.
  Brightness get brightness => Theme.brightnessOf(this);

  /// Returns true if the device is in dark mode.
  bool get isDarkMode => platformBrightness == Brightness.dark;

  /// Returns true if the device is in light mode.
  bool get isLightMode => platformBrightness == Brightness.light;

  /// Whether the current device is an `Android`.
  bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  /// Whether the current device is an `iOS`.
  bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// Returns the text scale factor of the screen.
  double textScaleFactor({double maxTextScaleFactor = 1}) {
    final width = this.width;
    final val = (width / 1400) * maxTextScaleFactor;
    return max(1, min(val, maxTextScaleFactor));
  }

  /// A set of [TargetPlatform]s that for desktop devices.
  static const Set<TargetPlatform> desktop = <TargetPlatform>{
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows,
  };

  /// A set of [TargetPlatform]s that for mobile devices.
  static const Set<TargetPlatform> mobile = <TargetPlatform>{
    TargetPlatform.android,
    TargetPlatform.fuchsia,
    TargetPlatform.iOS,
  };
}
