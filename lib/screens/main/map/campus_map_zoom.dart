import 'package:tattoo/shells/adaptive_navigation_scaffold.dart';

/// Building labels yield to campus outlines below this overview scale.
const campusMapBuildingLabelMinZoom = 16.5;

/// Separate entry and exit thresholds prevent indoor selection from flickering.
const campusMapBuildingAutoSelectZoom = 19.5;
const campusMapBuildingDeselectZoom = 18.0;

/// Enlarges labels smoothly in wide map views, up to 1.8 times their base size.
///
/// Compact views retain their existing size. Uses logical map width so desktop
/// window resizing works independently of pixel density and system text scaling.
double campusMapAreaLabelViewportScale(double width) =>
    1 + ((width - navigationRailBreakpoint) / 600).clamp(0.0, 0.8);

/// Grows labels smoothly from half size at overview to full size at zoom 19.
///
/// Smoothstep eases both ends without reflowing text during fractional zooms.
double campusMapBuildingLabelScale(double zoom) {
  if (zoom < campusMapBuildingLabelMinZoom) return 0;
  final progress = ((zoom - campusMapBuildingLabelMinZoom) / 2.5).clamp(
    0.0,
    1.0,
  );
  return 0.5 + 0.5 * progress * progress * (3 - 2 * progress);
}
