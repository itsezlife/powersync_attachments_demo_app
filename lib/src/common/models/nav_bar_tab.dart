import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// The main outlined icon.
const mainInactiveIcon = Icon(Icons.home_outlined);

/// The main rounded icon.
const mainActiveIcon = Icon(Icons.home_rounded);

/// The settings outlined icon.
const profileInactiveIcon = Icon(Icons.person_outline);

/// The settings rounded icon.
const profileActiveIcon = Icon(Icons.person_rounded, weight: 100);

/// The create post outlined icon.
const createPostInactiveIcon = Icon(Icons.add_box_outlined);

/// The create post rounded icon.
const createPostActiveIcon = Icon(Icons.add_box_outlined, weight: 100);

/// The type of home tabs.
enum HomeTabsEnum with NavBarTab {
  /// The main page.
  main(order: 0),

  createPost(order: 1),

  /// The catalog page.
  profile(order: 2);

  const HomeTabsEnum({required this.order});

  @override
  final int order;

  /// Creates a new instance of [HomeTabsEnum] from a given string.
  static HomeTabsEnum fromValue(String? value, {HomeTabsEnum? fallback}) =>
      switch (value?.trim().toLowerCase()) {
        'main' => main,
        'profile' => profile,
        'createPost' => createPost,
        _ => fallback ?? (throw ArgumentError.value(value)),
      };

  @override
  String label(String Function(HomeTabsEnum type) l10n) => l10n(this);

  @override
  String tooltip(String Function(HomeTabsEnum type) l10n) => label(l10n);

  @override
  Widget get icon => switch (this) {
    main => mainInactiveIcon,
    createPost => createPostInactiveIcon,
    profile => profileInactiveIcon,
  };

  @override
  Widget get activeIcon => switch (this) {
    main => mainActiveIcon,
    createPost => createPostActiveIcon,
    profile => profileActiveIcon,
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

  @override
  int compareTo(NavBarTab other) => order.compareTo(other.order);
}

/// The bottom navigation bar item.
mixin NavBarTab on Enum implements Comparable<NavBarTab> {
  /// The label of the bottom navigation bar item.
  String label(String Function(NavBarTab type) l10n);

  /// The tooltip of the bottom navigation bar item.
  String tooltip(String Function(NavBarTab type) l10n);

  /// The index of the bottom navigation bar item.
  int get order;

  /// The icon of the bottom navigation bar item.
  Widget get icon;

  /// The active icon of the bottom navigation bar item.
  Widget get activeIcon;

  /// The item of the bottom navigation bar item.
  BottomNavigationBarItem item(
    String Function(NavBarTab type) labelL10n, {
    String Function(NavBarTab type)? tooltipL10n,
  });
}
