import 'dart:ui';

/// Keeps a dragged item inside a [Rect] (e.g. full screen or playfield).
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
  double topMagnetBand = 12,
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

/// Resolves which bucket catches an item, if any (1 = left / P1, 2 = right / P2).
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
