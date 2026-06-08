import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Brief "+1" float when a player scores.
class CompetitiveScorePopupFx extends StatelessWidget {
  const CompetitiveScorePopupFx({
    super.key,
    required this.center,
    required this.progress,
  });

  final Offset center;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final y = lerpDouble(0, -48, t)!;
    final opacity = (1.0 - Curves.easeIn.transform(progress.clamp(0.0, 1.0)))
        .clamp(0.0, 1.0);
    final scale = lerpDouble(0.7, 1.0, Curves.elasticOut.transform(t.clamp(0.0, 1.0)))!;

    return Positioned(
      left: center.dx - 24,
      top: center.dy + y - 16,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: const Text(
              '+1',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2A4A22),
                shadows: [
                  Shadow(
                    color: Color(0xCCFFFFFF),
                    blurRadius: 6,
                    offset: Offset(0, 1),
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

/// Dust ring when litter expires on the ground.
class CompetitiveMissedItemFx extends StatelessWidget {
  const CompetitiveMissedItemFx({
    super.key,
    required this.center,
    required this.progress,
    required this.baseSize,
  });

  final Offset center;
  final double progress;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    final scale = lerpDouble(0.5, 1.3, t)!;
    final alpha = (1.0 - t) * 0.65;

    return Positioned(
      left: center.dx - baseSize * scale / 2,
      top: center.dy - baseSize * scale * 0.3,
      child: IgnorePointer(
        child: Opacity(
          opacity: alpha.clamp(0.0, 1.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: baseSize * scale,
                height: baseSize * scale * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5A4A38).withValues(alpha: 0.35),
                ),
              ),
              Text(
                '· · ·',
                style: TextStyle(
                  fontSize: baseSize * 0.22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF4A3D30).withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft pulse on the central play mud (ambient life).
class CompetitiveArenaBreath extends StatelessWidget {
  const CompetitiveArenaBreath({
    super.key,
    required this.rect,
    required this.phase,
  });

  final Rect rect;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final wave = 0.5 + 0.5 * sin(phase * 2 * pi);
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.06 + wave * 0.04,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(rect.width * 0.22),
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8A6B4A).withValues(alpha: 0.0),
                  const Color(0xFF6A5038).withValues(alpha: 0.35),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
