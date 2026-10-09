import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/course_repository.dart';
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
    child: Column(
      mainAxisSize: .min,
      children: [
        for (final material in materials)
          _MaterialTile(key: ValueKey(material.id), material: material),
      ],
    ),
  );
}

class _MaterialTile extends ConsumerStatefulWidget {
  const _MaterialTile({super.key, required this.material});
  final CourseMaterial material;

  @override
  ConsumerState<_MaterialTile> createState() => _MaterialTileState();
}

class _MaterialTileState extends ConsumerState<_MaterialTile> {
  CancelToken? _cancelToken;
  double? _progress;
  var _saving = false;
  String? _errorMessage;

  Future<void> _download() async {
    if (_cancelToken != null) return;
    final strings = Translations.of(context).courseTable.detail.materials;
    if (widget.material.streamable == true) {
      _showError(strings.streamUnavailable);
      return;
    }
    final token = CancelToken();
    setState(() {
      _cancelToken = token;
      _progress = null;
      _saving = false;
      _errorMessage = null;
    });
    String? errorMessage;
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
        errorMessage = error is UnsupportedError
            ? strings.streamUnavailable
            : strings.downloadFailed;
      }
    } finally {
      if (mounted) {
        setState(() {
          _cancelToken = null;
          _saving = false;
          _progress = null;
        });
      }
    }
    if (errorMessage case final message? when mounted) {
      _showError(message);
    }
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    _showMessage(message);
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
    final strings = Translations.of(context).courseTable.detail.materials;
    final downloading = _cancelToken != null;
    final title = widget.material.title;
    return ListTile(
      onTap: downloading ? null : _download,
      title: Text(
        (title == null || title.isEmpty ? strings.unnamed : title).spaced,
      ),
      trailing: SizedBox.square(
        dimension: 48,
        child: downloading
            ? Semantics(
                liveRegion: true,
                label: (_saving ? strings.saving : strings.downloading).spaced,
                child: Stack(
                  alignment: .center,
                  children: [
                    SizedBox.square(
                      dimension: 32,
                      child: CircularProgressIndicator(
                        value: _saving ? null : _progress,
                        strokeWidth: 2,
                      ),
                    ),
                    IconButton(
                      tooltip:
                          (_saving ? strings.saving : strings.cancel).spaced,
                      onPressed: _saving
                          ? null
                          : () => _cancelToken?.cancel(
                              'User cancelled material download',
                            ),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              )
            : IconButton(
                tooltip: (_errorMessage ?? strings.download).spaced,
                onPressed: _download,
                icon: Icon(
                  _errorMessage == null
                      ? Icons.download_outlined
                      : Icons.error_outline,
                  color: _errorMessage == null
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              ),
      ),
    );
  }
}
