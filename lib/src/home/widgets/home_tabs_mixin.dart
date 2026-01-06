import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/guards/tabs.dart';
import 'package:powersync_attachments_example/src/common/models/nav_bar_tab.dart';
import 'package:powersync_attachments_example/src/navigation/view/navigation_bar.dart';

mixin HomeTabsMixin<T extends StatefulWidget> on State<T> {
  AppTab get tab;

  OctopusOnBackButtonPressed get onBackButtonPressed => (context, navigator) {
    // First check if the current navigator can pop
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return Future.value(true);
    }

    // Then check if the Octopus navigator can pop
    if (navigator.canPop()) {
      navigator.pop();
      return Future.value(true);
    }
    return Future.value(false);
  };

  OctopusTabBuilder get tabBuilder =>
      (context, route, tabIdentifier, onBackButtonPressed) =>
          TabBucketNavigator(
            route: route,
            tabIdentifier: tabIdentifier,
            onBackButtonPressed: onBackButtonPressed,
          );
  OctopusOnTabChanged get onTabChanged => (index, tab) {
    currentIndex = index;
  };

  void onTabPressed(int index, VoidCallback innerOnTabPressed) {
    innerOnTabPressed();
  }

  int currentIndex = 0;

  Widget buildTabs(BuildContext context) => NoAnimationScope(
    child: OctopusTabs.lazy(
      root: tab.root,
      tabs: tab.tabs,
      onBackButtonPressed: onBackButtonPressed,
      tabBuilder: tabBuilder,
      onTabChanged: onTabChanged,
      builder: (context, child, currentIndex, innerOnTabPressed) => _Body(
        currentIndex: currentIndex,
        tabs: tab.bottomTabs,
        onTap: (index) => onTabPressed(index, () => innerOnTabPressed(index)),
        child: child,
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({
    required this.child,
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final Widget child;
  final int currentIndex;
  final List<NavBarTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: child,
    bottomNavigationBar: BottomNavBar(
      tabs: tabs,
      currentIndex: currentIndex,
      onTap: onTap,
    ),
  );
}
