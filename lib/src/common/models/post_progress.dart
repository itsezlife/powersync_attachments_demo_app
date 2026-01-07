import 'package:equatable/equatable.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

/// {@template post_progress}
/// A model that represents the progress of a post.
/// {@endtemplate}
class PostProgress extends Equatable {
  /// {@macro post_progress}
  const PostProgress({
    required this.postId,
    required this.asset,
    required this.value,
    this.hasError,
  });

  /// The ID of the post.
  final String postId;

  /// The asset entity.
  final AssetEntity asset;

  /// The progress value.
  final double value;

  /// Whether the post has an error.
  final bool? hasError;

  @override
  List<Object?> get props => [postId, asset, value, hasError];
}
