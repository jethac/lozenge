import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Visual variants for [LzButton], mirroring the `.btn-*` classes of the
/// Lozenge CSS engine (`scss/components/_button.scss`).
enum LzButtonVariant {
  /// Default neutral button (`.btn`).
  standard,

  /// Bold accent call-to-action (`.btn-primary`).
  primary,

  /// Bold warning (`.btn-warning`).
  warning,

  /// Bold destructive action (`.btn-danger`).
  danger,

  /// Transparent until hovered (`.btn-subtle`).
  subtle,

  /// Looks like a link (`.btn-link`).
  link,

  /// Muted link (`.btn-subtle-link`).
  subtleLink,
}

/// A Lozenge button.
///
/// Matches the CSS `.btn` recipe: 32px tall (24px compact), 12px horizontal
/// padding, 3px radius, 14px medium text, with hover/pressed/disabled/focus
/// states driven entirely by Lozenge system tokens.
///
/// ```dart
/// LzButton(
///   variant: LzButtonVariant.primary,
///   onPressed: save,
///   child: const Text('Create issue'),
/// )
/// ```
class LzButton extends StatefulWidget {
  /// The button label.
  final Widget child;

  /// Called on tap / keyboard activation. `null` renders the disabled state.
  final VoidCallback? onPressed;

  /// Visual variant (see [LzButtonVariant]).
  final LzButtonVariant variant;

  /// 24px height instead of 32px (`.btn-compact`).
  final bool compact;

  /// Toggled-on state (`.btn.active`), e.g. filter buttons.
  final bool selected;

  /// Replaces [icon] (or the label, for [LzIconButton]) with a 16px spinner
  /// and suppresses taps while true.
  final bool loading;

  /// Optional leading icon, rendered at 16px in the current text color.
  final Widget? icon;

  final bool _square;

  const LzButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = LzButtonVariant.standard,
    this.compact = false,
    this.selected = false,
    this.loading = false,
    this.icon,
  }) : _square = false;

  const LzButton._square({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = LzButtonVariant.standard,
    this.compact = false,
    this.selected = false,
    this.loading = false,
  })  : icon = null,
        _square = true;

  @override
  State<LzButton> createState() => _LzButtonState();
}

/// Icon-only square button (`.btn-icon`): width equals height, no padding.
///
/// ```dart
/// LzIconButton(icon: const Icon(Icons.close), onPressed: dismiss)
/// ```
class LzIconButton extends LzButton {
  const LzIconButton({
    super.key,
    required Widget icon,
    super.onPressed,
    super.variant,
    super.compact,
    super.selected,
    super.loading,
  }) : super._square(child: icon);
}

class _LzButtonState extends State<LzButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _interactive => widget.onPressed != null && !widget.loading;

  void _activate() {
    if (_interactive) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final disabled = widget.onPressed == null;
    final transparent = t.surface.withValues(alpha: 0.0);

    Color bg;
    Color fg;
    var underline = false;

    if (disabled) {
      bg = t.interactionBg;
      fg = t.textDisabled;
    } else if (widget.selected) {
      bg = t.statusNeutralBoldBg;
      fg = t.statusNeutralOnBold;
    } else {
      switch (widget.variant) {
        case LzButtonVariant.standard:
          bg = _pressed
              ? t.interactionPressed
              : _hovered
                  ? t.interactionHovered
                  : t.interactionBg;
          fg = _pressed ? t.link : t.text;
        case LzButtonVariant.primary:
          bg = _pressed
              ? t.accentBoldPressed
              : _hovered
                  ? t.accentBoldHovered
                  : t.accentBold;
          fg = t.textInverse;
        case LzButtonVariant.warning:
          bg = _pressed
              ? t.warningBoldPressed
              : _hovered
                  ? t.warningBoldHovered
                  : t.warningBold;
          fg = t.statusWarningOnBold;
        case LzButtonVariant.danger:
          bg = _pressed
              ? t.dangerBoldPressed
              : _hovered
                  ? t.dangerBoldHovered
                  : t.dangerBold;
          fg = t.textInverse;
        case LzButtonVariant.subtle:
          bg = _pressed
              ? t.interactionPressed
              : _hovered
                  ? t.interactionHovered
                  : transparent;
          fg = _pressed ? t.link : t.text;
        case LzButtonVariant.link:
          bg = transparent;
          fg = _pressed
              ? t.linkActive
              : _hovered
                  ? t.linkHover
                  : t.link;
          underline = _hovered && !_pressed;
        case LzButtonVariant.subtleLink:
          bg = transparent;
          fg = (_hovered || _pressed) ? t.text : t.textSubtle;
          underline = _hovered && !_pressed;
      }
    }

    final height = widget.compact ? 24.0 : 32.0;
    final padX = widget._square ? 0.0 : (widget.compact ? 8.0 : 12.0);
    final radius =
        _LzButtonGroupSlot.maybeOf(context)?.radius ?? BorderRadius.circular(3);

    final children = <Widget>[];
    if (widget.loading) {
      children.add(_LzSpinner(color: fg));
    } else if (widget.icon != null) {
      children.add(widget.icon!);
    }
    if (!(widget._square && widget.loading)) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 4));
      children.add(Flexible(child: widget.child));
    }

    final button = AnimatedContainer(
      duration: LzMotion.fast,
      curve: Curves.easeOut,
      height: height,
      width: widget._square ? height : null,
      padding: EdgeInsets.symmetric(horizontal: padX),
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: AnimatedDefaultTextStyle(
        duration: LzMotion.fast,
        style: TextStyle(
          fontSize: 14,
          height: 1.0,
          fontWeight: FontWeight.w500,
          color: fg,
          decoration: underline ? TextDecoration.underline : TextDecoration.none,
          decorationColor: fg,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: fg, size: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: children,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      child: FocusableActionDetector(
        enabled: _interactive,
        mouseCursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _interactive ? (_) => setState(() => _pressed = false) : null,
          onTapCancel:
              _interactive ? () => setState(() => _pressed = false) : null,
          onTap: _interactive ? _activate : null,
          child: CustomPaint(
            foregroundPainter:
                _focused ? _LzFocusRingPainter(t.focusRing, radius) : null,
            child: button,
          ),
        ),
      ),
    );
  }
}

/// Seamless joined buttons (`.btn-group`): outer corners rounded, inner
/// corners square, 2px gaps.
///
/// ```dart
/// LzButtonGroup([
///   LzButton(onPressed: () {}, child: const Text('Board')),
///   LzButton(onPressed: () {}, child: const Text('Backlog')),
/// ])
/// ```
class LzButtonGroup extends StatelessWidget {
  final List<LzButton> children;
  const LzButtonGroup(this.children, {super.key});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(3);
    final last = children.length - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          _LzButtonGroupSlot(
            radius: children.length == 1
                ? BorderRadius.circular(3)
                : i == 0
                    ? const BorderRadius.horizontal(left: r)
                    : i == last
                        ? const BorderRadius.horizontal(right: r)
                        : BorderRadius.zero,
            child: children[i],
          ),
        ],
      ],
    );
  }
}

class _LzButtonGroupSlot extends InheritedWidget {
  final BorderRadius radius;
  const _LzButtonGroupSlot({required this.radius, required super.child});

  static _LzButtonGroupSlot? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LzButtonGroupSlot>();

  @override
  bool updateShouldNotify(_LzButtonGroupSlot oldWidget) =>
      radius != oldWidget.radius;
}

/// 2px focus ring drawn 1px outside the widget bounds — the Flutter twin of
/// the CSS `focus-ring` mixin (`box-shadow: 0 0 0 2px $focus-ring-color`).
class _LzFocusRingPainter extends CustomPainter {
  final Color color;
  final BorderRadius radius;
  const _LzFocusRingPainter(this.color, this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    canvas.drawRRect(radius.toRRect(rect), paint);
  }

  @override
  bool shouldRepaint(_LzFocusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Tiny inline loading spinner: a rotating 270° arc stroked in the current
/// text color, 16px square.
class _LzSpinner extends StatefulWidget {
  final Color color;
  const _LzSpinner({required this.color});

  @override
  State<_LzSpinner> createState() => _LzSpinnerState();
}

class _LzSpinnerState extends State<_LzSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        size: const Size.square(16),
        painter: _LzSpinnerPainter(widget.color),
      ),
    );
  }
}

class _LzSpinnerPainter extends CustomPainter {
  final Color color;
  const _LzSpinnerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      (Offset.zero & size).deflate(1),
      -math.pi / 2,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LzSpinnerPainter oldDelegate) =>
      oldDelegate.color != color;
}
