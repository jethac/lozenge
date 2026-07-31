import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

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

/// Shared chrome for the small form controls: hover/focus tracking, keyboard
/// activation, focus ring, and the optional trailing label (`.form-check`).
class _LzControlShell extends StatefulWidget {
  final bool enabled;
  final VoidCallback? onActivate;
  final Widget? label;
  final BorderRadius ringRadius;
  final Widget Function(BuildContext context, bool hovered, bool focused)
      builder;

  const _LzControlShell({
    required this.enabled,
    required this.onActivate,
    required this.ringRadius,
    required this.builder,
    this.label,
  });

  @override
  State<_LzControlShell> createState() => _LzControlShellState();
}

class _LzControlShellState extends State<_LzControlShell> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final control = CustomPaint(
      foregroundPainter: _focused
          ? _LzFocusRingPainter(t.focusRing, widget.ringRadius)
          : null,
      child: widget.builder(context, _hovered, _focused),
    );
    final body = widget.label == null
        ? control
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              control,
              const SizedBox(width: 8),
              DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: widget.enabled ? t.text : t.textDisabled,
                ),
                child: widget.label!,
              ),
            ],
          );
    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onActivate : null,
        child: body,
      ),
    );
  }
}

/// Lozenge checkbox (`.form-check-input`): 16×16, 2px `border` outline with
/// 2px radius; checked fills `accent-bold` with a white check.
///
/// ```dart
/// LzCheckbox(
///   value: done,
///   onChanged: (v) => setState(() => done = v ?? false),
///   label: const Text('Done'),
/// )
/// ```
class LzCheckbox extends StatelessWidget {
  /// Current value. May only be null when [tristate] is true.
  final bool? value;

  /// Called with the next value; null disables the control.
  final ValueChanged<bool?>? onChanged;

  /// Optional trailing label; tapping it also toggles.
  final Widget? label;

  /// Allow the indeterminate (null) state, cycling false → true → null.
  final bool tristate;

  const LzCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.tristate = false,
  }) : assert(tristate || value != null,
            'value may only be null when tristate is true');

  void _toggle() {
    if (onChanged == null) return;
    if (tristate) {
      onChanged!(value == false ? true : (value == true ? null : false));
    } else {
      onChanged!(!(value ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final enabled = onChanged != null;
    final checked = value != false;
    return Semantics(
      container: true,
      checked: value == true,
      mixed: tristate ? value == null : null,
      enabled: enabled,
      child: _LzControlShell(
        enabled: enabled,
        onActivate: _toggle,
        label: label,
        ringRadius: BorderRadius.circular(2),
        builder: (context, hovered, focused) => AnimatedContainer(
          duration: LzMotion.medium,
          curve: LzMotion.standard,
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: checked
                ? t.accentBold
                : (hovered ? t.inputHoverBg : t.inputBg),
            border: Border.all(
              color: checked ? t.accentBold : t.border,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          child: value == true
              ? Center(child: Icon(Icons.check, size: 12, color: t.textOnBold))
              : value == null
                  ? Center(
                      child: Icon(Icons.remove, size: 12, color: t.textOnBold))
                  : null,
        ),
      ),
    );
  }
}

/// Lozenge radio button: a 16px circle; selected fills `accent-bold` with a
/// white ring around an accent center dot (mirrors the CSS inset shadow).
///
/// ```dart
/// LzRadio<Priority>(
///   value: Priority.high,
///   groupValue: priority,
///   onChanged: (v) => setState(() => priority = v),
///   label: const Text('High'),
/// )
/// ```
class LzRadio<T> extends StatelessWidget {
  /// The value this radio represents.
  final T value;

  /// The currently selected value of the group.
  final T? groupValue;

  /// Called with [value] when this radio is selected; null disables.
  final ValueChanged<T>? onChanged;

  /// Optional trailing label; tapping it also selects.
  final Widget? label;

  const LzRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final enabled = onChanged != null;
    final selected = value == groupValue;
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: _LzControlShell(
        enabled: enabled,
        onActivate: () => onChanged?.call(value),
        label: label,
        ringRadius: BorderRadius.circular(8),
        builder: (context, hovered, focused) => AnimatedContainer(
          duration: LzMotion.medium,
          curve: LzMotion.standard,
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? t.accentBold
                : (hovered ? t.inputHoverBg : t.inputBg),
            border: selected ? null : Border.all(color: t.border, width: 2),
          ),
          child: selected
              ? Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.textOnBold,
                    ),
                    child: Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: t.accentBold,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Lozenge toggle switch (`.toggle`): 32×16 (40×20 large), `toggle-off`
/// track that turns `status-success-bold-bg` when on, white knob sliding
/// with [LzMotion.fast].
///
/// ```dart
/// LzToggle(value: notify, onChanged: (v) => setState(() => notify = v))
/// ```
class LzToggle extends StatelessWidget {
  /// Whether the toggle is on.
  final bool value;

  /// Called with the next value; null disables (rendered at 50% opacity).
  final ValueChanged<bool>? onChanged;

  /// 40×20 instead of 32×16 (`.toggle-lg`).
  final bool large;

  const LzToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final enabled = onChanged != null;
    final width = large ? 40.0 : 32.0;
    final height = large ? 20.0 : 16.0;
    final knob = height - 4;
    return Semantics(
      container: true,
      toggled: value,
      enabled: enabled,
      child: _LzControlShell(
        enabled: enabled,
        onActivate: () => onChanged?.call(!value),
        ringRadius: BorderRadius.circular(height / 2),
        builder: (context, hovered, focused) => Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: LzMotion.fast,
            curve: LzMotion.standard,
            width: width,
            height: height,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: value ? t.statusSuccessBoldBg : t.toggleOff,
              borderRadius: BorderRadius.circular(height / 2),
            ),
            child: AnimatedAlign(
              duration: LzMotion.fast,
              curve: LzMotion.standard,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.textOnBold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
