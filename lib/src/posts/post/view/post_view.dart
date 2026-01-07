import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/posts/post/widgets/post_attachment.dart';
import 'package:shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PostView extends StatelessWidget {
  const PostView({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.attachments case final attachments
              when attachments.isNotEmpty)
            SizedBox(
              height: PostAttachment.height,
              child: CarouselView(
                itemExtent: PostAttachment.height,
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                ),
                children: [
                  for (final attachment in attachments)
                    if (attachment.isImage)
                      Skeleton.replace(
                        replacement: const PostAttachmentPlaceholder(),
                        child: PostAttachment(
                          post: post,
                          attachment: attachment,
                        ),
                      ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gapH8,
                if (post.content case final content when content.isNotEmpty)
                  Text(content, style: textTheme.bodyLarge),
                gapH8,
                Align(
                  alignment: Alignment.centerRight,
                  child: Skeleton.ignore(
                    child: Text(
                      DateFormat('MMM d, HH:mm:ss').format(post.createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
                if (post.localOnly)
                  Text('Local only', style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
