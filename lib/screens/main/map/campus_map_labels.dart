import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/utils/localized.dart';

/// Translates a GeoServer building [code], falling back to [fallbackName].
///
/// The locale YAMLs own the map under `campusMap.buildingNames`; its keys are
/// building codes such as `A6T` and `HR`. Room names use server data instead.
String campusMapBuildingName(String code, {required String fallbackName}) =>
    t.campusMap.buildingNames[code] ?? fallbackName;

/// Formats a developer menu entry as the original [code] and mapped name.
String campusMapBuildingMenuLabel(String code) {
  final translation = t.campusMap.buildingNames[code];
  return translation == null ? code : '$code: $translation';
}

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
