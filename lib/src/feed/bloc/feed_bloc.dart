import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';

part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({required PostsRepository postsRepository})
    : _postsRepository = postsRepository,
      super(const FeedState.initial()) {
    on<FeedPostsRequested>(_onFeedPostsRequested);
    on<FeedPostsRefreshRequested>(_onFeedPostsRefreshRequested);
  }

  final PostsRepository _postsRepository;

  static const _postsPageSize = 10;

  Future<void> _onFeedPostsRequested(
    FeedPostsRequested event,
    Emitter<FeedState> emit,
  ) async {
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
      );

      final newPage = currentPage + 1;
      final hasMore = posts.length >= _postsPageSize;

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

  Future<void> _onFeedPostsRefreshRequested(
    FeedPostsRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    try {
      emit(state.copyWith(postsPage: state.postsPage.loading()));

      const currentPage = 0;

      final posts = await _postsRepository.fetchPosts(
        limit: _postsPageSize,
        offset: _postsPageSize * currentPage,
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
}
