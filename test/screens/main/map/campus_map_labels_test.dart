import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/models/campus_map.dart';
import 'package:tattoo/repositories/campus_map_first_floor_outlines.dart';
import 'package:tattoo/screens/main/map/campus_map_labels.dart';

void main() {
  setUp(() async => await LocaleSettings.setLocale(AppLocale.zhTw));
  tearDown(() async => await LocaleSettings.setLocale(AppLocale.zhTw));

  test('building translation keys match the original first-floor names in both locales', () async {
    final names = campusMapFirstFloorOutlines.values
        .map((outline) => outline.name)
        .toSet();
    for (final locale in AppLocale.values) {
      await LocaleSettings.setLocale(locale);
      expect(t.campusMap.buildingNames.keys.toSet(), names);
      expect(
        t.campusMap.buildingNames.values.every((name) => name.isNotEmpty),
        isTrue,
      );
    }
  });

  test(
    'building names follow locale changes without changing their source keys',
    () async {
      const original = '宏裕科技研究大樓';
      expect(campusMapBuildingName(original), '宏裕科技大樓');
      await LocaleSettings.setLocale(AppLocale.enUs);
      expect(
        campusMapBuildingName(original),
        'Hong-Yue Technology Research Building',
      );
      await LocaleSettings.setLocale(AppLocale.zhTw);
      expect(campusMapBuildingName(original), '宏裕科技大樓');
    },
  );

  test('unmapped building names fall back to the original value', () async {
    for (final locale in AppLocale.values) {
      await LocaleSettings.setLocale(locale);
      expect(campusMapBuildingName('尚未翻譯的大樓'), '尚未翻譯的大樓');
    }
  });

  test('developer building menu preserves original names and annotates mapped values', () async {
    expect(
      campusMapBuildingMenuLabel('宏裕科技研究大樓'),
      '宏裕科技研究大樓（宏裕科技大樓）',
    );
    expect(campusMapBuildingMenuLabel('圖書館'), '圖書館（圖書館）');
    expect(campusMapBuildingMenuLabel('尚未翻譯的大樓'), '尚未翻譯的大樓');
    await LocaleSettings.setLocale(AppLocale.enUs);
    expect(campusMapBuildingMenuLabel('圖書館'), '圖書館（Library）');
    expect(campusMapBuildingMenuLabel('尚未翻譯的大樓'), '尚未翻譯的大樓');
  });

  test('room names use server translations and preserve Chinese when English is absent', () async {
    await LocaleSettings.setLocale(AppLocale.enUs);
    const room = CampusMapRoom(
      id: 'A1T_1F.101',
      buildingCode: 'A1T',
      buildingName: '第一教學大樓',
      floor: CampusMapFloor(layerName: 'gis_room:A1T_1F', code: '1F'),
      nameZh: '圖書館',
      nameEn: '',
      number: '101',
    );
    expect(campusMapBuildingName('圖書館'), 'Library');
    expect(campusMapRoomName(room), '圖書館');
    expect(campusMapRoomTitle(room), '101 · 圖書館');
    const translatedRoom = CampusMapRoom(
      id: 'A1T_1F.102',
      buildingCode: 'A1T',
      buildingName: '第一教學大樓',
      floor: CampusMapFloor(layerName: 'gis_room:A1T_1F', code: '1F'),
      nameZh: '原始中文名稱',
      nameEn: 'Original English name',
      number: '102',
    );
    expect(campusMapRoomName(translatedRoom), 'Original English name');
    expect(campusMapRoomTitle(translatedRoom), '102 · Original English name');
  });
}
