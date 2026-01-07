import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/common/widgets/scaffold_padding.dart';
import 'package:powersync_attachments_example/src/common/widgets/skeletonizer_container_theme_override.dart';
import 'package:powersync_attachments_example/src/posts/widgets/post_progress_list.dart';
import 'package:powersync_attachments_example/src/user_profile/widgets/user_posts_list_view.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const UserProfileView();
}

class UserProfileView extends StatelessWidget {
  const UserProfileView({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          title: const Text('User Profile'),
          actions: [
            IconButton(
              onPressed: () {
                context.octopus.push(Routes.settings);
              },
              icon: const Icon(Icons.settings),
            ),
          ],
          pinned: true,
          floating: true,
          snap: true,
        ),
        ScaffoldPadding.sliver(
          context,
          horizontalPadding: 0,
          child: SliverList.list(children: const [PostProgressList()]),
        ),
        SkeletonizerContainerThemeOverride(
          child: ScaffoldPadding.sliver(
            context,
            horizontalPadding: 0,
            child: const UserPostsListView(),
          ),
        ),
      ],
    ),
  );
}
