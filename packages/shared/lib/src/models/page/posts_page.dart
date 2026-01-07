import 'package:json_annotation/json_annotation.dart';
import 'package:shared/shared.dart';

part 'posts_page.g.dart';

/// The status of the [PostsPage].
enum PostsPageTotalLengthStatus {
  /// The initial status.
  initial,

  /// The loading status.
  loading,

  /// The populated status.
  populated,

  /// The failure status.
  failure;

  /// Whether the status is the initial status.
  bool get isInitial => this == initial;

  /// Whether the status is the loading status.
  bool get isLoading => this == loading;

  /// Whether the status is the populated status.
  bool get isPopulated => this == populated;

  /// Whether the status is the failure status.
  bool get isFailure => this == failure;
}

/// The status of the [PostsPage].
enum PostsPageStatus {
  /// The initial status.
  initial,

  /// The loading status.
  loading,

  /// The next page loading status.
  nextPageLoading,

  /// The populated status.
  populated,

  /// The failure status.
  failure,

  /// The page failure status.
  nextPageFailure;

  /// Whether the status is the initial status.
  bool get isInitial => this == initial;

  /// Whether the status is the loading status.
  bool get isLoading => this == loading;

  /// Whether the status is the next page loading status.
  bool get isNextPageLoading => this == nextPageLoading;

  /// Whether the status is the populated status.
  bool get isPopulated => this == populated;

  /// Whether the status is the failure status.
  bool get isFailure => this == failure;

  /// Whether the status is the page failure status.
  bool get isNextPageFailure => this == nextPageFailure;

  /// Pattern matching for [PostsPageStatus].
  T map<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function() nextPageLoading,
    required T Function() populated,
    required T Function() failure,
    required T Function() nextPageFailure,
  }) {
    switch (this) {
      case PostsPageStatus.initial:
        return initial();
      case PostsPageStatus.loading:
        return loading();
      case PostsPageStatus.nextPageLoading:
        return nextPageLoading();
      case PostsPageStatus.populated:
        return populated();
      case PostsPageStatus.failure:
        return failure();
      case PostsPageStatus.nextPageFailure:
        return nextPageFailure();
    }
  }

  /// Pattern matching for [PostsPageStatus] with nullable return.
  T? mapOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function()? nextPageLoading,
    T Function()? populated,
    T Function()? failure,
    T Function()? nextPageFailure,
  }) {
    switch (this) {
      case PostsPageStatus.initial:
        return initial?.call();
      case PostsPageStatus.loading:
        return loading?.call();
      case PostsPageStatus.nextPageLoading:
        return nextPageLoading?.call();
      case PostsPageStatus.populated:
        return populated?.call();
      case PostsPageStatus.failure:
        return failure?.call();
      case PostsPageStatus.nextPageFailure:
        return nextPageFailure?.call();
    }
  }

  /// Pattern matching for [PostsPageStatus] with optional orElse.
  T maybeMap<T>({
    required T Function() orElse,
    T Function()? initial,
    T Function()? loading,
    T Function()? nextPageLoading,
    T Function()? populated,
    T Function()? failure,
    T Function()? nextPageFailure,
  }) {
    switch (this) {
      case PostsPageStatus.initial:
        return initial?.call() ?? orElse();
      case PostsPageStatus.loading:
        return loading?.call() ?? orElse();
      case PostsPageStatus.nextPageLoading:
        return nextPageLoading?.call() ?? orElse();
      case PostsPageStatus.populated:
        return populated?.call() ?? orElse();
      case PostsPageStatus.failure:
        return failure?.call() ?? orElse();
      case PostsPageStatus.nextPageFailure:
        return nextPageFailure?.call() ?? orElse();
    }
  }
}

/// {@template posts_page}
/// A representation of Instagram posts page.
/// {@endtemplate}
@JsonSerializable()
class PostsPage extends Paginated<Post> {
  /// {@macro posts_page}
  const PostsPage({
    required super.items,
    required super.totalLength,
    required super.currentPage,
    required super.hasMore,
    required this.id,
    this.needsRebuild = true,
    this.status = PostsPageStatus.initial,
    this.totalLengthStatus = PostsPageTotalLengthStatus.initial,
  });

  /// Converts a `Map<String, dynamic>` into a [PostsPage] instance.
  factory PostsPage.fromJson(Map<String, dynamic> json) =>
      _$PostsPageFromJson(json);

  /// {@macro posts_page.empty}
  const PostsPage.empty()
    : id = '',
      status = PostsPageStatus.initial,
      totalLengthStatus = PostsPageTotalLengthStatus.initial,
      needsRebuild = true,
      super.empty();

  /// {@macro posts_page.loading}
  PostsPage loading() => copyWith(status: PostsPageStatus.loading);

  /// {@macro posts_page.failure}
  PostsPage failure() => copyWith(status: PostsPageStatus.failure);

  /// {@macro posts_page.next_page_failure}
  PostsPage nextPageFailure() =>
      copyWith(status: PostsPageStatus.nextPageFailure);

  /// {@macro posts_page.next_page_loading}
  PostsPage nextPageLoading() =>
      copyWith(status: PostsPageStatus.nextPageLoading);

  /// {@macro posts_page.populated}
  PostsPage populated({
    String? id,
    List<Post>? posts,
    int? totalLength,
    int? currentPage,
    bool? hasMore,
    bool? needsRebuild,
    PostsPageTotalLengthStatus? totalLengthStatus,
  }) => copyWith(
    id: id ?? this.id,
    items: posts ?? items,
    totalLength: totalLength ?? this.totalLength,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    needsRebuild: needsRebuild ?? this.needsRebuild,
    status: PostsPageStatus.populated,
    totalLengthStatus: totalLengthStatus ?? this.totalLengthStatus,
  );

  /// {@macro posts_page.total_length_loading}
  PostsPage totalLengthLoading() =>
      copyWith(totalLengthStatus: PostsPageTotalLengthStatus.loading);

  /// {@macro posts_page.total_length_populated}
  PostsPage totalLengthPopulated({
    int? totalLength,
  }) => copyWith(
    totalLength: totalLength ?? this.totalLength,
    totalLengthStatus: PostsPageTotalLengthStatus.populated,
  );

  /// The blocks inside the posts page.
  List<Post> get posts => super.items;

  /// The unique identifier of the page. Used to check whether previous page
  /// is different from new page by checking ids, instead of checking all
  /// properties which is not accurate.
  final String id;

  /// The status of the [PostsPage].
  final PostsPageStatus status;

  /// The status of the [PostsPage].
  final PostsPageTotalLengthStatus totalLengthStatus;

  /// Whether the [PostsPage] needs to be rebuilt.
  final bool needsRebuild;

  /// Converts current instance into a `Map<String, dynamic>`.
  Map<String, dynamic> toJson() => _$PostsPageToJson(this);

  @override
  List<Object?> get props => [
    id,
    status,
    totalLengthStatus,
    needsRebuild,
    ...super.props,
  ];

  /// Copies the current [PostsPage] instance and overrides the provided
  /// properties.
  PostsPage copyWith({
    List<Post>? items,
    int? totalLength,
    int? currentPage,
    bool? hasMore,
    String? id,
    PostsPageStatus? status,
    PostsPageTotalLengthStatus? totalLengthStatus,
    bool? needsRebuild,
  }) {
    return PostsPage(
      items: items ?? this.items,
      totalLength: totalLength ?? this.totalLength,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      id: id ?? this.id,
      status: status ?? this.status,
      totalLengthStatus: totalLengthStatus ?? this.totalLengthStatus,
      needsRebuild: needsRebuild ?? this.needsRebuild,
    );
  }
}
