import 'package:authentication_client/authentication_client.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:user_repository/user_repository.dart';

class MockAuthenticationClient extends Mock implements AuthenticationClient {}

class MockDatabaseClient extends Mock implements DatabaseClient {}

void main() {
  group('UserRepository', () {
    late AuthenticationClient authenticationClient;
    late DatabaseClient databaseClient;

    setUp(() {
      authenticationClient = MockAuthenticationClient();
      databaseClient = MockDatabaseClient();
    });
    test('can be instantiated', () {
      expect(
        UserRepository(
          authenticationClient: authenticationClient,
          databaseClient: databaseClient,
        ),
        returnsNormally,
      );
    });
  });
}
