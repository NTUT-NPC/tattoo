import 'package:flutter_test/flutter_test.dart';
import 'package:tattoo/utils/material_file_name.dart';

void main() {
  test('prefers UTF-8 attachment filename over manifest title', () {
    expect(
      materialFileName(
        disposition: "attachment; filename=fallback.pdf; filename*=UTF-8''%E6%95%99%E6%9D%90.pdf",
        title: 'Lecture',
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
      materialFileName(title: '..', contentType: 'application/pdf'),
      'material.pdf',
    );
    expect(materialFileName(title: 'CON.txt'), '_CON.txt');
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
}
