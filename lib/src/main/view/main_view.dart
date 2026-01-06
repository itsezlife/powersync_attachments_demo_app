import 'package:flutter/material.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Main View'),
            pinned: true,
            floating: true,
            snap: true,
          ),
        ],
      ),
    ),
  );
}
