import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/utils/http.dart';

final githubServiceProvider = Provider((ref) => GithubService());

final contributorsProvider = FutureProvider.autoDispose<List<Contributor>>((
  ref,
) async {
  final githubService = ref.watch(githubServiceProvider);
  return githubService.getContributors();
});

class GithubService {
  late final Dio _dio;

  GithubService() {
    _dio = createDio()..options.baseUrl = 'https://api.github.com/';
  }

  Dio get dio => _dio;

  Future<List<Contributor>> getContributors() async {
    final response = await _dio.get('repos/NTUT-NPC/tattoo/contributors');

    if (response.data is List) {
      return (response.data as List)
          .map((item) => Contributor.fromJson(item as Map<String, dynamic>))
          .where((contributor) => !contributor.isBot)
          .toList();
    }
    return [];
  }
}
