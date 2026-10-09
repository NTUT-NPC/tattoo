import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
import 'package:tattoo/screens/main/course_table/course_table_providers.dart';
import 'package:tattoo/utils/auto_spacing.dart';

class CourseMaterialsList extends StatelessWidget {
  const CourseMaterialsList({super.key, required this.materials});

  final List<CourseMaterial> materials;

  @override
  Widget build(BuildContext context) => Card(
    margin: const .all(8),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: .circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    color: Theme.of(context).colorScheme.surfaceContainer,
    clipBehavior: .antiAlias,
    child: SizedBox(
      height: min(420, MediaQuery.sizeOf(context).height * 0.45),
      child: ListView.builder(
        itemCount: materials.length,
        itemBuilder: (context, index) => _MaterialTile(
          key: ValueKey(materials[index].id),
          material: materials[index],
        ),
      ),
    ),
  );
}

class _MaterialTile extends ConsumerStatefulWidget {
  const _MaterialTile({super.key, required this.material});
  final CourseMaterial material;

  @override
  ConsumerState<_MaterialTile> createState() => _MaterialTileState();
}

class _MaterialTileState extends ConsumerState<_MaterialTile>
    with AutomaticKeepAliveClientMixin {
  CancelToken? _cancelToken;
  double? _progress;
  var _saving = false;

  @override
  bool get wantKeepAlive => _cancelToken != null;

  Future<void> _download() async {
    if (_cancelToken != null) return;
    final token = CancelToken();
    setState(() {
      _cancelToken = token;
      _progress = null;
      _saving = false;
    });
    updateKeepAlive();
    final strings = Translations.of(context).courseTable.detail.materials;
    try {
      final saved = await ref
          .read(courseRepositoryProvider)
          .saveMaterial(
            widget.material,
            cancelToken: token,
            onReceiveProgress: (received, total) {
              if (mounted && !token.isCancelled) {
                setState(() => _progress = total > 0 ? received / total : null);
              }
            },
            onSaving: () {
              if (mounted && !token.isCancelled) setState(() => _saving = true);
            },
          );
      if (saved && mounted) _showMessage(strings.saved);
    } catch (error) {
      if (mounted && !token.isCancelled) {
        _showMessage(
          error is UnsupportedError
              ? strings.streamUnavailable
              : strings.downloadFailed,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _cancelToken = null;
          _saving = false;
          _progress = null;
        });
        updateKeepAlive();
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message.spaced)));
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Material pane closed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = Translations.of(context).courseTable.detail.materials;
    final typeProvider = courseMaterialTypeProvider(widget.material);
    final type = switch (widget.material.streamable) {
      final streamable? => AsyncData(streamable),
      null => ref.watch(typeProvider),
    };
    final streamable = type.value;
    final downloading = _cancelToken != null;
    final title = widget.material.title;
    return ListTile(
      isThreeLine: streamable == true,
      leading: Icon(
        streamable == true
            ? Icons.video_library_outlined
            : Icons.insert_drive_file_outlined,
      ),
      title: Text(
        (title == null || title.isEmpty ? strings.unnamed : title).spaced,
      ),
      subtitle: downloading
          ? Column(
              crossAxisAlignment: .start,
              mainAxisSize: .min,
              children: [
                Text((_saving ? strings.saving : strings.downloading).spaced),
                if (!_saving) LinearProgressIndicator(value: _progress),
              ],
            )
          : Text(
              (streamable == true
                      ? '${strings.stream} · ${strings.streamUnavailable}'
                      : streamable == false
                      ? strings.file
                      : type.hasError
                      ? strings.resolveFailed
                      : strings.resolving)
                  .spaced,
            ),
      trailing: downloading
          ? IconButton(
              tooltip: strings.cancel.spaced,
              onPressed: _saving
                  ? null
                  : () => _cancelToken?.cancel(
                      'User cancelled material download',
                    ),
              icon: const Icon(Icons.close),
            )
          : streamable == false
          ? IconButton(
              tooltip: strings.download.spaced,
              onPressed: _download,
              icon: const Icon(Icons.download_outlined),
            )
          : type.hasError
          ? IconButton(
              tooltip: strings.retry.spaced,
              onPressed: () => ref.invalidate(typeProvider),
              icon: const Icon(Icons.refresh),
            )
          : streamable == null
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
    );
  }
}
