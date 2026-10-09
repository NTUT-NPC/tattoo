import 'dart:io';

import 'package:path/path.dart' as p;

/// Chooses an attachment filename and removes unsafe path characters.
String materialFileName({
  String? disposition,
  String? title,
  String? contentType,
}) {
  String? name;
  if (disposition != null) {
    try {
      final parameters = HeaderValue.parse(disposition).parameters;
      final encoded = parameters['filename*'];
      if (encoded != null) {
        final parts = encoded.split("'");
        if (parts.length == 3 && parts.first.toLowerCase() == 'utf-8') {
          name = Uri.decodeComponent(parts[2]);
        }
      }
      name ??= parameters['filename'];
    } on FormatException {
      // Fall back to the material title when the server sends a malformed header.
    } on ArgumentError {
      // RFC 5987 filename encoding may itself be malformed.
    }
  }
  name = p.posix
      .basename(p.windows.basename(name ?? title ?? 'material'))
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();
  if (name.isEmpty || name == '.') name = 'material';
  final extension = p.extension(name);
  if (name.length > 180) name = '${name.substring(0, 160)}$extension';
  if (extension.isEmpty) {
    name += switch (contentType?.split(';').first.trim().toLowerCase()) {
      'application/pdf' => '.pdf',
      'application/zip' => '.zip',
      'application/msword' => '.doc',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' =>
        '.docx',
      'application/vnd.ms-powerpoint' => '.ppt',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation' =>
        '.pptx',
      'application/vnd.ms-excel' => '.xls',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' =>
        '.xlsx',
      'text/plain' => '.txt',
      'image/jpeg' => '.jpg',
      'image/png' => '.png',
      _ => '',
    };
  }
  if (RegExp(
    r'^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$',
    caseSensitive: false,
  ).hasMatch(p.basenameWithoutExtension(name))) {
    name = '_$name';
  }
  return name;
}
