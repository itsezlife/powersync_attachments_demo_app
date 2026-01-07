import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/widgets/loader_item.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:powersync_attachments_example/src/network_error/network_error.dart';
import 'package:powersync_attachments_example/src/posts/post/view/post_view.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class PostsList extends StatefulWidget {
  const PostsList({
    required this.posts,
    this.pageId,
    this.onLoadMore,
    this.hasMore,
    this.nextPageFailure,
    this.nextPageLoading,
    this.builder,
    super.key,
  });

  final List<Post> posts;
  final String? pageId;
  final VoidCallback? onLoadMore;
  final bool? hasMore;
  final bool? nextPageFailure;
  final bool? nextPageLoading;
  final Widget Function(BuildContext context, Post post)? builder;

  @override
  State<PostsList> createState() => PostsListState();
}

class PostsListState extends State<PostsList> {
  List<Post> get posts => widget.posts;

  final _postBlocksKeyMap = <String, int>{};

  @override
  void didUpdateWidget(covariant PostsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality<Post>().equals(oldWidget.posts, widget.posts)) {
      // If the page id is different, we need to clear the key map
      // because the blocks are from a different page.
      //
      // This is to prevent causing an exception when having list blocks key
      // map mismatch in findChildIndexCallback.
      if (oldWidget.pageId != widget.pageId) {
        log('Clearing posts key map');
        _postBlocksKeyMap.clear();
      }
      _updateBlocks();
    }
  }

  void _updateBlocks() {
    for (var i = 0; i < posts.length; i++) {
      _postBlocksKeyMap[posts[i].id] = i;
    }
  }

  double _itemExtentBuilder(int index, double crossAxisExtent, bool hasMore) {
    // Check if this is a loader item
    final isLastItem = index + 1 == widget.posts.length;
    if (isLastItem && hasMore) {
      // Height for PropertyLoaderItem:
      // - CircularProgressIndicator (typically 36.0)
      // - Vertical padding (AppSpacing.md * 2)
      return 36.0 + (AppSpacing.md * 2);
    }

    // Return a default height for unknown block types
    return 120;
  }

  @override
  Widget build(BuildContext context) {
    final hasMore = widget.hasMore ?? false;

    return SuperSliverList.builder(
      itemCount: posts.length,
      findChildIndexCallback: (key) {
        final valueKey = key as ValueKey<String>;
        final val = _postBlocksKeyMap[valueKey.value];
        return val;
      },
      extentPrecalculationPolicy: DefaultExtentPrecalculationPolicy(
        policy: PrecomputeExtentPolicy.none,
      ),
      extentEstimation: (index, crossAxisExtent) {
        if (index == null) return 0;
        final height = _itemExtentBuilder(index, crossAxisExtent, hasMore);
        return height;
      },
      itemBuilder: (context, index) {
        final post = posts[index];
        final isLastItem = index + 1 == posts.length;
        if (isLastItem && hasMore) {
          if (widget.nextPageFailure ?? false) {
            return NetworkError(onRetry: widget.onLoadMore);
          }
          final nextPageLoading = widget.nextPageLoading ?? false;
          return LoaderItem(
            onPresented: nextPageLoading ? null : widget.onLoadMore,
          );
        }
        if (widget.builder != null) {
          return widget.builder!.call(context, post);
        }
        return PostView(key: ValueKey(post.id), post: post);
      },
    );
  }
}

class PostsListNotFound extends StatelessWidget {
  const PostsListNotFound({
    required this.title,
    this.icon,
    this.child,
    super.key,
  }) : _isSliver = false;

  const PostsListNotFound.sliver({this.title, this.icon, this.child, super.key})
    : _isSliver = true;

  final String? title;
  final IconData? icon;
  final Widget? child;
  final bool _isSliver;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = this.title ?? l10n.noPostsTitle;

    return _isSliver
        ? SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(title: title, child: child),
          )
        : EmptyView(title: title, child: child);
  }
}

class PostsListLoading extends StatelessWidget {
  const PostsListLoading({super.key});

  static final fakePosts = List.generate(
    10,
    (index) => Post(
      id: 'fake_${Config.randomId(size: 23)}',
      author: PostAuthor(
        id: Config.randomId(size: 23),
        name: Config.randomId(size: 8),
      ),
      content: Config.randomId(size: 19),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  @override
  Widget build(BuildContext context) => Skeletonizer.sliver(
    key: UniqueKey(),
    child: PostsList(posts: fakePosts, hasMore: false),
  );
}

class PostsListFailure extends StatelessWidget {
  const PostsListFailure({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      SliverFillRemaining(child: FailureLoadView(onRetry: onRetry));
}

enum PrecomputeExtentPolicy { none, automatic, all }

class DefaultExtentPrecalculationPolicy extends ExtentPrecalculationPolicy {
  DefaultExtentPrecalculationPolicy({required this.policy});

  final PrecomputeExtentPolicy policy;

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) {
    switch (policy) {
      case PrecomputeExtentPolicy.none:
        return false;
      case PrecomputeExtentPolicy.all:
        return true;
      case PrecomputeExtentPolicy.automatic:
        final contentDimensions = context.contentTotalExtent ?? 0;
        return context.numberOfItems <= 20 ||
            contentDimensions < (context.viewportMainAxisExtent ?? 0) * 10;
    }
  }
}
