/// Exact classroom name → English translation.
///
/// For named venues that don't follow the building-prefix + room pattern.
const classroomNames = {
  '科研哈佛講堂': 'HYTRB B424',
  '思源講堂': 'CB 417-2',
  '綜一演講廳': 'CB 1A',
  '綜二演講廳': 'CB 2A',
  '綜三演講廳': 'CB 3A',
  '共同演講廳': 'GSB B1A',
  '光華階梯教室': 'GHB B4F',
};

/// Maps Chinese building name prefixes to English abbreviations.
///
/// Longer prefixes must precede their substrings (e.g., 科研大樓 before 科研)
/// since the first match wins.
///
/// Source: [OIA Guide for New Students](https://oia.ntut.edu.tw/var/file/32/1032/img/GuideForNewStudents.pdf).
const classroomPrefixes = {
  '科研大樓': 'HYTRB',
  '科研': 'HYTRB',
  '一教': '1TB',
  '二教': '2TB',
  '三教': '3TB',
  '四教': '4TB',
  '五教': '5TB',
  '六教': '6TB',
  '共同': 'GSB',
  '綜科': 'CB',
  '設計': 'DB',
  '土木': 'CEB',
  '億光': 'EB',
  '光華館': 'GHB',
  '光華': 'GHB',
  '化工': 'ChemEB',
  '化學': 'ChemB',
  '先鋒': 'PIB',
  '分子館': 'MSE',
  '分子': 'MSE',
  '紡織': 'TEB',
  '國百館': 'SYMH',
  '材資': 'MRB',
};

/// Translates a Chinese classroom name to abbreviated English format.
///
/// Returns `null` if the classroom name is not recognized.
String? translateClassroomName(String nameZh) {
  final exact = classroomNames[nameZh];
  if (exact != null) return exact;

  for (final MapEntry(key: prefix, value: abbrev)
      in classroomPrefixes.entries) {
    if (nameZh.startsWith(prefix)) {
      final room = nameZh.substring(prefix.length);
      return '$abbrev $room';
    }
  }
  return null;
}
