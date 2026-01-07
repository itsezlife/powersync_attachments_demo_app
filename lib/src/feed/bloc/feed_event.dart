part of 'feed_bloc.dart';

sealed class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

final class FeedPostsRequested extends FeedEvent {
  const FeedPostsRequested({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

final class FeedPostsRefreshRequested extends FeedEvent {
  const FeedPostsRefreshRequested();
}
