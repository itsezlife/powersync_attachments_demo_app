import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/models/nav_bar_tab.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarTab> tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = context.theme;
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final tabs = this.tabs
        .map((tab) => tab.item((type) => l10n.bottomNavBarTabLabel(type.name)))
        .toList(growable: false);

    return BottomNavigationBar(
      iconSize: 28,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      showSelectedLabels: true,
      selectedItemColor: colorScheme.onSurface,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.outline,
        fontWeight: FontWeight.w400,
      ),
      items: tabs,
    );
  }
}

class NavRail extends StatelessWidget {
  const NavRail({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarTab> tabs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(color: colorScheme.onSurface, size: 28),
      unselectedIconTheme: IconThemeData(color: colorScheme.outline, size: 28),
      selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.outline,
        fontWeight: FontWeight.w400,
      ),
      destinations: tabs
          .map(
            (tab) => NavigationRailDestination(
              icon: tab.icon,
              label: Text(
                tab.label((type) => l10n.bottomNavBarTabLabel(type.name)),
              ),
            ),
          )
          .toList(),
    );
  }
}
