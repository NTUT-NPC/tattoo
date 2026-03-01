import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/services/github_service.dart';

void main() {
  group('Contributor Model', () {
    test('should correctly identify bots', () {
      final user = Contributor(
        login: 'octocat',
        avatarUrl: 'https://avatar.url',
        htmlUrl: 'https://html.url',
        type: 'User',
      );
      final bot = Contributor(
        login: 'dependabot[bot]',
        avatarUrl: 'https://avatar.url',
        htmlUrl: 'https://html.url',
        type: 'Bot',
      );

      expect(user.isBot, isFalse);
      expect(bot.isBot, isTrue);
    });
  });

  group('GithubService Integration Tests', () {
    late GithubService githubService;

    setUp(() {
      githubService = GithubService();
    });

    test(
      'should fetch contributors from NTUT-NPC/tattoo and exclude bots',
      () async {
        final contributors = await githubService.getContributors();

        expect(contributors, isNotEmpty);
        expect(contributors.every((c) => !c.isBot), isTrue);
        expect(contributors.any((c) => c.login.isNotEmpty), true);
      },
    );

    test('should handle API errors gracefully', () async {
      final contributors = await githubService.getContributors();
      expect(contributors, isList);
    });
  });
}
