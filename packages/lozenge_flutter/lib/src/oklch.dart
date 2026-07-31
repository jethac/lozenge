part of '../lozenge_flutter.dart';

/// An OKLCH color triple with conversion to gamut-clamped sRGB.
///
/// The conversion and the chroma-reduction gamut mapping mirror the web
/// engine (culori's `clampChroma`): out-of-gamut colors reduce chroma —
/// preserving lightness and hue — until they fit sRGB.
class LzOklch {
  final double l;
  final double c;
  final double h;
  const LzOklch(this.l, this.c, this.h);

  static double _srgbEncode(double v) => v <= 0.0031308
      ? 12.92 * v
      : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

  /// Linear-sRGB channels for this OKLCH color (may be out of [0,1]).
  List<double> _linearRgb(double chroma) {
    final hRad = h * math.pi / 180;
    final a = chroma * math.cos(hRad);
    final b = chroma * math.sin(hRad);
    final l_ = l + 0.3963377774 * a + 0.2158037573 * b;
    final m_ = l - 0.1055613458 * a - 0.0638541728 * b;
    final s_ = l - 0.0894841775 * a - 1.2914855480 * b;
    final l3 = l_ * l_ * l_, m3 = m_ * m_ * m_, s3 = s_ * s_ * s_;
    return [
      4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
      -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
      -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3,
    ];
  }

  static bool _inGamut(List<double> lin) => lin.every(
      (v) => v >= -0.0000001 && v <= 1.0000001);

  /// Convert to a Flutter [Color], gamut-mapping by chroma reduction.
  Color toColor([double alpha = 1]) {
    var lin = _linearRgb(c);
    if (!_inGamut(lin)) {
      var lo = 0.0, hi = c;
      for (var i = 0; i < 24; i++) {
        final mid = (lo + hi) / 2;
        if (_inGamut(_linearRgb(mid))) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      lin = _linearRgb(lo);
    }
    double ch(double v) => (_srgbEncode(v.clamp(0.0, 1.0)) * 255).roundToDouble();
    return Color.fromARGB(
      (alpha * 255).round(),
      ch(lin[0]).toInt(),
      ch(lin[1]).toInt(),
      ch(lin[2]).toInt(),
    );
  }
}
