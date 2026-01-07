// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart' hide Change;
import 'package:diffutil_dart/diffutil.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/posts_operations_mixin.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:powersync_database_client/powersync_database_client.dart';
import 'package:shared/shared.dart' as shared show Attachment;
import 'package:shared/shared.dart' hide Attachment;
import 'package:user_repository/user_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState>
    with PostsDatabaseMixin {
  UserProfileBloc({
    required PowerSyncClient powerSyncClient,
    required UserRepository userRepository,
    required PostsRepository postsRepository,
  }) : _userRepository = userRepository,
       _powerSyncClient = powerSyncClient,
       _postsRepository = postsRepository,
       super(const UserProfileState.initial()) {
    on<UserProfileChanged>(_onUserProfileChanged);
    on<UserProfileSubscriptionRequested>(_onUserProfileSubscriptionRequested);
    on<UserProfilePostsFetchRequested>(_onPostsFetchRequested);
    on<UserProfilePostsRefreshRequested>(_onPostsRefreshRequested);
    on<UserProfilePostCreateRequested>(_onPostCreateRequested);
    on<UserProfilePostCreateStartRequested>(_onPostCreateStartRequested);
    on<UserProfilePostDeleteRequested>(_onPostDeleteRequested);
    on<UserProfilePostsUpdateRequested>(_onPostsUpdateRequested);

    add(const UserProfileSubscriptionRequested());
  }

  final UserRepository _userRepository;
  final PostsRepository _postsRepository;
  final PowerSyncClient _powerSyncClient;

  static const _postsPageSize = 10;

  StreamSubscription<List<Post>>? _postsSubscription;
  StreamSubscription<List<Post>>? _localPostsSubscription;
  bool _shouldProcessWatchedPosts = false;

  Future<void> _onUserProfileSubscriptionRequested(
    UserProfileSubscriptionRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(state.copyWith(status: UserProfileStatus.userLoading));
    await emit.onEach(
      _userRepository.user,
      onData: (user) => add(UserProfileChanged(user)),
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        add(const UserProfileChanged(User.anonymous));
      },
    );
  }

  void _onUserProfileChanged(
    UserProfileChanged event,
    Emitter<UserProfileState> emit,
  ) {
    final user = event.user;

    if (user.isAnonymous) {
      return emit(
        state.copyWith(status: UserProfileStatus.userNotFound, user: user),
      );
    }

    final picture = user.avatarUrl == null
        ? null
        : user.avatarUrl!.startsWith(RegExp('https?://'))
        ? user.avatarUrl
        : _userRepository.getProfileImageUrl(
            userId: user.id,
            imageName: user.avatarUrl!,
          );

    final shouldFetch = state.user.isAnonymous && !user.isAnonymous;

    emit(
      state.copyWith(
        user: event.user.copyWith(avatarUrl: picture),
        status: UserProfileStatus.userPopulated,
      ),
    );

    // Only fetch additional data if previous state was anonymous and new
    // user is not
    if (!shouldFetch) return;

    add(const UserProfilePostsFetchRequested(page: 0));
  }

  /// The [isBusy] flag is to prevent multiple calls to make API calls
  /// from `HomePage` when we hot restart the app.
  ///
  /// When the app is hot restarted the `HomePage` get rebuilds two
  /// or more times, causing unnecessary API calls, while the [UserProfileBloc]
  /// with `forceCurrentUser` flag set to `true` is already fetching the data.
  @internal
  bool isBusy = false;

  Future<void> _onPostsFetchRequested(
    UserProfilePostsFetchRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    isBusy = true;
    final fetchNewPage = event.page != null;
    try {
      if (!state.postsPage.hasMore && !fetchNewPage) {
        return emit(state.copyWith(postsPage: state.postsPage.populated()));
      }

      if (state.postsPage.status.isNextPageFailure) {
        emit(state.copyWith(postsPage: state.postsPage.nextPageLoading()));
      }

      if (fetchNewPage) {
        emit(
          state.copyWith(
            postsPage: state.postsPage.copyWith(
              status: PostsPageStatus.loading,
              totalLengthStatus: PostsPageTotalLengthStatus.loading,
            ),
          ),
        );
      }

      final currentPage = event.page ?? state.postsPage.currentPage;

      final posts = await _postsRepository.fetchPosts(
        limit: _postsPageSize,
        offset: _postsPageSize * currentPage,
        userId: state.user.id,
      );

      final newPage = currentPage + 1;
      final hasMore = posts.length >= _postsPageSize;

      isBusy = false;

      emit(
        state.copyWith(
          postsPage: state.postsPage.populated(
            id: fetchNewPage ? uuid.v4() : null,
            posts: fetchNewPage ? posts : [...state.postsPage.posts, ...posts],
            hasMore: hasMore,
            currentPage: newPage,
            needsRebuild: false,
            totalLengthStatus: PostsPageTotalLengthStatus.populated,
          ),
        ),
      );

      _subscribeToRemoteChanges();
      _subscribeToLocalChanges();
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          postsPage: fetchNewPage
              ? state.postsPage.failure().copyWith(
                  totalLengthStatus: PostsPageTotalLengthStatus.failure,
                )
              : state.postsPage.nextPageFailure(),
        ),
      );
    }
  }

  Future<void> _onPostsRefreshRequested(
    UserProfilePostsRefreshRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(postsPage: state.postsPage.loading()));

      const currentPage = 0;

      final posts = await _postsRepository.fetchPosts(
        limit: _postsPageSize,
        offset: _postsPageSize * currentPage,
        userId: state.user.id,
      );

      const newPage = currentPage + 1;
      final hasMore = posts.length >= _postsPageSize;

      emit(
        state.copyWith(
          postsPage: state.postsPage.populated(
            id: uuid.v4(),
            posts: posts,
            hasMore: hasMore,
            currentPage: newPage,
            needsRebuild: false,
          ),
        ),
      );

      _subscribeToRemoteChanges();
      _subscribeToLocalChanges();
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(postsPage: state.postsPage.failure()));
    }
  }

  Future<void> _onPostCreateRequested(
    UserProfilePostCreateRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(status: UserProfileStatus.postCreating));
      await _postsRepository.createPost(
        id: event.postId,
        content: event.content,
        attachments: event.attachments,
      );
      emit(state.copyWith(status: UserProfileStatus.postCreated));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: UserProfileStatus.postCreateFailed));
    }
  }

  void _onPostCreateStartRequested(
    UserProfilePostCreateStartRequested event,
    Emitter<UserProfileState> emit,
  ) {
    emit(state.copyWith(status: UserProfileStatus.postCreating));
  }

  Future<void> _onPostDeleteRequested(
    UserProfilePostDeleteRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      await _postsRepository.deletePost(postId: event.postId);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: UserProfileStatus.postDeleteFailed));
    }
  }

  void _subscribeToRemoteChanges() {
    _shouldProcessWatchedPosts = false;
    _postsSubscription?.cancel();

    final oldestTimestamp = state.postsPage.posts.isNotEmpty
        ? state.postsPage.posts.last.createdAt.toIso8601String()
        : null;

    final whereClause = oldestTimestamp != null
        ? 'AND datetime(p.created_at) >= datetime(?2)'
        : '';
    final query = _powerSyncClient.db().watch(
      postsQuery(local: false, andWhereClause: whereClause),
      parameters: [state.user.id, ?oldestTimestamp],
    );

    _postsSubscription = query
        .asyncMap(
          (results) => PostsDatabaseUtils.parsePosts(
            results,
            local: false,
            getAttachmentImageUrl: (postId, attachmentName) => _postsRepository
                .getPostImageUrl(imageName: attachmentName, postId: postId),
          ),
        )
        .listen((results) {
          if (!_shouldProcessWatchedPosts) {
            _shouldProcessWatchedPosts = true;
            return;
          }
          add(UserProfilePostsUpdateRequested(results));
        });
  }

  void _subscribeToLocalChanges() {
    _localPostsSubscription?.cancel();
    final query = _powerSyncClient.db().watch(
      postsQuery(local: true),
      parameters: [state.user.id],
      triggerOnTables: ['post_attachments_local'],
    );

    _localPostsSubscription = query
        .asyncMap(
          (results) => PostsDatabaseUtils.parsePosts(
            results,
            local: true,
            // Local posts don't have remote attachments, so we don't transform urls
            // getAttachmentImageUrl: ...
          ),
        )
        .listen((results) {
          if (results.isEmpty) return;
          add(
            UserProfilePostsUpdateRequested(
              results,
              excludedDiffs: const [DiffUpdateType.remove],
            ),
          );
        });
  }

  Future<void> _onPostsUpdateRequested(
    UserProfilePostsUpdateRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      final newList = List<Post>.from(event.posts);

      // Add local only messages that are not yet in the new list
      for (final localPost in state.postsPage.posts.where((p) => p.localOnly)) {
        if (!newList.any((p) => p.id == localPost.id)) {
          newList.add(localPost);
        }
      }

      newList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final oldList = state.postsPage.posts;

      log(
        'oldList(${oldList.length}): $oldList',
        name: '_onPostsUpdateRequested',
      );
      log(
        'newList(${newList.length}): $newList',
        name: '_onPostsUpdateRequested',
      );

      final diffResult = await compute(calculatePostsChangesDiff, [
        oldList,
        newList,
        event.excludedDiffs,
      ]);

      // Create a new list by applying the updates from the diff result
      final updatedList = List<Post>.from(oldList);
      final updates = diffResult;
      log('updates: $updates', name: '_onPostsUpdateRequested');

      // Track position offset for adjusting subsequent operations
      var positionOffset = 0;

      for (final update in updates) {
        update.when(
          insert: (pos, count) {
            final adjustedPos = pos + positionOffset;
            final data = newList.sublist(pos, pos + count);
            updatedList.insertAll(adjustedPos, data);

            for (var i = 0; i < count; i++) {
              final message = data[i];
              postsChangesController.add(
                DataInsert(position: pos + i, data: message),
              );
            }

            // Insertions shift subsequent positions forward
            positionOffset += count;
          },
          remove: (pos, count) {
            final adjustedPos = pos + positionOffset;

            // Validate the range before attempting removal
            if (adjustedPos >= updatedList.length) {
              log(
                'Invalid remove position: adjustedPos=$adjustedPos, '
                'updatedList.length=${updatedList.length}, '
                'originalPos=$pos, offset=$positionOffset',
                name: '_onPostsUpdateRequested',
              );
              return;
            }

            final actualCount = (adjustedPos + count > updatedList.length)
                ? updatedList.length - adjustedPos
                : count;

            updatedList.removeRange(adjustedPos, adjustedPos + actualCount);

            for (var i = 0; i < actualCount; i++) {
              if (pos + i < oldList.length) {
                final message = oldList[pos + i];
                postsChangesController.add(
                  DataRemove(position: pos + i, data: message),
                );
              }
            }

            // Removals shift subsequent positions backward
            positionOffset -= actualCount;
          },
          change: (pos, payload) {
            final adjustedPos = pos + positionOffset;

            if (pos >= newList.length || adjustedPos >= updatedList.length) {
              log(
                'Invalid position: pos=$pos, adjustedPos=$adjustedPos, '
                'newList.length=${newList.length}, '
                'updatedList.length=${updatedList.length}, '
                'oldList.length=${oldList.length}',
                name: '_onPostsUpdateRequested',
              );
              return;
            }

            final newMessage = newList[pos];
            final existingMessage = oldList[pos];

            postsChangesController.add(
              DataChange(
                position: pos,
                oldData: existingMessage,
                newData: newMessage,
              ),
            );
            // This is for partial updates, for simplicity we replace the item
            updatedList[adjustedPos] = newList[pos];
          },
          move: (from, to) {
            // not used since detectMoves is false
          },
        );
      }

      emit(
        state.copyWith(
          postsPage: state.postsPage.copyWith(
            items: updatedList,
            totalLength: updatedList.length,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }
}
