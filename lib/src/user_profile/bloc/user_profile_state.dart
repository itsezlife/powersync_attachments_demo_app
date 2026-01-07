part of 'user_profile_bloc.dart';

enum UserProfileStatus {
  initial,
  userLoading,
  userPopulated,
  userNotFound,
  userUpdated,
  postDeleted,
  postDeleteFailed,
  postCreating,
  postCreateFailed,
  postCreated;

  bool get isInitial => this == UserProfileStatus.initial;
  bool get isUserLoading => this == UserProfileStatus.userLoading;
  bool get isUserNotFound => this == UserProfileStatus.userNotFound;
  bool get isUserPopulated => this == UserProfileStatus.userPopulated;
  bool get isUserUpdated => this == UserProfileStatus.userUpdated;
  bool get isPostDeleted => this == UserProfileStatus.postDeleted;
  bool get isPostDeleteFailed => this == UserProfileStatus.postDeleteFailed;
  bool get isPostCreating => this == UserProfileStatus.postCreating;
  bool get isPostCreateFailed => this == UserProfileStatus.postCreateFailed;
  bool get isPostCreated => this == UserProfileStatus.postCreated;
}

enum UserProfileFollowStatus {
  initial,
  loading,
  success,
  failure;

  bool get isInitial => this == UserProfileFollowStatus.initial;
  bool get isLoading => this == UserProfileFollowStatus.loading;
  bool get isSuccess => this == UserProfileFollowStatus.success;
  bool get isFailure => this == UserProfileFollowStatus.failure;
}

enum FollowersStatus {
  initial,
  loading,
  populated,
  failure;

  bool get isInitial => this == FollowersStatus.initial;
  bool get isLoading => this == FollowersStatus.loading;
  bool get isPopulated => this == FollowersStatus.populated;
  bool get isFailure => this == FollowersStatus.failure;
}

enum FollowingsStatus {
  initial,
  loading,
  populated,
  failure;

  bool get isInitial => this == FollowingsStatus.initial;
  bool get isLoading => this == FollowingsStatus.loading;
  bool get isPopulated => this == FollowingsStatus.populated;
  bool get isFailure => this == FollowingsStatus.failure;
}

class UserProfileState extends Equatable {
  const UserProfileState._({
    required this.user,
    required this.postsPage,
    this.status = UserProfileStatus.initial,
  });

  const UserProfileState.initial()
    : this._(user: User.anonymous, postsPage: const PostsPage.empty());

  final UserProfileStatus status;
  final User user;
  final PostsPage postsPage;

  @override
  List<Object> get props => [status, user, postsPage];

  UserProfileState copyWith({
    UserProfileStatus? status,
    User? user,
    PostsPage? postsPage,
  }) => UserProfileState._(
    status: status ?? this.status,
    user: user ?? this.user,
    postsPage: postsPage ?? this.postsPage,
  );
}
