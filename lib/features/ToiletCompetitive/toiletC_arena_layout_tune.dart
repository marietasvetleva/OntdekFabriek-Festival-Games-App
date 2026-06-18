/// Runtime-tunable arena layout (design space 1024×571). Values scale with viewport.
class ArenaLayoutTune {
  ArenaLayoutTune({
    required this.leftBinCenterX,
    required this.leftBinCenterY,
    required this.rightBinCenterX,
    required this.rightBinCenterY,
    required this.binPitDiameter,
    required this.bucketFillInPit,
    required this.leftBucketAnchorX,
    required this.rightBucketAnchorX,
    required this.bucketAnchorY,
  });

  double leftBinCenterX;
  double leftBinCenterY;
  double rightBinCenterX;
  double rightBinCenterY;
  double binPitDiameter;
  double bucketFillInPit;
  double leftBucketAnchorX;
  double rightBucketAnchorX;
  double bucketAnchorY;

  factory ArenaLayoutTune.defaults() {
    return ArenaLayoutTune(
      leftBinCenterX: 0.138,
      leftBinCenterY: 0.549,
      rightBinCenterX: 0.867,
      rightBinCenterY: 0.549,
      binPitDiameter: 0.141,
      bucketFillInPit: 0.707,
      leftBucketAnchorX: 0.520,
      rightBucketAnchorX: 0.504,
      bucketAnchorY: 0.850,
    );
  }

  ArenaLayoutTune copyWith({
    double? leftBinCenterX,
    double? leftBinCenterY,
    double? rightBinCenterX,
    double? rightBinCenterY,
    double? binPitDiameter,
    double? bucketFillInPit,
    double? leftBucketAnchorX,
    double? rightBucketAnchorX,
    double? bucketAnchorY,
  }) {
    return ArenaLayoutTune(
      leftBinCenterX: leftBinCenterX ?? this.leftBinCenterX,
      leftBinCenterY: leftBinCenterY ?? this.leftBinCenterY,
      rightBinCenterX: rightBinCenterX ?? this.rightBinCenterX,
      rightBinCenterY: rightBinCenterY ?? this.rightBinCenterY,
      binPitDiameter: binPitDiameter ?? this.binPitDiameter,
      bucketFillInPit: bucketFillInPit ?? this.bucketFillInPit,
      leftBucketAnchorX: leftBucketAnchorX ?? this.leftBucketAnchorX,
      rightBucketAnchorX: rightBucketAnchorX ?? this.rightBucketAnchorX,
      bucketAnchorY: bucketAnchorY ?? this.bucketAnchorY,
    );
  }

  String _f(double v) => v.toStringAsFixed(3);

  /// Paste into [ToiletCompetitiveArenaLayout] constants or [ArenaLayoutTune.defaults].
  String toDartSnippet() {
    return '''
// Arena layout tune (${DateTime.now().toIso8601String()})
leftBinCenterX: ${_f(leftBinCenterX)},
leftBinCenterY: ${_f(leftBinCenterY)},
rightBinCenterX: ${_f(rightBinCenterX)},
rightBinCenterY: ${_f(rightBinCenterY)},
binPitDiameter: ${_f(binPitDiameter)},
bucketFillInPit: ${_f(bucketFillInPit)},
leftBucketAnchorX: ${_f(leftBucketAnchorX)},
rightBucketAnchorX: ${_f(rightBucketAnchorX)},
bucketAnchorY: ${_f(bucketAnchorY)},
''';
  }
}
