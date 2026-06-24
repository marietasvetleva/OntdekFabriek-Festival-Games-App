import 'dart:ui';

import 'toiletC_arena_art.dart';
import 'toiletC_arena_layout_tune.dart';
import 'toiletC_arena_viewport.dart';

/// Normalized layout for festival arena art (design coords per [ArenaArtSpec]).
class ToiletCompetitiveArenaLayout {
  ToiletCompetitiveArenaLayout._();

  /// Fallback behind arena — dark mud (not visible when cover fills the screen).
  static const Color edgeFillColor = Color(0xFF2C2618);

  static const double leftBucketAspect = 334 / 279;
  static const double rightBucketAspect = 333 / 278;

  static ArenaArtSpec _spec(ArenaViewport viewport) => viewport.artSpec;

  /// Fitted arena image rect in screen coordinates.
  static Rect arenaImageRect(ArenaViewport viewport) => viewport.arenaRect;

  /// Screen position → normalized design coords (0–1 on art).
  static Offset screenToDesignNorm(ArenaViewport viewport, Offset screenPos) {
    final spec = _spec(viewport);
    final r = viewport.arenaRect;
    return Offset(
      (screenPos.dx - r.left) / (spec.designWidth * viewport.scale),
      (screenPos.dy - r.top) / (spec.designHeight * viewport.scale),
    );
  }

  /// Normalized design coords → screen position.
  static Offset designNormToScreen(ArenaViewport viewport, double nx, double ny) {
    final spec = _spec(viewport);
    final r = viewport.arenaRect;
    return Offset(
      r.left + nx * spec.designWidth * viewport.scale,
      r.top + ny * spec.designHeight * viewport.scale,
    );
  }

  static Rect normRect(
    ArenaViewport viewport,
    double nx,
    double ny,
    double nw,
    double nh,
  ) {
    final spec = _spec(viewport);
    final r = viewport.arenaRect;
    final scale = viewport.scale;
    return Rect.fromLTWH(
      r.left + nx * spec.designWidth * scale,
      r.top + ny * spec.designHeight * scale,
      nw * spec.designWidth * scale,
      nh * spec.designHeight * scale,
    );
  }

  static Rect circularPitRect(
    ArenaViewport viewport,
    double centerX,
    double centerY,
    double diameterPx,
  ) {
    final spec = _spec(viewport);
    final scale = viewport.scale;
    final nw = diameterPx / (spec.designWidth * scale);
    final nh = diameterPx / (spec.designHeight * scale);
    return normRect(
      viewport,
      centerX - nw / 2,
      centerY - nh / 2,
      nw,
      nh,
    );
  }

  static Rect playArea(ArenaViewport viewport) {
    final spec = _spec(viewport);
    return normRect(
      viewport,
      spec.playLeft,
      spec.playTop,
      spec.playWidth,
      spec.playHeight,
    );
  }

  static double _bucketSizeReference(ArenaViewport viewport) =>
      viewport.screenSize.shortestSide;

  static Rect binPitRect(
    ArenaViewport viewport,
    int player,
    ArenaLayoutTune tune,
  ) {
    final t = tune;
    final centerX = player == 1 ? t.leftBinCenterX : t.rightBinCenterX;
    final centerY = player == 1 ? t.leftBinCenterY : t.rightBinCenterY;
    // Screen-relative so buckets stay similar size across 16∶9 vs 4∶3 cover fits.
    final diameterPx = t.binPitDiameter * _bucketSizeReference(viewport);
    return circularPitRect(viewport, centerX, centerY, diameterPx);
  }

  static double bucketAspectFor(int player) =>
      player == 1 ? leftBucketAspect : rightBucketAspect;

  static double bucketAnchorXFor(int player, ArenaLayoutTune tune) =>
      player == 1 ? tune.leftBucketAnchorX : tune.rightBucketAnchorX;

  static Size bucketSizeForPit(Rect pit, int player, ArenaLayoutTune tune) {
    final aspect = bucketAspectFor(player);
    final maxSide = pit.width * tune.bucketFillInPit;
    var h = maxSide;
    var w = h * aspect;
    if (w > maxSide) {
      w = maxSide;
      h = w / aspect;
    }
    return Size(w, h);
  }

  static Rect playerBucketRect({
    required ArenaViewport viewport,
    required int player,
    required ArenaLayoutTune tune,
  }) {
    final pit = binPitRect(viewport, player, tune);
    final size = bucketSizeForPit(pit, player, tune);
    return Rect.fromCenter(
      center: pit.center,
      width: size.width,
      height: size.height,
    );
  }

  static Offset bucketTopLeft(
    Offset pitCenter,
    Size bucketSize,
    int player,
    ArenaLayoutTune tune,
  ) {
    return Offset(
      pitCenter.dx - bucketSize.width * bucketAnchorXFor(player, tune),
      pitCenter.dy - bucketSize.height * tune.bucketAnchorY,
    );
  }

  static Rect bucketCatchRect(
    Rect bucketRect,
    int player,
    ArenaLayoutTune tune,
  ) {
    final openY = bucketRect.top + bucketRect.height * 0.42;
    return Rect.fromCenter(
      center: Offset(
        bucketRect.left + bucketRect.width * bucketAnchorXFor(player, tune),
        openY,
      ),
      width: bucketRect.width * 0.44,
      height: bucketRect.height * 0.14,
    );
  }
}
