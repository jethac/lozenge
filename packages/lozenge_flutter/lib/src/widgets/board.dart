// Kanban board layout. Mirrors scss/components/_board.scss.
import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// A fixed-width (272px) Kanban column: uppercase header with an optional
/// count badge above a sunken well of cards.
///
/// ```dart
/// LzBoardColumn(title: 'To do', count: 4, cards: [LzIssueCard(...)])
/// ```
class LzBoardColumn extends StatelessWidget {
  /// Column title, rendered uppercase; truncates.
  final String title;

  /// Optional count shown as an [LzBadge] after the title.
  final int? count;

  /// The stack of cards (typically [LzIssueCard]s), spaced 8px apart.
  final List<Widget> cards;

  const LzBoardColumn({
    super.key,
    required this.title,
    this.count,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: theme.surfaceSunken,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              spacing: 8,
              children: [
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    // heading(300): 12/16 semibold, subtle, uppercase.
                    style: TextStyle(
                      color: theme.textSubtle,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 16 / 12,
                    ),
                  ),
                ),
                if (count != null) LzBadge('$count'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            // min-height keeps empty columns usable as drop targets.
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: cards,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kanban board: a horizontally scrolling row of top-aligned
/// [LzBoardColumn]s with an 8px gap.
///
/// ```dart
/// LzBoard([LzBoardColumn(...), LzBoardColumn(...)])
/// ```
class LzBoard extends StatelessWidget {
  /// The board's columns, left to right.
  final List<LzBoardColumn> columns;

  const LzBoard(this.columns, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: columns,
      ),
    );
  }
}
