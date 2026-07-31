// Section messages, page banners, and flags (toasts).
// Mirrors scss/components/_message.scss.
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

// $shadow-modal: 0 8px 16px -4px rgba(#091E42, .25), 0 0 1px rgba(#091E42, .31).
const List<BoxShadow> _shadowModal = [
  BoxShadow(
    color: Color(0x40091E42),
    offset: Offset(0, 8),
    blurRadius: 16,
    spreadRadius: -4,
  ),
  BoxShadow(color: Color(0x4F091E42), blurRadius: 1),
];

/// Inline section message (callout) with a colored edge bar: contextual
/// info, warnings, errors, successes, or discovery announcements.
///
/// ```dart
/// LzMessage(
///   title: 'Trial ending',
///   status: LzStatus.warning,
///   child: Text('Your trial expires in 3 days.'),
/// )
/// ```
class LzMessage extends StatelessWidget {
  /// The message body.
  final Widget child;

  /// Optional bold heading line above the body.
  final String? title;

  /// Status family driving fill and accent-bar colors.
  final LzStatus status;

  const LzMessage({
    super.key,
    required this.child,
    this.title,
    this.status = LzStatus.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        color: status.subtleBg(theme),
        child: Stack(
          children: [
            // The 4px inset accent bar (box-shadow: inset 4px 0 0 in CSS).
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: status.boldBg(theme)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        title!,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 16 / 14,
                        ),
                      ),
                    ),
                  DefaultTextStyle(
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual tone of an [LzBanner].
enum LzBannerAppearance {
  /// Neutral-bold announcement (the CSS `.banner` default).
  announcement,

  /// Warning-bold background (`.banner-warning`).
  warning,

  /// Danger-bold background (`.banner-error`).
  error,
}

/// Full-width single-line page banner (maintenance notices, read-only mode,
/// outages); content is centered on a bold background.
///
/// ```dart
/// LzBanner(
///   appearance: LzBannerAppearance.error,
///   child: Text("Something's gone wrong — retrying…"),
/// )
/// ```
class LzBanner extends StatelessWidget {
  /// The banner content, centered.
  final Widget child;

  /// Visual tone; defaults to the neutral announcement.
  final LzBannerAppearance appearance;

  const LzBanner({
    super.key,
    required this.child,
    this.appearance = LzBannerAppearance.announcement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final (Color bg, Color fg) = switch (appearance) {
      LzBannerAppearance.announcement => (
          theme.statusNeutralBoldBg,
          theme.statusNeutralOnBold,
        ),
      LzBannerAppearance.warning => (
          theme.warningBold,
          theme.statusWarningOnBold,
        ),
      LzBannerAppearance.error => (
          theme.dangerBold,
          theme.statusDangerOnBold,
        ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: bg,
      child: DefaultTextStyle(
        style: TextStyle(
          color: fg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 20 / 14,
        ),
        textAlign: TextAlign.center,
        child: Center(child: child),
      ),
    );
  }
}

/// Floating toast notification (bottom-left in Jira): icon, content block
/// (title/description/actions), and a dismiss button. A glass surface by
/// default; [boldStatus] recolors the whole flag for success/error toasts.
///
/// ```dart
/// LzFlag(
///   title: 'Issue created',
///   description: 'LOZ-42 has been added to the backlog.',
///   onDismiss: close,
/// )
/// ```
///
/// See also [showLzFlag], which floats one over the current [Overlay].
class LzFlag extends StatefulWidget {
  /// Heading line of the toast.
  final String title;

  /// Optional subtle description under the title.
  final String? description;

  /// Bold tone: fills the flag with the status bold-bg and switches all
  /// text to the on-bold color. Null keeps the glass surface.
  final LzStatus? boldStatus;

  /// Optional leading icon block (e.g. an [LzIssueTypeIcon]).
  final Widget? icon;

  /// Row of action widgets under the description.
  final List<Widget> actions;

  /// When non-null, renders a trailing dismiss button.
  final VoidCallback? onDismiss;

  const LzFlag({
    super.key,
    required this.title,
    this.description,
    this.boldStatus,
    this.icon,
    this.actions = const [],
    this.onDismiss,
  });

  @override
  State<LzFlag> createState() => _LzFlagState();
}

class _LzFlagState extends State<LzFlag> {
  bool _dismissHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final bold = widget.boldStatus;
    final onBold = bold?.onBold(theme);
    final alpha = bold == null ? theme.materialAlpha : 1.0;
    final bg = bold?.boldBg(theme) ??
        theme.surfaceOverlay.withValues(alpha: alpha);

    final content = Container(
      width: 400,
      padding: const EdgeInsets.all(16),
      color: bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          if (widget.icon != null) widget.icon!,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: onBold ?? theme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 16 / 14,
                  ),
                ),
                if (widget.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.description!,
                      style: TextStyle(
                        color: onBold ?? theme.textSubtle,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                if (widget.actions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: onBold ?? theme.link,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 20 / 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: widget.actions,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.onDismiss != null)
            Semantics(
              button: true,
              label: 'Dismiss',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _dismissHovered = true),
                onExit: (_) => setState(() => _dismissHovered = false),
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !_dismissHovered
                          ? null
                          : bold != null
                              ? const Color(0x33000000)
                              : theme.interactionHovered,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '×',
                      style: TextStyle(
                        color: onBold ??
                            (_dismissHovered ? theme.text : theme.textSubtle),
                        fontSize: 16,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Glass: blur what's behind when the material alpha is translucent.
    final glassed = bold == null && alpha < 1
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16 * theme.glass,
              sigmaY: 16 * theme.glass,
            ),
            child: content,
          )
        : content;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        boxShadow: _shadowModal,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: glassed,
      ),
    );
  }
}

/// Floats an [LzFlag] over the current [Overlay], bottom-left, sliding and
/// fading in with [LzMotion.entrance] and auto-dismissing after [duration].
///
/// Returns the [OverlayEntry] so callers can remove it early.
///
/// ```dart
/// showLzFlag(context, title: 'Issue created', description: 'LOZ-42 added.');
/// ```
OverlayEntry showLzFlag(
  BuildContext context, {
  required String title,
  String? description,
  LzStatus? boldStatus,
  Widget? icon,
  List<Widget> actions = const [],
  Duration duration = const Duration(seconds: 4),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 24,
      bottom: 24,
      child: _LzFlagToast(
        title: title,
        description: description,
        boldStatus: boldStatus,
        icon: icon,
        actions: actions,
        duration: duration,
        onRemoved: () {
          if (entry.mounted) entry.remove();
        },
      ),
    ),
  );
  overlay.insert(entry);
  return entry;
}

class _LzFlagToast extends StatefulWidget {
  final String title;
  final String? description;
  final LzStatus? boldStatus;
  final Widget? icon;
  final List<Widget> actions;
  final Duration duration;
  final VoidCallback onRemoved;

  const _LzFlagToast({
    required this.title,
    required this.description,
    required this.boldStatus,
    required this.icon,
    required this.actions,
    required this.duration,
    required this.onRemoved,
  });

  @override
  State<_LzFlagToast> createState() => _LzFlagToastState();
}

class _LzFlagToastState extends State<_LzFlagToast> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
    _timer = Timer(widget.duration, _hide);
  }

  void _hide() {
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _shown = false);
    _timer = Timer(LzMotion.medium, widget.onRemoved);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.25),
      duration: _shown ? LzMotion.slow : LzMotion.medium,
      curve: _shown ? LzMotion.entrance : LzMotion.exit,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: LzMotion.medium,
        curve: _shown ? LzMotion.entrance : LzMotion.exit,
        child: LzFlag(
          title: widget.title,
          description: widget.description,
          boldStatus: widget.boldStatus,
          icon: widget.icon,
          actions: widget.actions,
          onDismiss: _hide,
        ),
      ),
    );
  }
}
