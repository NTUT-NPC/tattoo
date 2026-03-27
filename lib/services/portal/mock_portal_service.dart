import 'dart:typed_data';

import 'package:tattoo/services/portal/portal_service.dart';

/// Mock implementation of [PortalService] for repository unit tests
/// and demo mode.
class MockPortalService implements PortalService {
  UserDto? loginResult;
  Uint8List? avatarResult;
  String? uploadAvatarResult;
  Uri? ssoUrlResult;
  List<CalendarEventDto>? calendarResult;

  @override
  Future<UserDto> login(String username, String password) async {
    return loginResult ??
        (
          name: '王大同',
          avatarFilename: '111592347_temp1714460935341.jpeg',
          email: 't111592347@ntut.edu.tw',
          passwordExpiresInDays: null,
        );
  }

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {}

  @override
  Future<Uint8List> getAvatar([String? filename]) async {
    return avatarResult ?? Uint8List(0);
  }

  @override
  Future<String> uploadAvatar(Uint8List imageBytes, String? oldFilename) async {
    return uploadAvatarResult ?? '111590001_temp1052748000000.jpeg';
  }

  @override
  Future<void> sso(String serviceCode) async {}

  @override
  Future<Uri> getSsoUrl(String serviceCode) async {
    return ssoUrlResult ??
        Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
  }

  @override
  Future<List<CalendarEventDto>> getCalendar(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return calendarResult ??
        [
          (
            id: 60561,
            start: DateTime(2025, 8, 1), // 1753977600000
            end: DateTime(2025, 8, 2), // 1754064000000
            allDay: true,
            title: '114學年度第1學期開始',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60574,
            start: DateTime(2025, 9, 8), // 1757260800000
            end: DateTime(2025, 9, 9), // 1757347200000
            allDay: true,
            title: '開學暨註冊截止日、開學典禮',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60581,
            start: DateTime(2025, 10, 7), // 1759766400000
            end: DateTime(2025, 10, 8), // 1759852800000
            allDay: true,
            title: '期中撤選開始',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60582,
            start: DateTime(2025, 10, 7), // 1759766400000
            end: DateTime(2025, 10, 8), // 1759852800000
            allDay: true,
            title: '國文會考',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60589,
            start: DateTime(2025, 11, 3), // 1762099200000
            end: DateTime(2025, 11, 9), // 1762617600000
            allDay: true,
            title: '期中考試',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60591,
            start: DateTime(2025, 11, 28, 17, 0), // 1764259200000
            end: DateTime(2025, 11, 29, 17, 0), // 1764320400000
            allDay: false,
            title: '日間部期中撤選結束(17:00 截止)、休退學學生退1/3學雜費截止',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60603,
            start: DateTime(2026, 1, 5), // 1767542400000
            end: DateTime(2026, 1, 11), // 1768060800000
            allDay: true,
            title: '期末考試',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
          (
            id: 60605,
            start: DateTime(2026, 1, 12), // 1768147200000
            end: DateTime(2026, 1, 13), // 1768233600000
            allDay: true,
            title: '寒假開始、寒宿開始',
            place: null,
            content: null,
            ownerName: '學校行事曆',
            creatorName: '教務處',
          ),
        ];
  }
}
