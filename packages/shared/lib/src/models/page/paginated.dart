import 'package:equatable/equatable.dart';

/// {@template paginated}
/// A representation of a paginated list of items.
/// {@endtemplate}
abstract class Paginated<T> extends Equatable {
  /// {@macro paginated}
  const Paginated({
    required this.currentPage,
    required this.hasMore,
    required this.totalLength,
    required this.items,
  });

  /// {@macro paginated.empty}
  const Paginated.empty()
    : this(
        currentPage: 0,
        hasMore: false,
        totalLength: 0,
        items: const [],
      );

  /// The current page number.
  final int currentPage;

  /// Whether there are more pages available.
  final bool hasMore;

  /// The total number of items across all pages.
  final int totalLength;

  /// The items in the current page.
  final List<T> items;

  @override
  List<Object?> get props => [currentPage, hasMore, totalLength, items];
}
