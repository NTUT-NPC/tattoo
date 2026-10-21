import 'package:material_ui/material_ui.dart';
import 'package:tattoo/models/campus_map.dart';

/// Visual categories inferred from original Chinese names in either UI locale.
enum CampusMapSpaceKind {
  room,
  passage,
  elevator,
  restroom,
  column,
  voidSpace,
  stairs,
}

final _chineseKinds = <(RegExp, CampusMapSpaceKind)>[
  (RegExp('柱子'), .column),
  (RegExp('挑空'), .voidSpace),
  (RegExp('走道|門廳|走廊|大廳|梯廳'), .passage),
  (RegExp('廁'), .restroom),
  (RegExp('電梯|升降|昇降|貨梯|客梯|無障礙梯'), .elevator),
  (RegExp('樓梯|戶外梯|室外梯|安全梯|逃生梯'), .stairs),
];

/// Classifies only the original Chinese name, regardless of the display locale.
///
/// Keywords match substrings. Lift and stair lobbies are circulation spaces, so
/// passage names take precedence over elevator and stair names. Missing or
/// unrecognized Chinese names remain ordinary rooms; English is display-only.
CampusMapSpaceKind campusMapSpaceKind(CampusMapRoom room) {
  for (final (pattern, kind) in _chineseKinds) {
    if (pattern.hasMatch(room.nameZh)) return kind;
  }
  return .room;
}

/// Keeps rooms brighter than circulation areas in either theme.
Color campusMapSpaceFill(CampusMapSpaceKind kind, ColorScheme colors) {
  final dark = colors.brightness == .dark;
  return switch (kind) {
    .room => dark ? colors.surfaceContainerHigh : colors.surfaceContainerLowest,
    .passage =>
      dark ? colors.surfaceContainerLowest : colors.surfaceContainerHigh,
    .column =>
      dark ? colors.surfaceContainerLowest : colors.surfaceContainerHighest,
    .elevator => dark ? const Color(0xFF68502A) : const Color(0xFFF7DEAC),
    .restroom => dark ? const Color(0xFF28544F) : const Color(0xFFC7EAE4),
    .voidSpace => dark ? const Color(0xFF202C3A) : const Color(0xFFD7DEE8),
    .stairs => dark ? const Color(0xFF594536) : const Color(0xFFEAD7C8),
  };
}
