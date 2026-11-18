/// Search terms for spaces verified against the GeoServer layer and room number.
const campusMapRoomAliases =
    <({String building, String floor, String number}), List<String>>{
      // Verified from the matching GeoServer room features.
      (building: 'AD', floor: '1F', number: '101'): [
        '學務',
        '學務處',
        '課指組',
      ],
      (building: 'AD', floor: '2F', number: '201'): [
        '教學事務處',
      ],
      (building: 'AD', floor: '5F', number: '501'): [
        '產學',
        '產學處',
      ],
      (building: 'AD', floor: '7F', number: '701'): [
        '總務處',
        '總務',
      ],
      // GeoServer's Chinese name is 第一演講廳; its English field says "3rd Auditorium".
      (building: 'CB', floor: '1F', number: '125'): [
        '粽一',
        '綜一',
        '綜一演講廳',
        'first auditorium',
        '1st auditorium',
      ],
      (building: 'CB', floor: 'B1', number: 'B19'): [
        '粽二',
        '綜二',
        '綜二演講廳',
        'second auditorium',
        '2nd auditorium',
      ],
      (building: 'CB', floor: 'B1', number: 'B20'): [
        '粽三',
        '綜三',
        '綜三演講廳',
        'third auditorium',
        '3rd auditorium',
      ],
      (building: 'CK', floor: '1F', number: '107'): [
        '禮堂',
        '大禮堂',
        '中正廳',
        '中正禮堂',
        '中正館禮堂',
      ],
      (building: 'GB', floor: '1F', number: '110'): [
        '計中',
        '計網',
        '計算機中心',
        '計網中心',
      ],
      (building: 'GB', floor: 'B1', number: 'B07'): [
        '共科演講廳',
        'B1演講廳',
      ],
      // https://rnd.ntut.edu.tw/p/412-1042-1445.php?Lang=zh-tw
      (building: 'AD', floor: '6F', number: '602'): [
        '研發處',
        '研究發展處',
      ],
    };
