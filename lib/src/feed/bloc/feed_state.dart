part of 'feed_bloc.dart';

enum FeedStatus {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == initial;
  bool get isLoading => this == loading;
  bool get isSuccess => this == success;
  bool get isFailure => this == failure;
}

class FeedState extends Equatable {
  const FeedState._({required this.status, required this.postsPage});

  const FeedState.initial()
    : this._(status: FeedStatus.initial, postsPage: const PostsPage.empty());

  final FeedStatus status;
  final PostsPage postsPage;

  @override
  List<Object?> get props => [status, postsPage];

  FeedState copyWith({FeedStatus? status, PostsPage? postsPage}) => FeedState._(
    status: status ?? this.status,
    postsPage: postsPage ?? this.postsPage,
  );
}
