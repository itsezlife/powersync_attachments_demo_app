import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/common/widgets/scaffold_padding.dart';
import 'package:powersync_attachments_example/src/common/widgets/skeletonizer_container_theme_override.dart';
import 'package:powersync_attachments_example/src/feed/bloc/feed_bloc.dart';
import 'package:powersync_attachments_example/src/feed/widgets/feed_posts_list_view.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        FeedBloc(postsRepository: context.read<PostsRepository>())
          ..add(const FeedPostsRequested(page: 0)),
    child: const FeedView(),
  );
}

class FeedView extends StatelessWidget {
  const FeedView({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: RefreshIndicator.adaptive(
      onRefresh: () async =>
          context.read<FeedBloc>().add(const FeedPostsRefreshRequested()),
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Feed'),
            pinned: true,
            floating: true,
            snap: true,
          ),
          SkeletonizerContainerThemeOverride(
            child: ScaffoldPadding.sliver(
              context,
              horizontalPadding: 0,
              child: const FeedPostsListView(),
            ),
          ),
        ],
      ),
    ),
  );
}
