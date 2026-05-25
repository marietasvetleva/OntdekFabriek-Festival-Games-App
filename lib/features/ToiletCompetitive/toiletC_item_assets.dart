import 'toiletC_models.dart';

/// Visual age step for items that have multiple sprites over their lifetime.
enum ItemAgeStage {
  fresh,
  slightlyAged,
  veryAged,
}

/// Asset paths and age-stage resolution for competitive trash items.
class ToiletCompetitiveItemAssets {
  ToiletCompetitiveItemAssets._();

  static const String _base = 'assets/ToiletCompetitive/items';

  /// Normalized lifetime progress at which the sprite switches (0.0–1.0).
  static const double slightlyAgedThreshold = 0.34;
  static const double veryAgedThreshold = 0.67;

  static const Set<CompetitiveItemType> _agingTypes = {
    CompetitiveItemType.bananaPeel,
    CompetitiveItemType.appleCore,
    CompetitiveItemType.leaf,
    CompetitiveItemType.metalCan,
    CompetitiveItemType.juiceBox,
    CompetitiveItemType.waterBottle,
  };

  static bool hasAgingStages(CompetitiveItemType type) =>
      _agingTypes.contains(type);

  static ItemAgeStage stageFromProgress(double progress) {
    final p = progress.clamp(0.0, 1.0);
    if (p < slightlyAgedThreshold) return ItemAgeStage.fresh;
    if (p < veryAgedThreshold) return ItemAgeStage.slightlyAged;
    return ItemAgeStage.veryAged;
  }

  /// Sprite for [type] at a given lifetime progress (hold time excluded by caller).
  static String pathForProgress(CompetitiveItemType type, double progress) {
    if (!hasAgingStages(type)) {
      return pathFor(type, ItemAgeStage.fresh);
    }
    return pathFor(type, stageFromProgress(progress));
  }

  static String pathFor(CompetitiveItemType type, ItemAgeStage stage) {
    switch (type) {
      case CompetitiveItemType.bananaPeel:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/banana/banana_peel.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/banana/slightly_aged_banana.png';
          case ItemAgeStage.veryAged:
            return '$_base/banana/very_aged_banana.png';
        }
      case CompetitiveItemType.appleCore:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/apple/apple_core.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/apple/slightly_aged_apple_core.png';
          case ItemAgeStage.veryAged:
            return '$_base/apple/very_aged_apple_core.png';
        }
      case CompetitiveItemType.leaf:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/leaf/leaf.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/leaf/slightly_aged_leaf.png';
          case ItemAgeStage.veryAged:
            return '$_base/leaf/very_aged_leaf.png';
        }
      case CompetitiveItemType.metalCan:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/metal_can/metal_can.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/metal_can/slightly_aged_metal_can.png';
          case ItemAgeStage.veryAged:
            return '$_base/metal_can/very_aged_metal_can.png';
        }
      case CompetitiveItemType.juiceBox:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/juice_box/juice_box.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/juice_box/slightly_aged_juice_box.png';
          case ItemAgeStage.veryAged:
            return '$_base/juice_box/very_aged_juice_box.png';
        }
      case CompetitiveItemType.waterBottle:
        switch (stage) {
          case ItemAgeStage.fresh:
            return '$_base/water_bottle/water_bottle.png';
          case ItemAgeStage.slightlyAged:
            return '$_base/water_bottle/slightly_aged_water_bottle.png';
          case ItemAgeStage.veryAged:
            return '$_base/water_bottle/very_aged_water_bottle.png';
        }
      case CompetitiveItemType.cigaretteBud:
        return '$_base/cigarette_bud.png';
      case CompetitiveItemType.gum:
        return '$_base/gum.png';
    }
  }
}
