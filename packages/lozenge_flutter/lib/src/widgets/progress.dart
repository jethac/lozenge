// Lozenge progress widgets: bar, spinner, skeleton, tracker.
// Mirrors scss/components/{_progress,_skeleton,_tracker}.scss.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Determinate progress bar (`.progress`) — 6px rounded track and fill.
///
/// The fill uses the accent by default; pass a [status] to recolor it with
/// that status family's bold background (success, danger, …).
class LzProgressBar extends StatelessWidget {
  /// Completion in `0..1`.
  final double value;

  /// Optional status family for the fill color.
  final LzStatus? status;

  const LzProgressBar({super.key, required this.value, this.status});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final Color fill;
    if (status == null) {
      fill = theme.accentBold;
    } else {
      // Accept either family names (success, danger, …) or lozenge variant
      // names (removed, inprogress, …) — same mapping the CSS engine uses.
      final family = lzLozengeVariants[status!.name] ?? status!.name;
      fill = theme.resolve('status-$family-bold-bg');
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        height: 6,
        color: theme.track,
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedFractionallySizedBox(
          duration: LzMotion.slow,
          curve: Curves.ease,
          alignment: AlignmentDirectional.centerStart,
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indeterminate spinner (`.spinner`) — a rotating arc, subtle text color by
/// default; pass [color] to match surrounding content (currentColor).
class LzSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const LzSpinner({super.key, this.size = 16, this.color});

  @override
  State<LzSpinner> createState() => _LzSpinnerState();
}

class _LzSpinnerState extends State<LzSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 860),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final color = widget.color ?? theme.textSubtle;
    // Mirrors the CSS keyframe easing: cubic-bezier(0.4, 0.15, 0.6, 0.85).
    final turns = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.4, 0.15, 0.6, 0.85),
    );
    return RotationTransition(
      turns: turns,
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _LzSpinnerPainter(
          color: color,
          strokeWidth: widget.size >= 24 ? 3 : 2,
        ),
      ),
    );
  }
}

class _LzSpinnerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  const _LzSpinnerPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    // Border-top-only ring: a quarter arc.
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      -math.pi * 3 / 4,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_LzSpinnerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

/// Loading placeholder (`.skeleton`) — sunken block with a shimmer sweep.
///
/// The shimmer is decorative and shuts off under
/// `MediaQuery.disableAnimations`.
class LzSkeleton extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final bool _circle;

  const LzSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  }) : _circle = false;

  /// One line of body text (`.skeleton-text`).
  const LzSkeleton.text({super.key, this.width})
      : height = 14,
        borderRadius = const BorderRadius.all(Radius.circular(2)),
        _circle = false;

  /// Circular avatar placeholder (`.skeleton-avatar`).
  const LzSkeleton.avatar({super.key, double size = 32})
      : width = size,
        height = size,
        borderRadius = null,
        _circle = true;

  /// Issue-card-shaped block (`.skeleton-card`).
  const LzSkeleton.card({super.key, this.width})
      : height = 84,
        borderRadius = const BorderRadius.all(Radius.circular(2)),
        _circle = false;

  @override
  State<LzSkeleton> createState() => _LzSkeletonState();
}

class _LzSkeletonState extends State<LzSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    // --lz-motion-deliberate * 2.
    duration: LzMotion.deliberate * 2,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final radius = widget._circle
        ? BorderRadius.circular(widget.height / 2)
        : (widget.borderRadius ?? BorderRadius.circular(3));
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        width: widget.width ?? (widget._circle ? widget.height : null),
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => DecoratedBox(
            decoration: BoxDecoration(
              color: theme.surfaceSunken,
              gradient: _controller.isAnimating
                  ? LinearGradient(
                      // Sweep from -100% to +100%, eased like the CSS.
                      begin: Alignment(
                        -3 +
                            4 *
                                LzMotion.standard
                                    .transform(_controller.value),
                        0,
                      ),
                      end: Alignment(
                        -1 +
                            4 *
                                LzMotion.standard
                                    .transform(_controller.value),
                        0,
                      ),
                      colors: [
                        theme.surfaceSunken,
                        theme.surface.withValues(alpha: 0.65),
                        theme.surfaceSunken,
                      ],
                    )
                  : null,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Wizard stepper (`.tracker`) — 24px markers joined by 2px connectors.
/// Steps before [current] are done (success + check), [current] is accent,
/// later steps are upcoming.
class LzTracker extends StatelessWidget {
  final List<String> steps;

  /// Index of the current step, 0-based.
  final int current;

  const LzTracker({super.key, required this.steps, required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final done = theme.statusSuccessBoldBg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: _LzTrackerStep(
              label: steps[i],
              number: i + 1,
              state: i < current
                  ? _LzStepState.done
                  : (i == current
                      ? _LzStepState.current
                      : _LzStepState.upcoming),
              // Incoming connector: done up to and including the current step.
              before: i == 0 ? null : (i <= current ? done : theme.track),
              // Outgoing connector: done only behind completed steps.
              after: i == steps.length - 1
                  ? null
                  : (i < current ? done : theme.track),
            ),
          ),
      ],
    );
  }
}

enum _LzStepState { done, current, upcoming }

class _LzTrackerStep extends StatelessWidget {
  final String label;
  final int number;
  final _LzStepState state;
  final Color? before;
  final Color? after;

  const _LzTrackerStep({
    required this.label,
    required this.number,
    required this.state,
    this.before,
    this.after,
  });

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final Color markerBg;
    final Widget markerChild;
    switch (state) {
      case _LzStepState.done:
        markerBg = theme.statusSuccessBoldBg;
        markerChild =
            Icon(Icons.check, size: 14, color: theme.statusSuccessOnBold);
      case _LzStepState.current:
        markerBg = theme.accentBold;
        markerChild = Text(
          '$number',
          style: TextStyle(
            color: theme.textOnBold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
      case _LzStepState.upcoming:
        markerBg = theme.surfaceSunken;
        markerChild = Text(
          '$number',
          style: TextStyle(
            color: theme.textSubtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        );
    }
    return Stack(
      children: [
        // Connector halves, centered on the 24px marker (top: 11px);
        // each spans from its edge to 16px shy of center.
        Positioned.fill(
          top: 11,
          bottom: null,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsetsDirectional.only(end: 16),
                  color: before ?? const Color(0x00000000),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsetsDirectional.only(start: 16),
                  color: after ?? const Color(0x00000000),
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration:
                  BoxDecoration(color: markerBg, shape: BoxShape.circle),
              child: markerChild,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: state == _LzStepState.current
                      ? theme.text
                      : theme.textSubtle,
                  fontWeight: state == _LzStepState.current
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
