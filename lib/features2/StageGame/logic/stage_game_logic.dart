import 'stage_game_models.dart';

class StageGameLogic {
  final StageGameConfig config;

  StageGameLogic({
    this.config = const StageGameConfig(),
  });

  static const Map<SoundOption, StageOptionValues> _soundValues = {
    SoundOption.cheap: StageOptionValues(
      soundDb: 72,
      powerLoad: 250,
      sustainabilityChange: 0,
      audienceChange: 0,
    ),
    SoundOption.eco: StageOptionValues(
      soundDb: 84,
      powerLoad: 180,
      sustainabilityChange: 5,
      audienceChange: 5,
    ),
    SoundOption.pro: StageOptionValues(
      soundDb: 92,
      powerLoad: 400,
      sustainabilityChange: -5,
      audienceChange: 10,
    ),
  };

  static const Map<LightOption, StageOptionValues> _lightValues = {
    LightOption.led: StageOptionValues(
      lightIntensity: 75,
      powerLoad: 120,
      sustainabilityChange: 5,
      audienceChange: 5,
    ),
    LightOption.smart: StageOptionValues(
      lightIntensity: 82,
      powerLoad: 300,
      sustainabilityChange: 0,
      audienceChange: 8,
    ),
    LightOption.halogen: StageOptionValues(
      lightIntensity: 92,
      powerLoad: 600,
      sustainabilityChange: -8,
      audienceChange: 10,
    ),
  };

  static const Map<PowerSourceOption, StageOptionValues> _powerSourceValues = {
    PowerSourceOption.solar: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 1000,
      sustainabilityChange: 15,
      audienceChange: 0,
    ),
    PowerSourceOption.hybrid: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 1800,
      sustainabilityChange: 5,
      audienceChange: 0,
    ),
    PowerSourceOption.generator: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 2400,
      sustainabilityChange: -10,
      audienceChange: 0,
    ),
  };

  static const Map<EffectOption, StageOptionValues> _effectValues = {
    EffectOption.laser: StageOptionValues(
      powerLoad: 150,
      sustainabilityChange: -5,
      audienceChange: 15,
    ),
    EffectOption.drone: StageOptionValues(
      powerLoad: 250,
      sustainabilityChange: -10,
      audienceChange: 20,
    ),
    EffectOption.fireworks: StageOptionValues(
      powerLoad: 500,
      sustainabilityChange: -30,
      audienceChange: 25,
    ),
  };

  StageGameState createInitialState() {
    return StageGameState(
      phase: StageGamePhase.intro,
      selectedSound: null,
      selectedLight: null,
      selectedPowerSource: null,
      selectedEffect: null,
      currentSoundDb: 0,
      currentLightIntensity: 0,
      totalPowerLoad: 0,
      currentPowerCapacity: 0,
      sustainabilityScore: config.startingSustainabilityScore,
      stabilityScore: config.startingStabilityScore,
      audienceSatisfactionScore: config.startingAudienceScore,
      soundFeedback: 'Choose a sound setup',
      lightFeedback: 'Choose a light setup',
      powerFeedback: 'Choose a power source',
      endCrowdReaction: '',
      endComment: '',
      isWin: false,
      isLose: false,
    );
  }

  void start(StageGameState state) {
    state.phase = StageGamePhase.running;
    state.selectedSound = null;
    state.selectedLight = null;
    state.selectedPowerSource = null;
    state.selectedEffect = null;

    state.currentSoundDb = 0;
    state.currentLightIntensity = 0;
    state.totalPowerLoad = 0;
    state.currentPowerCapacity = 0;

    state.sustainabilityScore = config.startingSustainabilityScore;
    state.stabilityScore = config.startingStabilityScore;
    state.audienceSatisfactionScore = config.startingAudienceScore;

    state.soundFeedback = 'Choose a sound setup';
    state.lightFeedback = 'Choose a light setup';
    state.powerFeedback = 'Choose a power source';

    state.endCrowdReaction = '';
    state.endComment = '';

    state.isWin = false;
    state.isLose = false;
  }

  void selectSound(StageGameState state, SoundOption option) {
    state.selectedSound = option;
    _recalculate(state);
  }

  void selectLight(StageGameState state, LightOption option) {
    state.selectedLight = option;
    _recalculate(state);
  }

  void selectPowerSource(StageGameState state, PowerSourceOption option) {
    state.selectedPowerSource = option;
    _recalculate(state);
  }

  void selectEffect(StageGameState state, EffectOption option) {
    state.selectedEffect = option;
    _recalculate(state);
  }

  void finishRound(StageGameState state) {
    _recalculate(state);

    if (_isWinningBuild(state)) {
      state.phase = StageGamePhase.finished;
      state.isWin = true;
      state.isLose = false;
      state.endCrowdReaction = 'Yay!';
      state.endComment = _buildWinComment(state);
      return;
    }

    state.phase = StageGamePhase.finished;
    state.isWin = false;
    state.isLose = true;
    state.endCrowdReaction = 'Boo!';
    state.endComment = _buildLoseComment(state);
  }

  bool canFinish(StageGameState state) {
    return state.hasAllSelections;
  }

  bool _isWinningBuild(StageGameState state) {
    final soundOk = state.currentSoundDb >= config.soundTargetMin &&
        state.currentSoundDb <= config.soundTargetMax;
    final lightOk = state.currentLightIntensity >= config.lightTargetMin &&
        state.currentLightIntensity <= config.lightTargetMax;
    final powerOk = state.totalPowerLoad <= state.currentPowerCapacity;

    return soundOk && lightOk && powerOk;
  }

  void _recalculate(StageGameState state) {
    _calculateMainValues(state);
    _calculateFeedback(state);
    _calculateStabilityScore(state);
    _calculateSustainabilityScore(state);
    _calculateAudienceScore(state);

    if (state.phase == StageGamePhase.finished) {
      if (_isWinningBuild(state)) {
        state.isWin = true;
        state.isLose = false;
      } else {
        state.isWin = false;
        state.isLose = true;
      }
    }
  }

  void _calculateMainValues(StageGameState state) {
    final sound = state.selectedSound != null
        ? _soundValues[state.selectedSound]!
        : null;
    final light = state.selectedLight != null
        ? _lightValues[state.selectedLight]!
        : null;
    final source = state.selectedPowerSource != null
        ? _powerSourceValues[state.selectedPowerSource]!
        : null;
    final effect = state.selectedEffect != null
        ? _effectValues[state.selectedEffect]!
        : null;

    state.currentSoundDb = sound?.soundDb ?? 0;
    state.currentLightIntensity = light?.lightIntensity ?? 0;
    state.currentPowerCapacity = source?.powerCapacity ?? 0;

    state.totalPowerLoad =
        (sound?.powerLoad ?? 0) +
        (light?.powerLoad ?? 0) +
        (effect?.powerLoad ?? 0);
  }

  void _calculateFeedback(StageGameState state) {
    state.soundFeedback = _soundComment(state.currentSoundDb);
    state.lightFeedback = _lightComment(state.currentLightIntensity);
    state.powerFeedback =
        _powerComment(state.totalPowerLoad, state.currentPowerCapacity);
  }

  void _calculateStabilityScore(StageGameState state) {
    var score = config.startingStabilityScore;

    if (state.selectedSound != null) {
      final soundOk = state.currentSoundDb >= config.soundTargetMin &&
          state.currentSoundDb <= config.soundTargetMax;
      if (!soundOk) {
        score -= 20;
      }
    }

    if (state.selectedLight != null) {
      final lightOk = state.currentLightIntensity >= config.lightTargetMin &&
          state.currentLightIntensity <= config.lightTargetMax;
      if (!lightOk) {
        score -= 20;
      }
    }

    if (state.selectedPowerSource != null &&
        state.totalPowerLoad > state.currentPowerCapacity) {
      score -= 60;
    }

    state.stabilityScore = score.clamp(0, 100);
  }

  void _calculateSustainabilityScore(StageGameState state) {
    var score = config.startingSustainabilityScore;

    if (state.selectedSound != null) {
      score += _soundValues[state.selectedSound]!.sustainabilityChange;
    }
    if (state.selectedLight != null) {
      score += _lightValues[state.selectedLight]!.sustainabilityChange;
    }
    if (state.selectedPowerSource != null) {
      score +=
          _powerSourceValues[state.selectedPowerSource]!.sustainabilityChange;
    }
    if (state.selectedEffect != null) {
      score += _effectValues[state.selectedEffect]!.sustainabilityChange;
    }

    state.sustainabilityScore = score.clamp(0, 100);
  }

  void _calculateAudienceScore(StageGameState state) {
    var score = config.startingAudienceScore;

    if (state.selectedSound != null) {
      score += _soundValues[state.selectedSound]!.audienceChange;
    }
    if (state.selectedLight != null) {
      score += _lightValues[state.selectedLight]!.audienceChange;
    }
    if (state.selectedEffect != null) {
      score += _effectValues[state.selectedEffect]!.audienceChange;
    }

    state.audienceSatisfactionScore = score.clamp(0, 100);
  }

  String _soundComment(double soundDb) {
    if (soundDb <= 0) return 'Choose a sound setup';
    if (soundDb < config.soundTargetMin) return 'Sound too low';
    if (soundDb > config.soundTargetMax) return 'Sound too loud';
    return 'Sound good';
  }

  String _lightComment(double lightIntensity) {
    if (lightIntensity <= 0) return 'Choose a light setup';
    if (lightIntensity < config.lightTargetMin) return 'Not enough light';
    if (lightIntensity > config.lightTargetMax) return 'Too bright';
    return 'Light good';
  }

  String _powerComment(int totalLoad, int capacity) {
    if (capacity <= 0) return 'Choose a power source';

    final ratio = totalLoad / capacity;

    if (ratio > 1.0) return 'Overload';
    if (ratio >= 0.8) return 'Almost full';
    return 'Safe';
  }

  String _buildWinComment(StageGameState state) {
    if (state.audienceSatisfactionScore >= 75 &&
        state.sustainabilityScore >= 60) {
      return 'Great show! The crowd is excited and the setup was smart.';
    }

    if (state.audienceSatisfactionScore >= 75) {
      return 'Great show! The festival crowd cheers loudly.';
    }

    if (state.sustainabilityScore >= 60) {
      return 'Good job! The stage worked well and stayed sustainable.';
    }

    return 'Nice work! The stage is stable and the show can start.';
  }

  String _buildLoseComment(StageGameState state) {
    if (state.totalPowerLoad > state.currentPowerCapacity &&
        state.currentPowerCapacity > 0) {
      return 'Stage overloaded. Too much power was used.';
    }

    if (state.currentSoundDb < config.soundTargetMin) {
      return 'Sound too low. The crowd cannot hear enough.';
    }

    if (state.currentSoundDb > config.soundTargetMax) {
      return 'Sound too loud. The setup is out of balance.';
    }

    if (state.currentLightIntensity < config.lightTargetMin) {
      return 'Not enough light. The stage looks too dark.';
    }

    if (state.currentLightIntensity > config.lightTargetMax) {
      return 'Too much light. The setup is stronger than needed.';
    }

    return 'The stage setup is not balanced yet.';
  }

  String stabilityLabel(int score) {
    if (score >= 80) return 'Stable setup';
    if (score >= 50) return 'Partly stable';
    return 'Unstable setup';
  }

  String sustainabilityLabel(int score) {
    if (score >= 60) return 'Good sustainability';
    if (score >= 40) return 'Average sustainability';
    return 'Poor sustainability';
  }

  String audienceLabel(int score) {
    if (score >= 75) return 'Strong show';
    if (score >= 50) return 'Decent show';
    return 'Weak show';
  }
}