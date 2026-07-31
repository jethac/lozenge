// Lozenge structure widgets: navbar, sidebar, tabs, breadcrumbs, pagination.
// Mirrors scss/components/{_navbar,_sidebar,_tabs,_breadcrumbs,_pagination}.scss.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Hover-tracking tap region shared by the navigation widgets.
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

/// Tells [LzNavLink]s whether they sit inside a `primary` (bold) navbar.
class _LzNavbarScope extends InheritedWidget {
  final bool primary;
  const _LzNavbarScope({required this.primary, required super.child});

  static bool primaryOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LzNavbarScope>()?.primary ??
      false;

  @override
  bool updateShouldNotify(_LzNavbarScope oldWidget) =>
      oldWidget.primary != primary;
}

/// Top navigation bar — 56px tall, frosted glass when the materials axis is
/// on, hairline separator underneath. Mirrors `.navbar` / `.navbar-primary`.
class LzNavbar extends StatelessWidget implements PreferredSizeWidget {
  /// Leading brand slot (logo / product name).
  final Widget? brand;

  /// Navigation links, typically [LzNavLink]s.
  final List<Widget> items;

  /// Trailing actions (buttons, avatar), pushed to the end.
  final List<Widget> actions;

  /// Bold accent variant (`.navbar-primary`): solid accent, white content.
  final bool primary;

  const LzNavbar({
    super.key,
    this.brand,
    this.items = const [],
    this.actions = const [],
    this.primary = false,
  });

  /// `$navbar-height`.
  static const double height = 56;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final alpha = theme.materialAlpha;
    final glass = !primary && alpha < 1;
    final contentColor = primary ? theme.textOnBold : theme.text;

    Widget bar = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: primary
            ? theme.accentBold
            : theme.surface.withValues(alpha: alpha * theme.surface.a),
        border: primary
            ? null
            : Border(bottom: BorderSide(color: theme.separator)),
      ),
      child: Row(
        children: [
          if (brand != null) ...[
            DefaultTextStyle.merge(
              style: TextStyle(
                color: contentColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              child: brand!,
            ),
            const SizedBox(width: 16),
          ],
          for (final item in items) ...[item, const SizedBox(width: 4)],
          const Spacer(),
          for (final action in actions) ...[
            const SizedBox(width: 8),
            action,
          ],
        ],
      ),
    );
    if (glass) {
      bar = ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: bar,
        ),
      );
    }
    return _LzNavbarScope(
      primary: primary,
      child: IconTheme.merge(
        data: IconThemeData(color: contentColor, size: 20),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: contentColor, fontSize: 14),
          child: bar,
        ),
      ),
    );
  }
}

/// A navbar link (`.nav-link`) — 32px tall, underlined when [selected].
class LzNavLink extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const LzNavLink({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final primary = _LzNavbarScope.primaryOf(context);
    return _LzHover(
      onTap: onTap,
      builder: (context, hovered) {
        final Color fg;
        if (primary) {
          fg = theme.textOnBold;
        } else if (selected) {
          fg = theme.link;
        } else {
          fg = hovered ? theme.text : theme.textSubtle;
        }
        final Color? bg = hovered
            ? (primary
                ? const Color(0xFFFFFFFF).withValues(alpha: 0.16)
                : theme.interactionHovered)
            : null;
        final underline = primary ? theme.textOnBold : theme.link;
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: selected
                ? const BorderRadius.vertical(top: Radius.circular(3))
                : BorderRadius.circular(3),
            border: selected
                ? Border(bottom: BorderSide(color: underline, width: 2))
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w500),
          ),
        );
      },
    );
  }
}

/// Project sidebar (`.sidebar`) — 240 wide, surface background, separator
/// edge on the trailing side.
class LzSidebar extends StatelessWidget {
  /// Optional header (project avatar + title), rendered above [children].
  final Widget? header;
  final List<Widget> children;

  const LzSidebar({super.key, this.header, required this.children});

  /// `$sidebar-width`.
  static const double width = 240;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(right: BorderSide(color: theme.separator)),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
              child: header!,
            ),
          ...children,
        ],
      ),
    );
  }
}

/// A sidebar row (`.sidebar-item`) — hover wash, selected pill.
class LzSidebarItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const LzSidebarItem({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return _LzHover(
      onTap: onTap,
      builder: (context, hovered) {
        final Color fg = selected
            ? theme.selectedText
            : (hovered ? theme.text : theme.textSubtle);
        final Color? bg = selected
            ? theme.selectedBg
            : (hovered ? theme.interactionHovered : null);
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Collapsible sidebar section (`.sidebar-group`) — uppercase title with a
/// rotating chevron, children animate open/closed with [LzMotion.fast].
class LzSidebarGroup extends StatefulWidget {
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  const LzSidebarGroup({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
  });

  @override
  State<LzSidebarGroup> createState() => _LzSidebarGroupState();
}

class _LzSidebarGroupState extends State<LzSidebarGroup> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LzHover(
          onTap: () => setState(() => _expanded = !_expanded),
          builder: (context, hovered) => Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: LzMotion.fast,
                  curve: LzMotion.standard,
                  child: Icon(
                    Icons.arrow_right,
                    size: 16,
                    color: theme.textSubtle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: LzMotion.fast,
            curve: LzMotion.standard,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}

/// Underline tabs (`.tabs`) — 2px separator baseline, selected tab underlined
/// in the link color. Pass [panes] to render the selected pane below.
class LzTabs extends StatelessWidget {
  final List<String> tabs;
  final int index;
  final ValueChanged<int> onChanged;

  /// Optional panes, one per tab; the selected one renders under the row.
  final List<Widget>? panes;

  const LzTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    this.panes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final row = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(height: 2, color: theme.separator),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tabs.length; i++)
              _LzHover(
                onTap: () => onChanged(i),
                builder: (context, hovered) {
                  final selected = i == index;
                  final Color fg = selected
                      ? theme.link
                      : (hovered ? theme.linkHover : theme.textSubtle);
                  return Container(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color:
                              selected ? theme.link : const Color(0x00000000),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      tabs[i],
                      style:
                          TextStyle(color: fg, fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
    if (panes == null) return row;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row,
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: panes![index.clamp(0, panes!.length - 1)],
        ),
      ],
    );
  }
}

/// One crumb in an [LzBreadcrumbs] trail.
class LzBreadcrumb {
  final String label;
  final VoidCallback? onTap;
  const LzBreadcrumb(this.label, {this.onTap});
}

/// Breadcrumb trail (`.breadcrumbs`) — "/" separators in the subtlest text
/// color; tappable crumbs underline on hover.
class LzBreadcrumbs extends StatelessWidget {
  final List<LzBreadcrumb> crumbs;
  const LzBreadcrumbs(this.crumbs, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(color: theme.textSubtlest)),
            ),
          _LzHover(
            onTap: crumbs[i].onTap,
            builder: (context, hovered) {
              final interactive = crumbs[i].onTap != null;
              return Text(
                crumbs[i].label,
                style: TextStyle(
                  color: hovered && interactive
                      ? theme.linkHover
                      : theme.textSubtle,
                  decoration: hovered && interactive
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Pagination (`.pagination`) — 32px page targets with elision, chevron
/// prev/next, selected page in the selection colors.
class LzPagination extends StatelessWidget {
  /// Current page, 1-based.
  final int page;
  final int pageCount;
  final ValueChanged<int> onChanged;

  const LzPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onChanged,
  });

  /// Which page numbers to show: first, last, and a window around [page],
  /// with `null` marking an elided range.
  List<int?> _pages() {
    if (pageCount <= 7) {
      return [for (var i = 1; i <= pageCount; i++) i];
    }
    final out = <int?>[1];
    final lo = (page - 1).clamp(2, pageCount - 1);
    final hi = (page + 1).clamp(2, pageCount - 1);
    if (lo > 2) out.add(null);
    for (var i = lo; i <= hi; i++) {
      out.add(i);
    }
    if (hi < pageCount - 1) out.add(null);
    out.add(pageCount);
    return out;
  }

  Widget _link(
    BuildContext context, {
    Widget? child,
    int? number,
    VoidCallback? onTap,
    bool active = false,
    bool disabled = false,
  }) {
    final theme = LzTheme.of(context);
    return _LzHover(
      onTap: disabled ? null : onTap,
      builder: (context, hovered) {
        final Color fg;
        if (disabled) {
          fg = theme.textDisabled;
        } else if (active) {
          fg = theme.selectedText;
        } else {
          fg = theme.text;
        }
        final Color? bg = active
            ? theme.selectedBg
            : (hovered && !disabled ? theme.interactionHovered : null);
        return Container(
          constraints: const BoxConstraints(minWidth: 32),
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(3),
          ),
          child: child ??
              Text(
                '$number',
                style: TextStyle(color: fg, fontWeight: FontWeight.w500),
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _link(
          context,
          disabled: page <= 1,
          onTap: () => onChanged(page - 1),
          child: Icon(
            Icons.chevron_left,
            size: 20,
            color: page <= 1 ? theme.textDisabled : theme.text,
          ),
        ),
        for (final p in _pages()) ...[
          const SizedBox(width: 4),
          if (p == null)
            Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text('…', style: TextStyle(color: theme.textSubtle)),
            )
          else
            _link(
              context,
              number: p,
              active: p == page,
              onTap: () => onChanged(p),
            ),
        ],
        const SizedBox(width: 4),
        _link(
          context,
          disabled: page >= pageCount,
          onTap: () => onChanged(page + 1),
          child: Icon(
            Icons.chevron_right,
            size: 20,
            color: page >= pageCount ? theme.textDisabled : theme.text,
          ),
        ),
      ],
    );
  }
}
