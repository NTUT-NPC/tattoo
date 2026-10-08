import 'dart:convert' show jsonDecode;

/// Parses link URL overrides from a JSON array of `{"id": ..., "url": ...}`
/// objects:
///
/// ```json
/// [
///   {"id": "campus_affairs_feedback", "url": "https://example.com"},
///   {"id": "upcoming_school_policies", "url": ""}
/// ]
/// ```
///
/// Returns a map keyed by link ID. An entry with an empty or missing `url`
/// maps to `null` (hides the link). IDs not listed are absent from the map, so
/// callers keep their defaults. Returns an empty map when [raw] is malformed.
Map<String, String?> parseLinkUrlOverrides(String raw) {
  try {
    if (jsonDecode(raw) case final List<dynamic> decoded) {
      return {
        for (final entry in decoded)
          if (entry case {'id': final String id})
            id: switch (entry) {
              {'url': final String url} when url.trim().isNotEmpty =>
                url.trim(),
              _ => null,
            },
      };
    }
  } on FormatException {
    // Malformed config — keep the defaults.
  }
  return const {};
}
