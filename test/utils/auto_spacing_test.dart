import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/auto_spacing.dart';

void main() {
  final sp = String.fromCharCode(0x2005); // FOUR-PER-EM SPACE (1/4 em)

  group('spaced', () {
    test('inserts a space between CJK and following Latin', () {
      expect('關於TAT'.spaced, '關於${sp}TAT');
    });

    test('inserts a space between Latin and following CJK', () {
      expect('TAT的實作'.spaced, 'TAT$sp的實作');
    });

    test('spaces both sides of an embedded Latin run', () {
      expect('發生Flutter錯誤'.spaced, '發生${sp}Flutter$sp錯誤');
    });

    test('spaces digits against CJK', () {
      expect('歷年GPA'.spaced, '歷年${sp}GPA');
      expect('密碼將在1天後過期'.spaced, '密碼將在${sp}1$sp天後過期');
    });

    test('leaves ASCII punctuation between scripts untouched', () {
      // Closing paren is punctuation, not a letter/digit — no space added.
      expect('Project Tattoo (TAT)是'.spaced, 'Project Tattoo (TAT)是');
    });

    test('is a no-op for English-only text', () {
      expect('Project Tattoo'.spaced, 'Project Tattoo');
    });

    test('is a no-op for CJK-only text', () {
      expect('北科生活'.spaced, '北科生活');
    });

    test('is idempotent', () {
      final once = '關於TAT'.spaced;
      expect(once.spaced, once);
    });

    test('handles empty string', () {
      expect(''.spaced, '');
    });
  });
}
