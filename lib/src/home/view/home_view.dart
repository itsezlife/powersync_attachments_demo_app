// ignore_for_file: use_setters_to_change_properties

import 'package:flutter/material.dart';
import 'package:powersync_attachments_example/src/app/router/tabs.dart';
import 'package:powersync_attachments_example/src/home/widgets/home_tabs_mixin.dart';

/// {@template home_view}
/// HomeView widget.
/// {@endtemplate}
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => const _Tabs();
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> with HomeTabsMixin {
  @override
  AppTab get tab => const HomeAppTab();

  @override
  Widget build(BuildContext context) => buildTabs(context);
}
