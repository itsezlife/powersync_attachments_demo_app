import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/home/view/home_view.dart';
import 'package:powersync_attachments_example/src/main/view/main_view.dart';
import 'package:powersync_attachments_example/src/menu/view/menu_view.dart';

enum Routes with OctopusRoute {
  home('home', title: 'Home'),
  main('main', title: 'Main'),
  menu('menu', title: 'Menu');

  const Routes(this.name, {this.title});

  @override
  final String name;

  @override
  final String? title;

  @override
  Widget builder(BuildContext context, OctopusState state, OctopusNode node) {
    switch (this) {
      case Routes.home:
        return const HomeView();
      case Routes.main:
        return const MainView();
      case Routes.menu:
        return const MenuView();
    }
  }

  @override
  Page<Object?> pageBuilder(
    BuildContext context,
    OctopusState state,
    OctopusNode node,
  ) {
    if (node.name.startsWith(Routes.home.name)) {
      return super.pageBuilder(context, state, node);
    }
    return super.pageBuilder(context, state, node);
  }
}
