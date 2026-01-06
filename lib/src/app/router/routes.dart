import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/auth/auth.dart';
import 'package:powersync_attachments_example/src/home/view/home_view.dart';
import 'package:powersync_attachments_example/src/main/view/main_view.dart';
import 'package:powersync_attachments_example/src/posts/create_post/create_post.dart';
import 'package:powersync_attachments_example/src/user_profile/view/user_page.dart';

enum Routes with OctopusRoute {
  home('home', title: 'Home'),
  main('main', title: 'Main'),
  profile('profile', title: 'Profile'),
  auth('auth', title: 'Auth'),
  createPost('createPost', title: 'Create Post');

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
      case Routes.profile:
        return const UserProfilePage();
      case Routes.auth:
        final showLogin = switch (node.arguments['showLogin']) {
          final String value => value == 'true',
          null => true,
        };
        return AuthPage(showLogin: showLogin);
      case Routes.createPost:
        return const CreatePostView();
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
