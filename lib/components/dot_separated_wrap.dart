import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class DotSeparatedWrap extends Wrap {
  const DotSeparatedWrap({super.key, required super.children, this.style})
    : super(alignment: .center, crossAxisAlignment: .center);

  final TextStyle? style;

  TextPainter _separator(BuildContext context) => TextPainter(
    text: TextSpan(
      text: ' · ',
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();

  @override
  RenderWrap createRenderObject(BuildContext context) =>
      _RenderDotSeparatedWrap(
        separator: _separator(context),
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderWrap renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderDotSeparatedWrap).separator = _separator(context);
  }
}

class _RenderDotSeparatedWrap extends RenderWrap {
  _RenderDotSeparatedWrap({
    required TextPainter separator,
    required super.textDirection,
  }) : _separator = separator,
       super(
         alignment: .center,
         crossAxisAlignment: .center,
         spacing: separator.width,
       );

  TextPainter _separator;

  set separator(TextPainter value) {
    _separator.dispose();
    _separator = value;
    spacing = value.width;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    Rect? previous;
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as WrapParentData;
      final rect = parentData.offset & child.size;
      // Center-aligned children in the same run share a vertical center.
      if (previous case final before?
          when (before.center.dy - rect.center.dy).abs() < 0.01) {
        final gapCenter = textDirection == TextDirection.rtl
            ? (rect.right + before.left) / 2
            : (before.right + rect.left) / 2;
        _separator.paint(
          context.canvas,
          offset +
              Offset(
                gapCenter - _separator.width / 2,
                rect.center.dy - _separator.height / 2,
              ),
        );
      }
      previous = rect;
      child = parentData.nextSibling;
    }
  }

  @override
  void dispose() {
    _separator.dispose();
    super.dispose();
  }
}
