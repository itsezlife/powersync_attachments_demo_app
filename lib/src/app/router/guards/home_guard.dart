import 'dart:async';

import 'package:octopus/octopus.dart';
import 'package:powersync_attachments_example/src/app/router/routes.dart';
import 'package:user_repository/user_repository.dart';

/// Check routes always contain the home route at the first position.
class HomeGuard extends OctopusGuard {
  HomeGuard();

  static final String _homeName = Routes.home.name;

  @override
  FutureOr<OctopusState> call(
    List<OctopusHistoryEntry> history,
    OctopusState$Mutable state,
    Map<String, Object?> context,
  ) {
    final user = context['user'];
    if (user case final User user when user.isAnonymous) {
      return state;
    }
    
    // Home route should be the first route in the state
    // and should be only one in whole state.
    if (state.isEmpty) return _fix(state);
    final count = state.findAllByName(_homeName).length;
    if (count != 1) return _fix(state);
    if (state.children.first.name != _homeName) return _fix(state);
    return state;
  }

  /// Change the state of the nested navigation.
  OctopusState _fix(OctopusState$Mutable state) => state
    ..clear()
    ..putIfAbsent(_homeName, () => Routes.home.node());
}
