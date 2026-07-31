// Lozenge content widgets: empty state, comments, tree.
// Mirrors scss/components/{_empty-state,_comments,_tree}.scss.
import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Hover-tracking tap region shared by the content widgets.
class _LzHover extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(BuildContext context, bool hovered) builder;
  const _LzHover({this.onTap, required this.builder});

  @override
  State<_LzHover> createState() => _LzHoverState();
}

class _LzHoverState extends State<_LzHover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.builder(context, _hovered),
      ),
    );
  }
}

/// Small initials avatar used by the comment widgets.
class _LzCommentAvatar extends StatelessWidget {
  final String? initials;
  const _LzCommentAvatar({this.initials});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: initials == null ? theme.surfaceSunken : theme.accentBold,
        shape: BoxShape.circle,
      ),
      child: initials == null
          ? Icon(Icons.person, size: 18, color: theme.textSubtle)
          : Text(
              initials!,
              style: TextStyle(
                color: theme.textOnBold,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Empty state (`.empty-state`) — centered explanation for a region with
/// nothing in it yet, capped at 460px wide.
class LzEmptyState extends StatelessWidget {
  /// Illustration slot, shown inside a 96px sunken circle.
  final Widget? media;
  final String title;
  final String? description;
  final List<Widget> actions;

  const LzEmptyState({
    super.key,
    this.media,
    required this.title,
    this.description,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (media != null)
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: IconTheme.merge(
                    data:
                        IconThemeData(color: theme.textSubtlest, size: 40),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(
                        color: theme.textSubtlest,
                        fontSize: 40,
                        height: 1,
                      ),
                      child: media!,
                    ),
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 20 / 16,
                ),
              ),
              if (description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    description!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.textSubtle),
                  ),
                ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: actions,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single comment (`.comment`) — avatar column, author/time meta row,
/// body, optional actions, and an indented rail of [replies].
class LzComment extends StatelessWidget {
  final String author;
  final String time;
  final Widget body;
  final String? avatarInitials;
  final List<Widget> actions;
  final List<LzComment> replies;

  const LzComment({
    super.key,
    required this.author,
    required this.time,
    required this.body,
    this.avatarInitials,
    this.actions = const [],
    this.replies = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LzCommentAvatar(initials: avatarInitials),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    author,
                    style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(
                      color: theme.textSubtlest,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: theme.text),
                  child: body,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: DefaultTextStyle.merge(
                    style:
                        TextStyle(color: theme.textSubtle, fontSize: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < actions.length; i++) ...[
                          if (i > 0) const SizedBox(width: 12),
                          actions[i],
                        ],
                      ],
                    ),
                  ),
                ),
              if (replies.isNotEmpty)
                Container(
                  margin: const EdgeInsetsDirectional.only(top: 16, start: 2),
                  padding: const EdgeInsetsDirectional.only(start: 20),
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      start: BorderSide(color: theme.separator, width: 2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < replies.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        replies[i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A stack of comments (`.comment-thread`) with 16px gaps.
class LzCommentThread extends StatelessWidget {
  final List<Widget> comments;
  const LzCommentThread(this.comments, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < comments.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          comments[i],
        ],
      ],
    );
  }
}

/// Reply box (`.comment-editor`) — avatar beside a bordered text area.
class LzCommentEditor extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final String? avatarInitials;

  const LzCommentEditor({
    super.key,
    this.controller,
    this.hint = 'Add a comment…',
    this.avatarInitials,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LzCommentAvatar(initials: avatarInitials),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.inputBg,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: theme.border),
            ),
            child: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 6,
              cursorColor: theme.text,
              style: TextStyle(color: theme.text, fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                hintText: hint,
                hintStyle: TextStyle(color: theme.textSubtlest),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A node in an [LzTree] — a leaf, or a branch when it has [children].
/// Branch rows carry a rotating chevron and toggle open on tap.
class LzTreeNode extends StatefulWidget {
  final String label;
  final Widget? icon;
  final List<LzTreeNode> children;
  final bool initiallyExpanded;
  final bool selected;
  final VoidCallback? onTap;

  const LzTreeNode({
    super.key,
    required this.label,
    this.icon,
    this.children = const [],
    this.initiallyExpanded = false,
    this.selected = false,
    this.onTap,
  });

  @override
  State<LzTreeNode> createState() => _LzTreeNodeState();
}

class _LzTreeNodeState extends State<LzTreeNode> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final branch = widget.children.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LzHover(
          onTap: () {
            if (branch) setState(() => _expanded = !_expanded);
            widget.onTap?.call();
          },
          builder: (context, hovered) {
            final Color fg = widget.selected
                ? theme.selectedText
                : theme.text;
            final Color? bg = widget.selected
                ? theme.selectedBg
                : (hovered ? theme.interactionHovered : null);
            return Container(
              // Leaf rows get extra start padding so their labels align
              // with branch labels (12px chevron + no gap ≈ CSS's 20px).
              padding: EdgeInsetsDirectional.only(
                start: branch ? 8 : 20,
                end: 8,
                top: 4,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                children: [
                  if (branch)
                    AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: LzMotion.fast,
                      curve: LzMotion.standard,
                      child: Icon(Icons.arrow_right, size: 12, color: fg),
                    ),
                  if (widget.icon != null) ...[
                    IconTheme.merge(
                      data: IconThemeData(size: 16, color: fg),
                      child: widget.icon!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: fg),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (branch)
          ClipRect(
            child: AnimatedSize(
              duration: LzMotion.fast,
              curve: LzMotion.standard,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      // Each nesting level indents by 20px.
                      padding: const EdgeInsetsDirectional.only(start: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: widget.children,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
      ],
    );
  }
}

/// Tree view (`.tree`) — nested expandable hierarchy (file trees,
/// epic > story breakdowns); 20px indent per level.
class LzTree extends StatelessWidget {
  final List<LzTreeNode> nodes;
  const LzTree(this.nodes, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: nodes,
    );
  }
}
