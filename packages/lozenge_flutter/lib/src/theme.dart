part of '../lozenge_flutter.dart';

/// One scheme's definition of a system token: a ramp reference plus the
/// contrast-dial coefficients. Mirrors tokens/sys.json exactly.
class LzTokenDef {
  final String ref;
  final double lShift;
  final double k;
  final double ck;
  final double cScale;
  final double? alpha;
  const LzTokenDef({
    required this.ref,
    this.lShift = 0,
    this.k = 0,
    this.ck = 0,
    this.cScale = 1,
    this.alpha,
  });
}

class LzTokenSchemes {
  final LzTokenDef light;
  final LzTokenDef dark;
  const LzTokenSchemes({required this.light, required this.dark});
}

/// The resolved Lozenge theme: four numeric axes plus scheme, resolving
/// every system token on demand (cached per instance).
class LzThemeData {
  final bool dark;

  /// Contrast dial, -1..+1 (0 = design default).
  final double contrast;

  /// Accent hue in OKLCH degrees (default: Jira blue).
  final double accentHue;

  /// Accent chroma multiplier (0 = grayscale accent).
  final double accentChroma;

  /// Materials axis: 1 = glass surfaces, 0 = solid.
  final double glass;

  final Map<String, Color> _cache = {};

  LzThemeData({
    this.dark = false,
    this.contrast = 0,
    this.accentHue = lzDefaultAccentHue,
    this.accentChroma = 1,
    this.glass = 1,
  });

  factory LzThemeData.light() => LzThemeData();
  factory LzThemeData.dark() => LzThemeData(dark: true);

  /// Resolve a system token by its kebab-case name (e.g. `text-subtle`).
  Color resolve(String name) => _cache.putIfAbsent(name, () {
        final schemes = lzSysTokens[name];
        if (schemes == null) {
          throw ArgumentError('unknown Lozenge sys token: $name');
        }
        final def = dark ? schemes.dark : schemes.light;
        final parts = def.ref.split('.');
        final LzOklch base;
        if (parts[0] == 'accent') {
          final b = lzRamps['blue']![parts[1]]!;
          base = LzOklch(b.l, b.c * accentChroma, accentHue);
        } else {
          base = lzRamps[parts[0]]![parts[1]]!;
        }
        final l = (base.l + def.lShift + def.k * contrast).clamp(0.0, 1.0);
        final c = math.max(
            0.0, base.c * def.cScale * (1 + def.ck * contrast.abs()));
        return LzOklch(l, c, base.h).toColor(def.alpha ?? 1);
      });

  /// Effective alpha for glass (overlay) surfaces: coupled to the contrast
  /// dial exactly like the CSS `--lz-material-alpha`.
  double get materialAlpha =>
      (1 - glass * 0.28 * (1 - contrast.clamp(0.0, 1.0))).clamp(0.0, 1.0);

  LzThemeData copyWith({
    bool? dark,
    double? contrast,
    double? accentHue,
    double? accentChroma,
    double? glass,
  }) =>
      LzThemeData(
        dark: dark ?? this.dark,
        contrast: contrast ?? this.contrast,
        accentHue: accentHue ?? this.accentHue,
        accentChroma: accentChroma ?? this.accentChroma,
        glass: glass ?? this.glass,
      );

  static LzThemeData lerp(LzThemeData a, LzThemeData b, double t) =>
      LzThemeData(
        dark: t < 0.5 ? a.dark : b.dark,
        contrast: a.contrast + (b.contrast - a.contrast) * t,
        accentHue: a.accentHue + (b.accentHue - a.accentHue) * t,
        accentChroma: a.accentChroma + (b.accentChroma - a.accentChroma) * t,
        glass: a.glass + (b.glass - a.glass) * t,
      );

  /// Bridge into Material so stock widgets sit comfortably next to Lozenge.
  ThemeData toMaterialTheme() {
    final scheme = ColorScheme(
      brightness: dark ? Brightness.dark : Brightness.light,
      primary: accentBold,
      onPrimary: textOnBold,
      secondary: selectedText,
      onSecondary: textInverse,
      error: dangerBold,
      onError: textOnBold,
      surface: surface,
      onSurface: text,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      dividerColor: separator,
      splashFactory: NoSplash.splashFactory,
      visualDensity: VisualDensity.compact,
      useMaterial3: true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LzThemeData &&
      other.dark == dark &&
      other.contrast == contrast &&
      other.accentHue == accentHue &&
      other.accentChroma == accentChroma &&
      other.glass == glass;

  @override
  int get hashCode =>
      Object.hash(dark, contrast, accentHue, accentChroma, glass);
}

/// Inherited access to the current [LzThemeData].
class LzTheme extends InheritedWidget {
  final LzThemeData data;
  const LzTheme({super.key, required this.data, required super.child});

  static LzThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LzTheme>()?.data ??
      LzThemeData.light();

  @override
  bool updateShouldNotify(LzTheme oldWidget) => oldWidget.data != data;
}

/// Implicitly animates axis changes — turn any dial, the UI sweeps.
class AnimatedLzTheme extends ImplicitlyAnimatedWidget {
  final LzThemeData data;
  final Widget child;
  const AnimatedLzTheme({
    super.key,
    required this.data,
    required this.child,
    super.duration = LzMotion.medium,
    super.curve = LzMotion.standard,
  });

  @override
  AnimatedWidgetBaseState<AnimatedLzTheme> createState() =>
      _AnimatedLzThemeState();
}

class _LzThemeDataTween extends Tween<LzThemeData> {
  _LzThemeDataTween({super.begin});
  @override
  LzThemeData lerp(double t) => LzThemeData.lerp(begin!, end!, t);
}

class _AnimatedLzThemeState extends AnimatedWidgetBaseState<AnimatedLzTheme> {
  _LzThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(_data, widget.data,
        (v) => _LzThemeDataTween(begin: v as LzThemeData)) as _LzThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) =>
      LzTheme(data: _data!.evaluate(animation), child: widget.child);
}
