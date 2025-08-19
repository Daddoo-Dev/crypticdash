import 'package:flutter_test/flutter_test.dart';
import 'package:crypticdash/services/github_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    // Initialize Flutter bindings for testing
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('GitHubService', () {
    late GitHubService githubService;

    setUp(() {
      githubService = GitHubService();
    });

    test('hasValidToken returns false when no token is set', () async {
      final result = await githubService.hasValidToken();
      expect(result, isFalse);
    });

    test('setAccessToken updates the token', () async {
      const testToken = 'test_token_123';
      await githubService.setAccessToken(testToken);
      
      expect(githubService.accessToken, equals(testToken));
    });

    test('clearAccessToken removes the token', () async {
      await githubService.setAccessToken('test_token');
      await githubService.clearAccessToken();
      
      expect(githubService.accessToken, isNull);
    });

    test('getUserRepositories throws exception without token', () {
      expect(
        () => githubService.getUserRepositories(),
        throwsA(isA<Exception>()),
      );
    });

    test('getFileContent throws exception without token', () {
      expect(
        () => githubService.getFileContent('owner', 'repo', 'path'),
        throwsA(isA<Exception>()),
      );
    });

    test('getAuthenticatedUser throws exception without token', () {
      expect(
        () => githubService.getAuthenticatedUser(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
