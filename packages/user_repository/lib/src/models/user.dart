import 'package:authentication_client/authentication_client.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

String _userIdReadValue(Map<dynamic, dynamic> json, String key) =>
    json['user_id'] as String? ?? json[key] as String;

/// {@template user}
/// User model represents the current user.
/// {@endtemplate}
@JsonSerializable()
class User extends AuthenticationUser {
  /// {@macro user}
  const User({
    required super.id,
    super.email,
    super.name,
    super.avatarUrl,
    super.isNewUser,
  });

  /// Converts an [AuthenticationUser] instance to [User].
  factory User.fromAuthenticationUser(AuthenticationUser authenticationUser) =>
      User(
        email: authenticationUser.email,
        id: authenticationUser.id,
        name: authenticationUser.name,
        avatarUrl: authenticationUser.avatarUrl,
        isNewUser: authenticationUser.isNewUser,
      );

  /// Converts a `Map<String, dynamic>` json to a [User] instance.
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Whether the current user is anonymous.
  @override
  bool get isAnonymous => this == anonymous || id.isEmpty;

  /// The ID of the user.
  @override
  @JsonKey(readValue: _userIdReadValue)
  String get id;

  /// Anonymous user which represents an unauthenticated user.
  static const User anonymous = User(id: '');

  /// The effective name display without null aware operators.
  /// By default no existing name value is `Unknown`.
  String get displayName => name ?? 'Unknown';

  /// The initials of the user's name.
  String get initials {
    if (name == null) return '';
    final nameParts = name!.split(' ');
    final firstLetter = nameParts[0][0].toUpperCase();
    final secondLetter = (nameParts.length > 1)
        ? nameParts[1][0].toUpperCase()
        : null;
    return firstLetter == secondLetter || secondLetter == null
        ? firstLetter
        : firstLetter + secondLetter;
  }

  /// Converts current [User] instance to a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    bool? isNewUser,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    isNewUser: isNewUser ?? this.isNewUser,
  );
}
