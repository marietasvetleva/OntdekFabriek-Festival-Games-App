import 'package:flutter/material.dart';
import '../logic/stage_game_models.dart';

enum StagePanelStatus {
  neutral,
  good,
  caution,
  warning,
}

class StagePanelStatusHelper {
  static StagePanelStatus soundStatus(
    StageGameState state,
    StageGameConfig config,
  ) {
    if (state.currentSoundDb <= 0) return StagePanelStatus.neutral;

    if (state.currentSoundDb < config.soundTargetMin) {
      return StagePanelStatus.caution;
    }

    if (state.currentSoundDb > config.soundTargetMax) {
      return StagePanelStatus.warning;
    }

    return StagePanelStatus.good;
  }

  static StagePanelStatus lightStatus(
    StageGameState state,
    StageGameConfig config,
  ) {
    if (state.currentLightIntensity <= 0) return StagePanelStatus.neutral;

    if (state.currentLightIntensity < config.lightTargetMin) {
      return StagePanelStatus.caution;
    }

    if (state.currentLightIntensity > config.lightTargetMax) {
      return StagePanelStatus.warning;
    }

    return StagePanelStatus.good;
  }

  static StagePanelStatus powerStatus(StageGameState state) {
    if (state.currentPowerCapacity <= 0) return StagePanelStatus.neutral;

    final ratio = state.powerUsageRatio;

    if (ratio > 1.0) return StagePanelStatus.warning;
    if (ratio >= 0.8) return StagePanelStatus.caution;

    return StagePanelStatus.good;
  }

  static Color statusColor(StagePanelStatus status) {
    switch (status) {
      case StagePanelStatus.good:
        return const Color(0xFF79A982);
      case StagePanelStatus.caution:
        return const Color(0xFFE0B650);
      case StagePanelStatus.warning:
        return const Color(0xFFD26455);
      case StagePanelStatus.neutral:
        return const Color(0xFF9C9C91);
    }
  }

  static Color softStatusColor(StagePanelStatus status) {
    switch (status) {
      case StagePanelStatus.good:
        return const Color(0xFFD6EDE0);
      case StagePanelStatus.caution:
        return const Color(0xFFF7E6B3);
      case StagePanelStatus.warning:
        return const Color(0xFFF5B9A8);
      case StagePanelStatus.neutral:
        return const Color(0xFFEAEAE0);
    }
  }

  static String cardBackground(StagePanelStatus status) {
    switch (status) {
      case StagePanelStatus.good:
        return 'assets/StageGameV2-image/right_panel/card_bg_good.png';
      case StagePanelStatus.caution:
        return 'assets/StageGameV2-image/right_panel/card_bg_caution.png';
      case StagePanelStatus.warning:
        return 'assets/StageGameV2-image/right_panel/card_bg_warning.png';
      case StagePanelStatus.neutral:
        return 'assets/StageGameV2-image/right_panel/card_bg_neutral.png';
    }
  }

  static String feedbackMessage(
    StageGameState state,
    StageGameConfig config,
  ) {
    final power = powerStatus(state);
    final sound = soundStatus(state, config);
    final light = lightStatus(state, config);

    if (power == StagePanelStatus.warning) {
      return 'Power overload. Change power source or remove an effect.';
    }

    if (power == StagePanelStatus.caution) {
      return 'Power is getting risky. Keep the setup lighter.';
    }

    if (sound == StagePanelStatus.warning) {
      return 'Sound is too loud. Pick a softer sound setup.';
    }

    if (sound == StagePanelStatus.caution &&
        state.currentSoundDb > 0 &&
        state.currentSoundDb < config.soundTargetMin) {
      return 'Sound is too low. The crowd may not hear enough.';
    }

    if (light == StagePanelStatus.warning) {
      return 'Lighting is too intense. Try a calmer light setup.';
    }

    if (light == StagePanelStatus.caution &&
        state.currentLightIntensity > 0 &&
        state.currentLightIntensity < config.lightTargetMin) {
      return 'Lighting is too low. The stage needs more focus.';
    }

    if (state.hasAllSelections) {
      return 'Nice balance. The stage feels ready for the show.';
    }

    return 'Choose the setup parts and watch the panel update.';
  }
}