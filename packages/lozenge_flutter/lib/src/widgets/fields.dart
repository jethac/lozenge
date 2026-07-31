import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Builds the Lozenge input skin (`.form-control`) as an [InputDecoration]:
/// 2px border with 3px radius, `input-bg` fill that shifts to `input-hover-bg`
/// on hover and `surface` + `focus-ring` border on focus.
InputDecoration _lzInputDecoration(
  LzThemeData t, {
  String? hint,
  bool error = false,
  bool compact = false,
  bool subtle = false,
  Widget? prefixIcon,
  BoxConstraints? prefixIconConstraints,
  Widget? suffixIcon,
  BoxConstraints? suffixIconConstraints,
}) {
  OutlineInputBorder outline(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(3),
        borderSide: BorderSide(color: color, width: 2),
      );
  final transparent = t.border.withValues(alpha: 0.0);
  final restingBorder = error ? t.dangerBold : (subtle ? transparent : t.border);
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      color: t.textSubtlest,
    ),
    isDense: true,
    filled: true,
    fillColor: WidgetStateColor.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return t.surfaceSunken;
      if (states.contains(WidgetState.focused)) return t.surface;
      if (states.contains(WidgetState.hovered)) {
        return subtle ? t.surfaceSunken : t.inputHoverBg;
      }
      return subtle ? t.surface.withValues(alpha: 0.0) : t.inputBg;
    }),
    contentPadding:
        EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 4 : 8),
    enabledBorder: outline(restingBorder),
    focusedBorder: outline(error ? t.dangerBold : t.focusRing),
    disabledBorder: outline(t.surfaceSunken),
    prefixIcon: prefixIcon,
    prefixIconConstraints: prefixIconConstraints,
    suffixIcon: suffixIcon,
    suffixIconConstraints: suffixIconConstraints,
  );
}

/// A Lozenge text field with the full form-group treatment: optional label
/// above, helper or error text below, and the `.form-control` input skin
/// (40px tall, 32px compact, 2px border, 3px radius).
///
/// ```dart
/// LzTextField(
///   label: 'Summary',
///   hint: 'What needs to be done?',
///   helper: 'Keep it short and specific.',
///   onChanged: (v) => summary = v,
/// )
/// ```
class LzTextField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Placeholder shown inside the empty field.
  final String? hint;

  /// Label rendered above the field (12px semibold, `text-subtle`).
  final String? label;

  /// Helper text rendered below the field (12px, `text-subtle`).
  final String? helper;

  /// Validation message; when non-null the border turns `danger-bold` and
  /// this text replaces [helper] below the field.
  final String? error;

  /// 32px tall instead of 40px (`.form-control-compact`).
  final bool compact;

  /// Invisible until interacted with (`.form-control-subtle`, inline edit).
  final bool subtle;

  /// Line count; values above 1 make a textarea-style field.
  final int? maxLines;

  final bool enabled;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const LzTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.label,
    this.helper,
    this.error,
    this.compact = false,
    this.subtle = false,
    this.maxLines = 1,
    this.enabled = true,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final below = error ?? helper;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: t.textSubtle,
            ),
          ),
          const SizedBox(height: 4),
        ],
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          obscureText: obscureText,
          autofocus: autofocus,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          cursorColor: t.text,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            color: enabled ? t.text : t.textDisabled,
          ),
          decoration: _lzInputDecoration(
            t,
            hint: hint,
            error: error != null,
            compact: compact,
            subtle: subtle,
          ),
        ),
        if (below != null) ...[
          const SizedBox(height: 4),
          Text(
            below,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              color: error != null ? t.dangerBold : t.textSubtle,
            ),
          ),
        ],
      ],
    );
  }
}

/// Compact search input (`.search-field`): 32px tall with a leading
/// magnifier in `text-subtle` and an optional keyboard-shortcut hint chip
/// (`.search-kbd`).
///
/// ```dart
/// LzSearchField(hint: 'Search issues', kbdHint: '/', onChanged: search)
/// ```
class LzSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;

  /// Placeholder text.
  final String? hint;

  /// Keyboard-shortcut hint rendered as a small mono chip ("/", "⌘K").
  final String? kbdHint;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const LzSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.kbdHint,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: t.text,
      style: TextStyle(
        fontSize: 14,
        height: 20 / 14,
        color: enabled ? t.text : t.textDisabled,
      ),
      decoration: _lzInputDecoration(
        t,
        hint: hint,
        compact: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Icon(
            Icons.search,
            size: 16,
            color: enabled ? t.textSubtle : t.textDisabled,
          ),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 32, minHeight: 16),
        suffixIcon: kbdHint == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: t.statusNeutralSubtleBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    kbdHint!,
                    style: TextStyle(
                      fontSize: 11,
                      height: 16 / 11,
                      color: t.textSubtle,
                      fontFamily: 'monospace',
                      fontFamilyFallback: const [
                        'SF Mono',
                        'Menlo',
                        'Consolas',
                        'Courier',
                      ],
                    ),
                  ),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(minHeight: 16),
      ),
    );
  }
}
