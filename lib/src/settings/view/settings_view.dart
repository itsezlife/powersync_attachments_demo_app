import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/common/widgets/app_scaffold.dart';
import 'package:powersync_attachments_example/src/common/widgets/scaffold_padding.dart';
import 'package:powersync_attachments_example/src/settings/widgets/log_out_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: CustomScrollView(
      slivers: [
        const SliverAppBar(
          title: Text('Settings'),
          pinned: true,
          floating: true,
          snap: true,
        ),
        ScaffoldPadding.sliver(
          context,
          horizontalPadding: 0,
          child: SliverList.list(children: const [LogOutTile()]),
        ),
      ],
    ),
  );
}
