import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/shared.dart';

part 'post.g.dart';

/// {@template date_time_from_milliseconds_since_epoch}
/// A converter for [DateTime] that matches the format of the database.
/// {@endtemplate}
class DateTimeFromMillisecondsSinceEpoch
    implements JsonConverter<DateTime, Object> {
  /// {@macro date_time_from_milliseconds_since_epoch}
  const DateTimeFromMillisecondsSinceEpoch();

  @override
  DateTime fromJson(Object json) {
    return switch (json) {
      final int value => DateTime.fromMillisecondsSinceEpoch(value),
      final String value => DateTime.parse(value),
      _ => DateTime.now().toUtc(),
    };
  }

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

/// {@template nullable_date_time_from_milliseconds_since_epoch}
/// A converter for nullable [DateTime] that matches the format of the database.
/// {@endtemplate}
class NullableDateTimeFromMillisecondsSinceEpoch
    implements JsonConverter<DateTime?, Object?> {
  /// {@macro nullable_date_time_from_milliseconds_since_epoch}
  const NullableDateTimeFromMillisecondsSinceEpoch();

  @override
  DateTime? fromJson(Object? json) {
    return switch (json) {
      final int value => DateTime.fromMillisecondsSinceEpoch(value),
      final String value => DateTime.parse(value),
      _ => null,
    };
  }

  @override
  int? toJson(DateTime? object) => object?.millisecondsSinceEpoch;
}

/// {@template post}
/// A post is a message created by a user.
/// {@endtemplate}
@JsonSerializable()
class Post extends Equatable {
  /// {@macro post}
  const Post({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.author,
    this.attachments = const [],
  });

  /// Create a new instance from a json
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  /// The id of the post.
  final String id;

  /// The content of the post.
  final String content;

  /// The author of the post.
  @JsonKey()
  final PostAuthor author;

  /// The attachments of the post.
  @JsonKey(includeIfNull: false)
  final List<Attachment> attachments;

  /// The date and time the post was created.
  @DateTimeFromMillisecondsSinceEpoch()
  final DateTime createdAt;

  /// The date and time the post was last updated.
  @DateTimeFromMillisecondsSinceEpoch()
  final DateTime updatedAt;

  /// Serialize to json
  Map<String, dynamic> toJson() => _$PostToJson(this);

  @override
  List<Object?> get props => [
    id,
    content,
    author,
    attachments,
    createdAt,
    updatedAt,
  ];
}
