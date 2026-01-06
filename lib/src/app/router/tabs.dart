import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:powersync_attachments_example/src/common/models/nav_bar_tab.dart';

mixin AppTab {
  OctopusRoute get root;
  List<OctopusRoute> get tabs;
  List<NavBarTab> get bottomTabs;
  String get identifier;

  String tabRouteName(OctopusRoute route) => '${route.name}-$identifier';

  List<String> get tabRouteNames => [for (final tab in tabs) tabRouteName(tab)];
}

class HomeAppTab with AppTab {
  const HomeAppTab();

  static const _identifier = 'tab';

  @override
  String get identifier => _identifier;

  static const _root = Routes.home;

  static const mainTab = Routes.main;
  static const menuTab = Routes.menu;

  @override
  OctopusRoute get root => _root;

  static const _tabs = <OctopusRoute>[
    mainTab,
    menuTab,
  ];

  @override
  List<OctopusRoute> get tabs => _tabs;

  static const _bottomTabs = <NavBarTab>[
    HomeTabsEnum.main,
    HomeTabsEnum.menu,
  ];

  @override
  List<NavBarTab> get bottomTabs => _bottomTabs;

  @override
  String toString() => 'HomeAppTab(identifier: $identifier)';
}
