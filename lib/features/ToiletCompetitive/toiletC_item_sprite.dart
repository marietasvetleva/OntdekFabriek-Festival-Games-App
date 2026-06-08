import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Trash on the festival mud — top-down ground contact, not side-lit drop shadows.
class CompetitiveTrashSprite extends StatelessWidget {
  CompetitiveTrashSprite({
    super.key,
    required this.assetPath,
    required this.size,
    required this.rotationRad,
    required this.flipX,
    required this.displayScale,
    required this.spawnPhase,
    required this.ttlUrgency,
    required this.isHeld,
    required this.fallbackColor,
  });

  final String assetPath;
  final double size;
  final double rotationRad;
  final bool flipX;
  final double displayScale;
  /// 0 = just landed, 1 = settled.
  final double spawnPhase;
  /// 0 = fresh, 1 = about to expire.
  final double ttlUrgency;
  final bool isHeld;
  final Color fallbackColor;

  static const Color _contactTint = Color(0xFF3D2E22);

  @override
  Widget build(BuildContext context) {
    final heldLift = isHeld ? 1.05 : 1.0;
    final spawnBoost = 1.0 - spawnPhase.clamp(0.0, 1.0);
    final showUrgency = ttlUrgency > 0.72;

    final sprite = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ(rotationRad)
        // ignore: deprecated_member_use
        ..scale((flipX ? -1.0 : 1.0) * displayScale * heldLift, displayScale * heldLift),
      child: RepaintBoundary(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(1.5, 2),
                child: _silhouette(),
              ),
              _rawImage(),
              if (spawnBoost > 0.08)
                IgnorePointer(
                  child: _SpawnLandingRing(
                    size: size,
                    progress: 1.0 - spawnBoost,
                  ),
                ),
              if (showUrgency)
                IgnorePointer(
                  child: _UrgencyRing(
                    size: size,
                    strength: ((ttlUrgency - 0.72) / 0.28).clamp(0.0, 1.0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _TopDownGroundShadow(
            footprint: size * 0.72 * displayScale,
            lifted: isHeld,
          ),
          if (isHeld)
            Transform.translate(offset: const Offset(0, -5), child: sprite)
          else
            sprite,
        ],
      ),
    );
  }

  Widget _silhouette() {
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(_contactTint, BlendMode.srcIn),
      child: _rawImage(filterQuality: FilterQuality.low),
    );
  }

  Widget _rawImage({FilterQuality filterQuality = FilterQuality.medium}) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: filterQuality,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: fallbackColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _contactTint, width: 2),
        ),
      ),
    );
  }
}

/// Screen-aligned oval on the mud; does not rotate with the litter sprite.
class _TopDownGroundShadow extends StatelessWidget {
  _TopDownGroundShadow({
    required this.footprint,
    required this.lifted,
  });

  final double footprint;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final alpha = lifted ? 0.12 : 0.24;
    final scale = lifted ? 0.88 : 1.0;

    return Transform.translate(
      offset: Offset(footprint * 0.08, footprint * 0.14),
      child: Transform.scale(
        scaleX: 0.78 * scale,
        scaleY: 0.34 * scale,
        child: Container(
          width: footprint,
          height: footprint,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF2A2218).withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}

class _SpawnLandingRing extends StatelessWidget {
  _SpawnLandingRing({required this.size, required this.progress});

  final double size;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final scale = lerpDouble(0.35, 1.15, t)!;
    final alpha = (1.0 - t) * 0.7;
    return Opacity(
      opacity: alpha.clamp(0.0, 1.0),
      child: Container(
        width: size * scale,
        height: size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF8A7358),
            width: 2.5,
          ),
        ),
      ),
    );
  }
}

class _UrgencyRing extends StatelessWidget {
  _UrgencyRing({required this.size, required this.strength});

  final double size;
  final double strength;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: (0.2 + strength * 0.5).clamp(0.0, 1.0),
      child: Container(
        width: size * 1.06,
        height: size * 1.06,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF6A5A48),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Minimal sprite for short deposit animations (no ground shadow stack).
class CompetitiveTrashFxSprite extends StatelessWidget {
  CompetitiveTrashFxSprite({
    super.key,
    required this.assetPath,
    required this.size,
    required this.rotationRad,
    required this.flipX,
    required this.displayScale,
    required this.fallbackColor,
  });

  final String assetPath;
  final double size;
  final double rotationRad;
  final bool flipX;
  final double displayScale;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ(rotationRad)
        // ignore: deprecated_member_use
        ..scale((flipX ? -1.0 : 1.0) * displayScale, displayScale),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: fallbackColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
