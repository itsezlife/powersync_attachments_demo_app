// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:powersync_attachments_example/src/app/router/tabs.dart';

/// {@template route_tracker}
/// A service that tracks the current route and provides utilities
/// for checking if we're on specific routes from anywhere in the app.
///
/// Supports multiple tab-oriented navigation roots (e.g., home, community)
/// and automatically determines the current node.
/// {@endtemplate}
class RouteTracker extends ChangeNotifier {
  /// {@macro route_tracker}
  RouteTracker._();

  static final RouteTracker _instance = RouteTracker._();
  static RouteTracker get instance => _instance;

  static const _supportedTabs = [HomeAppTab()];

  RouteInfo? _currentRouteInfo;
  AppTab? _currentTab;

  /// The current node
  OctopusNode? get currentNode => _currentRouteInfo?.currentNode;

  /// The current node
  OctopusNode? get currentRootNode => _currentRouteInfo?.rootNode;

  /// The current active tab (null if not in tab-based navigation)
  AppTab? get currentTab => _currentTab;

  /// Updates the current node based on the Octopus state tree.
  ///
  /// 1. Find the latest (rightmost) tab root in state.children
  /// 2. If nodes exist after the tab root, the last one is current (pushed root)
  /// 3. If no nodes after, we're within tab navigation:
  ///    - Use tab argument to find specific tab node, or
  ///    - Default to first tab if no argument
  /// 4. If no tab roots found, we're outside tab navigation (e.g., auth flow)
  void updateRoute(OctopusState state) {
    try {
      final previousNode = _currentRouteInfo;
      final previousTab = _currentTab;

      // Find the rightmost tab root in the children list
      final tabRootIndex = _findLatestTabRootIndex(state);

      if (tabRootIndex == -1) {
        // No tab root found - we're in a non-tab flow (e.g., auth, onboarding)
        _setCurrentNodeFromFirst(state);
        _currentTab = null;
      } else if (tabRootIndex < state.children.length - 1) {
        // Nodes exist after the tab root - a root route was pushed over tabs
        // Example: home -> symbols (symbols is pushed as root)
        _setCurrentNodeFromLast(state);
        // Still track which tab is underneath
        final tabRoot = state.children[tabRootIndex];
        _currentTab = _findTabByRootName(tabRoot.name);
      } else {
        // We're within tab navigation - find the active tab node
        final tabRoot = state.children[tabRootIndex];
        final tab = _findTabByRootName(tabRoot.name);
        if (tab != null) {
          _currentTab = tab;
          _setCurrentNodeFromTab(state, tab, tabRoot);
        } else {
          // Fallback: should never happen if configuration is correct
          _currentTab = null;
          _setCurrentNodeFromFirst(state);
        }
      }

      // Notify listeners only if the node or tab changed
      if (previousNode != _currentRouteInfo || previousTab != _currentTab) {
        log(
          'currentNode: $_currentRouteInfo, currentTab: $_currentTab',
          name: 'RouteTracker',
        );
        notifyListeners();
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RouteTracker',
          context: ErrorDescription('Error updating node tracking'),
        ),
      );
    }
  }

  /// Finds the index of the rightmost (latest) tab root in state.children.
  /// Returns -1 if no tab root is found.
  int _findLatestTabRootIndex(OctopusState state) {
    for (var i = state.children.length - 1; i >= 0; i--) {
      final childName = state.children[i].name;
      if (_supportedTabs.any((tab) => tab.root.name == childName)) {
        return i;
      }
    }
    return -1;
  }

  /// Finds a tab configuration by its root route name.
  AppTab? _findTabByRootName(String rootName) {
    for (final tab in _supportedTabs) {
      if (tab.root.name == rootName) {
        return tab;
      }
    }
    return null;
  }

  /// Sets current node from the first child (fallback for non-tab flows).
  void _setCurrentNodeFromFirst(OctopusState state) {
    if (state.children.isNotEmpty) {
      final firstNode = state.children.first;
      _currentRouteInfo = RouteInfo(
        rootNode: firstNode,
        currentNode: firstNode,
      );
    }
  }

  /// Sets current node from the last child (pushed root over tabs).
  void _setCurrentNodeFromLast(OctopusState state) {
    if (state.children.isNotEmpty) {
      final lastNode = state.children.last;
      _currentRouteInfo = RouteInfo(rootNode: lastNode, currentNode: lastNode);
    }
  }

  /// Sets current node based on the active tab within a tab root.
  ///
  /// Uses the tab argument from state to find the specific tab node,
  /// then extracts the deepest child node to get the actual current route.
  void _setCurrentNodeFromTab(
    OctopusState state,
    AppTab tab,
    OctopusNode tabRoot,
  ) {
    // Check if there's an explicit tab selection in arguments
    final selectedTabName = state.arguments[tab.identifier];

    if (selectedTabName != null) {
      // Find the matching tab route
      final selectedTabRoute = tab.tabs.firstWhereOrNull(
        (route) => route.name == selectedTabName,
      );

      if (selectedTabRoute != null) {
        // Find the specific tab node (e.g., 'watchlist-tab', 'settings-tab')
        final tabNodeName = tab.tabRouteName(selectedTabRoute);

        // Use state.find to locate the tab node in the tree
        final tabNode = state.find((node) => node.name == tabNodeName);

        if (tabNode != null) {
          // Get the deepest node in this tab branch
          final deepestNode = _findDeepestNode(tabNode);
          _currentRouteInfo = deepestNode;
          return;
        }
      }
    }

    // No argument or tab node not found - default to first tab
    final defaultTab = tab.tabs.first;
    final defaultTabNodeName = tab.tabRouteName(defaultTab);

    // Try to find the default tab node in the tree
    final defaultTabNode = state.find(
      (node) => node.name == defaultTabNodeName,
    );

    if (defaultTabNode != null) {
      // Get the deepest node in this tab branch
      final deepestNode = _findDeepestNode(defaultTabNode);
      _currentRouteInfo = deepestNode;
    } else {
      // fallback: use the tab root itself
      _currentRouteInfo = RouteInfo(rootNode: tabRoot, currentNode: tabRoot);
    }
  }

  /// Finds the deepest (leaf) node in a branch by following the first child
  /// recursively until no more children exist.
  ///
  /// This extracts the actual route node from tab wrapper nodes.
  RouteInfo _findDeepestNode(OctopusNode node) {
    var lastNode = node;
    var firstNode = node;
    while (lastNode.children.isNotEmpty) {
      firstNode = firstNode.children.first;
      lastNode = lastNode.children.last;
    }
    return RouteInfo(rootNode: firstNode, currentNode: lastNode);
  }

  /// Check if currently on a specific route
  bool isOnRoute(OctopusRoute route) =>
      _currentRouteInfo?.currentNode.name == route.name;

  /// Check if currently on main route
  bool get isOnMain => isOnRoute(Routes.main);

  /// Check if a specific tab is currently active
  bool isOnTab(AppTab tab) => _currentTab?.identifier == tab.identifier;

  /// Check if currently in any tab-based navigation
  bool get isInTabNavigation => _currentTab != null;
}

@immutable
class RouteInfo {
  const RouteInfo({required this.rootNode, required this.currentNode});

  final OctopusNode rootNode;
  final OctopusNode currentNode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteInfo &&
          rootNode == other.rootNode &&
          currentNode == other.currentNode;

  @override
  int get hashCode => Object.hash(rootNode, currentNode);

  @override
  String toString() =>
      'RouteInfo(rootNode: $rootNode, currentNode: $currentNode)';
}
