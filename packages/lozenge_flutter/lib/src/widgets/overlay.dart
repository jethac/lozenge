import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

// ---------------------------------------------------------------------------
// Glass material + shadow recipes shared by modal / drawer / menu / tooltip.
// ---------------------------------------------------------------------------

// Shadow colors intentionally use black (allowed for shadows only).
List<BoxShadow> _overlayShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: -2,
      ),
      BoxShadow(color: Colors.black.withValues(alpha: 0.31), blurRadius: 1),
    ];

List<BoxShadow> _modalShadow() => [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        offset: const Offset(0, 8),
        blurRadius: 16,
        spreadRadius: -4,
      ),
      BoxShadow(color: Colors.black.withValues(alpha: 0.31), blurRadius: 1),
    ];

/// Glass surface panel — the Flutter twin of the CSS `glass()` mixin:
/// `surface-overlay` at [LzThemeData.materialAlpha], with a backdrop blur
/// whenever the material is translucent.
class _LzGlassPanel extends StatelessWidget {
  final BorderRadius radius;
  final List<BoxShadow> shadows;
  final Widget child;

  const _LzGlassPanel({
    required this.radius,
    required this.shadows,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final alpha = t.materialAlpha;
    final color =
        t.surfaceOverlay.withValues(alpha: t.surfaceOverlay.a * alpha);
    Widget panel = DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: child,
    );
    if (alpha < 1) {
      final sigma = t.glass * 8; // ≈ CSS blur(16px)
      panel = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: panel,
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadows),
      child: panel,
    );
  }
}

/// Fades its child in over [duration] on first frame — used for menu and
/// tooltip entrances.
class _FadeIn extends StatefulWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;
  const _FadeIn({
    required this.duration,
    required this.child,
    this.curve = LzMotion.entrance,
  });

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      );
}

// ---------------------------------------------------------------------------
// Modal
// ---------------------------------------------------------------------------

/// Modal widths, mirroring the CSS `$modal-widths` map.
enum LzModalSize {
  /// 400px.
  small,

  /// 600px.
  medium,

  /// 800px.
  large,

  /// 968px.
  xlarge,
}

/// Shows [builder]'s widget as a Lozenge modal dialog: `blanket` barrier,
/// near-top centered placement, and the CSS entrance animation
/// (fade + 8px rise + 0.98 scale over [LzMotion.medium]).
///
/// ```dart
/// final confirmed = await showLzModal<bool>(
///   context,
///   builder: (context) => LzModal(
///     title: 'Delete issue?',
///     danger: true,
///     body: const Text('This cannot be undone.'),
///     actions: [
///       LzButton(
///         variant: LzButtonVariant.subtle,
///         onPressed: () => Navigator.of(context).pop(false),
///         child: const Text('Cancel'),
///       ),
///       LzButton(
///         variant: LzButtonVariant.danger,
///         onPressed: () => Navigator.of(context).pop(true),
///         child: const Text('Delete'),
///       ),
///     ],
///   ),
/// );
/// ```
Future<T?> showLzModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final t = LzTheme.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierColor: t.blanket,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    transitionDuration: LzMotion.medium,
    pageBuilder: (ctx, animation, secondaryAnimation) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 60),
          child: builder(ctx),
        ),
      ),
    ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: LzMotion.entrance);
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (_, inner) {
          final v = curved.value;
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - v)),
              child: Transform.scale(scale: 0.98 + 0.02 * v, child: inner),
            ),
          );
        },
      );
    },
  );
}

/// The modal panel itself (`dialog.modal`): glass `surface-overlay`
/// material, modal shadow, 3px radius, 24px paddings, with an optional
/// title row and footer actions.
class LzModal extends StatelessWidget {
  /// Heading text (20px medium). Colored `danger-bold` when [danger] is set.
  final String? title;

  /// Scrollable modal content.
  final Widget body;

  /// Footer buttons, laid out end-aligned with 8px gaps.
  final List<Widget>? actions;

  /// Maximum width preset. Defaults to [LzModalSize.medium] (600px).
  final LzModalSize size;

  /// Destructive-confirmation emphasis (`.modal-danger`).
  final bool danger;

  const LzModal({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.size = LzModalSize.medium,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    final width = switch (size) {
      LzModalSize.small => 400.0,
      LzModalSize.medium => 600.0,
      LzModalSize.large => 800.0,
      LzModalSize.xlarge => 968.0,
    };
    final hasActions = actions != null && actions!.isNotEmpty;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: _LzGlassPanel(
        radius: BorderRadius.circular(3),
        shadows: _modalShadow(),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 20,
                      height: 24 / 20,
                      fontWeight: FontWeight.w500,
                      color: danger ? t.dangerBold : t.text,
                    ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    title == null ? 24 : 0,
                    24,
                    hasActions ? 0 : 24,
                  ),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: t.text,
                    ),
                    child: body,
                  ),
                ),
              ),
              if (hasActions)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (var i = 0; i < actions!.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        actions![i],
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Drawer
// ---------------------------------------------------------------------------

/// Shows [builder]'s widget in a Lozenge drawer (`dialog.drawer`): a
/// full-height glass side sheet, 480px wide (720px [wide]), sliding in from
/// the end edge (or the start edge with [fromStart]) over [LzMotion.slow].
///
/// ```dart
/// showLzDrawer(context, builder: (context) => const IssueDetailPane());
/// ```
Future<T?> showLzDrawer<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool fromStart = false,
  bool wide = false,
}) {
  final t = LzTheme.of(context);
  final width = wide ? 720.0 : 480.0;
  const r = Radius.circular(3);
  // Round only the free edge; the attached edge stays square.
  final radius = fromStart
      ? const BorderRadius.only(topRight: r, bottomRight: r)
      : const BorderRadius.only(topLeft: r, bottomLeft: r);
  return showGeneralDialog<T>(
    context: context,
    barrierColor: t.blanket,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    transitionDuration: LzMotion.slow,
    pageBuilder: (ctx, animation, secondaryAnimation) => Align(
      alignment: fromStart ? Alignment.centerLeft : Alignment.centerRight,
      child: _LzGlassPanel(
        radius: radius,
        shadows: _modalShadow(),
        child: SizedBox(
          width: width,
          height: double.infinity,
          child: Material(type: MaterialType.transparency, child: builder(ctx)),
        ),
      ),
    ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) =>
        SlideTransition(
      position: Tween<Offset>(
        begin: Offset(fromStart ? -1 : 1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: LzMotion.entrance)),
      child: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Menu
// ---------------------------------------------------------------------------

/// Marker interface for widgets accepted inside a Lozenge menu:
/// [LzMenuItem], [LzMenuHeading], and [LzMenuDivider].
abstract class LzMenuEntry implements Widget {}

class _LzMenuScope extends InheritedWidget {
  final VoidCallback close;
  const _LzMenuScope({required this.close, required super.child});

  static _LzMenuScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_LzMenuScope>();

  @override
  bool updateShouldNotify(_LzMenuScope oldWidget) => close != oldWidget.close;
}

/// The dropdown panel skin (`.dropdown-menu`): 160–320px wide, glass
/// `surface-overlay`, overlay shadow, 3px radius, 4px vertical padding.
class _LzMenuPanel extends StatelessWidget {
  final List<LzMenuEntry> items;
  const _LzMenuPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 320),
      child: _LzGlassPanel(
        radius: BorderRadius.circular(3),
        shadows: _overlayShadow(),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable menu row (`.dropdown-item`), with optional secondary
/// [description], and `selected` / `danger` / `disabled` states.
class LzMenuItem extends StatefulWidget implements LzMenuEntry {
  /// The row content (usually a [Text]).
  final Widget child;

  /// Secondary line below [child] (12px, `text-subtle`).
  final String? description;

  /// Highlighted with `selected-bg` / `selected-text`.
  final bool selected;

  /// Destructive item: `danger-bold` text, danger-subtle hover.
  final bool danger;

  /// Non-interactive, `text-disabled`.
  final bool disabled;

  /// Called on tap; the menu closes afterwards.
  final VoidCallback? onTap;

  const LzMenuItem({
    super.key,
    required this.child,
    this.description,
    this.selected = false,
    this.danger = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  State<LzMenuItem> createState() => _LzMenuItemState();
}

class _LzMenuItemState extends State<LzMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    Color? bg;
    Color fg;
    if (widget.disabled) {
      fg = t.textDisabled;
    } else if (widget.selected) {
      bg = t.selectedBg;
      fg = t.selectedText;
    } else if (widget.danger) {
      bg = _hovered ? t.statusDangerSubtleBg : null;
      fg = _hovered ? t.statusDangerSubtleText : t.dangerBold;
    } else {
      bg = _hovered ? t.interactionHovered : null;
      fg = t.text;
    }
    return Semantics(
      button: true,
      enabled: !widget.disabled,
      child: MouseRegion(
        cursor: widget.disabled
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.disabled
              ? null
              : () {
                  widget.onTap?.call();
                  _LzMenuScope.maybeOf(context)?.close();
                },
          child: Container(
            color: bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontSize: 14, height: 20 / 14, color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: widget.description == null
                  ? widget.child
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.child,
                        Text(
                          widget.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 16 / 12,
                            color: t.textSubtle,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uppercase section heading inside a menu (`.dropdown-heading`).
class LzMenuHeading extends StatelessWidget implements LzMenuEntry {
  final String text;
  const LzMenuHeading(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          height: 16 / 11,
          fontWeight: FontWeight.w700,
          color: t.textSubtle,
        ),
      ),
    );
  }
}

/// 2px separator line inside a menu (`.dropdown-divider`).
class LzMenuDivider extends StatelessWidget implements LzMenuEntry {
  const LzMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      height: 2,
      color: t.separator,
    );
  }
}

/// Shows a Lozenge dropdown menu anchored below-start of [anchorKey]'s
/// widget, or at an explicit [position]. Light-dismiss via the transparent
/// barrier; items close the menu after their `onTap`.
///
/// ```dart
/// final key = GlobalKey();
/// // ...
/// showLzMenu(context, anchorKey: key, items: [
///   LzMenuHeading('Move to'),
///   LzMenuItem(child: const Text('To do'), onTap: () => move(Status.todo)),
///   const LzMenuDivider(),
///   LzMenuItem(child: const Text('Delete'), danger: true, onTap: delete),
/// ]);
/// ```
Future<void> showLzMenu(
  BuildContext context, {
  RelativeRect? position,
  GlobalKey? anchorKey,
  required List<LzMenuEntry> items,
}) {
  assert(position != null || anchorKey != null,
      'Provide either position or anchorKey');
  double left;
  double top;
  if (anchorKey != null) {
    final box = anchorKey.currentContext!.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    left = origin.dx;
    top = origin.dy + box.size.height + 4;
  } else {
    left = position!.left;
    top = position.top;
  }
  final t = LzTheme.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierColor: t.blanket.withValues(alpha: 0.0),
    barrierDismissible: true,
    barrierLabel: 'Dismiss menu',
    transitionDuration: LzMotion.fast,
    pageBuilder: (ctx, animation, secondaryAnimation) => Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: _LzMenuScope(
            close: () => Navigator.of(ctx).pop(),
            child: _LzMenuPanel(items: items),
          ),
        ),
      ],
    ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) =>
        FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: LzMotion.entrance),
      child: child,
    ),
  );
}

/// Declarative dropdown: wraps [trigger] so a tap opens a Lozenge menu
/// anchored below its start edge (via `CompositedTransformTarget`/`Follower`
/// in the app [Overlay]); tapping outside or picking an item closes it.
///
/// The trigger should be a non-interactive widget — [LzMenuButton] supplies
/// the tap handling itself.
///
/// ```dart
/// LzMenuButton(
///   trigger: const LzButton(child: Text('Status')),
///   items: [
///     LzMenuItem(child: const Text('To do'), onTap: () => move(Status.todo)),
///     LzMenuItem(child: const Text('Done'), onTap: () => move(Status.done)),
///   ],
/// )
/// ```
class LzMenuButton extends StatefulWidget {
  /// The widget that toggles the menu.
  final Widget trigger;

  /// Menu contents.
  final List<LzMenuEntry> items;

  const LzMenuButton({super.key, required this.trigger, required this.items});

  @override
  State<LzMenuButton> createState() => _LzMenuButtonState();
}

class _LzMenuButtonState extends State<LzMenuButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _openMenu() {
    final theme = LzTheme.of(context);
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: TapRegion(
            groupId: this,
            onTapOutside: (_) => _close(),
            child: LzTheme(
              data: theme,
              child: _LzMenuScope(
                close: _close,
                child: _FadeIn(
                  duration: LzMotion.fast,
                  child: _LzMenuPanel(items: widget.items),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TapRegion(
        groupId: this,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _open ? _close() : _openMenu(),
          child: Semantics(
            button: true,
            expanded: _open,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: widget.trigger,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tooltip
// ---------------------------------------------------------------------------

/// Which side of the child the tooltip appears on.
enum LzTooltipPosition { top, bottom, left, right }

/// Lozenge tooltip: an n800-style chip (`tooltip-bg` / `tooltip-text`,
/// 12px text, 2×6 padding) shown after a 200ms hover delay with an
/// [LzMotion.fast] fade.
///
/// ```dart
/// LzTooltip(
///   message: 'Assign to me',
///   child: LzIconButton(icon: const Icon(Icons.person), onPressed: assign),
/// )
/// ```
class LzTooltip extends StatefulWidget {
  /// Tooltip text.
  final String message;

  /// The hover target.
  final Widget child;

  /// Placement relative to [child]. Defaults to [LzTooltipPosition.top].
  final LzTooltipPosition position;

  const LzTooltip({
    super.key,
    required this.message,
    required this.child,
    this.position = LzTooltipPosition.top,
  });

  @override
  State<LzTooltip> createState() => _LzTooltipState();
}

class _LzTooltipState extends State<LzTooltip> {
  static const _delay = Duration(milliseconds: 200);

  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  Timer? _timer;

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(_delay, _show);
  }

  void _cancel() {
    _timer?.cancel();
    _timer = null;
    _hide();
  }

  void _show() {
    if (!mounted || _entry != null) return;
    final theme = LzTheme.of(context);
    final (targetAnchor, followerAnchor, offset) = switch (widget.position) {
      LzTooltipPosition.top => (
          Alignment.topCenter,
          Alignment.bottomCenter,
          const Offset(0, -4),
        ),
      LzTooltipPosition.bottom => (
          Alignment.bottomCenter,
          Alignment.topCenter,
          const Offset(0, 4),
        ),
      LzTooltipPosition.left => (
          Alignment.centerLeft,
          Alignment.centerRight,
          const Offset(-4, 0),
        ),
      LzTooltipPosition.right => (
          Alignment.centerRight,
          Alignment.centerLeft,
          const Offset(4, 0),
        ),
    };
    _entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: 0,
        top: 0,
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: offset,
          child: IgnorePointer(
            child: LzTheme(
              data: theme,
              child: _FadeIn(
                duration: LzMotion.fast,
                curve: LzMotion.standard,
                child: _LzTooltipBubble(message: widget.message),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: Semantics(
        tooltip: widget.message,
        child: MouseRegion(
          onEnter: (_) => _schedule(),
          onExit: (_) => _cancel(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _LzTooltipBubble extends StatelessWidget {
  final String message;
  const _LzTooltipBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final t = LzTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.tooltipBg,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w400,
              color: t.tooltipText,
            ),
          ),
        ),
      ),
    );
  }
}
