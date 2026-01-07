import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/models/post_progress.dart';
import 'package:powersync_attachments_example/src/posts/controller/posts_controller.dart';

class PostProgressList extends StatelessWidget {
  const PostProgressList({super.key});

  @override
  Widget build(BuildContext context) {
    final progressList = context.select<PostProvider, List<PostProgress>>(
      (p) => p.progress,
    );
    final theme = context.theme;
    final textTheme = theme.textTheme;

    final colorScheme = theme.colorScheme;

    return AnimatedSize(
      duration: kThemeAnimationDuration,
      child: progressList.isEmpty
          ? const SizedBox.shrink()
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: progressList.length,
              separatorBuilder: (_, _) => gapH12,
              itemBuilder: (context, index) {
                final progress = progressList[index];

                return SizedBox(
                  height: 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                          child: switch (progress.file) {
                            final File value => Image(
                              image: FileImage(value),
                              fit: BoxFit.cover,
                            ),
                            _ =>
                              progress.asset != null
                                  ? Image(
                                      image: AssetEntityImageProvider(
                                        progress.asset!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.upload_file,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 20,
                                      ),
                                    ),
                          },
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: LinearProgressIndicator(
                            value: progress.value,
                            color: progress.hasError ?? false
                                ? colorScheme.error
                                : colorScheme.primary,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      if (progress.hasError ?? false)
                        Row(
                          children: [
                            Icon(Icons.error, color: colorScheme.error),
                            GestureDetector(
                              onTap: () {
                                context.read<PostProvider>().removeProgress(
                                  progress.postId,
                                );
                              },
                              child: const SizedBox.square(
                                dimension: 24,
                                child: FittedBox(
                                  child: Icon(Icons.close_rounded),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${(progress.value * 100).toInt()}%',
                          style: textTheme.bodyMedium,
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
