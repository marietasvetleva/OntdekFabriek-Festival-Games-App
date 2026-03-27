import 'dart:ui';

/// Returns the next vertical position from a simple falling motion.
double nextFallY({
  required double y,
  required double speed,
  required double dt,
}) {
  return y + (speed * dt);
}

/// Returns a shrunk size over time, clamped to avoid negative values.
double nextSize({
  required double size,
  required double shrinkPerSecond,
  required double dt,
  required double minSize,
}) {
  final next = size - (shrinkPerSecond * dt);
  return next < minSize ? minSize : next;
}

/// Despawns tiny or floor-reached items.
bool shouldDespawn({
  required double y,
  required double size,
  required double floorY,
  required double minVisibleSize,
}) {
  final reachedFloor = y + size >= floorY;
  final tooSmall = size <= minVisibleSize;
  return reachedFloor || tooSmall;
}

/// Keeps a dragged item in the playfield bounds.
Offset clampDragPosition({
  required Offset desiredTopLeft,
  required double itemSize,
  required Rect playArea,
}) {
  final clampedX =
      desiredTopLeft.dx.clamp(playArea.left, playArea.right - itemSize);
  final clampedY =
      desiredTopLeft.dy.clamp(playArea.top, playArea.bottom - itemSize);
  return Offset(clampedX, clampedY);
}

/// Forgiving bucket collision: wider hitbox + upper magnetic band.
bool isItemCaughtByBucket({
  required Rect itemRect,
  required Rect bucketRect,
  double horizontalPadding = 20,
  double topMagnetBand = 24,
  double verticalTolerance = 12,
}) {
  final expandedBucket = Rect.fromLTRB(
    bucketRect.left - horizontalPadding,
    bucketRect.top - topMagnetBand,
    bucketRect.right + horizontalPadding,
    bucketRect.bottom + verticalTolerance,
  );

  return expandedBucket.overlaps(itemRect);
}

/// Resolves which bucket catches an item, if any.
int? resolveBucketOwner({
  required Rect itemRect,
  required Rect playerOneBucket,
  required Rect playerTwoBucket,
}) {
  if (isItemCaughtByBucket(itemRect: itemRect, bucketRect: playerOneBucket)) {
    return 1;
  }
  if (isItemCaughtByBucket(itemRect: itemRect, bucketRect: playerTwoBucket)) {
    return 2;
  }
  return null;
}
