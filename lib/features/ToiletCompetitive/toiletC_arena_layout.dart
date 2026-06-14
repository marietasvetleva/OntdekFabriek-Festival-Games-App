import 'dart:ui';

import 'toiletC_arena_layout_tune.dart';
import 'toiletC_arena_viewport.dart';

/// Normalized layout for the festival arena art (design size 1024×571).
class ToiletCompetitiveArenaLayout {
  ToiletCompetitiveArenaLayout._();

  static const double designWidth = 1024;
  static const double designHeight = 571;
  static const String arenaAsset = 'assets/ToiletCompetitive/festival_arena.jpg';
  static const Color edgeFillColor = Color(0xFF7FA86C);

  static const double playLeft = 0.22;
  static const double playTop = 0.29;
  static const double playWidth = 0.56;
  static const double playHeight = 0.43;

  static const double leftBucketAspect = 334 / 279;
  static const double rightBucketAspect = 333 / 278;

  /// Fitted arena image rect in screen coordinates.
  static Rect arenaImageRect(ArenaViewport viewport) => viewport.arenaRect;

  /// Screen position → normalized design coords (0–1 on 1024×571 art).
  static Offset screenToDesignNorm(ArenaViewport viewport, Offset screenPos) {
    final r = viewport.arenaRect;
    return Offset(
      (screenPos.dx - r.left) / (designWidth * viewport.scale),
      (screenPos.dy - r.top) / (designHeight * viewport.scale),
    );
  }

  /// Normalized design coords → screen position.
  static Offset designNormToScreen(ArenaViewport viewport, double nx, double ny) {
    final r = viewport.arenaRect;
    return Offset(
      r.left + nx * designWidth * viewport.scale,
      r.top + ny * designHeight * viewport.scale,
    );
  }

  static Rect normRect(
    ArenaViewport viewport,
    double nx,
    double ny,
    double nw,
    double nh,
  ) {
    final r = viewport.arenaRect;
    final scale = viewport.scale;
    return Rect.fromLTWH(
      r.left + nx * designWidth * scale,
      r.top + ny * designHeight * scale,
      nw * designWidth * scale,
      nh * designHeight * scale,
    );
  }

  static Rect circularPitRect(
    ArenaViewport viewport,
    double centerX,
    double centerY,
    double diameterPx,
  ) {
    final scale = viewport.scale;
    final nw = diameterPx / (designWidth * scale);
    final nh = diameterPx / (designHeight * scale);
    return normRect(
      viewport,
      centerX - nw / 2,
      centerY - nh / 2,
      nw,
      nh,
    );
  }

  static Rect playArea(ArenaViewport viewport) {
    return normRect(viewport, playLeft, playTop, playWidth, playHeight);
  }

  static Rect binPitRect(
    ArenaViewport viewport,
    int player,
    ArenaLayoutTune tune,
  ) {
    final t = tune;
    final centerX = player == 1 ? t.leftBinCenterX : t.rightBinCenterX;
    final centerY = player == 1 ? t.leftBinCenterY : t.rightBinCenterY;
    final diameterPx = t.binPitDiameter * viewport.arenaWidth;
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
