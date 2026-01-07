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

  static OctopusRoute tabRoute(HomeTabsEnum tab) => switch (tab) {
    HomeTabsEnum.feed => Routes.feed,
    HomeTabsEnum.profile => Routes.profile,
    HomeTabsEnum.createPost => Routes.createPost,
  };

  @override
  OctopusRoute get root => _root;

  static final List<OctopusRoute> _tabs = <OctopusRoute>[
    for (final tab in HomeTabsEnum.values) tabRoute(tab),
  ];

  @override
  List<OctopusRoute> get tabs => _tabs;

  static final List<NavBarTab> _bottomTabs = <NavBarTab>[
    for (final tab in HomeTabsEnum.values) tab,
  ];

  @override
  List<NavBarTab> get bottomTabs => _bottomTabs;

  @override
  String toString() => 'HomeAppTab(identifier: $identifier)';
}
