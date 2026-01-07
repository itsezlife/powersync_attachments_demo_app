import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';

/// Full-screen media preview page similar to Threads
class MediaPreviewPage extends StatefulWidget {
  const MediaPreviewPage({
    required this.assets,
    required this.initialIndex,
    super.key,
  });

  final List<AssetEntity> assets;
  final int initialIndex;

  @override
  State<MediaPreviewPage> createState() => _MediaPreviewPageState();
}

class _MediaPreviewPageState extends State<MediaPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      title: widget.assets.length > 1
          ? Text('${_currentIndex + 1} / ${widget.assets.length}')
          : null,
    ),
    body: PageView.builder(
      controller: _pageController,
      itemCount: widget.assets.length,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemBuilder: (context, index) =>
          _MediaPreviewItem(asset: widget.assets[index]),
    ),
  );
}

class _MediaPreviewItem extends StatelessWidget {
  const _MediaPreviewItem({required this.asset});

  final AssetEntity asset;

  @override
  Widget build(BuildContext context) => InteractiveViewer(
    minScale: 0.5,
    maxScale: 4,
    child: Center(child: AssetEntityImage(asset)),
  );
}
