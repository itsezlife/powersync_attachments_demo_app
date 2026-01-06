import 'package:flutter/material.dart';

class MenuView extends StatelessWidget {
  const MenuView({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Menu'),
            pinned: true,
            floating: true,
            snap: true,
          ),
        ],
      ),
    ),
  );
}
