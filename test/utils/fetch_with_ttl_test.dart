import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';

void main() {
  const cached = 'cached';
  const fresh = 'fresh';
  final now = DateTime.now();

  Future<String> fetchFromNetwork() async => fresh;

  group('fetchWithTtl', () {
    test('fetches from network when no cached data', () async {
      final result = await fetchWithTtl(
        cached: null,
        getFetchedAt: (_) => now,
        fetchFromNetwork: fetchFromNetwork,
      );
      expect(result, fresh);
    });

    test('returns cached data when fresh', () async {
      final result = await fetchWithTtl(
        cached: cached,
        getFetchedAt: (_) => now.subtract(const Duration(hours: 1)),
        fetchFromNetwork: fetchFromNetwork,
      );
      expect(result, cached);
    });

    test('fetches from network when stale', () async {
      final result = await fetchWithTtl(
        cached: cached,
        getFetchedAt: (_) => now.subtract(const Duration(days: 30)),
        fetchFromNetwork: fetchFromNetwork,
      );
      expect(result, fresh);
    });

    test('fetches from network when refresh is true', () async {
      final result = await fetchWithTtl(
        cached: cached,
        getFetchedAt: (_) => now.subtract(const Duration(hours: 1)),
        fetchFromNetwork: fetchFromNetwork,
        refresh: true,
      );
      expect(result, fresh);
    });

    test('fetches from network when fetchedAt is null', () async {
      final result = await fetchWithTtl(
        cached: cached,
        getFetchedAt: (_) => null,
        fetchFromNetwork: fetchFromNetwork,
      );
      expect(result, fresh);
    });

    test('respects custom ttl', () async {
      final result = await fetchWithTtl(
        cached: cached,
        getFetchedAt: (_) => now.subtract(const Duration(hours: 2)),
        fetchFromNetwork: fetchFromNetwork,
        ttl: const Duration(hours: 1),
      );
      expect(result, fresh);
    });
  });
}
