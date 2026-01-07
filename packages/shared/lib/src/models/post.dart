import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/shared.dart';

part 'post.g.dart';

/// {@template bool_json_converter}
/// A converter for [bool] to [int] and vice versa.
/// {@endtemplate}
class BoolJsonConverter implements JsonConverter<bool, Object> {
  /// {@macro bool_json_converter}
  const BoolJsonConverter({this.defaultValue = false});

  /// The default value to return if the JSON value is null.
  final bool defaultValue;

  @override
  bool fromJson(Object json) {
    return switch (json) {
      final int value => value != 0,
      final bool value => value,
      _ => defaultValue,
    };
  }

  @override
  bool toJson(bool object) => object;
}

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
    this.localOnly = false,
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

  /// Whether the post is local only.
  @BoolJsonConverter()
  final bool localOnly;

  /// Serialize to json
  Map<String, dynamic> toJson() => _$PostToJson(this);

  /// Create a new instance with the given properties changed.
  Post copyWith({
    String? id,
    String? content,
    PostAuthor? author,
    List<Attachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? localOnly,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      localOnly: localOnly ?? this.localOnly,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    author,
    attachments,
    createdAt,
    updatedAt,
    localOnly,
  ];
}
