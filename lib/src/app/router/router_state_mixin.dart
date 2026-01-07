import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/bloc/app_bloc.dart';
import 'package:powersync_attachments_example/src/app/router/guards/authentication_guard.dart';
import 'package:powersync_attachments_example/src/app/router/guards/home_guard.dart';
import 'package:powersync_attachments_example/src/app/router/guards/tabs_guard.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:user_repository/user_repository.dart';

mixin RouterStateMixin<T extends StatefulWidget> on State<T> {
  User get user;

  late final Octopus router;
  late final ValueNotifier<List<({Object error, StackTrace stackTrace})>>
  errorsObserver;

  @override
  void initState() {
    // Observe all errors.
    errorsObserver =
        ValueNotifier<List<({Object error, StackTrace stackTrace})>>(
          <({Object error, StackTrace stackTrace})>[],
        );

    final appBloc = context.read<AppBloc>();

    // Create router.
    router = Octopus(
      routes: Routes.values,
      defaultRoute: user.isAnonymous ? Routes.auth : Routes.home,
      transitionDelegate: const DefaultTransitionDelegate<void>(),
      duplicateStrategy: OctopusDuplicateStrategy.allow,
      guards: [
        // Check authentication.
        AuthenticationGuard(
          // Get current user from app bloc.
          getUser: () => appBloc.state.user,
          // Available routes for non authenticated user.
          routes: {Routes.auth.name},
          // Default route for non authenticated user.
          signinNavigation: OctopusState.single(Routes.auth.node()),
          // Default route for authenticated user.
          homeNavigation: OctopusState.single(Routes.home.node()),
          // Check authentication on every app bloc state change.
          refresh: OctopusGuardRefreshStream(appBloc.stream),
        ),
        // Home route should be always on top.
        HomeGuard(),
        // Home tabs guard.
        HomeTabsGuard(),
      ],
      onError: (error, stackTrace) =>
          errorsObserver.value = <({Object error, StackTrace stackTrace})>[
            (error: error, stackTrace: stackTrace),
            ...errorsObserver.value,
          ],
    );

    super.initState();
  }
}

/// {@template octopus_guard_refresh_stream}
/// A [ChangeNotifier] that notifies listeners when a [Stream] emits a value.
/// This is used to refresh the guard when the [Stream] emits a new value.
/// {@endtemplate}
class OctopusGuardRefreshStream extends ChangeNotifier {
  /// {@macro octopus_guard_refresh_stream}
  OctopusGuardRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((value) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
