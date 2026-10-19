import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/material_file_name.dart';

void main() {
  test('prefers the material title over the server attachment name', () {
    expect(
      materialFileName(
        disposition: "attachment; filename=fallback.pdf; filename*=UTF-8''%E6%95%99%E6%9D%90.pdf",
        title: 'Lecture',
      ),
      'Lecture.pdf',
    );
    expect(
      materialFileName(
        disposition: "attachment; filename=\"'ebook.pdf'\"",
        title: 'CT_L0.pdf',
      ),
      'CT_L0.pdf',
    );
    expect(
      materialFileName(
        disposition: "attachment; filename*=UTF-8''%E6%95%99%E6%9D%90.pdf",
        title: ' ',
      ),
      '教材.pdf',
    );
  });
  test('removes server paths and unsafe control characters', () {
    expect(
      materialFileName(disposition: 'attachment; filename="../../notes.pdf"'),
      'notes.pdf',
    );
    expect(materialFileName(title: 'Week:1?'), 'Week_1_');
    expect(
      materialFileName(
        title: 'Week/1',
        disposition: 'attachment; filename=ebook.pdf',
      ),
      'Week_1.pdf',
    );
    expect(
      materialFileName(title: '..', contentType: 'application/pdf'),
      'material.pdf',
    );
    expect(materialFileName(title: 'CON.txt'), '_CON.txt');
  });
  test('retains filename when the encoded attachment name is malformed', () {
    expect(
      materialFileName(
        disposition: "attachment; filename=123456.rar; filename*=UTF-8''%zz",
        title: 'Solution Manual',
      ),
      'Solution Manual.rar',
    );
  });
  test('infers archive extensions without using numbered attachment names', () {
    for (final (contentType, extension) in [
      ('application/vnd.rar', '.rar'),
      ('application/x-rar', '.rar'),
      ('application/x-rar-compressed', '.rar'),
      ('application/x-7z-compressed', '.7z'),
      ('application/x-zip-compressed', '.zip'),
      ('application/gzip', '.gz'),
      ('application/x-gzip', '.gz'),
    ]) {
      expect(
        materialFileName(
          disposition: 'attachment; filename=123456',
          title: 'Solution Manual',
          contentType: '$contentType; charset=binary',
        ),
        'Solution Manual$extension',
      );
    }
    expect(
      materialFileName(
        title: 'Solution Manual',
        contentType: 'application/octet-stream',
      ),
      'Solution Manual',
    );
  });
  test('infers missing extension and preserves existing filenames', () {
    expect(
      materialFileName(
        title: 'Lecture',
        contentType: 'application/pdf; charset=binary',
      ),
      'Lecture.pdf',
    );
    expect(
      materialFileName(title: 'archive.tar.gz', contentType: 'application/zip'),
      'archive.tar.gz',
    );
    expect(
      materialFileName(
        disposition: 'broken; filename*="UTF-8\'\'%zz"',
        title: 'Notes',
      ),
      'Notes',
    );
  });
  test('infers file types when dots belong to the material title', () {
    expect(
      materialFileName(
        disposition: 'attachment; filename=123456',
        title: 'Lecture 1. Introduction',
        contentType: 'application/pdf',
      ),
      'Lecture 1. Introduction.pdf',
    );
    expect(
      materialFileName(
        disposition: 'attachment; filename="Lecture 1. Introduction"',
        contentType: 'application/pdf',
      ),
      'Lecture 1. Introduction.pdf',
    );
    expect(
      materialFileName(
        title: 'Lecture 1. Introduction',
        contentType: 'application/octet-stream',
        leadingBytes: [0x25, 0x50, 0x44, 0x46, 0x2d],
      ),
      'Lecture 1. Introduction.pdf',
    );
    expect(
      materialFileName(title: 'Lecture 1. Introduction'),
      'Lecture 1. Introduction',
    );
  });
  test('preserves plausible extensions including uncommon file types', () {
    expect(
      materialFileName(title: 'Example.ipynb', contentType: 'text/plain'),
      'Example.ipynb',
    );
    expect(
      materialFileName(title: 'Archive.7z', contentType: 'application/zip'),
      'Archive.7z',
    );
    expect(
      materialFileName(title: 'Lecture.PDF', contentType: 'application/pdf'),
      'Lecture.PDF',
    );
  });
}
