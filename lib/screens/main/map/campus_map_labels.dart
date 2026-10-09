import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/utils/localized.dart';

/// Translates a server building name, falling back to the unmodified [name].
///
/// The locale YAMLs own the map under `campusMap.buildingNames`; its keys are
/// original first-floor `build_name` values. Room names use server data instead.
String campusMapBuildingName(String name) =>
    t.campusMap.buildingNames[name] ?? name;

/// Chooses the localized space name, treating blank server fields as missing.
String campusMapRoomName(CampusMapRoom room) => localized(
  room.nameZh.isEmpty ? null : room.nameZh,
  room.nameEn.isEmpty ? null : room.nameEn,
);

/// Formats a space's localized name and its number without duplication.
String campusMapRoomTitle(CampusMapRoom room) {
  final name = campusMapRoomName(room);
  return switch ((room.number, name)) {
    ('', '') => room.id,
    ('', final name) => name,
    (final number, '') => number,
    (final number, final name) when number == name => number,
    (final number, final name) => '$number · $name',
  };
}
