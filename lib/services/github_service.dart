import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/models/contributor.dart';
import 'package:tattoo/utils/http.dart';

final githubServiceProvider = Provider((ref) => GithubService());

final contributorsProvider = FutureProvider<List<Contributor>>((ref) async {
  final githubService = ref.watch(githubServiceProvider);
  return githubService.getContributors();
});

class GithubService {
  final _dio = createDio();

  @visibleForTesting
  Dio get dio => _dio;

  Future<List<Contributor>> getContributors() async {
    try {
      final response = await _dio.get(
        'https://api.github.com/repos/NTUT-NPC/tattoo/contributors',
      );

      if (response.data is List) {
        return (response.data as List)
            .map((item) => Contributor.fromJson(item as Map<String, dynamic>))
            .where((contributor) => !contributor.isBot)
            .toList();
      }
      return [];
    } catch (e) {
      // Return empty list on error for now, or handle specifically
      return [];
    }
  }
}
