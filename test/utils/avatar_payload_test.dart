import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/avatar_payload.dart';

/// Minimal valid JPEG: SOI + EOI.
final _minimalJpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]);

void main() {
  group('encodeAvatarPayload', () {
    test('appends header and payload after JPEG bytes', () {
      final data = {'key': 'value'};
      final result = encodeAvatarPayload(_minimalJpeg, data);

      // JPEG bytes preserved at the start
      expect(result.sublist(0, 4), _minimalJpeg);
      // Magic bytes follow EOI
      expect(result.sublist(4, 7), [0x7A, 0x77, 0x00]);
      // Version byte
      expect(result[7], 0x00);
      // Payload exists after header
      expect(result.length, greaterThan(8));
    });
  });

  group('decodeAvatarPayload', () {
    test('roundtrips data through encode/decode', () {
      final data = {'bool': true, 'int': 42, 'string': 'hello'};
      final encoded = encodeAvatarPayload(_minimalJpeg, data);
      final decoded = decodeAvatarPayload(encoded);

      expect(decoded.jpeg, _minimalJpeg);
      expect(decoded.version, 0);
      expect(decoded.data, data);
    });

    test('returns null payload for plain JPEG without embedded data', () {
      final decoded = decodeAvatarPayload(_minimalJpeg);

      expect(decoded.jpeg, _minimalJpeg);
      expect(decoded.version, isNull);
      expect(decoded.data, isNull);
    });

    test('returns null payload when bytes after EOI are not magic', () {
      final bytes = Uint8List.fromList([
        ..._minimalJpeg,
        0x00, 0x00, 0x00, 0x00, // random trailing bytes
      ]);
      final decoded = decodeAvatarPayload(bytes);

      expect(decoded.data, isNull);
    });

    test('handles empty map', () {
      final encoded = encodeAvatarPayload(_minimalJpeg, {});
      final decoded = decodeAvatarPayload(encoded);

      expect(decoded.jpeg, _minimalJpeg);
      expect(decoded.version, 0);
      expect(decoded.data, isEmpty);
    });

    test('ignores magic-like bytes inside JPEG data', () {
      // JPEG with magic bytes in entropy data, before EOI
      final jpegWithMagicInBody = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0x7A, 0x77, 0x00, // magic bytes inside JPEG body
        0xFF, 0xD9, // EOI
      ]);
      final decoded = decodeAvatarPayload(jpegWithMagicInBody);

      expect(decoded.jpeg, jpegWithMagicInBody);
      expect(decoded.data, isNull);
    });

    test('preserves larger JPEG bytes', () {
      final largeJpeg = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        ...List.filled(1000, 0x42), // body
        0xFF, 0xD9, // EOI
      ]);
      final data = {'synced': true};
      final encoded = encodeAvatarPayload(largeJpeg, data);
      final decoded = decodeAvatarPayload(encoded);

      expect(decoded.jpeg, largeJpeg);
      expect(decoded.data, data);
    });

    test('handles nested map values', () {
      final data = {
        'theme': {'primary': 0xFF6200EE, 'dark': true},
      };
      final encoded = encodeAvatarPayload(_minimalJpeg, data);
      final decoded = decodeAvatarPayload(encoded);

      expect(decoded.data!['theme'], {'primary': 0xFF6200EE, 'dark': true});
    });
  });
}
