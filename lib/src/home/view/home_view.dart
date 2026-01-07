// ignore_for_file: use_setters_to_change_properties

import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/guards/tabs.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:powersync_attachments_example/src/common/models/nav_bar_tab.dart';
import 'package:powersync_attachments_example/src/home/widgets/home_tabs_mixin.dart';
import 'package:powersync_attachments_example/src/posts/controller/posts_controller.dart';

/// {@template home_view}
/// HomeView widget.
/// {@endtemplate}
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    PostsController().init(context: context);
  }

  @override
  Widget build(BuildContext context) => const _Tabs();
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> with HomeTabsMixin {
  @override
  AppTab get tab => const HomeAppTab();

  void _pushCreatePost(BuildContext context) {
    context.octopus.push(Routes.createPost);
  }

  @override
  void onTabPressed(int index, VoidCallback innerOnTabPressed) {
    if (index == HomeTabsEnum.createPost.order) {
      _pushCreatePost(context);
      return;
    }

    innerOnTabPressed();
  }

  @override
  OctopusTabBuilder get tabBuilder =>
      (context, route, tabIdentifier, onBackButtonPressed) {
        if (route == Routes.createPost) {
          return const SizedBox.shrink();
        }
        return TabBucketNavigator(
          route: route,
          tabIdentifier: tabIdentifier,
          onBackButtonPressed: onBackButtonPressed,
        );
      };

  @override
  Widget build(BuildContext context) => buildTabs(context);
}
