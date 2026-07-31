// Cards and board issue cards. Mirrors scss/components/_card.scss.
import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

// $shadow-raised: 0 1px 1px rgba(#091E42, .25), 0 0 1px rgba(#091E42, .31).
const List<BoxShadow> _shadowRaised = [
  BoxShadow(color: Color(0x40091E42), offset: Offset(0, 1), blurRadius: 1),
  BoxShadow(color: Color(0x4F091E42), blurRadius: 1),
];

/// Generic raised surface container with optional header/body/footer.
///
/// ```dart
/// LzCard(header: Text('Sprint 14'), child: Text('Content'))
/// ```
class LzCard extends StatelessWidget {
  /// Optional heading strip with a bottom separator.
  final Widget? header;

  /// The padded main content region.
  final Widget child;

  /// Optional footer strip with a top separator.
  final Widget? footer;

  const LzCard({super.key, this.header, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final separator = BorderSide(color: theme.separator, width: 2);
    final body = TextStyle(color: theme.text, fontSize: 14, height: 20 / 14);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceRaised,
        borderRadius: BorderRadius.circular(3),
        boxShadow: _shadowRaised,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(border: Border(bottom: separator)),
              child: DefaultTextStyle(
                // heading(400): 14/16 semibold.
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 16 / 14,
                ),
                child: header!,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DefaultTextStyle(style: body, child: child),
          ),
          if (footer != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(border: Border(top: separator)),
              child: DefaultTextStyle(style: body, child: footer!),
            ),
        ],
      ),
    );
  }
}

/// Issue categories, rendered as fixed-color square icons on cards.
enum LzIssueType { story, bug, task, epic }

/// The small 16x16 colored square standing in for an issue-type glyph.
///
/// Colors are deliberately fixed ref-ramp values (not accent-driven).
///
/// ```dart
/// LzIssueTypeIcon(LzIssueType.bug)
/// ```
class LzIssueTypeIcon extends StatelessWidget {
  /// Which issue category to represent.
  final LzIssueType type;

  const LzIssueTypeIcon(this.type, {super.key});

  static Color _color(LzIssueType type) => switch (type) {
        LzIssueType.story => lzRamps['green']!['300']!.toColor(),
        LzIssueType.bug => lzRamps['red']!['300']!.toColor(),
        LzIssueType.task => lzRamps['blue']!['100']!.toColor(),
        LzIssueType.epic => lzRamps['purple']!['300']!.toColor(),
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: switch (type) {
        LzIssueType.story => 'Story',
        LzIssueType.bug => 'Bug',
        LzIssueType.task => 'Task',
        LzIssueType.epic => 'Epic',
      },
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: _color(type),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// A single issue on a Kanban board: summary text plus a meta row of
/// issue-type icon, key, badges/lozenges, and a right-aligned trailing
/// widget (typically an [LzAvatar]).
///
/// ```dart
/// LzIssueCard(
///   summary: 'Fix login redirect loop',
///   type: LzIssueType.bug,
///   issueKey: 'PROJ-42',
///   meta: [LzBadge('3')],
///   trailing: LzAvatar(initials: 'JC', size: LzAvatarSize.sm),
///   onTap: openIssue,
/// )
/// ```
class LzIssueCard extends StatefulWidget {
  /// The issue title; wraps and word-breaks.
  final String summary;

  /// Optional issue-type square shown first in the meta row.
  final LzIssueType? type;

  /// The issue identifier (e.g. `LOZ-42`); truncates.
  final String? issueKey;

  /// Extra meta widgets (badges, lozenges) after the key.
  final List<Widget> meta;

  /// Right-aligned trailing widget, pushed to the card's edge.
  final Widget? trailing;

  /// Tapping the card (hover shows the raised-hovered surface).
  final VoidCallback? onTap;

  const LzIssueCard({
    super.key,
    required this.summary,
    this.type,
    this.issueKey,
    this.meta = const [],
    this.trailing,
    this.onTap,
  });

  @override
  State<LzIssueCard> createState() => _LzIssueCardState();
}

class _LzIssueCardState extends State<LzIssueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final hasMeta = widget.type != null ||
        widget.issueKey != null ||
        widget.meta.isNotEmpty ||
        widget.trailing != null;
    final metaChildren = <Widget>[
      if (widget.type != null) LzIssueTypeIcon(widget.type!),
      if (widget.issueKey != null)
        Flexible(
          child: Text(
            widget.issueKey!,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.textSubtle, fontSize: 12),
          ),
        ),
      ...widget.meta,
      if (widget.trailing != null) ...[const Spacer(), widget.trailing!],
    ];

    Widget card = Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: _hovered ? theme.surfaceRaisedHovered : theme.surfaceRaised,
        borderRadius: BorderRadius.circular(2),
        boxShadow: _shadowRaised,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.summary,
            style: TextStyle(color: theme.text, fontSize: 14, height: 20 / 14),
          ),
          if (hasMeta)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(spacing: 8, children: metaChildren),
            ),
        ],
      ),
    );
    if (widget.onTap != null) {
      card = Semantics(
        button: true,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(onTap: widget.onTap, child: card),
        ),
      );
    }
    return card;
  }
}
