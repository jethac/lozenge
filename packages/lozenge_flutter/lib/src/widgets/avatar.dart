// Avatars and avatar groups. Mirrors scss/components/_avatar.scss.
import 'package:flutter/material.dart';

import '../../lozenge_flutter.dart';

/// Avatar diameters (`avatar-xs` … `avatar-xl`).
enum LzAvatarSize { xs, sm, md, lg, xl }

/// Pixel dimensions for each [LzAvatarSize].
extension LzAvatarSizeDimension on LzAvatarSize {
  /// The avatar's width/height in logical pixels.
  double get dimension => switch (this) {
        LzAvatarSize.xs => 16,
        LzAvatarSize.sm => 24,
        LzAvatarSize.md => 32,
        LzAvatarSize.lg => 40,
        LzAvatarSize.xl => 96,
      };
}

/// Presence indicator shown as a dot on the avatar's bottom-right corner.
enum LzPresence { online, busy, offline }

/// A circular user/entity avatar showing an image or initials fallback,
/// with optional presence dot and square variant for projects/apps.
///
/// ```dart
/// LzAvatar(initials: 'JC', presence: LzPresence.online)
/// LzAvatar(image: NetworkImage(url), size: LzAvatarSize.lg)
/// ```
class LzAvatar extends StatelessWidget {
  /// 1–2 characters shown when no [image] is given.
  final String? initials;

  /// Optional photo; fills the avatar (cover fit).
  final ImageProvider? image;

  /// Avatar size; defaults to 32px (`md`).
  final LzAvatarSize size;

  /// Square (3px radius) variant for projects/apps instead of a circle.
  final bool square;

  /// Optional presence dot on the bottom-right corner.
  final LzPresence? presence;

  const LzAvatar({
    super.key,
    this.initials,
    this.image,
    this.size = LzAvatarSize.md,
    this.square = false,
    this.presence,
  });

  Color _presenceColor(LzThemeData theme) => switch (presence!) {
        // Deliberately fixed ref-ramp colors (not accent-driven), per the CSS.
        LzPresence.online => lzRamps['green']!['300']!.toColor(),
        LzPresence.busy => lzRamps['yellow']!['300']!.toColor(),
        LzPresence.offline => theme.toggleOff,
      };

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final d = size.dimension;
    Widget avatar = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.statusNeutralSubtleBg,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(3) : null,
        image: image == null
            ? null
            : DecorationImage(image: image!, fit: BoxFit.cover),
      ),
      child: image == null && initials != null
          ? Text(
              initials!,
              style: TextStyle(
                color: theme.textSubtle,
                fontSize: d * 0.4,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            )
          : null,
    );
    if (presence != null) {
      // Dot: 30% of the avatar, min 8px, ringed with the surface color.
      final dot = d * 0.3 < 8 ? 8.0 : d * 0.3;
      avatar = SizedBox(
        width: d,
        height: d,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: _presenceColor(theme),
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return avatar;
  }
}

/// Overlapping horizontal stack of avatars (watchers, assignees), each
/// gaining a surface-colored ring; shows a "+N" counter past [max].
///
/// ```dart
/// LzAvatarGroup([LzAvatar(initials: 'AB'), LzAvatar(initials: 'CD')], max: 3)
/// ```
class LzAvatarGroup extends StatelessWidget {
  /// The stacked avatars; use the same [LzAvatar.size] for all of them.
  final List<LzAvatar> avatars;

  /// Maximum avatars to show before collapsing the rest into "+N".
  final int? max;

  const LzAvatarGroup(this.avatars, {super.key, this.max});

  @override
  Widget build(BuildContext context) {
    final theme = LzTheme.of(context);
    final collapse = max != null && avatars.length > max!;
    final visible = collapse ? avatars.sublist(0, max!) : avatars;
    final overflow = avatars.length - visible.length;
    final size = visible.isEmpty ? LzAvatarSize.md : visible.first.size;
    final d = size.dimension;
    // Ring drawn around each avatar; consecutive avatars overlap by 8px.
    const ring = 2.0;
    final cell = d + ring * 2;
    final step = d - 8;
    final children = <LzAvatar>[
      ...visible,
      if (overflow > 0) LzAvatar(initials: '+$overflow', size: size),
    ];

    Widget ringed(LzAvatar avatar) => Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            shape: avatar.square ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                avatar.square ? BorderRadius.circular(3 + ring) : null,
            border: Border.all(color: theme.surface, width: ring),
          ),
          child: avatar,
        );

    return SizedBox(
      width: children.isEmpty ? 0 : cell + (children.length - 1) * step,
      height: cell,
      child: Stack(
        children: [
          for (var i = 0; i < children.length; i++)
            Positioned(
              left: i * step,
              child: ringed(children[i]),
            ),
        ],
      ),
    );
  }
}
