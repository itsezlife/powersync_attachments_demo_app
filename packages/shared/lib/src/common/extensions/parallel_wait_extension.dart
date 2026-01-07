import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';

/// DON'T ADD THIS EXTENSION ON WEB. IT'S ONLY FOR FLUTTER.

/// {@template async_error}
/// Represents an error that occurred during an asynchronous operation.
/// {@endtemplate}
class AsyncError extends Equatable {
  /// {@macro async_error}
  const AsyncError({
    required this.error,
    required this.stackTrace,
  });

  /// The error that occurred.
  final Object error;

  /// The stack trace of the error.
  final StackTrace stackTrace;

  @override
  List<Object?> get props => [error, stackTrace];
}

/// {@template parallel_wait_error}
/// An error that contains both partial results and errors from parallel
/// operations.
/// {@endtemplate}
class ParallelWaitError<TValues, TErrors> extends Equatable
    implements Exception {
  /// {@macro parallel_wait_error}
  const ParallelWaitError({
    required this.values,
    required this.errors,
  });

  /// The values that were successfully resolved.
  final TValues values;

  /// The errors that occurred during the parallel operations.
  final TErrors errors;

  @override
  List<Object?> get props => [values, errors];
}

/// {@template parallel_wait_result}
/// The result of a parallel wait operation.
/// {@endtemplate}
class ParallelWaitResult<T> extends Equatable {
  /// {@macro parallel_wait_result}
  const ParallelWaitResult({
    required this.all,
    required this.successes,
    required this.failures,
    required this.hasFailures,
  });

  /// The results of all operations.
  final List<T?> all;

  /// The successful results.
  final List<T> successes;

  /// The failed operations with their errors.
  final List<({int index, Object error, StackTrace stackTrace})> failures;

  /// Whether there are any failures.
  final bool hasFailures;

  /// Whether all operations succeeded.
  bool get hasOnlySuccesses => !hasFailures;

  /// Whether all operations failed.
  bool get hasOnlyFailures => successes.isEmpty && failures.isNotEmpty;

  /// Whether there are both successes and failures.
  bool get hasPartialSuccess => successes.isNotEmpty && failures.isNotEmpty;

  /// The total number of operations.
  int get totalCount => successes.length + failures.length;

  @override
  List<Object?> get props => [all, successes, failures, hasFailures];
}

/// Enum representing different strategies for handling parallel wait errors.
enum ParallelWaitStrategy {
  /// Throw on any error (default Future.wait behavior).
  throwOnAnyError,

  /// Continue with partial results and provide detailed error information.
  continueWithPartialResults,

  /// Only throw if all operations fail.
  throwOnAllErrors,

  /// Collect all results and errors but never throw.
  collectAll,
}

/// {@template parallel_wait_options}
/// Options for configuring parallel wait behavior.
/// {@endtemplate}
class ParallelWaitOptions {
  /// {@macro parallel_wait_options}
  const ParallelWaitOptions({
    this.strategy = ParallelWaitStrategy.continueWithPartialResults,
    this.onError,
    this.maxConcurrency,
  });

  /// {@macro parallel_wait_options}
  const ParallelWaitOptions.throwOnAllErrors({
    void Function(int index, Object error, StackTrace stackTrace)? onError,
    int? maxConcurrency,
  }) : this(
         strategy: ParallelWaitStrategy.throwOnAllErrors,
         onError: onError,
         maxConcurrency: maxConcurrency,
       );

  /// The strategy to use for handling errors.
  final ParallelWaitStrategy strategy;

  /// Optional callback for handling individual errors.
  final void Function(int index, Object error, StackTrace stackTrace)? onError;

  /// Optional limit on the number of concurrent operations.
  final int? maxConcurrency;
}

/// Extension on [Iterable<Future<T>>] to provide parallel wait functionality.
extension ParallelWaitExtension<T> on Iterable<Future<T>> {
  /// Waits for all futures to complete with configurable error handling.
  ///
  /// This method provides different strategies for handling errors:
  /// - [ParallelWaitStrategy.throwOnAnyError]: Throws on the first error
  /// (default Future.wait behavior)
  /// - [ParallelWaitStrategy.continueWithPartialResults]: Returns partial
  /// results and detailed error info
  /// - [ParallelWaitStrategy.throwOnAllErrors]: Only throws if all operations
  /// fail
  /// - [ParallelWaitStrategy.collectAll]: Never throws, always returns results
  ///
  /// Example usage:
  /// ```dart
  /// // Basic usage with partial results strategy
  /// final result = await futures.waitWithStrategy();
  /// log('Successes: ${result.successes.length}');
  /// log('Failures: ${result.failures.length}');
  ///
  /// // With custom error handling
  /// final result = await futures.waitWithStrategy(
  ///   ParallelWaitOptions(
  ///     strategy: ParallelWaitStrategy.throwOnAllErrors,
  ///     onError: (index, error, stackTrace) {
  ///       logger.error('Operation $index failed: $error');
  ///     },
  ///     debugContext: 'FetchTickerDetails',
  ///   ),
  /// );
  /// ```
  Future<ParallelWaitResult<T>> waitWithStrategy([
    ParallelWaitOptions options = const ParallelWaitOptions(),
  ]) async {
    final futures = toList();
    if (futures.isEmpty) {
      return const ParallelWaitResult(
        all: [],
        successes: [],
        failures: [],
        hasFailures: false,
      );
    }

    final all = <T?>[]..length = futures.length;
    final successes = <T>[];
    final failures = <({int index, Object error, StackTrace stackTrace})>[];

    if (options.maxConcurrency != null) {
      // Handle concurrency limiting
      await _waitWithConcurrencyLimit(
        futures,
        options,
        successes,
        failures,
      );
    } else {
      // Process all futures in parallel
      final results = await Future.wait(
        futures.asMap().entries.map((entry) async {
          try {
            final result = await entry.value;
            return (success: result, error: null, index: entry.key);
          } on Object catch (error, stackTrace) {
            options.onError?.call(entry.key, error, stackTrace);
            return (
              success: null,
              error: (error: error, stackTrace: stackTrace),
              index: entry.key,
            );
          }
        }),
      );

      for (final result in results) {
        if (result.error != null) {
          all[result.index] = null;
          failures.add(
            (
              index: result.index,
              error: result.error!.error,
              stackTrace: result.error!.stackTrace,
            ),
          );
        } else {
          all[result.index] = result.success as T;
          successes.add(result.success as T);
        }
      }
    }

    final result = ParallelWaitResult<T>(
      all: all,
      successes: successes,
      failures: failures,
      hasFailures: failures.isNotEmpty,
    );

    // Apply strategy
    switch (options.strategy) {
      case ParallelWaitStrategy.throwOnAnyError:
        if (result.hasFailures) {
          final firstFailure = failures.first;
          Error.throwWithStackTrace(
            firstFailure.error,
            firstFailure.stackTrace,
          );
        }

      case ParallelWaitStrategy.throwOnAllErrors:
        if (result.hasOnlyFailures) {
          final firstFailure = failures.first;
          Error.throwWithStackTrace(
            firstFailure.error,
            firstFailure.stackTrace,
          );
        }

      case ParallelWaitStrategy.continueWithPartialResults:
      case ParallelWaitStrategy.collectAll:
        // Return results as-is
        break;
    }

    return result;
  }

  /// Legacy wait method that matches the existing codebase behavior.
  ///
  /// This method throws a [ParallelWaitError] when some operations fail,
  /// maintaining compatibility with existing error handling patterns.
  Future<List<T>> get waitCustom async {
    final futures = toList();
    if (futures.isEmpty) return [];

    final results = <T>[];
    final errors = <AsyncError?>[];

    final completedResults = await Future.wait(
      futures.asMap().entries.map((entry) async {
        try {
          final result = await entry.value;
          return (success: result, error: null, index: entry.key);
        } on Object catch (error, stackTrace) {
          return (
            success: null,
            error: AsyncError(error: error, stackTrace: stackTrace),
            index: entry.key,
          );
        }
      }),
    );

    // Initialize arrays with correct size
    results.length = futures.length;
    errors.length = futures.length;

    for (final result in completedResults) {
      if (result.error != null) {
        errors[result.index] = result.error;
      } else {
        results[result.index] = result.success as T;
        errors[result.index] = null;
      }
    }

    // Check if there are any errors
    final hasErrors = errors.any((error) => error != null);
    if (hasErrors) {
      throw ParallelWaitError<List<T>, List<AsyncError?>>(
        values: results,
        errors: errors,
      );
    }

    return results;
  }

  /// Waits for all futures with a timeout.
  Future<ParallelWaitResult<T>> waitWithTimeout(
    Duration timeout, [
    ParallelWaitOptions options = const ParallelWaitOptions(),
  ]) async {
    try {
      return await waitWithStrategy(options).timeout(timeout);
    } on TimeoutException catch (error, stackTrace) {
      if (options.strategy == ParallelWaitStrategy.collectAll) {
        return ParallelWaitResult<T>(
          all: const [],
          successes: const [],
          failures: [(index: -1, error: error, stackTrace: stackTrace)],
          hasFailures: true,
        );
      }
      rethrow;
    }
  }

  /// Helper method to handle concurrency limiting
  Future<void> _waitWithConcurrencyLimit(
    List<Future<T>> futures,
    ParallelWaitOptions options,
    List<T> successes,
    List<({int index, Object error, StackTrace stackTrace})> failures,
  ) async {
    final semaphore = _Semaphore(options.maxConcurrency!);
    final tasks = futures.asMap().entries.map((entry) async {
      await semaphore.acquire();
      try {
        final result = await entry.value;
        successes.add(result);
      } on Object catch (error, stackTrace) {
        options.onError?.call(entry.key, error, stackTrace);
        failures.add(
          (
            index: entry.key,
            error: error,
            stackTrace: stackTrace,
          ),
        );
      } finally {
        semaphore.release();
      }
    });

    await Future.wait(tasks);
  }
}

/// Utility extensions for working with parallel wait results.
extension ParallelWaitResultExtensions<T> on ParallelWaitResult<T> {
  /// Returns failures for specific indices.
  List<({int index, Object error, StackTrace stackTrace})> failuresForIndices(
    List<int> indices,
  ) {
    return failures.where((f) => indices.contains(f.index)).toList();
  }

  /// Returns the first N successes.
  List<T> takeSuccesses(int count) {
    return successes.take(count).toList();
  }

  /// Retries failed operations with a new set of futures.
  Future<ParallelWaitResult<T>> retryFailures(
    List<Future<T>> retryFutures, [
    ParallelWaitOptions options = const ParallelWaitOptions(),
  ]) async {
    if (retryFutures.length != failures.length) {
      throw ArgumentError(
        'Retry futures count (${retryFutures.length}) must match '
        'failures count (${failures.length})',
      );
    }

    final retryResult = await retryFutures.waitWithStrategy(options);

    return ParallelWaitResult<T>(
      all: [...all, ...retryResult.all],
      successes: [...successes, ...retryResult.successes],
      failures: retryResult.failures,
      hasFailures: retryResult.hasFailures,
    );
  }
}

/// Simple semaphore implementation for concurrency limiting.
class _Semaphore {
  _Semaphore(this._maxCount) : _currentCount = 0;

  final int _maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Future<void> acquire() async {
    if (_currentCount < _maxCount) {
      _currentCount++;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst().complete();
    } else {
      _currentCount--;
    }
  }
}
