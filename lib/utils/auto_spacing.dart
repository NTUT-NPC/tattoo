/// Inserts a four-per-em space (U+2005) between adjacent CJK ideographs and
/// Latin letters or digits, approximating the inter-script gap specified by the
/// W3C's Requirements for Chinese Text Layout (CLREQ) and CSS
/// `text-autospace: ideograph-alpha ideograph-numeric`.
///
/// CLREQ targets *flexible* spacing applied by the layout engine — a default of
/// 1/4 em, compressible to 1/8 em and expandable to 1/2 em during
/// justification. Flutter has no native inter-script spacing
/// (https://github.com/flutter/flutter/issues/94531), so this inserts a fixed
/// U+2005 (exactly 1/4 em, the CLREQ resting width) as the closest static
/// approximation. Hardcoding a regular space in source strings instead would
/// produce an incorrect ~1/2 em gap and double up if native support ever lands,
/// so apply this at render time — see issue #178.
///
/// Only Han ideographs are treated as CJK and only ASCII letters/digits as
/// Latin; punctuation on either side is left untouched, matching the CSS spec.
/// For non-mixed text (e.g. English-only strings) this is a cheap no-op.
extension AutoSpacing on String {
  static const _space = '\u2005';

  // CJK Extension A, Unified Ideographs, and Compatibility Ideographs.
  static const _cjk = '\u3400-\u4DBF\u4E00-\u9FFF\uF900-\uFAFF';
  static const _latin = 'A-Za-z0-9';

  static final _cjkThenLatin = RegExp('([$_cjk])([$_latin])');
  static final _latinThenCjk = RegExp('([$_latin])([$_cjk])');

  /// This string with 1/4-em spaces inserted at CJK–Latin boundaries.
  String get spaced =>
      replaceAllMapped(
        _cjkThenLatin,
        (m) => '${m[1]}$_space${m[2]}',
      ).replaceAllMapped(
        _latinThenCjk,
        (m) => '${m[1]}$_space${m[2]}',
      );
}
