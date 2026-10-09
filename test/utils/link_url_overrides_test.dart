import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/link_url_overrides.dart';

void main() {
  group('parseLinkUrlOverrides', () {
    test('maps listed IDs to their URLs', () {
      expect(
        parseLinkUrlOverrides('[{"id": "a", "url": " https://a.test "}]'),
        {'a': 'https://a.test'},
      );
    });

    test('maps empty or missing URLs to null', () {
      expect(
        parseLinkUrlOverrides('[{"id": "a", "url": ""}, {"id": "b"}]'),
        {'a': null, 'b': null},
      );
    });

    test('skips entries without a string ID', () {
      expect(
        parseLinkUrlOverrides('[{"url": "https://a.test"}, {"id": 1}, 2]'),
        isEmpty,
      );
    });

    test('returns empty for malformed or non-array JSON', () {
      expect(parseLinkUrlOverrides(''), isEmpty);
      expect(parseLinkUrlOverrides('not json'), isEmpty);
      expect(parseLinkUrlOverrides('{"id": "a"}'), isEmpty);
    });
  });
}
