// Lozenge, badge, and tag — the small inline labels of the Lozenge system.
// Mirrors scss/components/_lozenge.scss, _badge.scss, _tag.scss.
import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// A workflow-status family, mapping to the `status-*` system token sets.
///
/// The enum names match the token families exactly (`status-info-subtle-bg`
/// etc.); [LzStatusColors] resolves each slot against an [LzThemeData].
enum LzStatus { neutral, info, warning, danger, success, discovery }

/// Resolves the four status-token slots for an [LzStatus].
extension LzStatusColors on LzStatus {
  /// Subtle (tinted) background for this status family.
  Color subtleBg(LzThemeData theme) => theme.resolve('status-$name-subtle-bg');

  /// Text color paired with [subtleBg].
  Color subtleText(LzThemeData theme) =>
      theme.resolve('status-$name-subtle-text');

  /// Bold (saturated) background for this status family.
  Color boldBg(LzThemeData theme) => theme.resolve('status-$name-bold-bg');

  /// Text color paired with [boldBg].
  Color onBold(LzThemeData theme) => theme.resolve('status-$name-on-bold');
}

/// The signature Jira-style status pill: a small uppercase label
/// communicating workflow state.
///
/// ```dart
/// LzLozenge('In progress', status: LzStatus.info)
/// LzLozenge('Done', status: LzStatus.success, bold: true)
/// ```
class LzLozenge extends StatelessWidget {
  /// The status word. Rendered uppercase; truncates past 200px.
  final String text;

  /// Which status color family to use.
  final LzStatus status;

  /// Bold variant: saturated background with on-bold text.
  final bool bold;

  const LzLozenge(
    this.text, {
    super.key,
    this.status = LzStatus.neutral,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: bold ? status.boldBg(theme) : status.subtleBg(theme),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: bold ? status.onBold(theme) : status.subtleText(theme),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          height: 12 / 11,
          letterSpacing: 0.02 * 11,
        ),
      ),
    );
  }
}

/// Visual tone of an [LzBadge].
enum LzBadgeAppearance {
  /// Neutral counter (the CSS `.badge` default).
  defaultAppearance,

  /// Accent-bold background (`.badge-primary`).
  primary,

  /// Danger-bold background (`.badge-important`).
  important,

  /// Success-subtle tint (`.badge-added`).
  added,

  /// Danger-subtle tint (`.badge-removed`).
  removed,
}

/// A small pill for numeric counters — unread counts, story points, deltas.
///
/// ```dart
/// LzBadge('25')
/// LzBadge('8', appearance: LzBadgeAppearance.important)
/// ```
class LzBadge extends StatelessWidget {
  /// The counter text (usually a number).
  final String text;

  /// Visual tone; defaults to the neutral counter.
  final LzBadgeAppearance appearance;

  const LzBadge(
    this.text, {
    super.key,
    this.appearance = LzBadgeAppearance.defaultAppearance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final (Color bg, Color fg) = switch (appearance) {
      LzBadgeAppearance.defaultAppearance => (
          theme.statusNeutralSubtleBg,
          theme.text,
        ),
      LzBadgeAppearance.primary => (theme.accentBold, theme.textOnBold),
      LzBadgeAppearance.important => (theme.dangerBold, theme.textOnBold),
      LzBadgeAppearance.added => (
          theme.statusSuccessSubtleBg,
          theme.statusSuccessSubtleText,
        ),
      LzBadgeAppearance.removed => (
          theme.statusDangerSubtleBg,
          theme.statusDangerSubtleText,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 8),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// A label/keyword chip, optionally removable.
///
/// ```dart
/// LzTag('design')
/// LzTag('frontend', rounded: true, onRemove: () => removeLabel('frontend'))
/// ```
class LzTag extends StatefulWidget {
  /// The chip label.
  final String text;

  /// When non-null, renders a small "x" remove button after the label.
  final VoidCallback? onRemove;

  /// Pill-shaped variant with wider horizontal padding.
  final bool rounded;

  const LzTag(
    this.text, {
    super.key,
    this.onRemove,
    this.rounded = false,
  });

  @override
  State<LzTag> createState() => _LzTagState();
}

class _LzTagState extends State<LzTag> {
  bool _removeHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final removable = widget.onRemove != null;
    final sidePad = widget.rounded ? 8.0 : 4.0;
    return Container(
      height: 20,
      padding: EdgeInsets.only(
        left: sidePad,
        // The CSS remove button carries margin-right: -2px.
        right: removable ? sidePad - 2 : sidePad,
      ),
      decoration: BoxDecoration(
        color: theme.statusNeutralSubtleBg,
        borderRadius: BorderRadius.circular(widget.rounded ? 999 : 3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: TextStyle(color: theme.text, fontSize: 12, height: 1),
          ),
          if (removable) ...[
            const SizedBox(width: 2),
            Semantics(
              button: true,
              label: 'Remove ${widget.text}',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _removeHovered = true),
                onExit: (_) => setState(() => _removeHovered = false),
                child: GestureDetector(
                  onTap: widget.onRemove,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          _removeHovered ? theme.statusDangerSubtleBg : null,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '×',
                      style: TextStyle(
                        color: _removeHovered
                            ? theme.statusDangerSubtleText
                            : theme.text,
                        fontSize: 12,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
