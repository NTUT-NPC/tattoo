import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

double _expansionProgress(
  SheetController controller,
  double collapsedSize,
) {
  return collapsedSize >= 1
      ? 1
      : SheetOffsetDrivenAnimation(
          controller: controller,
          initialValue: 0,
          startOffset: SheetOffset(collapsedSize),
          endOffset: const SheetOffset(1),
        ).value;
}

double _phase(double progress, double start, double end) =>
    Curves.easeInOutCubic.transform(
      ((progress - start) / (end - start)).clamp(0, 1),
    );

class CourseDetailCollapsingTitle extends StatelessWidget {
  const CourseDetailCollapsingTitle({
    super.key,
    required this.sheetController,
    required this.collapsedSize,
    required this.sizeAnchor,
    required this.child,
  });

  final SheetController sheetController;
  final double collapsedSize;
  final GlobalKey sizeAnchor;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: sheetController,
    child: child,
    builder: (context, child) {
      final progress = _phase(
        _expansionProgress(sheetController, collapsedSize),
        .6,
        1,
      );
      return ClipRect(
        child: Align(
          key: sizeAnchor,
          alignment: .topCenter,
          heightFactor: 1 - progress,
          child: Opacity(opacity: 1 - progress, child: child),
        ),
      );
    },
  );
}

class CourseDetailMorphingHeader extends StatefulWidget {
  const CourseDetailMorphingHeader({
    super.key,
    required this.sheetController,
    required this.scrollController,
    required this.collapsedSize,
    required this.initiallyFullHeight,
    required this.title,
    required this.sourceAnchor,
    required this.dragHandle,
    required this.child,
  });

  final SheetController sheetController;
  final ScrollController scrollController;
  final double collapsedSize;
  final bool initiallyFullHeight;
  final String title;
  final GlobalKey sourceAnchor;
  final Widget dragHandle;
  final Widget child;

  @override
  State<CourseDetailMorphingHeader> createState() =>
      _CourseDetailMorphingHeaderState();
}

class _CourseDetailMorphingHeaderState
    extends State<CourseDetailMorphingHeader> {
  final _targetAnchor = GlobalKey();
  final _titleOverlayKey = GlobalKey();
  Rect? _scrollSourceAtZero;
  Drag? _headerDrag;

  @override
  void didUpdateWidget(CourseDetailMorphingHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.initiallyFullHeight != widget.initiallyFullHeight) {
      _scrollSourceAtZero = null;
    }
  }

  @override
  void dispose() {
    _headerDrag?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final changes = Listenable.merge([
      widget.sheetController,
      widget.scrollController,
    ]);
    return AnimatedBuilder(
      animation: changes,
      child: widget.child,
      builder: (context, child) {
        final progress = _expansionProgress(
          widget.sheetController,
          widget.collapsedSize,
        );
        final appBarProgress = _phase(progress, .55, .9);
        final titleProgress = _phase(progress, .6, 1);
        final toolbarHeight =
            AppBarTheme.of(context).toolbarHeight ?? kToolbarHeight;
        final headerHeight = lerpDouble(
          kMinInteractiveDimension,
          toolbarHeight,
          appBarProgress,
        )!;
        final sourceStyle = DefaultTextStyle.of(context).style.merge(
          Theme.of(context).textTheme.titleLarge,
        );
        final sourceTextScaler = MediaQuery.textScalerOf(context);
        return Stack(
          children: [
            Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Forward header drags through the package's scroll position
                  // so scrolled content returns to the top before collapsing.
                  onVerticalDragStart: (details) {
                    _headerDrag?.cancel();
                    if (!widget.scrollController.hasClients) return;
                    _headerDrag = widget.scrollController.position.drag(
                      details,
                      () => _headerDrag = null,
                    );
                  },
                  onVerticalDragUpdate: (details) =>
                      _headerDrag?.update(details),
                  onVerticalDragEnd: (details) {
                    _headerDrag?.end(details);
                    _headerDrag = null;
                  },
                  onVerticalDragCancel: () {
                    _headerDrag?.cancel();
                    _headerDrag = null;
                  },
                  child: SizedBox(
                    height: headerHeight,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 1 - _phase(progress, .5, .75),
                          child: widget.dragHandle,
                        ),
                        PositionedDirectional(
                          top: 0,
                          start: 0,
                          end: 0,
                          height: toolbarHeight,
                          child: IgnorePointer(
                            ignoring: appBarProgress < 1,
                            child: Opacity(
                              opacity: appBarProgress,
                              child: Transform.translate(
                                offset: Offset(
                                  0,
                                  -toolbarHeight * (1 - appBarProgress),
                                ),
                                child: AppBar(
                                  primary: false,
                                  leading: BackButton(
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  title: ExcludeSemantics(
                                    child: Opacity(
                                      opacity: 0,
                                      child: Text(
                                        key: _targetAnchor,
                                        widget.title,
                                        maxLines: 1,
                                        overflow: .ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: child!),
              ],
            ),
            Positioned.fill(
              child: Semantics(
                label: widget.title,
                header: true,
                child: IgnorePointer(
                  child: CustomPaint(
                    key: _titleOverlayKey,
                    painter: _TitlePainter(
                      title: widget.title,
                      source: widget.sourceAnchor,
                      target: _targetAnchor,
                      overlay: _titleOverlayKey,
                      sourceStyle: sourceStyle,
                      sourceTextScaler: sourceTextScaler,
                      progress: titleProgress,
                      scrollController: widget.scrollController,
                      initiallyFullHeight: widget.initiallyFullHeight,
                      scrollSourceAtZero: _scrollSourceAtZero,
                      onScrollSourceMeasured: (rect) =>
                          _scrollSourceAtZero = rect,
                      direction: Directionality.of(context),
                      repaint: changes,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TitlePainter extends CustomPainter {
  _TitlePainter({
    required this.title,
    required this.source,
    required this.target,
    required this.overlay,
    required this.sourceStyle,
    required this.sourceTextScaler,
    required this.progress,
    required this.scrollController,
    required this.initiallyFullHeight,
    required this.scrollSourceAtZero,
    required this.onScrollSourceMeasured,
    required this.direction,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final String title;
  final GlobalKey source;
  final GlobalKey target;
  final GlobalKey overlay;
  final TextStyle sourceStyle;
  final TextScaler sourceTextScaler;
  final double progress;
  final ScrollController scrollController;
  final bool initiallyFullHeight;
  final Rect? scrollSourceAtZero;
  final ValueChanged<Rect> onScrollSourceMeasured;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final root = overlay.currentContext?.findRenderObject();
    final sourceBox = source.currentContext?.findRenderObject();
    final targetBox = target.currentContext?.findRenderObject();
    if (root is! RenderBox ||
        targetBox is! RenderParagraph ||
        !targetBox.hasSize) {
      return;
    }
    // Read anchors at paint time so viewport scrolling and sheet resizing use
    // this frame's transforms, without a post-frame measurement or setState.
    Rect bounds(RenderBox box) =>
        root.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
    final targetRect = bounds(targetBox);
    final scrollOffset = scrollController.hasClients
        ? scrollController.offset
        : 0.0;
    final liveSourceRect =
        sourceBox is RenderBox && sourceBox.attached && sourceBox.hasSize
        ? bounds(sourceBox)
        : null;
    Rect? sourceRect = liveSourceRect ?? scrollSourceAtZero;
    if (!initiallyFullHeight && liveSourceRect != null) {
      onScrollSourceMeasured(liveSourceRect);
    }
    if (initiallyFullHeight) {
      // The source can leave a lazily built ListView. Keep its position at
      // scroll offset zero so the title remains pinned in the AppBar.
      if (liveSourceRect case final rect?
          when scrollSourceAtZero == null ||
              rect.overlaps(Offset.zero & size)) {
        final origin = rect.shift(Offset(0, scrollOffset));
        sourceRect = origin;
        onScrollSourceMeasured(origin);
      } else {
        sourceRect = scrollSourceAtZero;
      }
    }
    if (sourceRect == null) return;
    final titleProgress = initiallyFullHeight
        ? (scrollOffset /
                  (sourceRect.center.dy - targetRect.center.dy).clamp(
                    1.0,
                    double.infinity,
                  ))
              .clamp(0.0, 1.0)
        : progress;
    // Read the AppBar's resolved style and scaler after layout rather than
    // duplicating its theme defaults or text scaling limit.
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle.lerp(
          sourceStyle.copyWith(inherit: false),
          targetBox.text.style?.copyWith(inherit: false),
          titleProgress,
        ),
      ),
      textScaler: _MorphingTextScaler(
        sourceTextScaler,
        targetBox.textScaler,
        titleProgress,
      ),
      textDirection: direction,
      locale: targetBox.locale,
      textAlign: .center,
      textWidthBasis: .longestLine,
      // Keep one paragraph during the drag; crop its lower lines as the
      // source title block shrinks, then use the AppBar's single-line ellipsis.
      maxLines: titleProgress == 1 ? 1 : null,
      ellipsis: titleProgress == 1 ? '…' : null,
    );
    try {
      painter.layout(
        maxWidth: lerpDouble(
          sourceRect.width,
          targetRect.width,
          titleProgress,
        )!,
      );
      final titleSize = painter.size;
      final start = Rect.fromCenter(
        center: sourceRect.center,
        width: titleSize.width,
        height: sourceRect.height,
      );
      final end = Rect.fromLTWH(
        direction == .ltr
            ? targetRect.left
            : targetRect.right - titleSize.width,
        targetRect.center.dy - targetRect.height / 2,
        titleSize.width,
        targetRect.height,
      );
      final rect = Rect.lerp(start, end, titleProgress)!;
      canvas.save();
      canvas.clipRect(rect);
      painter.paint(canvas, rect.topLeft);
      canvas.restore();
    } finally {
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(_TitlePainter oldDelegate) =>
      title != oldDelegate.title ||
      progress != oldDelegate.progress ||
      initiallyFullHeight != oldDelegate.initiallyFullHeight ||
      scrollSourceAtZero != oldDelegate.scrollSourceAtZero ||
      direction != oldDelegate.direction ||
      sourceStyle != oldDelegate.sourceStyle ||
      sourceTextScaler != oldDelegate.sourceTextScaler ||
      source != oldDelegate.source ||
      target != oldDelegate.target ||
      overlay != oldDelegate.overlay;
}

class _MorphingTextScaler extends TextScaler {
  const _MorphingTextScaler(this.source, this.target, this.progress);

  final TextScaler source;
  final TextScaler target;
  final double progress;

  @override
  double scale(double fontSize) =>
      lerpDouble(source.scale(fontSize), target.scale(fontSize), progress)!;

  @override
  double get textScaleFactor => scale(14) / 14;
}
