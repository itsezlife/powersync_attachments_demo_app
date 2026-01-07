import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/widgets/cached_network_image_with_minithumbnail.dart';
import 'package:shared/shared.dart';

class PostAttachment extends StatelessWidget {
  const PostAttachment({
    required this.post,
    required this.attachment,
    super.key,
  });

  final Post post;
  final Attachment attachment;

  static const double height = 200;
  static const double width = 200;

  static const double _kMinimumProgress = 0;

  @override
  Widget build(BuildContext context) {
    final imageUrl = attachment.imageUrl;

    final state = attachment.uploadState;
    final progress = state.map<double>(
      preparing: (_) => _kMinimumProgress,
      inProgress: (value) =>
          max(value.uploaded / value.total, _kMinimumProgress),
      success: (_) => 1,
      failed: (_) => 0,
    );

    // Complex conditional logic for visibility based on message localOnly
    // status and attachment count
    final isVisible = state.maybeMap(
      success: (_) {
        // If post is localOnly and has multiple attachments, keep visible
        // to show success checkmark
        if (post.localOnly && post.attachments.length > 1) {
          return true;
        }
        // If post is localOnly and has single attachment, hide only when
        // localOnly becomes false
        if (post.localOnly && post.attachments.length == 1) {
          return true;
        }
        // If post is not localOnly, hide (existing behavior)
        return false;
      },
      orElse: () => true,
    );

    // Show success checkmark only for localOnly messages with multiple
    // attachments when upload succeeds
    final showSuccessCheckmark =
        post.localOnly && post.attachments.length > 1 && state.isSuccess;

    return Stack(
      children: [
        CachedNetworkImageWithMinithumbnail(
          height: height,
          width: width,
          // Just for simplicity, we use the same height as for the image
          cacheWidth: height.toInt(),
          cacheHeight: null,
          url: switch (imageUrl) {
            final String value => value,
            _ => '',
          },
          file: File(switch (attachment.file?.path) {
            final String value when imageUrl == null => value,
            _ => Config.appDocsPath.resolveFilePath(imageUrl!.split('/').last),
          }),
          fit: BoxFit.cover,
          minithumbnail: attachment.minithumbnail?.toMinithumbnailData(),
        ),
        if (isVisible)
          Positioned(
            bottom: 8,
            right: 8,
            child: PostAttachmentProgress(
              showSuccessCheckmark: showSuccessCheckmark,
              progress: progress,
            ),
          ),
      ],
    );
  }
}

class PostAttachmentPlaceholder extends StatelessWidget {
  const PostAttachmentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: PostAttachment.height,
    child: ColoredBox(color: context.theme.colorScheme.surfaceContainerHighest),
  );
}

class PostAttachmentError extends StatelessWidget {
  const PostAttachmentError({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: PostAttachment.height,
    child: ColoredBox(
      color: context.theme.colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    ),
  );
}

class PostAttachmentProgress extends StatelessWidget {
  const PostAttachmentProgress({
    required this.showSuccessCheckmark,
    required this.progress,
    super.key,
  });

  final bool showSuccessCheckmark;
  final double progress;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    child: showSuccessCheckmark
        ? Container(
            key: const ValueKey('success'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.check_circle,
              color: context.theme.colorScheme.primary,
              size: 20,
            ),
          )
        : Container(
            key: const ValueKey('progress'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
  );
}
