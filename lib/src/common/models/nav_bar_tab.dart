import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// The main outlined icon.
const mainInactiveIcon = Icon(Icons.home_outlined);

/// The main rounded icon.
const mainActiveIcon = Icon(Icons.home_rounded);

/// The settings outlined icon.
const menuInactiveIcon = Icon(Icons.menu_outlined);

/// The settings rounded icon.
const menuActiveIcon = Icon(Icons.menu_rounded, weight: 100);

/// The type of home tabs.
enum HomeTabsEnum with NavBarTab {
  /// The main page.
  main,

  /// The catalog page.
  menu;

  /// Creates a new instance of [HomeTabsEnum] from a given string.
  static HomeTabsEnum fromValue(String? value, {HomeTabsEnum? fallback}) =>
      switch (value?.trim().toLowerCase()) {
        'main' => main,
        'menu' => menu,
        _ => fallback ?? (throw ArgumentError.value(value)),
      };

  @override
  String label(String Function(HomeTabsEnum type) l10n) => l10n(this);

  @override
  String tooltip(String Function(HomeTabsEnum type) l10n) => label(l10n);

  @override
  Widget get icon => switch (this) {
    main => mainInactiveIcon,
    menu => menuInactiveIcon,
  };

  @override
  Widget get activeIcon => switch (this) {
    main => mainActiveIcon,
    menu => menuActiveIcon,
  };

  @override
  BottomNavigationBarItem item(
    String Function(HomeTabsEnum type) labelL10n, {
    String Function(HomeTabsEnum type)? tooltipL10n,
  }) => BottomNavigationBarItem(
    icon: icon,
    activeIcon: activeIcon,
    label: label(labelL10n),
    tooltip: tooltipL10n != null ? tooltipL10n(this) : tooltip(labelL10n),
  );
}

/// The bottom navigation bar item.
mixin NavBarTab {
  /// The label of the bottom navigation bar item.
  String label(String Function(HomeTabsEnum type) l10n);

  /// The tooltip of the bottom navigation bar item.
  String tooltip(String Function(HomeTabsEnum type) l10n);

  /// The icon of the bottom navigation bar item.
  Widget get icon;

  /// The active icon of the bottom navigation bar item.
  Widget get activeIcon;

  /// The item of the bottom navigation bar item.
  BottomNavigationBarItem item(
    String Function(HomeTabsEnum type) labelL10n, {
    String Function(HomeTabsEnum type)? tooltipL10n,
  });
}
