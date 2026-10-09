import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/services/i_school_plus/i_school_plus_service.dart';

final fileSaveServiceProvider = Provider<FileSaveService>(
  (ref) => FileSaveService(),
);

/// Exports temporary downloads through the Android and iOS save dialogs.
class FileSaveService {
  Future<void> _saveTail = Future.value();

  final Future<Directory> Function() _temporaryDirectory;
  final Future<String?> Function(String path, String fileName) _saveFile;

  FileSaveService({
    Future<Directory> Function()? temporaryDirectory,
    Future<String?> Function(String path, String fileName)? saveFile,
  }) : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
       _saveFile =
           saveFile ??
           ((path, fileName) => FlutterFileDialog.saveFile(
             params: SaveFileDialogParams(
               sourceFilePath: path,
               fileName: fileName,
             ),
           ));

  /// Downloads and exports a file, cleaning temporary data on every outcome.
  ///
  /// Returns `false` when cancelled. Serializes downloads and save dialogs so
  /// multiple requests cannot open overlapping native pickers.
  Future<bool> saveDownloadedFile(
    Future<MaterialFileDto> Function(String directory) download, {
    bool Function()? canSave,
  }) {
    final task = _saveTail.then(
      (_) => _saveDownloadedFile(download, canSave: canSave),
    );
    _saveTail = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<bool> _saveDownloadedFile(
    Future<MaterialFileDto> Function(String directory) download, {
    bool Function()? canSave,
  }) async {
    if (canSave?.call() == false) return false;
    final directory = await (await _temporaryDirectory()).createTemp(
      'tattoo-material-',
    );
    try {
      final file = await download(directory.path);
      if (canSave?.call() == false) return false;
      return await _saveFile(file.path, file.fileName) != null;
    } finally {
      await directory.delete(recursive: true);
    }
  }
}
