import 'package:tattoo/models/campus_map.dart';

typedef CampusMapSearchBuilding = ({String name, Iterable<String> aliases});

/// Matches complete building and room references before offering name fragments.
CampusMapSearchResult matchCampusMapPlaces(
  String query, {
  required Map<String, CampusMapSearchBuilding> buildings,
  required Iterable<CampusMapRoom> rooms,
  Map<({String building, String floor, String number}), List<String>>
      roomAliases =
      const {},
}) {
  final normalized = normalizeCampusMapSearchText(query);
  if (normalized.isEmpty) return const CampusMapSearchResult([]);

  final exact = <(String, String?), CampusMapSearchMatch>{};
  final suggestions = <(String, String?), CampusMapSearchMatch>{};
  final qualified = <String, ({Set<String> after, Set<String> before})>{};
  for (final entry in buildings.entries) {
    final code = entry.key;
    final building = entry.value;
    final names = _searchTerms([code, building.name, ...building.aliases]);
    final match = (buildingCode: code, buildingName: building.name, room: null);
    if (names.contains(normalized)) {
      exact[(code, null)] = match;
    } else if (names.any((name) => name.contains(normalized))) {
      suggestions[(code, null)] = match;
    }

    qualified[code] = (
      after: {
        for (final name in names)
          if (normalized.startsWith(name) && normalized.length > name.length)
            _unwrap(
              normalized
                  .substring(name.length)
                  .replaceFirst(_leadingSeparator, ''),
            ),
      }..remove(''),
      before: {
        for (final name in names)
          if (normalized.endsWith(name) && normalized.length > name.length)
            _unwrap(
              normalized
                  .substring(0, normalized.length - name.length)
                  .replaceFirst(_trailingSeparator, ''),
            ),
      }..remove(''),
    );
  }

  for (final room in rooms) {
    final parts = qualified[room.buildingCode];
    if (parts == null) continue;
    final aliases =
        roomAliases[(
          building: room.buildingCode,
          floor: room.floor.code,
          number: room.number,
        )];
    final names = _searchTerms([room.nameZh, room.nameEn, ...?aliases]);
    final number = normalizeCampusMapSearchText(room.number);
    final match = (
      buildingCode: room.buildingCode,
      buildingName: room.buildingName,
      room: room,
    );
    final key = (room.buildingCode, room.id);
    if (names.contains(normalized) ||
        parts.after.any(names.contains) ||
        parts.before.any(names.contains) ||
        _matchesNumber(normalized, number) ||
        parts.after.any((part) => _matchesNumber(part, number))) {
      exact[key] = match;
    } else if (names.any(
      (name) =>
          _isNameFragment(normalized, name) ||
          parts.after.any((part) => _isNameFragment(part, name)) ||
          parts.before.any((part) => _isNameFragment(part, name)),
    )) {
      suggestions[key] = match;
    }
  }

  final matches = (exact.isNotEmpty ? exact : suggestions).values.toList()
    ..sort(_compareMatches);
  return CampusMapSearchResult(matches, isExact: exact.isNotEmpty);
}

final _leadingSeparator = RegExp(r'^[_/-]+');
final _trailingSeparator = RegExp(r'[_/-]+$');
final _roomNumber = RegExp(r'^[a-z0-9-]*[0-9][a-z0-9-]*室?$');
final _whitespace = RegExp(r'\s+');

Set<String> _searchTerms(Iterable<String> values) => {
  for (final value in values) normalizeCampusMapSearchText(value),
}..remove('');

bool _matchesNumber(String query, String number) =>
    number.isNotEmpty && (query == number || query == '$number室');

bool _isNameFragment(String query, String name) =>
    !_roomNumber.hasMatch(query) && name.contains(query);

int _compareMatches(CampusMapSearchMatch a, CampusMapSearchMatch b) {
  final byBuilding = a.buildingName.compareTo(b.buildingName);
  if (byBuilding != 0) return byBuilding;
  final byCode = a.buildingCode.compareTo(b.buildingCode);
  if (byCode != 0) return byCode;
  final byFloor = (a.room?.floor.order ?? 0).compareTo(
    b.room?.floor.order ?? 0,
  );
  if (byFloor != 0) return byFloor;
  final byNumber = (a.room?.number ?? '').compareTo(b.room?.number ?? '');
  return byNumber == 0
      ? (a.room?.id ?? '').compareTo(b.room?.id ?? '')
      : byNumber;
}

/// Folds full-width ASCII and case while preserving punctuation inside fields.
String normalizeCampusMapSearchText(String value) => _unwrap(
  String.fromCharCodes(
    value.runes.map(
      (rune) => switch (rune) {
        >= 0xff01 && <= 0xff5e => rune - 0xfee0,
        0x3000 => 0x20,
        _ => rune,
      },
    ),
  ).toLowerCase().replaceAll(_whitespace, ''),
);

String _unwrap(String value) {
  while (value.startsWith('(') && value.endsWith(')')) {
    var depth = 1;
    var end = 1;
    for (; end < value.length; end++) {
      if (value[end] == '(') depth++;
      if (value[end] == ')') depth--;
      if (depth == 0) break;
    }
    if (end != value.length - 1) break;
    value = value.substring(1, end);
  }
  return value;
}
