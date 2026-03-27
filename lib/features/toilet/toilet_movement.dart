import 'toilet_models.dart';

/// Clamps bucket x-position so the catcher stays inside play bounds.
double clampBucketX({
  required double bucketX,
  required double screenWidth,
  required double bucketWidth,
}) {
  return bucketX.clamp(0.0, screenWidth - bucketWidth - 120);
}

/// Advances all falling items vertically using their speed and delta time.
void moveFallingItems({
  required List<ToiletFallingItem> items,
  required double dt,
}) {
  for (final item in items) {
    item.y += item.speed * dt;
  }
}

/// Returns true when a falling item overlaps the bucket hit area.
bool isBucketCollision({
  required ToiletFallingItem item,
  required double bucketX,
  required double bucketY,
  required double bucketWidth,
}) {
  final bucketLeft = bucketX;
  final bucketRight = bucketX + bucketWidth;
  final itemLeft = item.x;
  final itemRight = item.x + item.size;
  final itemBottom = item.y + item.size;

  final verticalOverlap = itemBottom >= bucketY + 10;
  final horizontalOverlap =
      !(itemRight < bucketLeft || itemLeft > bucketRight);
  return verticalOverlap && horizontalOverlap;
}
