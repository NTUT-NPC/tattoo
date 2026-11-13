/// Search terms for spaces verified against the GeoServer layer and room number.
const campusMapRoomAliases =
    <({String building, String floor, String number}), List<String>>{
      // https://ece.ntut.edu.tw/p/405-1071-5660,c2678.php?Lang=zh-tw
      (building: 'CB', floor: '3F', number: '302'): ['高立人', 'Lih-Jen Kau'],
      // https://rnd.ntut.edu.tw/p/412-1042-1445.php?Lang=zh-tw
      (building: 'AD', floor: '6F', number: '602'): ['研發處', '研究發展處'],
    };
