part of 'user_profile_bloc.dart';

sealed class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

final class UserProfileSubscriptionRequested extends UserProfileEvent {
  const UserProfileSubscriptionRequested();
}

final class UserProfileChanged extends UserProfileEvent {
  const UserProfileChanged(this.user);

  final User user;

  @override
  List<Object> get props => [user];
}

final class UserProfilePostsFetchRequested extends UserProfileEvent {
  const UserProfilePostsFetchRequested({this.page});

  final int? page;

  @override
  List<Object?> get props => [page];
}

final class UserProfilePostsRefreshRequested extends UserProfileEvent {
  const UserProfilePostsRefreshRequested();
}

final class UserProfilePostsChanged extends UserProfileEvent {
  const UserProfilePostsChanged(this.payload, {this.newPost});

  final ({Map<String, dynamic> newRecord, Map<String, dynamic> oldRecord})
  payload;
  final Post? newPost;

  @override
  List<Object?> get props => [payload, newPost];
}

final class UserProfilePostCreateStartRequested extends UserProfileEvent {
  const UserProfilePostCreateStartRequested();
}

final class UserProfilePostCreateRequested extends UserProfileEvent {
  const UserProfilePostCreateRequested({
    required this.postId,
    this.content,
    this.attachments = const [],
  });

  final String postId;
  final String? content;
  final List<Attachment> attachments;

  @override
  List<Object?> get props => [postId, content, attachments];
}

final class UserProfilePostDeleteRequested extends UserProfileEvent {
  const UserProfilePostDeleteRequested({required this.postId});

  final String postId;

  @override
  List<Object> get props => [postId];
}