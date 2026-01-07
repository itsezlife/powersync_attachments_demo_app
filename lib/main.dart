import 'package:google_sign_in/google_sign_in.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_attachments_example/bootstrap.dart';
import 'package:powersync_attachments_example/src/app/view/app.dart';
import 'package:powersync_database_client/powersync_database_client.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:user_repository/user_repository.dart';

void main() =>
    bootstrap((powerSyncClient, sharedPreferences, listStorage) async {
      final tokenStorage = InMemoryTokenStorage();
      final supabaseAuthenticationClient = SupabaseAuthenticationClient(
        powerSyncClient: powerSyncClient,
        tokenStorage: tokenStorage,
        googleSignIn: GoogleSignIn(),
      );
      final powerSyncDatabaseClient = PowerSyncDatabaseClient(
        powerSyncClient: powerSyncClient,
      );

      final userRepository = UserRepository(
        authenticationClient: supabaseAuthenticationClient,
        databaseClient: powerSyncDatabaseClient,
      );

      final postsRepository = PostsRepository(
        databaseClient: powerSyncDatabaseClient,
      );

      return App(
        postsRepository: postsRepository,
        userRepository: userRepository,
        powerSyncClient: powerSyncClient,
        user: await userRepository.user.first,
      );
    });
