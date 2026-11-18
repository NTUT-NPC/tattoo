import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_search.dart';

void main() {
  const buildings = <String, CampusMapSearchBuilding>{
    'A3T': (
      name: '第三教學大樓',
      aliases: [
        '三教',
        '3TB',
        'Third Academic Building',
        '3rd Teaching Building',
      ],
    ),
    'A4T': (name: '第四教學大樓', aliases: ['四教', '4TB', 'Fourth Academic Building']),
    'AD': (name: '行政大樓', aliases: ['行政', 'Administration Building']),
    'CB': (name: '綜合科館', aliases: ['綜科', '粽科', '合館']),
    'HR': (name: '宏裕科技大樓', aliases: ['宏裕', '科技', '科研', 'HYTRB', 'STRB', '合館']),
  };
  final third303 = _room('A3T', '3F', '303', '教室');
  final fourth303 = _room('A4T', '3F', '303', '教室');
  final innovation = _room('A4T', '2F', '201', '科技創新中心');
  final research = _room(
    'AD',
    '6F',
    '602',
    '研發處辦公室',
    nameEn: 'Office of Research and Development',
  );
  final faculty = _room('CB', '3F', '302', '高立人老師研究室');
  final basement = _room('HR', 'B2', 'B205', '社團教室');
  final room205 = _room('HR', '2F', '205', '205教室');
  final room205A = _room('HR', '2F', '205A', '205A教室');
  final otherBasement = _room('A3T', 'B2', 'B205', 'B205教室');
  final leadingZero = _room('HR', '9F', '0935', '教室');
  final hyphenated = _room('CB', '4F', '417-2', '思源講堂');
  final rooms = [
    third303,
    fourth303,
    innovation,
    research,
    faculty,
    basement,
    room205,
    room205A,
    otherBasement,
    leadingZero,
    hyphenated,
  ];

  CampusMapSearchResult search(
    String query, {
    Iterable<CampusMapRoom>? spaces,
  }) => matchCampusMapPlaces(
    query,
    buildings: buildings,
    rooms: spaces ?? rooms,
    roomAliases: const {
      (building: 'AD', floor: '6F', number: '602'): ['研發處'],
    },
  );

  test(
    'full building aliases match the building without including its rooms',
    () {
      for (final query in ['四教', '4TB', 'A4T', '（Fourth Academic Building）']) {
        final match = search(query).uniqueExactMatch;
        expect(match?.buildingCode, 'A4T', reason: query);
        expect(match?.room, isNull);
      }
      expect(search('合館').matches.map((match) => match.buildingCode), [
        'HR',
        'CB',
      ]);
      expect(search('合館').uniqueExactMatch, isNull);
    },
  );

  test('building fragments containing digits remain suggestions', () {
    final result = search('3rd');
    expect(result.matches.single.buildingCode, 'A3T');
    expect(result.matches.single.room, isNull);
    expect(result.isExact, isFalse);
    expect(result.uniqueExactMatch, isNull);
    expect(search('3TB').uniqueExactMatch?.buildingCode, 'A3T');

    final roomResult = search('205', spaces: [basement, room205A]);
    expect(roomResult.matches, isEmpty);
  });

  test(
    'qualified room numbers accept separators and preserve full room numbers',
    () {
      for (final query in [
        '三教303',
        '3TB_303',
        '３ＴＢ（３０３）',
        '3TB-303',
        '三教303室',
      ]) {
        expect(search(query).uniqueExactMatch?.room, third303, reason: query);
      }
      for (final query in ['宏裕B205', '科技B205', 'HYTRB-B205', 'STRB_B205']) {
        expect(search(query).uniqueExactMatch?.room, basement, reason: query);
      }
      expect(search('宏裕205').uniqueExactMatch?.room, room205);
      expect(search('宏裕205A').uniqueExactMatch?.room, room205A);
      expect(search('宏裕0935').uniqueExactMatch?.room, leadingZero);
      expect(search('CB-417-2').uniqueExactMatch?.room, hyphenated);
      for (final query in ['CB4172', 'CB417', 'CB417-3', '935', '05']) {
        expect(search(query).matches, isEmpty, reason: query);
      }
      expect(
        search('宏裕B205', spaces: [room205, otherBasement]).matches,
        isEmpty,
      );
      expect(search('宏裕205', spaces: [basement, room205A]).matches, isEmpty);
    },
  );

  test('space aliases match in both orders and only in their own building', () {
    for (final query in ['行政大樓研發處', '研發處 行政大樓', '行政/研發處', '研發處']) {
      expect(search(query).uniqueExactMatch?.room, research, reason: query);
    }
    expect(
      search('Office of Research and Development AD').uniqueExactMatch?.room,
      research,
    );
    expect(search('四教高立人').matches, isEmpty);
    expect(search('三教研發').matches, isEmpty);
  });

  test(
    'teacher-name fragments remain suggestions with one or multiple rooms',
    () {
      final lab = _room('CB', '1F', '107-1', '研究生綜合專題實驗室【高立人】');
      for (final spaces in [
        [faculty],
        [lab, faculty],
      ]) {
        for (final query in ['粽科高立人', '高立人 粽科', '綜科/高立人', '高立人']) {
          final result = search(query, spaces: spaces);
          expect(result.isExact, isFalse, reason: query);
          expect(result.uniqueExactMatch, isNull, reason: query);
          expect(
            result.matches.map((match) => match.room),
            spaces,
            reason: query,
          );
        }
      }
    },
  );

  test('full room names survive overlapping building aliases', () {
    expect(search('科技創新中心').uniqueExactMatch?.room, innovation);
    expect(search('科技').uniqueExactMatch?.buildingCode, 'HR');
  });

  test('same room number across buildings is ambiguous and targets are deduplicated', () {
    final result = search('303', spaces: [third303, fourth303, third303]);
    expect(result.isExact, isTrue);
    expect(result.uniqueExactMatch, isNull);
    expect(result.matches.map((match) => match.room), [third303, fourth303]);
  });

  test('a lone name fragment remains a suggestion', () {
    for (final query in ['行政大樓研發', '研發 行政大樓', '研發']) {
      final result = search(query);
      expect(result.matches.single.room, research, reason: query);
      expect(result.uniqueExactMatch, isNull);
    }
    expect(search('第四教學').matches.single.buildingCode, 'A4T');
    expect(search('第四教學').uniqueExactMatch, isNull);
  });
}

CampusMapRoom _room(
  String building,
  String floor,
  String number,
  String nameZh, {
  String nameEn = '',
}) => CampusMapRoom(
  id: '${building}_$floor.$number',
  buildingCode: building,
  buildingName: building,
  floor: CampusMapFloor(layerName: 'gis_room:${building}_$floor', code: floor),
  nameZh: nameZh,
  nameEn: nameEn,
  number: number,
);
