import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/route_tracker.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart'
    show Routes;

extension OctopusX on Octopus {
  /// Returns true if the [Octopus] state has any routes that are not the
  /// [Routes.home] route on the same level as home route.
  ///
  /// Example:
  /// ```dart
  /// home
  ///   watchlist-tab
  ///      watchlist
  ///   explore-tab
  ///      explore
  ///   community-tab
  ///      community
  ///   menu-tab
  ///      menu
  /// user-profile // On the same level as home route
  /// ```
  ///
  /// In this example, the state has root routes because it has user-profile
  /// route on the same level as home route.
  bool get hasRootRoutes =>
      state.children.any((child) => child.name != Routes.home.name);

  /// Pushes a route on the current tab.
  ///
  /// Checks if the [Octopus] state [hasRootRoutes]. If it does, it will push
  /// the route on the root using [push] instead. Otherwise, it will push(stack)
  /// the route on the current tab using [setState].
  ///
  /// ### Example(without root routes):
  /// ```dart
  /// home
  ///   watchlist-tab
  ///      watchlist
  ///   explore-tab
  ///      explore
  ///   community-tab
  ///      community
  ///      user-profile // Pushed(stacked) on community-tab
  ///   menu-tab
  ///      menu
  ///      profile
  ///      user-profile // Pushed(stacked) on menu-tab
  /// ```
  /// In this example routes are pushed(stacked) on the tabs. There are no
  /// routes that are on the same level(root routes) as home route. Therefore,
  /// [pushOnTab] will push the route on whatever tab.
  ///
  /// ### Example(with root routes):
  /// ```dart
  /// home
  ///   watchlist-tab
  ///      watchlist
  ///   explore-tab
  ///      explore
  ///   community-tab
  ///      community
  ///      user-profile // Pushed(stacked) on community-tab
  ///   menu-tab
  ///      menu
  ///      profile
  /// user-profile // Pushed(stacked) on home
  /// (news routes will be pushed on the root level)
  /// ```
  ///
  /// In this example community tab has user-profile route. At the same
  /// time, the user has pushed user-profile route on the root level.
  /// It can happen if the user clicked on a comment's user
  /// profile, which pushed user-profile route on the root level. Therefore,
  /// any subsequent [pushOnTab] calls will push the route on the root level
  /// using regular [push] method.
  Future<void> pushOnTab(
    OctopusRoute route, {
    String? targetedTabRouteName,
    Map<String, String>? arguments,
    Map<String, Object?>? extra,
    bool Function(OctopusNode$Mutable tabNode)? shouldPush,
    void Function(OctopusState$Mutable state, OctopusNode$Mutable tabNode)?
    afterPush,
  }) {
    if (hasRootRoutes) {
      return push(route, arguments: arguments, extra: extra);
    }

    final currentTab = RouteTracker.instance.currentTab;
    if (currentTab == null) {
      return push(route, arguments: arguments, extra: extra);
    }

    final currentTabIdentifier = currentTab.identifier;
    final initialTabArgument = currentTab.tabs.first.name;
    final currentTabArgument =
        targetedTabRouteName ??
        state.arguments[currentTabIdentifier] ??
        initialTabArgument;
    final currentTabRoute = currentTab.tabs.firstWhere(
      (tab) => tab.name == currentTabArgument,
    );
    return setState((state) {
      final tabNode = state.findByName(
        currentTab.tabRouteName(currentTabRoute),
      );
      if (tabNode == null) {
        return state;
      }

      final doPush = shouldPush?.call(tabNode) ?? true;
      if (!doPush) {
        return state;
      }

      final node = route.node(arguments: arguments);
      if (extra != null) {
        node.extra = extra;
      }

      tabNode.add(node);

      afterPush?.call(state, tabNode);

      return state;
    });
  }
}
