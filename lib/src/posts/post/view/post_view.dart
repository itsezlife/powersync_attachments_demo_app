import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';

class PostView extends StatelessWidget {
  const PostView({required this.post, super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final postsRepository = context.read<PostsRepository>();
    return ListTile(
      title: Text(post.content),
      leading: switch (post.attachments.firstOrNull) {
        Attachment(:final imageUrl) =>
          imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: postsRepository.getPostImageUrl(
                    imageName: imageUrl,
                    postId: post.id,
                  ),
                  placeholder: (context, url) => const SizedBox.square(
                    dimension: 40,
                    child: ColoredBox(color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                )
              : null,
        null => null,
      },
      subtitle: Text(post.createdAt.toString()),
    );
  }
}
