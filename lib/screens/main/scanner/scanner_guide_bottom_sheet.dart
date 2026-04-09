import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tattoo/i18n/strings.g.dart';

class ScannerGuideSheet extends StatelessWidget {
  final DraggableScrollableController controller;
  final bool isProcessing;
  final bool isSuccess;
  final String? error;
  final VoidCallback? onDismissError;

  static const maxSheetSize = 1.0;

  const ScannerGuideSheet({
    super.key,
    required this.controller,
    this.isProcessing = false,
    this.isSuccess = false,
    this.error,
    this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight + topPadding;
    final availableHeight = screenHeight - appBarHeight;

    // Calculate dynamic sizes relative to the available body height
    final minChildHeight = bottomPadding + 80;
    final minChildFraction = (minChildHeight / availableHeight).clamp(0.0, 1.0);

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: minChildFraction,
      minChildSize: minChildFraction,
      maxChildSize: maxSheetSize,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
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
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SelectionArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildContent(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isSuccess) return _buildSuccessView(context);
    if (error != null) return _buildErrorView(context, error!);
    if (isProcessing) return _buildProcessingView(context);
    return _buildGuideView(context);
  }

  Widget _buildSuccessView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
        const SizedBox(height: 16),
        Text(
          t.scanner.success,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('error'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.error_outline, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          t.scanner.failed,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        FilledButton.tonal(
          onPressed: onDismissError,
          child: Text(t.general.ok),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProcessingView(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('processing'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 48),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          t.scanner.loggingIn,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 64),
      ],
    );
  }

  Widget _buildGuideView(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    final appBarHeight = kToolbarHeight + topPadding;
    final availableHeight = screenHeight - appBarHeight;
    final minChildHeight = bottomPadding + 80;
    final minChildFraction = (minChildHeight / availableHeight).clamp(0.0, 1.0);

    return Column(
      key: const ValueKey('guide'),
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
        SelectionContainer.disabled(
          child: FilledButton.tonal(
            onPressed: () {
              controller.animateTo(
                minChildFraction,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
            child: Text(t.scanner.guide.button),
          ),
        ),
        const SizedBox(height: 24),
      ],
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
