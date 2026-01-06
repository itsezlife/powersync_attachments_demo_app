import 'package:flutter/material.dart';
import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/home_guard.dart';
import 'package:powersync_attachments_example/src/app/router/route_tracker.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:powersync_attachments_example/src/app/router/tabs_guard.dart';

mixin RouterStateMixin<T extends StatefulWidget> on State<T> {
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

    // Create router.
    router = Octopus(
      routes: Routes.values,
      defaultRoute: Routes.home,
      transitionDelegate: const DefaultTransitionDelegate<void>(),
      duplicateStrategy: OctopusDuplicateStrategy.allow,
      guards: [
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

  void setupRouteTracking(Octopus router) {
    try {
      // Track initial route
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = router.state;
        RouteTracker.instance.updateRoute(state);
      });

      // Listen to route changes
      router.observer.addListener(() {
        final state = router.state;
        RouteTracker.instance.updateRoute(state);
      });
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'RouterStateMixin',
          context: ErrorDescription('Error setting up route tracking'),
        ),
      );
    }
  }
}
