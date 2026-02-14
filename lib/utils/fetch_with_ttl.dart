/// Global default TTL for cached data.
///
/// Used by [fetchWithTtl] when no explicit TTL is provided.
/// Repositories can override this for entity-specific TTL requirements.
///
/// **Making this configurable:**
/// To connect this to user preferences later:
/// 1. Create a provider that reads from SharedPreferences/secure storage
/// 2. Pass the value through repository constructors or as a parameter
/// 3. Example: `fetchWithTtl(cached: data, ttl: ref.watch(userTtlPrefProvider))`
const Duration defaultFetchTtl = Duration(days: 3);

/// Helper for fetching data with TTL-based caching.
///
/// Implements the fetch-if-stale pattern used across repositories:
/// - If [cached] is null, fetches from network
/// - If [refresh] is true, fetches from network (pull-to-refresh)
/// - If [cached] is older than [ttl], fetches from network
/// - Otherwise returns [cached]
///
/// **TTL Configuration:**
/// - Defaults to [defaultFetchTtl] if not specified
/// - Repositories can override for entity-specific needs
/// - Can be made user-configurable via preferences provider
///
/// **Example:**
/// ```dart
/// class AuthRepository {
///   Future<User?> getUser({bool refresh = false}) async {
///     final user = await _database.select(_database.users).getSingleOrNull();
///     if (user == null) return null; // Not logged in
///
///     return fetchWithTtl(
///       cached: user,
///       getFetchedAt: (u) => u.fetchedAt,
///       fetchFromNetwork: _fetchUserFromNetwork,
///       refresh: refresh,
///     );
///   }
///
///   // Override TTL for specific entities
///   Future<User?> getUserWithCustomTtl({bool refresh = false}) async {
///     final user = await _database.select(_database.users).getSingleOrNull();
///     if (user == null) return null;
///
///     return fetchWithTtl(
///       cached: user,
///       getFetchedAt: (u) => u.fetchedAt,
///       fetchFromNetwork: _fetchUserFromNetwork,
///       ttl: const Duration(days: 7), // Custom TTL
///       refresh: refresh,
///     );
///   }
/// }
/// ```
Future<T> fetchWithTtl<T>({
  required T? cached,
  required DateTime? Function(T) getFetchedAt,
  required Future<T> Function() fetchFromNetwork,
  Duration? ttl,
  bool refresh = false,
}) async {
  // No cached data, fetch fresh
  if (cached == null) {
    return fetchFromNetwork();
  }

  // Check if cached data is still fresh
  final effectiveTtl = ttl ?? defaultFetchTtl;
  final fetchedAt = getFetchedAt(cached);
  if (!refresh && fetchedAt != null) {
    final age = DateTime.now().difference(fetchedAt);
    if (age < effectiveTtl) {
      return cached; // Data is fresh, return cached
    }
  }

  // Data is stale or refresh requested, fetch fresh
  return fetchFromNetwork();
}
