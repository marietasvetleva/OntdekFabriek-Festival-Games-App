import 'stage_game_models.dart';

class StageGameLogic {
  final StageGameConfig config;

  StageGameLogic({
    this.config = const StageGameConfig(),
  });

  static const Map<SoundOption, StageOptionValues> _soundValues = {
    SoundOption.cheap: StageOptionValues(
      soundDb: 58,
      powerLoad: 220,
      sustainabilityChange: 2,
      audienceChange: -4,
    ),
    SoundOption.eco: StageOptionValues(
      soundDb: 82,
      powerLoad: 220,
      sustainabilityChange: 6,
      audienceChange: 4,
    ),
    SoundOption.pro: StageOptionValues(
      soundDb: 98,
      powerLoad: 480,
      sustainabilityChange: -7,
      audienceChange: 10,
    ),
  };

  static const Map<LightOption, StageOptionValues> _lightValues = {
    LightOption.led: StageOptionValues(
      lightIntensity: 75,
      powerLoad: 120,
      sustainabilityChange: 8,
      audienceChange: 3,
    ),
    LightOption.smart: StageOptionValues(
      lightIntensity: 82,
      powerLoad: 300,
      sustainabilityChange: 1,
      audienceChange: 8,
    ),
    LightOption.halogen: StageOptionValues(
      lightIntensity: 92,
      powerLoad: 600,
      sustainabilityChange: -12,
      audienceChange: 7,
    ),
  };

  static const Map<PowerSourceOption, StageOptionValues> _powerSourceValues = {
    PowerSourceOption.solar: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 1000,
      sustainabilityChange: 18,
      audienceChange: 0,
    ),
    PowerSourceOption.hybrid: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 1800,
      sustainabilityChange: 7,
      audienceChange: 0,
    ),
    PowerSourceOption.generator: StageOptionValues(
      powerLoad: 0,
      powerCapacity: 2400,
      sustainabilityChange: -15,
      audienceChange: 0,
    ),
  };

  static const Map<EffectOption, StageOptionValues> _effectValues = {
    EffectOption.laser: StageOptionValues(
      powerLoad: 150,
      sustainabilityChange: -4,
      audienceChange: 10,
    ),
    EffectOption.drone: StageOptionValues(
      powerLoad: 250,
      sustainabilityChange: -9,
      audienceChange: 15,
    ),
    EffectOption.fireworks: StageOptionValues(
      powerLoad: 500,
      sustainabilityChange: -28,
      audienceChange: 22,
    ),
  };

  StageGameState createInitialState() {
    return StageGameState(
      phase: StageGamePhase.intro,
      selectedSound: null,
      selectedLight: null,
      selectedPowerSource: null,
      selectedEffect: null,
      soundControlLevel: StageControlLevel.medium,
      lightControlLevel: StageControlLevel.low,
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

    state.soundControlLevel = StageControlLevel.medium;
    state.lightControlLevel = StageControlLevel.low;

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

  void selectSoundLevel(StageGameState state, StageControlLevel level) {
    state.soundControlLevel = level;
    _recalculate(state);
  }

  void selectLightLevel(StageGameState state, StageControlLevel level) {
    state.lightControlLevel = level;
    _recalculate(state);
  }

  bool canFinish(StageGameState state) {
    return state.hasAllSelections;
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

  void _recalculate(StageGameState state) {
    _calculateMainValues(state);
    _calculateFeedback(state);
    _calculateScores(state);

    if (state.phase == StageGamePhase.finished) {
      state.isWin = _isWinningBuild(state);
      state.isLose = !state.isWin;
    }
  }

  bool _isWinningBuild(StageGameState state) {
    if (!state.hasAllSelections) return false;
    if (_hasPowerOverload(state)) return false;

    if (_hasCheapSpeakerDistortion(state)) return false;
    if (_hasDangerousHalogenHeat(state)) return false;

    /*
      IMPORTANT:
      Win must match the final scores.
      This avoids situations like:
      Sustainability 20, Stability 82, Audience 79, but still Boo.
    */
    final stableEnough = state.stabilityScore >= 60;
    final audienceEnough = state.audienceSatisfactionScore >= 60;
    final sustainableEnough = state.sustainabilityScore >= 45;

    final averageScore = (
      state.stabilityScore +
      state.audienceSatisfactionScore +
      state.sustainabilityScore
    ) / 3;

    return stableEnough && audienceEnough && sustainableEnough && averageScore >= 62;
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

    state.currentSoundDb = _calculateSoundDb(
      state.selectedSound,
      state.soundControlLevel,
    );

    state.currentLightIntensity = _calculateLightIntensity(
      state.selectedLight,
      state.lightControlLevel,
    );

    state.currentPowerCapacity = source?.powerCapacity ?? 0;

    final soundPower = _calculateSoundPower(
      state.selectedSound,
      state.soundControlLevel,
      sound?.powerLoad ?? 0,
    );

    final lightPower = _calculateLightPower(
      state.selectedLight,
      state.lightControlLevel,
      light?.powerLoad ?? 0,
    );

    state.totalPowerLoad = soundPower + lightPower + (effect?.powerLoad ?? 0);
  }

  double _calculateSoundDb(
    SoundOption? option,
    StageControlLevel level,
  ) {
    if (option == null) return 0;

    switch (option) {
      case SoundOption.cheap:
        switch (level) {
          case StageControlLevel.low:
            return 35;
          case StageControlLevel.medium:
            return 58;
          case StageControlLevel.high:
            return 75;
        }

      case SoundOption.eco:
        switch (level) {
          case StageControlLevel.low:
            return 55;
          case StageControlLevel.medium:
            return 82;
          case StageControlLevel.high:
            return 98;
        }

      case SoundOption.pro:
        switch (level) {
          case StageControlLevel.low:
            return 82;
          case StageControlLevel.medium:
            return 98;
          case StageControlLevel.high:
            return 110;
        }
    }
  }

  double _calculateLightIntensity(
    LightOption? option,
    StageControlLevel level,
  ) {
    if (option == null) return 0;

    switch (option) {
      case LightOption.led:
        switch (level) {
          case StageControlLevel.low:
            return 55;
          case StageControlLevel.medium:
            return 75;
          case StageControlLevel.high:
            return 82;
        }

      case LightOption.smart:
        switch (level) {
          case StageControlLevel.low:
            return 60;
          case StageControlLevel.medium:
            return 82;
          case StageControlLevel.high:
            return 85;
        }

      case LightOption.halogen:
        switch (level) {
          case StageControlLevel.low:
            return 65;
          case StageControlLevel.medium:
            return 82;
          case StageControlLevel.high:
            return 94;
        }
    }
  }

  int _calculateSoundPower(
    SoundOption? option,
    StageControlLevel level,
    int basePower,
  ) {
    if (option == null) return 0;

    final multiplier = switch (level) {
      StageControlLevel.low => 0.65,
      StageControlLevel.medium => 1.00,
      StageControlLevel.high => option == SoundOption.pro ? 1.60 : 1.35,
    };

    return (basePower * multiplier).round();
  }

  int _calculateLightPower(
    LightOption? option,
    StageControlLevel level,
    int basePower,
  ) {
    if (option == null) return 0;

    final multiplier = switch (level) {
      StageControlLevel.low => 0.70,
      StageControlLevel.medium => 1.00,
      StageControlLevel.high => option == LightOption.halogen ? 1.55 : 1.30,
    };

    return (basePower * multiplier).round();
  }

  void _calculateFeedback(StageGameState state) {
    state.soundFeedback = _soundComment(
      state.selectedSound,
      state.soundControlLevel,
    );

    state.lightFeedback = _lightComment(
      state.selectedLight,
      state.lightControlLevel,
    );

    state.powerFeedback = _powerComment(
      state.totalPowerLoad,
      state.currentPowerCapacity,
    );
  }

  void _calculateScores(StageGameState state) {
    /*
      NEW LOGIC:
      Scores now use:
      - a base score
      - bonuses / penalties
      - score caps
      - fail-condition balancing

      This makes losing setups show clearly lower scores.
    */
    var stability = 50;
    var sustainability = 50;
    var audience = 50;

    var stabilityCap = 88;
    var sustainabilityCap = 88;
    var audienceCap = 88;

    // ---------- POWER SOURCE ----------
    if (state.selectedPowerSource == null) {
      stability -= 18;
      sustainability -= 12;
      audience -= 8;
    } else {
      switch (state.selectedPowerSource!) {
        case PowerSourceOption.solar:
          stability += 0;
          sustainability += 22;
          audience -= 3;

          // Solar is sustainable, but less strong for huge show setups.
          audienceCap = _minCap(audienceCap, 82);
          break;

        case PowerSourceOption.hybrid:
          stability += 9;
          sustainability += 9;
          audience += 1;
          break;

        case PowerSourceOption.generator:
          stability += 10;
          sustainability -= 20;
          audience += 2;

          // Generator can be stable, but cannot have high sustainability.
          sustainabilityCap = _minCap(sustainabilityCap, 55);
          break;
      }
    }

    // ---------- POWER LOAD ----------
    if (state.currentPowerCapacity > 0) {
      final ratio = state.totalPowerLoad / state.currentPowerCapacity;

      if (ratio > 1.0) {
        stability -= 80;
        sustainability -= 30;
        audience -= 45;

        stabilityCap = _minCap(stabilityCap, 25);
        sustainabilityCap = _minCap(sustainabilityCap, 35);
        audienceCap = _minCap(audienceCap, 35);
      } else if (ratio >= 0.92) {
        stability -= 28;
        sustainability -= 12;
        audience -= 8;

        stabilityCap = _minCap(stabilityCap, 60);
        audienceCap = _minCap(audienceCap, 75);
      } else if (ratio >= 0.80) {
        stability -= 15;
        sustainability -= 7;
        audience -= 3;

        stabilityCap = _minCap(stabilityCap, 72);
      } else if (ratio <= 0.40) {
        // Underused power is safe and sustainable, but show may feel less impressive.
        stability += 3;
        sustainability += 5;
        audience -= 3;
      } else {
        stability += 5;
      }
    }

    // ---------- SOUND ----------
    if (state.selectedSound == null) {
      stability -= 12;
      audience -= 18;
    } else {
      switch (state.selectedSound!) {
        case SoundOption.cheap:
          sustainability += 3;

          switch (state.soundControlLevel) {
            case StageControlLevel.low:
              stability -= 3;
              audience -= 22;

              audienceCap = _minCap(audienceCap, 55);
              break;

            case StageControlLevel.medium:
              stability += 1;
              audience -= 8;

              audienceCap = _minCap(audienceCap, 68);
              stabilityCap = _minCap(stabilityCap, 78);
              break;

            case StageControlLevel.high:
              stability -= 38;
              audience -= 34;
              sustainability -= 4;

              stabilityCap = _minCap(stabilityCap, 42);
              audienceCap = _minCap(audienceCap, 40);
              break;
          }
          break;

        case SoundOption.eco:
          sustainability += 8;

          switch (state.soundControlLevel) {
            case StageControlLevel.low:
              stability += 5;
              audience -= 6;

              audienceCap = _minCap(audienceCap, 76);
              break;

            case StageControlLevel.medium:
              stability += 10;
              audience += 9;
              break;

            case StageControlLevel.high:
              stability += 2;
              audience += 8;
              sustainability -= 3;

              stabilityCap = _minCap(stabilityCap, 84);
              break;
          }
          break;

        case SoundOption.pro:
          sustainability -= 8;

          switch (state.soundControlLevel) {
            case StageControlLevel.low:
              stability += 7;
              audience += 6;
              break;

            case StageControlLevel.medium:
              stability += 8;
              audience += 13;
              sustainability -= 2;
              break;

            case StageControlLevel.high:
              stability -= 12;
              audience += 14;
              sustainability -= 10;

              stabilityCap = _minCap(stabilityCap, 72);
              sustainabilityCap = _minCap(sustainabilityCap, 66);
              break;
          }
          break;
      }
    }

    // ---------- LIGHT ----------
    if (state.selectedLight == null) {
      stability -= 12;
      audience -= 16;
    } else {
      switch (state.selectedLight!) {
        case LightOption.led:
          sustainability += 12;

          switch (state.lightControlLevel) {
            case StageControlLevel.low:
              stability += 5;
              audience -= 5;

              audienceCap = _minCap(audienceCap, 78);
              break;

            case StageControlLevel.medium:
              stability += 9;
              audience += 7;
              break;

            case StageControlLevel.high:
              stability += 5;
              audience += 8;
              sustainability -= 2;
              break;
          }
          break;

        case LightOption.smart:
          sustainability += 2;

          switch (state.lightControlLevel) {
            case StageControlLevel.low:
              stability += 3;
              audience -= 3;
              break;

            case StageControlLevel.medium:
              stability += 7;
              audience += 10;
              break;

            case StageControlLevel.high:
              stability += 1;
              audience += 12;
              sustainability -= 5;

              stabilityCap = _minCap(stabilityCap, 83);
              break;
          }
          break;

        case LightOption.halogen:
          sustainability -= 15;

          switch (state.lightControlLevel) {
            case StageControlLevel.low:
              stability -= 1;
              audience += 2;

              sustainabilityCap = _minCap(sustainabilityCap, 70);
              break;

            case StageControlLevel.medium:
              stability -= 8;
              audience += 6;
              sustainability -= 7;

              stabilityCap = _minCap(stabilityCap, 78);
              sustainabilityCap = _minCap(sustainabilityCap, 58);
              break;

            case StageControlLevel.high:
              stability -= 34;
              audience -= 8;
              sustainability -= 16;

              stabilityCap = _minCap(stabilityCap, 45);
              sustainabilityCap = _minCap(sustainabilityCap, 38);
              audienceCap = _minCap(audienceCap, 68);
              break;
          }
          break;
      }
    }

    // ---------- EFFECTS ----------
    if (state.selectedEffect == null) {
      audience -= 8;
    } else {
      switch (state.selectedEffect!) {
        case EffectOption.laser:
          stability += 2;
          audience += 9;
          sustainability -= 4;
          break;

        case EffectOption.drone:
          stability -= 4;
          audience += 13;
          sustainability -= 9;

          stabilityCap = _minCap(stabilityCap, 84);
          break;

        case EffectOption.fireworks:
          stability -= 15;
          audience += 18;
          sustainability -= 30;

          stabilityCap = _minCap(stabilityCap, 70);
          sustainabilityCap = _minCap(sustainabilityCap, 42);
          break;
      }
    }

    // ---------- COMBO LOGIC ----------
    final cleanBalancedSetup =
        state.selectedPowerSource == PowerSourceOption.hybrid &&
        state.selectedSound == SoundOption.eco &&
        state.soundControlLevel == StageControlLevel.medium &&
        state.selectedLight == LightOption.smart &&
        state.lightControlLevel == StageControlLevel.medium &&
        state.selectedEffect == EffectOption.drone;

    if (cleanBalancedSetup) {
      stability += 4;
      audience += 5;
      sustainability += 1;
    }

    final ecoSetup =
        state.selectedPowerSource == PowerSourceOption.solar &&
        state.selectedSound == SoundOption.eco &&
        state.selectedLight == LightOption.led &&
        state.selectedEffect == EffectOption.laser;

    if (ecoSetup) {
      stability += 3;
      sustainability += 5;
      audience += 1;
    }

    final riskyShowSetup =
        state.selectedPowerSource == PowerSourceOption.generator &&
        state.selectedSound == SoundOption.pro &&
        state.soundControlLevel == StageControlLevel.high &&
        state.selectedEffect == EffectOption.fireworks;

    if (riskyShowSetup) {
      audience += 3;
      stability -= 6;
      sustainability -= 8;

      stabilityCap = _minCap(stabilityCap, 68);
      sustainabilityCap = _minCap(sustainabilityCap, 35);
    }

    // ---------- RESULT CONSISTENCY CAPS ----------
    /*
      These caps make sure the final scores match win/lose feeling.

      Example:
      If sustainability is terrible, stability/audience should not stay near 80/90,
      because the final result is still bad.
    */
    if (sustainability < 35) {
      stabilityCap = _minCap(stabilityCap, 68);
      audienceCap = _minCap(audienceCap, 68);
    }

    if (sustainability < 25) {
      stabilityCap = _minCap(stabilityCap, 58);
      audienceCap = _minCap(audienceCap, 58);
    }

    if (stability < 45) {
      audienceCap = _minCap(audienceCap, 60);
    }

    if (audience < 45) {
      stabilityCap = _minCap(stabilityCap, 70);
    }

    if (_hasCheapSpeakerDistortion(state)) {
      stabilityCap = _minCap(stabilityCap, 42);
      audienceCap = _minCap(audienceCap, 40);
    }

    if (_hasDangerousHalogenHeat(state)) {
      stabilityCap = _minCap(stabilityCap, 45);
      audienceCap = _minCap(audienceCap, 62);
      sustainabilityCap = _minCap(sustainabilityCap, 38);
    }

    if (_hasPowerOverload(state)) {
      stabilityCap = _minCap(stabilityCap, 25);
      audienceCap = _minCap(audienceCap, 35);
      sustainabilityCap = _minCap(sustainabilityCap, 35);
    }

    stability = _applyCap(stability, stabilityCap);
    sustainability = _applyCap(sustainability, sustainabilityCap);
    audience = _applyCap(audience, audienceCap);

    state.stabilityScore = _clampScore(stability);
    state.sustainabilityScore = _clampScore(sustainability);
    state.audienceSatisfactionScore = _clampScore(audience);
  }

  int _minCap(int currentCap, int newCap) {
    return currentCap < newCap ? currentCap : newCap;
  }

  int _applyCap(int score, int cap) {
    if (score > cap) return cap;
    return score;
  }

  int _clampScore(int score) {
    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  bool _hasPowerOverload(StageGameState state) {
    return state.currentPowerCapacity > 0 &&
        state.totalPowerLoad > state.currentPowerCapacity;
  }

  bool _hasCheapSpeakerDistortion(StageGameState state) {
    return state.selectedSound == SoundOption.cheap &&
        state.soundControlLevel == StageControlLevel.high;
  }

  bool _hasDangerousHalogenHeat(StageGameState state) {
    return state.selectedLight == LightOption.halogen &&
        state.lightControlLevel == StageControlLevel.high;
  }

  String _soundComment(
    SoundOption? option,
    StageControlLevel level,
  ) {
    if (option == null) return 'Choose a sound setup';

    switch (option) {
      case SoundOption.cheap:
        switch (level) {
          case StageControlLevel.low:
            return 'Cheap speaker: the crowd can barely hear it';
          case StageControlLevel.medium:
            return 'Cheap speaker: weak sound, but still usable';
          case StageControlLevel.high:
            return 'Cheap speaker: sound is distorted and breaking';
        }

      case SoundOption.eco:
        switch (level) {
          case StageControlLevel.low:
            return 'Eco speaker: soft but clean';
          case StageControlLevel.medium:
            return 'Eco speaker: clean sound and good balance';
          case StageControlLevel.high:
            return 'Eco speaker: loud and still stable';
        }

      case SoundOption.pro:
        switch (level) {
          case StageControlLevel.low:
            return 'Pro speaker: clear sound, good for the crowd';
          case StageControlLevel.medium:
            return 'Pro speaker: powerful festival sound';
          case StageControlLevel.high:
            return 'Pro speaker: huge sound, very loud';
        }
    }
  }

  String _lightComment(
    LightOption? option,
    StageControlLevel level,
  ) {
    if (option == null) return 'Choose a light setup';

    switch (option) {
      case LightOption.led:
        switch (level) {
          case StageControlLevel.low:
            return 'LED: calm and energy friendly';
          case StageControlLevel.medium:
            return 'LED: nice light and good balance';
          case StageControlLevel.high:
            return 'LED: bright and still safe';
        }

      case LightOption.smart:
        switch (level) {
          case StageControlLevel.low:
            return 'Smart light: subtle, but a bit boring';
          case StageControlLevel.medium:
            return 'Smart light: nice vibe';
          case StageControlLevel.high:
            return 'Smart light: strong show effect';
        }

      case LightOption.halogen:
        switch (level) {
          case StageControlLevel.low:
            return 'Halogen: warm light, but less efficient';
          case StageControlLevel.medium:
            return 'Halogen: bright but uses more power';
          case StageControlLevel.high:
            return 'Halogen: too hot and risky';
        }
    }
  }

  String _powerComment(int totalLoad, int capacity) {
    if (capacity <= 0) return 'Choose a power source';

    final ratio = totalLoad / capacity;

    if (ratio > 1.0) return 'Power overload';
    if (ratio >= 0.92) return 'Power is getting risky';
    if (ratio >= 0.80) return 'Almost full';
    if (ratio <= 0.40) return 'Power stable, but maybe underused';
    return 'Power stable';
  }

  String _buildWinComment(StageGameState state) {
    if (state.stabilityScore >= 82 &&
        state.audienceSatisfactionScore >= 82 &&
        state.sustainabilityScore >= 70) {
      return 'Excellent show! The setup was stable, fun and sustainable.';
    }

    if (state.audienceSatisfactionScore >= 75 &&
        state.sustainabilityScore < 55) {
      return 'The crowd enjoyed the show, but the setup could be more sustainable.';
    }

    if (state.sustainabilityScore >= 70 &&
        state.audienceSatisfactionScore < 75) {
      return 'Good sustainable setup! The show worked, but it could be more exciting.';
    }

    if (state.stabilityScore >= 75) {
      return 'Nice work! The stage stayed stable and the show can start.';
    }

    return 'Good job! The stage setup works, but it is not perfect yet.';
  }

  String _buildLoseComment(StageGameState state) {
    if (_hasPowerOverload(state)) {
      return 'Stage overloaded. Too much power was used.';
    }

    if (_hasCheapSpeakerDistortion(state)) {
      return 'The cheap speaker distorted and the crowd did not enjoy the sound.';
    }

    if (_hasDangerousHalogenHeat(state)) {
      return 'The halogen lights became too hot and risky.';
    }

    if (state.sustainabilityScore < 45) {
      return 'The setup was too wasteful and not sustainable enough.';
    }

    if (state.stabilityScore < 60) {
      return 'The stage setup was not stable enough for the show.';
    }

    if (state.audienceSatisfactionScore < 60) {
      return 'The crowd was not satisfied with the show setup.';
    }

    return 'The stage setup is not balanced yet.';
  }

  String stabilityLabel(int score) {
    if (score >= 82) return 'Very stable setup';
    if (score >= 70) return 'Stable setup';
    if (score >= 55) return 'Risky setup';
    return 'Unstable setup';
  }

  String sustainabilityLabel(int score) {
    if (score >= 75) return 'Great sustainability';
    if (score >= 60) return 'Good sustainability';
    if (score >= 45) return 'Average sustainability';
    return 'Poor sustainability';
  }

  String audienceLabel(int score) {
    if (score >= 82) return 'Amazing show';
    if (score >= 70) return 'Strong show';
    if (score >= 55) return 'Decent show';
    return 'Weak show';
  }
}