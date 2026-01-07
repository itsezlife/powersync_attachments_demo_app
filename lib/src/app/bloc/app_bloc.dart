import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:user_repository/user_repository.dart';

part 'app_event.dart';
part 'app_state.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({required User user, required UserRepository userRepository})
    : _userRepository = userRepository,
      super(
        user == User.anonymous
            ? const AppState.unauthenticated()
            : AppState.authenticated(user),
      ) {
    on<AppLogoutRequested>(_onAppLogoutRequested);
    on<AppUserChanged>(_onUserChanged);

    _userSubscription = userRepository.user.listen(
      _userChanged,
      onError: addError,
    );
  }

  final UserRepository _userRepository;

  StreamSubscription<User>? _userSubscription;

  void _userChanged(User user) => add(AppUserChanged(user));

  Future<void> _onUserChanged(
    AppUserChanged event,
    Emitter<AppState> emit,
  ) async {
    final user = event.user;

    switch (state.status) {
      case AppStatus.authenticated:
        if (user == User.anonymous) {
          emit(const AppState.unauthenticated());
        } else {
          emit(state.copyWith(user: user));
        }
      case AppStatus.unauthenticated:
        if (user == User.anonymous) {
          emit(const AppState.unauthenticated());
        } else {
          emit(AppState.authenticated(user));
        }
    }
  }

  Future<void> _onAppLogoutRequested(
    AppLogoutRequested event,
    Emitter<AppState> emit,
  ) async {
    try {
      await _userRepository.logOut();
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
