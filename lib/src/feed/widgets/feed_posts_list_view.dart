import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powersync_attachments_example/src/feed/bloc/feed_bloc.dart';
import 'package:powersync_attachments_example/src/posts/widgets/posts_list_view.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/user_profile_bloc.dart';
import 'package:shared/shared.dart';
import 'package:sliver_tools/sliver_tools.dart';

class FeedPostsListView extends StatelessWidget {
  const FeedPostsListView({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<FeedBloc, FeedState>(
    buildWhen: (previous, current) {
      final hasDifference = !const ListEquality<Post>().equals(
        previous.postsPage.items,
        current.postsPage.items,
      );
      final hasDifferentPageId = previous.postsPage.id != current.postsPage.id;
      final wasLoadingAndBecamePopulated =
          previous.postsPage.status.isLoading &&
          current.postsPage.status.isPopulated;
      final wasPopulatedAndBecameLoading =
          previous.postsPage.status.isPopulated &&
          current.postsPage.status.isLoading;
      final wasLoadingAndBecameFailure =
          previous.postsPage.status.isLoading &&
          current.postsPage.status.isFailure;
      final wasFailureAndBecameLoading =
          previous.postsPage.status.isFailure &&
          current.postsPage.status.isLoading;
      final hasMoreChanged =
          previous.postsPage.hasMore != current.postsPage.hasMore;
      final wasPopulatedAndBecameNextPageFailure =
          previous.postsPage.status.isPopulated &&
          current.postsPage.status.isNextPageFailure;
      final wasNextPageFailureAndBecamePopulated =
          previous.postsPage.status.isNextPageFailure &&
          current.postsPage.status.isPopulated;
      final wasNextPageFailureAndBecameLoading =
          previous.postsPage.status.isNextPageFailure &&
          current.postsPage.status.isLoading;
      final wasNextPageFailureAndBecameNextPageLoading =
          previous.postsPage.status.isNextPageFailure &&
          current.postsPage.status.isNextPageLoading;
      final wasNextPageLoadingAndBecamePopulated =
          previous.postsPage.status.isNextPageLoading &&
          current.postsPage.status.isPopulated;
      final wasNextPageLoadingAndBecameNextPageFailure =
          previous.postsPage.status.isNextPageLoading &&
          current.postsPage.status.isNextPageFailure;
      return wasLoadingAndBecamePopulated && current.postsPage.items.isEmpty ||
          wasLoadingAndBecamePopulated && hasDifference ||
          wasPopulatedAndBecameLoading ||
          wasLoadingAndBecameFailure ||
          wasFailureAndBecameLoading ||
          hasDifference ||
          hasDifferentPageId ||
          hasMoreChanged ||
          wasPopulatedAndBecameNextPageFailure ||
          wasNextPageFailureAndBecamePopulated ||
          wasNextPageFailureAndBecameLoading ||
          wasNextPageLoadingAndBecameNextPageFailure ||
          wasNextPageLoadingAndBecamePopulated ||
          wasNextPageFailureAndBecameNextPageLoading;
    },
    builder: (context, state) {
      final page = state.postsPage;
      final status = page.status;
      return SliverAnimatedSwitcher(
        duration: kThemeAnimationDuration,
        child: switch (status) {
          PostsPageStatus.loading || PostsPageStatus.initial =>
            const PostsListLoading(key: ValueKey('posts-list-loading')),
          PostsPageStatus.failure => PostsListFailure(
            key: const ValueKey('posts-list-failure'),
            onRetry: () {
              context.read<UserProfileBloc>().add(
                const UserProfilePostsFetchRequested(page: 0),
              );
            },
          ),
          PostsPageStatus.populated ||
          PostsPageStatus.nextPageLoading ||
          PostsPageStatus.nextPageFailure => PostsList(
            pageId: page.id,
            posts: page.items,
            hasMore: page.hasMore,
            nextPageFailure: status.isNextPageFailure,
            nextPageLoading: status.isNextPageLoading,
            onLoadMore: () {
              context.read<UserProfileBloc>().add(
                const UserProfilePostsFetchRequested(),
              );
            },
          ),
        },
      );
    },
  );
}
