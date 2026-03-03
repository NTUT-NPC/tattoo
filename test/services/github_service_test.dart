import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/services/github_service.dart';
import 'package:tattoo/utils/http.dart';

class MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) onFetch;
  MockAdapter(this.onFetch);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => onFetch(options);

  @override
  void close({bool force = false}) {}
}

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

  group('GithubService', () {
    late GithubService githubService;

    setUp(() {
      githubService = GithubService();
    });

    group('getContributors', () {
      test('fetches and filters contributors excluding bots', () async {
        final contributors = await githubService.getContributors();

        expect(contributors, isNotNull);
        expect(contributors!.every((c) => !c.isBot), isTrue);
        expect(contributors.every((c) => c.login.isNotEmpty), isTrue);
      });

      test('returns null if response data is not a list', () async {
        githubService.dio.httpClientAdapter = MockAdapter((options) async {
          return ResponseBody.fromBytes(
            Uint8List.fromList('{"message": "Success"}'.codeUnits),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        final contributors = await githubService.getContributors();
        expect(contributors, isNull);
      });

      test('propagates DioException on connection error', () async {
        githubService.dio.httpClientAdapter = MockAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        });

        expect(
          () => githubService.getContributors(),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
