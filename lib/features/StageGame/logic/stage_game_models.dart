enum SoundOption {
  cheap,
  eco,
  pro,
}

enum LightOption {
  led,
  smart,
  halogen,
}

enum PowerSourceOption {
  solar,
  hybrid,
  generator,
}

enum EffectOption {
  laser,
  drone,
  fireworks,
}

enum StageGamePhase {
  intro,
  running,
  finished,
}

enum StageFeedbackLevel {
  low,
  good,
  high,
  safe,
  warning,
  overload,
}

class StageGameConfig {
  final double soundTargetMin;
  final double soundTargetMax;

  final double lightTargetMin;
  final double lightTargetMax;

  final int startingSustainabilityScore;
  final int startingAudienceScore;
  final int startingStabilityScore;

  const StageGameConfig({
    this.soundTargetMin = 80,
    this.soundTargetMax = 90,
    this.lightTargetMin = 70,
    this.lightTargetMax = 85,
    this.startingSustainabilityScore = 50,
    this.startingAudienceScore = 50,
    this.startingStabilityScore = 100,
  });
}

class StageOptionValues {
  final double? soundDb;
  final double? lightIntensity;
  final int powerLoad;
  final int sustainabilityChange;
  final int audienceChange;
  final int? powerCapacity;

  const StageOptionValues({
    this.soundDb,
    this.lightIntensity,
    required this.powerLoad,
    required this.sustainabilityChange,
    required this.audienceChange,
    this.powerCapacity,
  });
}

class StageGameState {
  StageGamePhase phase;

  SoundOption? selectedSound;
  LightOption? selectedLight;
  PowerSourceOption? selectedPowerSource;
  EffectOption? selectedEffect;

  double currentSoundDb;
  double currentLightIntensity;
  int totalPowerLoad;
  int currentPowerCapacity;

  int sustainabilityScore;
  int stabilityScore;
  int audienceSatisfactionScore;

  String soundFeedback;
  String lightFeedback;
  String powerFeedback;
  String endCrowdReaction;
  String endComment;

  bool isWin;
  bool isLose;

  StageGameState({
    required this.phase,
    required this.selectedSound,
    required this.selectedLight,
    required this.selectedPowerSource,
    required this.selectedEffect,
    required this.currentSoundDb,
    required this.currentLightIntensity,
    required this.totalPowerLoad,
    required this.currentPowerCapacity,
    required this.sustainabilityScore,
    required this.stabilityScore,
    required this.audienceSatisfactionScore,
    required this.soundFeedback,
    required this.lightFeedback,
    required this.powerFeedback,
    required this.endCrowdReaction,
    required this.endComment,
    required this.isWin,
    required this.isLose,
  });

  bool get hasAllSelections =>
      selectedSound != null &&
      selectedLight != null &&
      selectedPowerSource != null &&
      selectedEffect != null;

  double get powerUsageRatio {
    if (currentPowerCapacity <= 0) return 0;
    return totalPowerLoad / currentPowerCapacity;
  }
}