import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tattoo/i18n/strings.g.dart';

class ScannerGuideSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  final bool isProcessing;

  const ScannerGuideSheet({
    super.key,
    required this.controller,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.1,
      minChildSize: 0.08,
      maxChildSize: 0.53,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SelectionArea(
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        t.scanner.guide.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.scanner.guide.step1,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildUrlBox(context, t.scanner.guide.url),
                      const SizedBox(height: 16),
                      Text(
                        t.scanner.guide.step2,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.scanner.guide.step3,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      FilledButton.tonal(
                        onPressed: isProcessing
                            ? null
                            : () {
                                controller.animateTo(
                                  0.08,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              },
                        child: isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(t.scanner.guide.button),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUrlBox(BuildContext context, String url) {
    final colorScheme = Theme.of(context).colorScheme;

    const scheme = 'https://';
    final rest = url.startsWith(scheme) ? url.substring(scheme.length) : url;

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.general.copied),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withAlpha(50),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'monospace',
              color: colorScheme.onSurfaceVariant,
            ),
            children: [
              TextSpan(
                text: scheme,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withAlpha(120),
                  fontWeight: FontWeight.normal,
                ),
              ),
              TextSpan(
                text: rest,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
