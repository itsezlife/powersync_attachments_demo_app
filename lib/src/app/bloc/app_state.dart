part of 'app_bloc.dart';

/// {@template app_status}
/// The status of the application. Used to determine which page to show when
/// the application is started.
/// {@endtemplate}
enum AppStatus {
  /// The user is authenticated. Show `MainPage`.
  authenticated,

  /// The user is not authenticated or the authentication status is unknown.
  /// Show `AuthPage`.
  unauthenticated;

  bool get isAuthenticated => this == AppStatus.authenticated;
  bool get isUnauthenticated => this == AppStatus.unauthenticated;
}

/// {@template active_route_status}
/// The status of the active route.
/// {@endtemplate}
enum ActiveRouteStatus {
  /// The active route is not being fetched.
  initial,

  /// The active route is being fetched.
  loading,

  /// The active route is not set.
  notSet,

  /// The active route is set.
  set,
}

class AppState extends Equatable {
  const AppState({required this.status, this.user = User.anonymous});

  const AppState.authenticated(User user)
    : this(status: AppStatus.authenticated, user: user);

  const AppState.unauthenticated()
    : this(status: AppStatus.unauthenticated, user: User.anonymous);

  final AppStatus status;
  final User user;

  AppState copyWith({User? user, AppStatus? status}) =>
      AppState(user: user ?? this.user, status: status ?? this.status);

  @override
  List<Object?> get props => [status, user];
}
