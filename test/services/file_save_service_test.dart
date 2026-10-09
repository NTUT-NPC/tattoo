import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tattoo/services/file_save_service.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('export-test-');
  });
  tearDown(() => root.delete(recursive: true));
  for (final result in ['saved', null]) {
    test('cleans temporary files after save result $result', () async {
      final store = FileSaveService(
        temporaryDirectory: () async => root,
        saveFile: (path, name) async {
          expect(await File(path).readAsString(), 'Content');
          return result;
        },
      );
      final saved = await store.saveDownloadedFile((directory) async {
        final file = File(p.join(directory, 'notes.txt'));
        await file.writeAsString('Content');
        return (path: file.path, fileName: 'notes.txt');
      });
      expect(saved, result != null);
      expect(await root.list().isEmpty, isTrue);
    });
  }
  test('native save dialogs never overlap, even across downloads', () async {
    final firstPicker = Completer<String?>();
    var downloads = 0;
    var pickers = 0;
    final store = FileSaveService(
      temporaryDirectory: () async => root,
      saveFile: (_, _) async {
        pickers++;
        return pickers == 1 ? firstPicker.future : 'saved';
      },
    );
    Future<({String path, String fileName})> download(String directory) async {
      downloads++;
      final file = File(p.join(directory, 'notes.txt'));
      await file.writeAsString('Content');
      return (path: file.path, fileName: 'notes.txt');
    }

    final first = store.saveDownloadedFile(download);
    while (pickers == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    final second = store.saveDownloadedFile(download);
    await pumpEventQueue();
    expect(downloads, 1);
    expect(pickers, 1);
    firstPicker.complete(null);
    expect(await first, isFalse);
    expect(await second, isTrue);
    expect(pickers, 2);
    expect(await root.list().isEmpty, isTrue);
  });
  test(
    'picker failure cleans the file and does not block subsequent saves',
    () async {
      var failNext = true;
      final store = FileSaveService(
        temporaryDirectory: () async => root,
        saveFile: (_, _) async {
          if (failNext) {
            failNext = false;
            throw Exception('Picker failed');
          }
          return 'saved';
        },
      );
      Future<({String path, String fileName})> download(
        String directory,
      ) async {
        final file = File(p.join(directory, 'notes.txt'));
        await file.writeAsString('Content');
        return (path: file.path, fileName: 'notes.txt');
      }

      await expectLater(store.saveDownloadedFile(download), throwsException);
      expect(await root.list().isEmpty, isTrue);
      expect(await store.saveDownloadedFile(download), isTrue);
    },
  );
  test(
    'download failure removes partial files without opening picker',
    () async {
      final store = FileSaveService(
        temporaryDirectory: () async => root,
        saveFile: (_, _) async {
          fail('Picker must not open after a download failure');
        },
      );
      await expectLater(
        store.saveDownloadedFile((directory) async {
          await File(p.join(directory, 'partial')).writeAsString('partial');
          throw const FileSystemException('Failed');
        }),
        throwsA(isA<FileSystemException>()),
      );
      expect(await root.list().isEmpty, isTrue);
    },
  );
  test(
    'cancelled export does not open picker and cleans the completed file',
    () async {
      final store = FileSaveService(
        temporaryDirectory: () async => root,
        saveFile: (_, _) async {
          fail('Picker must not open when cancelled');
        },
      );
      expect(
        await store.saveDownloadedFile((directory) async {
          final file = File(p.join(directory, 'notes'));
          await file.writeAsString('Notes');
          return (path: file.path, fileName: 'notes');
        }, canSave: () => false),
        isFalse,
      );
      expect(await root.list().isEmpty, isTrue);
    },
  );
}
