import 'package:json_annotation/json_annotation.dart';
import 'package:user_repository/user_repository.dart';

part 'post_author.g.dart';

/// {@template post_author}
/// The representation of post author.
/// {@endtemplate}
@JsonSerializable()
class PostAuthor extends User {
  /// {@macro post_author}
  const PostAuthor({
    required super.id,
    required super.name,
    super.avatarUrl,
    this.isConfirmed = false,
    this.isOwner = false,
  });

  /// Deserialize [json] into a [PostAuthor] instance.
  factory PostAuthor.fromJson(Map<String, dynamic> json) =>
      _$PostAuthorFromJson(json);

  /// The anonymous post author instance.
  static const anonymous = PostAuthor(id: '', name: '');

  /// Whether the user is confirmed by the Reel Meals staff.
  final bool isConfirmed;

  /// Whether the current user is the owner of the post.
  final bool isOwner;

  /// Copy with new values.
  @override
  PostAuthor copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? email,
    bool? isNewUser,
    bool? isConfirmed,
    bool? isOwner,
  }) {
    return PostAuthor(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isOwner: isOwner ?? this.isOwner,
    );
  }

  /// Convert current instance to a `Map<String, dynamic>`.
  @override
  Map<String, dynamic> toJson() => _$PostAuthorToJson(this);

  @override
  List<Object?> get props => [
    ...super.props,
    isConfirmed,
    isOwner,
  ];
}
