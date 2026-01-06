import 'dart:async';

import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/tabs.dart';

abstract class ITabsGuard extends OctopusGuard {
  ITabsGuard({required this.tab});

  final AppTab tab;

  List<OctopusRoute> get tabs => tab.tabs;

  String _tabRouteName(OctopusRoute route) => tab.tabRouteName(route);

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) {
    final root = state.findByName(tab.root.name);

    if (root == null) return state; // Do nothing if `root` not found.

    // Keep only branches matching our tabs, remove others.
    final validNames = tabs.map(_tabRouteName).toSet();
    root.removeWhere(
      (node) => !validNames.contains(node.name),
      recursive: false,
    );

    // Ensure each tab branch exists under root.
    for (final tab in tabs) {
      final bucketName = _tabRouteName(tab);
      final branch = root.putIfAbsent(
        bucketName,
        () => OctopusNode.mutable(bucketName),
      );
      if (!branch.hasChildren) branch.add(OctopusNode.mutable(tab.name));
    }

    return state;
  }
}

class HomeTabsGuard extends ITabsGuard {
  HomeTabsGuard({super.tab = _tab});

  static const _tab = HomeAppTab();
}
