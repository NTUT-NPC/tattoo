// import 'package:flutter_test/flutter_test.dart';
// import 'package:tattoo/services/calendar_service.dart';
// import 'package:tattoo/services/portal_service.dart';

// import '../test_helpers.dart';

// /// Reference test to inspect raw JSON from calModeApp.do.
// ///
// /// Run with:
// /// ```bash
// /// flutter test --dart-define-from-file=test/test_config.json -r expanded test/services/cal_debug_test.dart
// /// ```
// ///
// /// Example response (2025/09 semester):
// /// ```json
// /// [
// ///   {
// ///     "id": 60564,
// ///     "calStart": 1755619200000,
// ///     "calEnd": 1756818000000,
// ///     "calTitle": "新生網路預選(日間部 17:00 截止；進修部 21:00 截止)",
// ///     "calPlace": "",
// ///     "calContent": "",
// ///     "calColor": "#DDDDDD;#000000",
// ///     "ownerId": "1540521049552",
// ///     "ownerName": "學校行事曆",
// ///     "creatorId": "ntutoaa",
// ///     "creatorName": "教務處",
// ///     "modifyDate": 1751339649000,
// ///     "hasBeenDeleted": 0,
// ///     "calAlertList": [],
// ///     "calInviteeList": []
// ///   },
// ///   {
// ///     "calStart": 1758297600000,
// ///     "calEnd": 1758384000000,
// ///     "allDay": "1",
// ///     "calTitle": "",
// ///     "ownerId": "holiday_system",
// ///     "isHoliday": "1",
// ///     "calAlertList": [],
// ///     "calInviteeList": []
// ///   }
// /// ]
// /// ```
// void main() {
//   test('print raw calModeApp.do JSON', () async {
//     TestCredentials.validate();
//     final portalService = PortalService();
//     await portalService.login(
//       TestCredentials.username,
//       TestCredentials.password,
//     );

//     final events = await CalendarService(portalService).getCalendar(
//       DateTime(2025, 1, 1),
//       DateTime(2026, 12, 31),
//     );

//     print('=== ${events.length} events ===');
//     for (final e in events) {
//       final start = e.calStart != null
//           ? DateTime.fromMillisecondsSinceEpoch(e.calStart!)
//           : null;
//       final end = e.calEnd != null
//           ? DateTime.fromMillisecondsSinceEpoch(e.calEnd!)
//           : null;
//       final holiday = e.isHoliday == '1' ? ' [holiday]' : '';
//       print('  $start ~ $end: ${e.calTitle ?? "(no title)"}$holiday');
//     }
//   });
// }
