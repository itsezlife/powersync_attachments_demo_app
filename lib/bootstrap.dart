import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:persistent_storage/persistent_storage.dart';
import 'package:powersync_client/powersync_client.dart';
import 'package:shared/shared.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('onCreate(${bloc.runtimeType})', name: 'AppBlocObserver');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}): $change', name: 'AppBlocObserver');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    log('onEvent(${bloc.runtimeType}): $event', name: 'AppBlocObserver');
    super.onEvent(bloc, event);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log(
      'onError(${bloc.runtimeType})',
      error: error,
      stackTrace: stackTrace,
      name: 'AppBlocObserver',
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    log('onClose(${bloc.runtimeType})', name: 'AppBlocObserver');
    super.onClose(bloc);
  }
}

Future<void> bootstrap(
  FutureOr<Widget> Function(
    PowerSyncClient powerSyncClient,
    SharedPreferencesWithCache sharedPreferences,
    PersistentListStorage listStorage,
  )
  builder,
) async {
  FlutterError.onError = (details) {
    log(
      'Flutter error.',
      name: 'bootstrap',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        Config.appDocsPath = (await getApplicationDocumentsDirectory()).path;
      } on Object catch (error, stackTrace) {
        log(
          'Error getting application documents directory.',
          name: 'bootstrap',
          error: error,
          stackTrace: stackTrace,
        );
      }

      if (kDebugMode) Bloc.observer = const AppBlocObserver();

      final sharedPreferences = await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      );

      final listStorage = PersistentListStorage(
        sharedPreferences: sharedPreferences,
      );

      final powerSyncClient = PowerSyncClient(
        env: Config.getEnv,
        listStorage: listStorage,
      );

      await Future.wait<dynamic>([
        powerSyncClient.initialize(),
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]),
      ]);

      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // if (kDebugMode) {
      //   await CachedNetworkImageProvider.defaultCacheManager.emptyCache();
      // }

      /// This is to ensure that events are processed sequentially.
      // Bloc.transformer = sequential();

      // if (kDebugMode) {
      //   await HydratedBloc.storage.clear();
      // }

      runApp(await builder(powerSyncClient, sharedPreferences, listStorage));
    },
    (error, stackTrace) {
      log(
        'Root Error.',
        name: 'bootstrap',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
