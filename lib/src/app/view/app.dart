import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_attachments_example/src/app/bloc/app_bloc.dart';
import 'package:powersync_attachments_example/src/app/view/app_view.dart';
import 'package:powersync_attachments_example/src/posts/controller/posts_controller.dart';
import 'package:powersync_attachments_example/src/user_profile/bloc/user_profile_bloc.dart';
import 'package:provider/provider.dart';
import 'package:user_repository/user_repository.dart';

class App extends StatelessWidget {
  const App({
    required this.user,
    required this.userRepository,
    required this.postsRepository,
    super.key,
  });

  final User user;
  final UserRepository userRepository;
  final PostsRepository postsRepository;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: userRepository),
      RepositoryProvider.value(value: postsRepository),
      ChangeNotifierProvider.value(value: PostProvider()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => AppBloc(user: user, userRepository: userRepository),
        ),
        BlocProvider(
          create: (_) => UserProfileBloc(
            userRepository: userRepository,
            postsRepository: postsRepository,
          ),
        ),
      ],
      child: AppView(user: user),
    ),
  );
}
