import 'dart:math';

import 'package:flutter/material.dart';

import 'toiletC_arena_layout.dart';
import 'toiletC_arena_layout_tune.dart';
import 'toiletC_arena_viewport.dart';
import 'toiletC_models.dart';

/// Renders the festival arena background and bucket sprites.
class ToiletCompetitiveArenaScene extends StatelessWidget {
  const ToiletCompetitiveArenaScene({
    super.key,
    required this.viewport,
    required this.p1Bucket,
    required this.p2Bucket,
    required this.p1Score,
    required this.p2Score,
    required this.p1BinType,
    required this.p2BinType,
    required this.bucketAssetLeft,
    required this.bucketAssetRight,
    required this.binTintFor,
    required this.scoreBadge,
    required this.layoutTune,
    required this.worldTimeSec,
    this.p1BucketBump = 0,
    this.p2BucketBump = 0,
  });

  final ArenaViewport viewport;
  final ArenaLayoutTune layoutTune;
  final double worldTimeSec;
  final double p1BucketBump;
  final double p2BucketBump;
  final Rect p1Bucket;
  final Rect p2Bucket;
  final int p1Score;
  final int p2Score;
  final BinType p1BinType;
  final BinType p2BinType;
  final String bucketAssetLeft;
  final String bucketAssetRight;
  final Color Function(BinType) binTintFor;
  final Widget Function(int score, Color binColor) scoreBadge;

  ArenaLayoutTune get _tune => layoutTune;
  Rect get _arena => viewport.arenaRect;
  static const double _edgeBleed = 2;

  @override
  Widget build(BuildContext context) {
    Widget bucketAt({
      required Rect bucketRect,
      required String asset,
      required BinType binType,
      required int score,
      required int player,
      required int quarterTurns,
      required double bump,
    }) {
      final pit = ToiletCompetitiveArenaLayout.binPitRect(
        viewport,
        player,
        _tune,
      );
      final size = Size(bucketRect.width, bucketRect.height);
      final topLeft = ToiletCompetitiveArenaLayout.bucketTopLeft(
        pit.center,
        size,
        player,
        _tune,
      );
      final idleBob = sin(worldTimeSec * 1.65 + player * 1.7) * 2.2;
      final bumpKick = bump * sin(bump * pi * 2.2) * 10;
      final squash = 1.0 - bump * 0.06;

      return Positioned(
        left: topLeft.dx - _arena.left + _edgeBleed,
        top: topLeft.dy - _arena.top + idleBob + bumpKick,
        width: size.width,
        height: size.height,
        child: Transform.scale(
          scaleY: squash,
          alignment: Alignment.bottomCenter,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                asset,
                width: size.width,
                height: size.height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    color: binTintFor(binType).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Positioned(
                left: size.width * 0.5 - 18,
                top: -40,
                child: RotatedBox(
                  quarterTurns: quarterTurns,
                  child: scoreBadge(score, binTintFor(binType)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        const Positioned.fill(
          child: ColoredBox(color: ToiletCompetitiveArenaLayout.edgeFillColor),
        ),
        Positioned(
          left: _arena.left - _edgeBleed,
          top: _arena.top,
          width: _arena.width + _edgeBleed * 2,
          height: _arena.height,
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    ToiletCompetitiveArenaLayout.arenaAsset,
                    fit: viewport.imageFit,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFD4C4A8),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: Color(0xFF6A5A48),
                      ),
                    ),
                  ),
                ),
                bucketAt(
                  bucketRect: p1Bucket,
                  asset: bucketAssetLeft,
                  binType: p1BinType,
                  score: p1Score,
                  player: 1,
                  quarterTurns: 1,
                  bump: p1BucketBump,
                ),
                bucketAt(
                  bucketRect: p2Bucket,
                  asset: bucketAssetRight,
                  binType: p2BinType,
                  score: p2Score,
                  player: 2,
                  quarterTurns: 3,
                  bump: p2BucketBump,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
