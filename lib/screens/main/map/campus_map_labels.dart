import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/utils/localized.dart';

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
