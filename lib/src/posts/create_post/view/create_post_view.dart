// ignore_for_file: lines_longer_than_80_chars, unused_field

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/constant/app_spacing.dart';
import 'package:powersync_attachments_example/src/common/constant/gaps.dart';
import 'package:powersync_attachments_example/src/common/extensions/build_context_extension.dart';
import 'package:powersync_attachments_example/src/common/extensions/show_snackbar_extension.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/l10n/l10n.dart';
import 'package:powersync_attachments_example/src/media_picker/media_picker.dart';
import 'package:powersync_attachments_example/src/posts/controller/posts_controller.dart';
import 'package:powersync_attachments_example/src/posts/create_post/widgets/dynamic_media_display.dart';
import 'package:powersync_attachments_example/src/posts/create_post/widgets/media_preview_page.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/user_profile_bloc.dart';
import 'package:shared/shared.dart';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView>
    with InstaPickerInterfaceStateMixin {
  StreamSubscription<dynamic>? _selectedImagesSubscription;
  final TextEditingController _textController = TextEditingController();
  // For mobile: AssetEntity from photo library
  List<AssetEntity> _selectedAssets = [];
  // For desktop: File objects from file picker
  List<File> _selectedFiles = [];
  List<MultiModeProcessedAsset> _processedAssets = [];

  @override
  void dispose() {
    _selectedImagesSubscription?.cancel();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    await pickAssets(
      maxAssets: 10,
      compress: !Config.isDesktop,
      closeOnComplete: true,
      requestType: RequestType.image,
      cropDelegate: const InstaAssetCropDelegate(preferredSize: 600),
      selectedAssets: _selectedAssets.isEmpty ? null : _selectedAssets,
      skipCropOnComplete: true,
      onUpload: (assetsFiles, [assetsBytes]) async {
        // Desktop: Store File objects directly
        _selectedFiles = List.from(assetsFiles);
        _selectedAssets = []; // Clear mobile assets
        setState(() {});
      },
      onCompleted: (details) async {
        // Mobile: Use AssetEntity from picker
        await _selectedImagesSubscription?.cancel();
        _selectedImagesSubscription = details.listen((details) {
          if (const ListEquality<String>().equals(
            _selectedAssets.map((e) => e.id).toList(),
            details.selectedAssets.map((e) => e.id).toList(),
          )) {
            return;
          }

          _selectedAssets = details.selectedAssets;
          _selectedFiles = []; // Clear desktop files
          setState(() {});
        });
      },
    );
  }

  Future<void> _submitPost() async {
    final l10n = context.l10n;
    final postText = _textController.text;

    // Validation: Ensure there's text or at least one image
    final hasMedia = _selectedAssets.isNotEmpty || _selectedFiles.isNotEmpty;
    if (postText.isEmpty && !hasMedia) {
      return;
    }

    // Clear inputs after submission
    _textController.clear();

    void goHome() {
      Navigator.pop(context);
    }

    try {
      unawaited(
        context.read<PostProvider>().uploadPost(
          context: context,
          processedAssets: _processedAssets,
          content: postText,
        ),
      );

      context.read<UserProfileBloc>().add(
        const UserProfilePostCreateStartRequested(),
      );

      goHome.call();
    } catch (error, stackTrace) {
      if (mounted) {
        context.showErrorSnackBar(error: l10n.postCreateFailedLabel);
      }
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'CreatePostView',
          context: ErrorDescription('Error during post upload process'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.createPostButtonLabel),
        centerTitle: false,
        leading: const CloseButton(),
      ),
      bottomNavigationBar: PublishPostBottom(
        selectedAssets: _selectedAssets,
        selectedFiles: _selectedFiles,
        commentTextController: _textController,
        onPublish: _submitPost,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            gapH16,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _textController,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: l10n.createPostHint,
                  border: InputBorder.none,
                ),
                minLines: 1,
                maxLines: 5,
              ),
            ),
            // Mobile: Show AssetEntity display
            if (_selectedAssets.isNotEmpty)
              DynamicMediaDisplay(
                assets: List.unmodifiable(_selectedAssets),
                onAssetRemoved: (asset, index) {
                  setState(() {
                    _selectedAssets = List.of(_selectedAssets)..remove(asset);
                  });
                },
                onProcessedAssetsChanged: (processedAssets) {
                  _processedAssets = processedAssets;
                  log(
                    'Processed assets: '
                    '${processedAssets.map((e) => e.processedAsset.asset.id).toList()}',
                  );
                },
                onAssetTapped: (asset, index) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MediaPreviewPage(
                        assets: _selectedAssets,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
              ),
            // Desktop: Show File display
            if (_selectedFiles.isNotEmpty)
              _DesktopFileDisplay(
                files: _selectedFiles,
                onFileRemoved: (file, index) {
                  setState(() {
                    _selectedFiles = List.of(_selectedFiles)..remove(file);
                  });
                },
              ),
            gapH16,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.addPostPhotosLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PublishPostBottom extends StatelessWidget {
  const PublishPostBottom({
    required this.selectedAssets,
    required this.selectedFiles,
    required this.commentTextController,
    required this.onPublish,
    super.key,
  });

  final TextEditingController commentTextController;
  final List<AssetEntity> selectedAssets;
  final List<File> selectedFiles;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final hasResult = selectedAssets.isNotEmpty || selectedFiles.isNotEmpty;
    final l10n = context.l10n;

    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: context.viewInsets.bottom),
      child: Material(
        color: colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 0, thickness: .5),
            gapH12,
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: commentTextController,
                      builder: (context, value, _) {
                        final hasText = value.text.trim().isNotEmpty;
                        final enabled = hasText || hasResult;
                        return FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxlg,
                            ),
                            textStyle: textTheme.titleMedium,
                          ),
                          onPressed: enabled ? onPublish : null,
                          child: Text(l10n.publishButtonLabel),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop-specific widget to display selected files
class _DesktopFileDisplay extends StatelessWidget {
  const _DesktopFileDisplay({required this.files, required this.onFileRemoved});

  final List<File> files;
  final void Function(File file, int index) onFileRemoved;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    const borderRadius = BorderRadius.all(Radius.circular(8));

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: files.length,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemBuilder: (context, index) {
          final file = files[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index < files.length - 1 ? AppSpacing.lg : 0,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.file(file, height: 240, fit: BoxFit.cover),
                ),
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: IconButton(
                    onPressed: () => onFileRemoved(file, index),
                    icon: const Icon(Icons.close, size: 16),
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
