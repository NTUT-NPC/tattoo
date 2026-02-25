import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

/// Magic bytes identifying an embedded payload after JPEG EOI.
const _magic = [0x7A, 0x77, 0x00];

/// Format version, appended after [_magic].
const _version = 0x00;

/// Header size: 3 bytes magic + 1 byte version.
const _headerSize = 4;

/// Encodes a JPEG image with an embedded MessagePack payload.
///
/// Format: `[JPEG bytes] [3-byte magic] [1-byte version] [MessagePack payload]`
Uint8List encodeAvatarPayload(Uint8List jpeg, Map<String, dynamic> data) {
  final payload = serialize(data);
  final result = BytesBuilder(copy: false);
  result.add(jpeg);
  result.add(_magic);
  result.addByte(_version);
  result.add(payload);
  return result.toBytes();
}

/// Decodes an avatar file that may contain an embedded payload.
///
/// Returns the JPEG bytes, version, and decoded payload map. If no payload
/// is found (plain avatar without embedded data), returns null for both.
({Uint8List jpeg, int? version, Map<String, dynamic>? data})
decodeAvatarPayload(Uint8List bytes) {
  final index = _findMagic(bytes);
  if (index == -1) {
    return (jpeg: bytes, version: null, data: null);
  }

  final jpeg = Uint8List.sublistView(bytes, 0, index);
  final version = bytes[index + _magic.length];
  final payload = Uint8List.sublistView(bytes, index + _headerSize);
  final data = deserialize(payload);
  return (
    jpeg: jpeg,
    version: version,
    data: Map<String, dynamic>.from(data as Map),
  );
}

/// Searches for the magic bytes in [bytes], scanning forward from the
/// last JPEG EOI marker (`FF D9`) to avoid false positives inside
/// JPEG entropy data.
///
/// Returns the index of the magic sequence, or -1 if not found.
int _findMagic(Uint8List bytes) {
  // Find JPEG EOI to start searching after it
  var searchFrom = 0;
  for (var i = bytes.length - 2; i >= 0; i--) {
    if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
      searchFrom = i + 2;
      break;
    }
  }

  if (searchFrom + _headerSize > bytes.length) return -1;

  // Check if magic immediately follows EOI
  for (var i = 0; i < _magic.length; i++) {
    if (bytes[searchFrom + i] != _magic[i]) return -1;
  }
  return searchFrom;
}
