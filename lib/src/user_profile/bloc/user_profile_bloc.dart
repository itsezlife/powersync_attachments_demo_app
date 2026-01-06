import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({
    required UserRepository userRepository,
    required PostsRepository postsRepository,
  }) : _userRepository = userRepository,
       _postsRepository = postsRepository,
       super(const UserProfileState.initial()) {
    on<UserProfileChanged>(_onUserProfileChanged);
    on<UserProfileSubscriptionRequested>(_onUserProfileSubscriptionRequested);
    on<UserProfilePostsFetchRequested>(_onPostsFetchRequested);
    on<UserProfilePostsRefreshRequested>(_onPostsRefreshRequested);
    on<UserProfilePostCreateRequested>(_onPostCreateRequested);
    on<UserProfilePostCreateStartRequested>(_onPostCreateStartRequested);
    on<UserProfilePostDeleteRequested>(_onPostDeleteRequested);
    on<UserProfilePostsChanged>(_onPostsChanged);

    add(const UserProfileSubscriptionRequested());
  }

  final UserRepository _userRepository;
  final PostsRepository _postsRepository;

  static const _postsPageSize = 10;
  int _shift = 0;
  Post? _newPost;

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
        _shift = 0;
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
      final shift = !fetchNewPage ? _shift : 0;

      final posts = await _postsRepository.fetchPosts(
        limit: _postsPageSize,
        offset: (_postsPageSize * currentPage) + shift,
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

      _shift = 0;

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
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(postsPage: state.postsPage.failure()));
    }
  }

  Future<List<Post>> _onPostsChanges({
    required ({Map<String, dynamic> newRecord, Map<String, dynamic> oldRecord})
    payload,
    Post? newPost,
  }) async {
    final posts = [...state.postsPage.items];
    final data = Map<String, dynamic>.from(payload.newRecord);
    final oldRecord = Map<String, dynamic>.from(payload.oldRecord);

    if (newPost != null) {
      posts.insert(0, newPost);
      _shift++;
      return posts;
    }
    if (oldRecord.length == 1 && oldRecord.containsKey('id')) {
      final index = posts.indexWhere((post) => post.id == oldRecord['id']);
      if (index == -1) return posts;
      posts.removeAt(index);
      _shift--;
      return posts;
    }
    if (_newPost != null) {
      posts.insert(0, _newPost!);
      _newPost = null;
      _shift++;
    } else {
      final json = Map<String, dynamic>.from(data);
      final post = Post.fromJson(json);
      posts.insert(0, post);
      _shift++;
    }
    return posts;
  }

  Future<void> _onPostsChanged(
    UserProfilePostsChanged event,
    Emitter<UserProfileState> emit,
  ) async {
    final payload = event.payload;
    final newPost = event.newPost;
    final posts = await _onPostsChanges(payload: payload, newPost: newPost);
    emit(state.copyWith(postsPage: state.postsPage.copyWith(items: posts)));
  }

  Future<void> _onPostCreateRequested(
    UserProfilePostCreateRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(state.copyWith(status: UserProfileStatus.postCreating));
      final createdAt = DateTime.now().toUtc().toIso8601String();
      final currentUser = await _userRepository.user.first;
      final post = Post(
        id: event.postId,
        content: event.content ?? '',
        attachments: event.attachments,
        createdAt: DateTime.parse(createdAt),
        author: PostAuthor.fromJson(
          currentUser.toJson()..putIfAbsent('is_owner', () => true),
        ),
        updatedAt: DateTime.parse(createdAt),
      );
      _newPost = post;
      await _postsRepository.createPost(
        id: post.id,
        content: event.content,
        attachments: event.attachments,
      );
      add(
        UserProfilePostsChanged((newRecord: {}, oldRecord: {}), newPost: post),
      );
      emit(
        state.copyWith(
          postsPage: state.postsPage.copyWith(
            totalLength: state.postsPage.totalLength + 1,
          ),
          status: UserProfileStatus.postCreated,
        ),
      );
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
      add(
        UserProfilePostsChanged((
          newRecord: {},
          oldRecord: {'id': event.postId},
        )),
      );
      emit(
        state.copyWith(
          postsPage: state.postsPage.copyWith(
            totalLength: state.postsPage.totalLength - 1,
          ),
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: UserProfileStatus.postDeleteFailed));
    }
  }
}
