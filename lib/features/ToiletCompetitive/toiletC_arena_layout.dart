import 'dart:ui';

import 'toiletC_arena_layout_tune.dart';

/// Normalized layout for the festival arena art (design size 1024×571).
/// Uses width-fit scaling for landscape desktop/iPad.
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

  static double _scaleFor(Size screen) => screen.width / designWidth;

  static double _topOffset(Size screen) {
    final scaledH = designHeight * _scaleFor(screen);
    return (screen.height - scaledH) / 2;
  }

  /// Fitted arena image rect (width-fit).
  static Rect arenaImageRect(Size screen) {
    final scale = _scaleFor(screen);
    final w = screen.width;
    final h = designHeight * scale;
    final top = (screen.height - h) / 2;
    return Rect.fromLTWH(0, top, w, h);
  }

  /// Screen position → normalized design coords (0–1 on 1024×571 art).
  static Offset screenToDesignNorm(Size screen, Offset screenPos) {
    final scale = _scaleFor(screen);
    return Offset(
      screenPos.dx / (designWidth * scale),
      (screenPos.dy - _topOffset(screen)) / (designHeight * scale),
    );
  }

  /// Normalized design coords → screen position.
  static Offset designNormToScreen(Size screen, double nx, double ny) {
    final scale = _scaleFor(screen);
    return Offset(
      nx * designWidth * scale,
      _topOffset(screen) + ny * designHeight * scale,
    );
  }

  static Rect normRect(
    Size screen,
    double nx,
    double ny,
    double nw,
    double nh,
  ) {
    final scale = _scaleFor(screen);
    final top = _topOffset(screen);
    return Rect.fromLTWH(
      nx * designWidth * scale,
      top + ny * designHeight * scale,
      nw * designWidth * scale,
      nh * designHeight * scale,
    );
  }

  static Rect circularPitRect(
    Size screen,
    double centerX,
    double centerY,
    double diameterPx,
  ) {
    final scale = _scaleFor(screen);
    final nw = diameterPx / (designWidth * scale);
    final nh = diameterPx / (designHeight * scale);
    return normRect(
      screen,
      centerX - nw / 2,
      centerY - nh / 2,
      nw,
      nh,
    );
  }

  static Rect playArea(Size screen) {
    return normRect(screen, playLeft, playTop, playWidth, playHeight);
  }

  static Rect binPitRect(Size screen, int player, ArenaLayoutTune tune) {
    final t = tune;
    final centerX = player == 1 ? t.leftBinCenterX : t.rightBinCenterX;
    final centerY = player == 1 ? t.leftBinCenterY : t.rightBinCenterY;
    final diameterPx = t.binPitDiameter * screen.width;
    return circularPitRect(screen, centerX, centerY, diameterPx);
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
    required Size screen,
    required int player,
    required ArenaLayoutTune tune,
  }) {
    final pit = binPitRect(screen, player, tune);
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
