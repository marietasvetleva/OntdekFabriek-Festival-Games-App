// IMPORTANT:
// StageGamePage full file.
// Current fixes:
// 1. Sound system stays as fixed before.
// 2. Light meter does not move before choosing a light source.
// 3. When choosing LED / Smart / Halogen, light starts at low / 0 bar position.
// 4. When changing light option, the light bar resets back to 0.
// 5. Sound, Light and Effects cannot be chosen before Power Source is chosen.
// 6. Sound audio does not start automatically.
// 7. Cheap speaker high stops clean music and plays distortion.
// 8. FinalScreen handles cheer/boo sound.
// 9. Speaker background music now changes based on Cheap / Eco / Pro speaker.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/led_service.dart';
import '../services/stage_audio_service.dart';
import '../logic/stage_game_logic.dart';
import '../logic/stage_game_models.dart';
import '../widgets/stage_right_panel.dart';
import 'final_screen.dart';

class StageGamePage extends StatefulWidget {
  const StageGamePage({super.key});

  @override
  State<StageGamePage> createState() => _StageGamePageState();
}

class _StageGamePageState extends State<StageGamePage>
    with SingleTickerProviderStateMixin {
  final StageGameLogic _logic = StageGameLogic();
  final StageAudioService _audioService = StageAudioService();

  // NEW:
  // This player is only for the speaker background music.
  // Cheap / Eco / Pro each use their own audio file.
  final AudioPlayer _speakerBackgroundPlayer = AudioPlayer();

  late StageGameState _state;

  static const String _assetBase = 'assets/StageGameV2-image';

  late final AnimationController _stageFxController;

  bool _isEndingRound = false;

  bool _audioReady = false;
  bool _backgroundMusicStarted = false;
  bool _isDistortionPlaying = false;

  // NEW:
  // Used to know if we need to switch the speaker background audio.
  String? _currentSpeakerBackgroundAsset;

  double _liveSoundSliderProgress = 0.5;
  double _liveLightSliderProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _state = _logic.createInitialState();
    _logic.start(_state);

    _liveSoundSliderProgress = _progressFromLevel(_state.soundControlLevel);
    _liveLightSliderProgress = _state.selectedLight == null
        ? 0.0
        : _progressFromLevel(_state.lightControlLevel);

    _stageFxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();

    Future.wait([
      _audioService.init(),
      _speakerBackgroundPlayer.setReleaseMode(ReleaseMode.loop),
    ]).then((_) {
      if (!mounted) return;
      _audioReady = true;
    });
  }

  @override
  void dispose() {
    _stageFxController.dispose();
    _speakerBackgroundPlayer.dispose();
    _audioService.dispose();
    super.dispose();
  }

  double _progressFromLevel(StageControlLevel level) {
    switch (level) {
      case StageControlLevel.low:
        return 0.0;
      case StageControlLevel.medium:
        return 0.5;
      case StageControlLevel.high:
        return 1.0;
    }
  }

  bool get _hasPowerSource {
    return _state.selectedPowerSource != null;
  }

  void _handleGameChange() {
    _liveSoundSliderProgress = _progressFromLevel(_state.soundControlLevel);

    _liveLightSliderProgress = _state.selectedLight == null
        ? 0.0
        : _progressFromLevel(_state.lightControlLevel);

    _playPrototypeAudioFeedback();
    _checkForInstantPowerFailure();
  }

  void _handleLiveSoundSlider(double progress) {
    _liveSoundSliderProgress = progress.clamp(0.0, 1.0);

    if (!_audioReady || _isEndingRound) return;

    if (_state.selectedSound == null) {
      _stopBackgroundMusicFlagged();
      _stopDistortionIfNeeded();
      return;
    }

    final isCheapMax = _state.selectedSound == SoundOption.cheap &&
        _state.soundControlLevel == StageControlLevel.high;

    if (isCheapMax) {
      _stopBackgroundMusicFlagged();
      _startDistortionIfNeeded();
      return;
    }

    _stopDistortionIfNeeded();
    _startOrUpdateMusicForSelectedSpeaker();
  }

  void _handleLiveLightSlider(double progress) {
    if (_state.selectedLight == null || _isEndingRound) {
      setState(() {
        _liveLightSliderProgress = 0.0;
      });
      return;
    }

    setState(() {
      _liveLightSliderProgress = progress.clamp(0.0, 1.0);
    });
  }

  // NEW:
  // This connects the selected speaker option to the right background audio.
  String? _speakerBackgroundAsset() {
    switch (_state.selectedSound) {
      case SoundOption.cheap:
        return 'StageGameV2-audio/festival_background_cheap.mp3';

      case SoundOption.eco:
        return 'StageGameV2-audio/festival_eco.mp3';

      case SoundOption.pro:
        return 'StageGameV2-audio/festival_background_pro.mp3';

      default:
        return null;
    }
  }

  void _startBackgroundMusicIfNeeded() async {
    if (_state.selectedSound == null) return;

    final asset = _speakerBackgroundAsset();
    if (asset == null) return;

    if (_backgroundMusicStarted && _currentSpeakerBackgroundAsset == asset) {
      return;
    }

    await _speakerBackgroundPlayer.stop();
    await _speakerBackgroundPlayer.play(
      AssetSource(asset),
      volume: _targetBackgroundVolume(),
    );

    _currentSpeakerBackgroundAsset = asset;
    _backgroundMusicStarted = true;
  }

  void _stopBackgroundMusicFlagged() async {
    await _speakerBackgroundPlayer.stop();
    _currentSpeakerBackgroundAsset = null;
    _backgroundMusicStarted = false;
  }

  void _startDistortionIfNeeded() {
    if (_isDistortionPlaying) return;

    _audioService.playSpeakerDistortion();
    _isDistortionPlaying = true;
  }

  void _stopDistortionIfNeeded() {
    if (!_isDistortionPlaying) return;

    _audioService.stopEffects();
    _isDistortionPlaying = false;
  }

  double _targetBackgroundVolume() {
    final p = _liveSoundSliderProgress.clamp(0.0, 1.0);

    if (_state.selectedSound == SoundOption.cheap) {
      return 0.006 + (p * 0.065);
    }

    if (_state.selectedSound == SoundOption.eco) {
      return 0.015 + (p * 0.280);
    }

    if (_state.selectedSound == SoundOption.pro) {
      return 0.020 + (p * 0.430);
    }

    return 0.0;
  }

  void _startOrUpdateMusicForSelectedSpeaker() async {
    if (!_audioReady || _isEndingRound) return;

    if (_state.selectedSound == null) {
      _stopBackgroundMusicFlagged();
      return;
    }

    final isCheapMax = _state.selectedSound == SoundOption.cheap &&
        _state.soundControlLevel == StageControlLevel.high;

    if (isCheapMax) {
      _stopBackgroundMusicFlagged();
      _startDistortionIfNeeded();
      return;
    }

    _stopDistortionIfNeeded();

    final asset = _speakerBackgroundAsset();
    if (asset == null) return;

    if (!_backgroundMusicStarted || _currentSpeakerBackgroundAsset != asset) {
      await _speakerBackgroundPlayer.stop();
      await _speakerBackgroundPlayer.play(
        AssetSource(asset),
        volume: _targetBackgroundVolume(),
      );

      _currentSpeakerBackgroundAsset = asset;
      _backgroundMusicStarted = true;
      return;
    }

    await _speakerBackgroundPlayer.setVolume(_targetBackgroundVolume());
  }

  void _playPrototypeAudioFeedback() {
    if (_isEndingRound || !_audioReady) return;

    final isOverloaded = _state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity;

    if (isOverloaded) {
      _stopBackgroundMusicFlagged();
      _stopDistortionIfNeeded();
      _audioService.playPowerOverload();
      return;
    }

    final powerRatio = _state.powerUsageRatio;

    if (powerRatio >= 0.8 && _state.currentPowerCapacity > 0) {
      _audioService.playPowerWarning();
    }

    if (_state.selectedSound == SoundOption.cheap &&
        _state.soundControlLevel == StageControlLevel.high) {
      _stopBackgroundMusicFlagged();
      _startDistortionIfNeeded();
      return;
    }

    _stopDistortionIfNeeded();
    _startOrUpdateMusicForSelectedSpeaker();
  }

  void _checkForInstantPowerFailure() {
    if (_isEndingRound) return;

    final isOverloaded = _state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity;

    if (!isOverloaded) return;

    _triggerPowerOverloadFailure();
  }

  Future<void> _triggerPowerOverloadFailure() async {
    if (_isEndingRound) return;

    _stopBackgroundMusicFlagged();
    _stopDistortionIfNeeded();
    _audioService.playPowerOverload();
    _audioService.playLightFlicker();

    setState(() {
      _isEndingRound = true;
    });

    await Future.delayed(const Duration(seconds: 7));

    await _speakerBackgroundPlayer.stop();
    _currentSpeakerBackgroundAsset = null;
    _backgroundMusicStarted = false;

    try {
      await LedService.completeMinigame('stage', 0);
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FinalScreen(
          sustainabilityScore: 0,
          stabilityScore: 0,
          audienceScore: 0,
          crowdReaction: 'Boo!',
          endComment: 'Power overload! The stage failed before the show.',
        ),
      ),
    );
  }

  Future<void> _finishRound() async {
    if (_isEndingRound) return;

    setState(() {
      _isEndingRound = true;
      _logic.finishRound(_state);
    });

    await _speakerBackgroundPlayer.stop();
    _currentSpeakerBackgroundAsset = null;
    _backgroundMusicStarted = false;
    _stopDistortionIfNeeded();
    _audioService.stopEffects();

    final totalScore = _state.stabilityScore +
        _state.sustainabilityScore +
        _state.audienceSatisfactionScore;

    try {
      await LedService.completeMinigame('stage', totalScore);
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FinalScreen(
          sustainabilityScore: _state.sustainabilityScore,
          stabilityScore: _state.stabilityScore,
          audienceScore: _state.audienceSatisfactionScore,
          crowdReaction: _state.endCrowdReaction,
          endComment: _state.endComment,
        ),
      ),
    );
  }

  String _soundOptionLabel(SoundOption option) {
    switch (option) {
      case SoundOption.cheap:
        return 'Cheap';
      case SoundOption.eco:
        return 'Eco';
      case SoundOption.pro:
        return 'Pro';
    }
  }

  String _lightOptionLabel(LightOption option) {
    switch (option) {
      case LightOption.led:
        return 'LED';
      case LightOption.smart:
        return 'Smart';
      case LightOption.halogen:
        return 'Halogen';
    }
  }

  String _powerSourceLabel(PowerSourceOption option) {
    switch (option) {
      case PowerSourceOption.solar:
        return 'Solar';
      case PowerSourceOption.hybrid:
        return 'Hybrid';
      case PowerSourceOption.generator:
        return 'Generator';
    }
  }

  String _effectOptionLabel(EffectOption option) {
    switch (option) {
      case EffectOption.laser:
        return 'Laser';
      case EffectOption.drone:
        return 'Drone';
      case EffectOption.fireworks:
        return 'Fireworks';
    }
  }

  String? _soundAsset() {
    switch (_state.selectedSound) {
      case SoundOption.cheap:
        return '$_assetBase/cheapspeaker.png';
      case SoundOption.eco:
        return '$_assetBase/ecospeaker-removebg-preview.png';
      case SoundOption.pro:
        return '$_assetBase/prospeaker.png';
      default:
        return null;
    }
  }

  String? _lightAsset() {
    switch (_state.selectedLight) {
      case LightOption.led:
        return '$_assetBase/led.png';
      case LightOption.smart:
        return '$_assetBase/smart.png';
      case LightOption.halogen:
        return '$_assetBase/halogen.png';
      default:
        return null;
    }
  }

  String? _powerAsset() {
    switch (_state.selectedPowerSource) {
      case PowerSourceOption.solar:
        return '$_assetBase/solar.png';
      case PowerSourceOption.hybrid:
        return '$_assetBase/hybrid.png';
      case PowerSourceOption.generator:
        return '$_assetBase/generator.png';
      default:
        return null;
    }
  }

  String? _effectAsset() {
    switch (_state.selectedEffect) {
      case EffectOption.laser:
        return '$_assetBase/laser.png';
      case EffectOption.drone:
        return '$_assetBase/drone.png';
      case EffectOption.fireworks:
        return '$_assetBase/firewoks.png';
      default:
        return null;
    }
  }

  Widget _buildChoiceWrap<T>({
    required List<T> options,
    required T? selected,
    required String Function(T option) labelBuilder,
    required void Function(T option) onSelected,
    double fontSize = 12,
    bool enabled = true,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: options.map((option) {
        final isSelected = selected == option;
        final canPress = enabled && !_isEndingRound;

        return ChoiceChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: canPress ? (_) => onSelected(option) : null,
          selectedColor: const Color(0xFFE2D5F2),
          backgroundColor: canPress
              ? const Color(0xFFFAF8FC)
              : const Color(0xFFE4E1DC),
          disabledColor: const Color(0xFFE4E1DC),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFB9A7D6)
                : canPress
                    ? const Color(0xFFCFC8D5)
                    : const Color(0xFFBEBAB2),
            width: 1.1,
          ),
          labelStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: canPress
                ? const Color(0xFF3A3940)
                : const Color(0xFF8B887F),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSoundOptions({double fontSize = 12}) {
    return _buildChoiceWrap<SoundOption>(
      options: SoundOption.values,
      selected: _state.selectedSound,
      fontSize: fontSize,
      enabled: _hasPowerSource,
      labelBuilder: _soundOptionLabel,
      onSelected: (option) {
        if (!_hasPowerSource) return;

        setState(() {
          _logic.selectSound(_state, option);
          _liveSoundSliderProgress = _progressFromLevel(
            _state.soundControlLevel,
          );
        });

        _handleGameChange();
      },
    );
  }

  Widget _buildLightOptions({double fontSize = 12}) {
    return _buildChoiceWrap<LightOption>(
      options: LightOption.values,
      selected: _state.selectedLight,
      fontSize: fontSize,
      enabled: _hasPowerSource,
      labelBuilder: _lightOptionLabel,
      onSelected: (option) {
        if (!_hasPowerSource) return;

        setState(() {
          _logic.selectLight(_state, option);
          _logic.selectLightLevel(_state, StageControlLevel.low);
          _liveLightSliderProgress = 0.0;
        });

        _handleGameChange();
      },
    );
  }

  Widget _buildPowerOptions({double fontSize = 12}) {
    return _buildChoiceWrap<PowerSourceOption>(
      options: PowerSourceOption.values,
      selected: _state.selectedPowerSource,
      fontSize: fontSize,
      enabled: true,
      labelBuilder: _powerSourceLabel,
      onSelected: (option) {
        setState(() {
          _logic.selectPowerSource(_state, option);
        });

        _handleGameChange();
      },
    );
  }

  Widget _buildEffectOptions({double fontSize = 12}) {
    return _buildChoiceWrap<EffectOption>(
      options: EffectOption.values,
      selected: _state.selectedEffect,
      fontSize: fontSize,
      enabled: _hasPowerSource,
      labelBuilder: _effectOptionLabel,
      onSelected: (option) {
        if (!_hasPowerSource) return;

        setState(() {
          _logic.selectEffect(_state, option);
        });

        _handleGameChange();
      },
    );
  }

  Widget _buildNormalOptionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD8D0DF),
          width: 1.4,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.caveat(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F2F35),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildMobileOptionsPanel() {
    return Column(
      children: [
        _buildNormalOptionCard(
          title: 'Sound',
          child: _buildSoundOptions(fontSize: 14),
        ),
        _buildNormalOptionCard(
          title: 'Lighting',
          child: _buildLightOptions(fontSize: 14),
        ),
        _buildNormalOptionCard(
          title: 'Power Source',
          child: _buildPowerOptions(fontSize: 14),
        ),
        _buildNormalOptionCard(
          title: 'Effects',
          child: _buildEffectOptions(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPlayerOneConsole(double boardHeight) {
    const panelWidth = 270.0;

    return SizedBox(
      width: panelWidth,
      height: boardHeight,
      child: RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: boardHeight,
          height: panelWidth,
          child: _buildFestivalAssistantPanel(),
        ),
      ),
    );
  }
    Widget _buildFestivalAssistantPanel() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EBDD),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF2F352F),
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'FESTIVAL ASSISTANT',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 24,
              height: 0.85,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
              color: const Color(0xFF2F2F35),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'Pick power first, then tune the stage',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 15,
              height: 0.9,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6D6A5C),
            ),
          ),
          const SizedBox(height: 5),
          const Divider(
            color: Color(0xFFBEB6A7),
            thickness: 1.2,
            height: 1,
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _assistantSectionBox(
                    title: 'Power',
                    icon: Icons.bolt_rounded,
                    accentColor: const Color(0xFFDCA63A),
                    options: _assistantPowerOptions(),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _assistantSectionBox(
                    title: 'Sound',
                    icon: Icons.graphic_eq_rounded,
                    accentColor: const Color(0xFF5B8FA8),
                    options: _assistantSoundOptions(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _assistantSectionBox(
                    title: 'Effects',
                    icon: Icons.auto_awesome_rounded,
                    accentColor: const Color(0xFF9A7AB8),
                    options: _assistantEffectOptions(),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _assistantSectionBox(
                    title: 'Lighting',
                    icon: Icons.lightbulb_rounded,
                    accentColor: const Color(0xFFE2B84F),
                    options: _assistantLightOptions(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Divider(
            color: Color(0xFFBEB6A7),
            thickness: 1,
            height: 1,
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                  child: _presetButton(
                    icon: Icons.eco_rounded,
                    label: 'Eco',
                    color: const Color(0xFF6B9E66),
                    onTap: _applyEcoPreset,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _presetButton(
                    icon: Icons.balance_rounded,
                    label: 'Balanced',
                    color: const Color(0xFF5B8FA8),
                    onTap: _applyBalancedPreset,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _presetButton(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Power',
                    color: const Color(0xFFD47B4D),
                    onTap: _applyPerformancePreset,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _assistantSectionBox({
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<Widget> options,
  }) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFDDD5C0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC8BFA9),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    height: 0.85,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF3B3B35),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              children: options.map((option) {
                return Expanded(child: option);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assistantOptionButton({
    required String label,
    required IconData icon,
    required Color accentColor,
    required Color iconBg,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final canPress = enabled && !_isEndingRound;

    return GestureDetector(
      onTap: canPress ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 170),
        opacity: canPress ? 1.0 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
          decoration: BoxDecoration(
            color: selected ? iconBg : const Color(0xFFFDFCF7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? accentColor
                  : canPress
                      ? const Color(0xFFE1DCCB)
                      : const Color(0xFFC9C4BA),
              width: selected ? 1.7 : 1,
            ),
            boxShadow: [
              if (selected && canPress)
                BoxShadow(
                  color: accentColor.withOpacity(0.22),
                  blurRadius: 7,
                  spreadRadius: 0.5,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 23,
                  height: 23,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.65)
                        : iconBg.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? accentColor.withOpacity(0.75)
                          : const Color(0xFFE0DED5),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: canPress
                        ? selected
                            ? accentColor
                            : const Color(0xFF5E665C)
                        : const Color(0xFF8B887F),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  height: 1,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: canPress
                      ? selected
                          ? const Color(0xFF263524)
                          : const Color(0xFF333333)
                      : const Color(0xFF8B887F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isEndingRound ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.55),
            width: 1,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: GoogleFonts.caveat(
                  fontSize: 14,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4E4D45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _assistantPowerOptions() {
    return [
      _assistantOptionButton(
        label: 'Solar',
        icon: Icons.wb_sunny_rounded,
        accentColor: const Color(0xFFDCA63A),
        iconBg: const Color(0xFFFFF1B8),
        selected: _state.selectedPowerSource == PowerSourceOption.solar,
        enabled: true,
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.solar);
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Hybrid',
        icon: Icons.bolt_rounded,
        accentColor: const Color(0xFF6B9E66),
        iconBg: const Color(0xFFE5F3D6),
        selected: _state.selectedPowerSource == PowerSourceOption.hybrid,
        enabled: true,
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.hybrid);
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Generator',
        icon: Icons.factory_rounded,
        accentColor: const Color(0xFF9A7AB8),
        iconBg: const Color(0xFFF0E6F5),
        selected: _state.selectedPowerSource == PowerSourceOption.generator,
        enabled: true,
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.generator);
          });

          _handleGameChange();
        },
      ),
    ];
  }

  List<Widget> _assistantSoundOptions() {
    return [
      _assistantOptionButton(
        label: 'Cheap',
        icon: Icons.volume_down_rounded,
        accentColor: const Color(0xFF6B9E66),
        iconBg: const Color(0xFFE5F3D6),
        selected: _state.selectedSound == SoundOption.cheap,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectSound(_state, SoundOption.cheap);
            _liveSoundSliderProgress = _progressFromLevel(
              _state.soundControlLevel,
            );
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Eco',
        icon: Icons.eco_rounded,
        accentColor: const Color(0xFF6B9E66),
        iconBg: const Color(0xFFE5F3D6),
        selected: _state.selectedSound == SoundOption.eco,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectSound(_state, SoundOption.eco);
            _liveSoundSliderProgress = _progressFromLevel(
              _state.soundControlLevel,
            );
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Pro',
        icon: Icons.speaker_rounded,
        accentColor: const Color(0xFF5B8FA8),
        iconBg: const Color(0xFFDDEFF4),
        selected: _state.selectedSound == SoundOption.pro,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectSound(_state, SoundOption.pro);
            _liveSoundSliderProgress = _progressFromLevel(
              _state.soundControlLevel,
            );
          });

          _handleGameChange();
        },
      ),
    ];
  }

  List<Widget> _assistantEffectOptions() {
    return [
      _assistantOptionButton(
        label: 'Laser',
        icon: Icons.flash_on_rounded,
        accentColor: const Color(0xFF5B8FA8),
        iconBg: const Color(0xFFDDEFF4),
        selected: _state.selectedEffect == EffectOption.laser,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectEffect(_state, EffectOption.laser);
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Drone',
        icon: Icons.flight_rounded,
        accentColor: const Color(0xFF9A7AB8),
        iconBg: const Color(0xFFF0E6F5),
        selected: _state.selectedEffect == EffectOption.drone,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectEffect(_state, EffectOption.drone);
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Firework',
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFD47B4D),
        iconBg: const Color(0xFFFBE4D3),
        selected: _state.selectedEffect == EffectOption.fireworks,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectEffect(_state, EffectOption.fireworks);
          });

          _handleGameChange();
        },
      ),
    ];
  }

  List<Widget> _assistantLightOptions() {
    return [
      _assistantOptionButton(
        label: 'LED',
        icon: Icons.lightbulb_rounded,
        accentColor: const Color(0xFFE2B84F),
        iconBg: const Color(0xFFFFF1B8),
        selected: _state.selectedLight == LightOption.led,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectLight(_state, LightOption.led);
            _logic.selectLightLevel(_state, StageControlLevel.low);
            _liveLightSliderProgress = 0.0;
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Smart',
        icon: Icons.memory_rounded,
        accentColor: const Color(0xFF5B8FA8),
        iconBg: const Color(0xFFDDEFF4),
        selected: _state.selectedLight == LightOption.smart,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectLight(_state, LightOption.smart);
            _logic.selectLightLevel(_state, StageControlLevel.low);
            _liveLightSliderProgress = 0.0;
          });

          _handleGameChange();
        },
      ),
      _assistantOptionButton(
        label: 'Halogen',
        icon: Icons.local_fire_department_rounded,
        accentColor: const Color(0xFFD47B4D),
        iconBg: const Color(0xFFFBE4D3),
        selected: _state.selectedLight == LightOption.halogen,
        enabled: _hasPowerSource,
        onTap: () {
          if (!_hasPowerSource) return;

          setState(() {
            _logic.selectLight(_state, LightOption.halogen);
            _logic.selectLightLevel(_state, StageControlLevel.low);
            _liveLightSliderProgress = 0.0;
          });

          _handleGameChange();
        },
      ),
    ];
  }

  void _applyEcoPreset() {
    if (_isEndingRound) return;

    setState(() {
      _logic.selectPowerSource(_state, PowerSourceOption.solar);
      _logic.selectSound(_state, SoundOption.eco);
      _logic.selectLight(_state, LightOption.led);
      _logic.selectLightLevel(_state, StageControlLevel.low);
      _logic.selectEffect(_state, EffectOption.laser);

      _liveSoundSliderProgress = _progressFromLevel(_state.soundControlLevel);
      _liveLightSliderProgress = 0.0;
    });

    _handleGameChange();
  }

  void _applyBalancedPreset() {
    if (_isEndingRound) return;

    setState(() {
      _logic.selectPowerSource(_state, PowerSourceOption.hybrid);
      _logic.selectSound(_state, SoundOption.eco);
      _logic.selectLight(_state, LightOption.smart);
      _logic.selectLightLevel(_state, StageControlLevel.low);
      _logic.selectEffect(_state, EffectOption.drone);

      _liveSoundSliderProgress = _progressFromLevel(_state.soundControlLevel);
      _liveLightSliderProgress = 0.0;
    });

    _handleGameChange();
  }

  void _applyPerformancePreset() {
    if (_isEndingRound) return;

    setState(() {
      _logic.selectPowerSource(_state, PowerSourceOption.generator);
      _logic.selectSound(_state, SoundOption.pro);
      _logic.selectLight(_state, LightOption.halogen);
      _logic.selectLightLevel(_state, StageControlLevel.low);
      _logic.selectEffect(_state, EffectOption.fireworks);

      _liveSoundSliderProgress = _progressFromLevel(_state.soundControlLevel);
      _liveLightSliderProgress = 0.0;
    });

    _handleGameChange();
  }

  Widget _buildPlayerTwoConsole(double boardHeight) {
    const panelWidth = 455.0;

    return SizedBox(
      width: panelWidth,
      height: boardHeight,
      child: RotatedBox(
        quarterTurns: 3,
        child: SizedBox(
          width: boardHeight,
          height: panelWidth,
          child: StageRightPanel(
            state: _state,
            config: _logic.config,
            onSoundSliderProgressChanged: _handleLiveSoundSlider,
            onLightSliderProgressChanged: _handleLiveLightSlider,
            onSoundLevelChanged: (level) {
              setState(() {
                _logic.selectSoundLevel(_state, level);
                _liveSoundSliderProgress = _progressFromLevel(level);
              });

              _handleGameChange();
            },
            onLightLevelChanged: (level) {
              if (_state.selectedLight == null) return;

              setState(() {
                _logic.selectLightLevel(_state, level);
                _liveLightSliderProgress = _progressFromLevel(level);
              });

              _handleGameChange();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStageVisualArea(double height) {
    final isOverloaded = _state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity;

    final lightColor = _selectedLightColor();
    final lightOpacity = _state.selectedLight == null ? 0.04 : _lightOpacity();

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5ED),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE0D9CB),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _stageFxController,
          builder: (context, child) {
            final pulse = _stageFxController.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFFF2EEE4),
                  ),
                ),
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    color: lightColor.withOpacity(lightOpacity),
                  ),
                ),
                if (_state.selectedLight != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildStageGlow(lightColor),
                    ),
                  ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 720,
                        height: 520,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: RotatedBox(
                                quarterTurns: 0,
                                child: Image.asset(
                                  '$_assetBase/Stage_top_view.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            _buildSelectedPowerOnStage(pulse),
                            _buildSelectedSoundOnStage(pulse),
                            _buildSelectedLightOnStage(pulse),
                            _buildSelectedEffectOnStage(pulse),
                            _buildCrowdFeedbackOnStage(pulse),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (isOverloaded)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD26455).withOpacity(0.58),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.45),
                              width: 1.3,
                            ),
                          ),
                          child: Text(
                            '⚠ POWER OVERLOAD ⚠',
                            style: GoogleFonts.caveat(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _lightOpacity() {
    if (_state.selectedLight == null) return 0.04;
    return 0.05 + (_liveLightSliderProgress * 0.19);
  }

  double _lightGlowPower() {
    if (_state.selectedLight == null) return 0.0;
    return 0.45 + (_liveLightSliderProgress * 0.70);
  }

  Color _selectedLightColor() {
    if (_state.selectedLight == LightOption.led) {
      return const Color(0xFF62B6F0);
    }

    if (_state.selectedLight == LightOption.smart) {
      return const Color(0xFFC45BFF);
    }

    if (_state.selectedLight == LightOption.halogen) {
      return const Color(0xFFFFA33A);
    }

    return const Color(0xFFBFC0B4);
  }

  Widget _buildStageGlow(Color color) {
    final glowPower = _lightGlowPower();

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 0.95,
          colors: [
            color.withOpacity(0.22 * glowPower),
            color.withOpacity(0.10 * glowPower),
            Colors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
    );
  }

  Widget _buildSelectedPowerOnStage(double pulse) {
    final asset = _powerAsset();
    if (asset == null) return const SizedBox.shrink();

    return Positioned(
      left: 72,
      bottom: 95,
      child: _stageAssetImage(
        asset: asset,
        size: 72,
        pulse: pulse,
        label: _state.selectedPowerSource == null
            ? null
            : _powerSourceLabel(_state.selectedPowerSource!),
      ),
    );
  }

  Widget _buildSelectedSoundOnStage(double pulse) {
    final asset = _soundAsset();
    if (asset == null) return const SizedBox.shrink();

    final isDistorted = _state.selectedSound == SoundOption.cheap &&
        _state.soundControlLevel == StageControlLevel.high;

    final shake = isDistorted ? math.sin(pulse * math.pi * 16) * 5 : 0.0;
    final rotate = isDistorted ? math.sin(pulse * math.pi * 14) * 0.05 : 0.0;
    final size = _state.selectedSound == SoundOption.pro ? 76.0 : 70.0;

    return Stack(
      children: [
        Positioned(
          left: 135 + shake,
          top: 215 + math.sin(pulse * math.pi * 2) * 2,
          child: Transform.rotate(
            angle: rotate,
            child: _stageAssetImage(
              asset: asset,
              size: size,
              pulse: pulse,
            ),
          ),
        ),
        Positioned(
          right: 135 - shake,
          top: 215 + math.sin((pulse + 0.3) * math.pi * 2) * 2,
          child: Transform.scale(
            scaleX: -1,
            child: Transform.rotate(
              angle: -rotate,
              child: _stageAssetImage(
                asset: asset,
                size: size,
                pulse: pulse,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedLightOnStage(double pulse) {
    final asset = _lightAsset();
    if (asset == null) return const SizedBox.shrink();

    final color = _selectedLightColor();
    final levelPower = _lightGlowPower();
    final glow = (0.28 + math.sin(pulse * math.pi * 2).abs() * 0.12) *
        levelPower;

    return Stack(
      children: [
        Positioned(
          left: 180,
          top: 58,
          child: _lightRigAsset(asset, color, glow),
        ),
        Positioned(
          right: 180,
          top: 58,
          child: _lightRigAsset(asset, color, glow),
        ),
        Positioned(
          left: 250,
          top: 112,
          child: _lightRigAsset(asset, color, glow * 0.8, size: 48),
        ),
        Positioned(
          right: 250,
          top: 112,
          child: _lightRigAsset(asset, color, glow * 0.8, size: 48),
        ),
      ],
    );
  }

  Widget _lightRigAsset(
    String asset,
    Color color,
    double glow, {
    double size = 58,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size + 32,
          height: size + 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(glow.clamp(0.0, 0.55)),
                blurRadius: 24,
                spreadRadius: 6,
              ),
            ],
          ),
        ),
        Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
    Widget _buildSelectedEffectOnStage(double pulse) {
    if (_state.selectedEffect == null) {
      return const SizedBox.shrink();
    }

    if (_state.selectedEffect == EffectOption.laser) {
      return Stack(
        children: [
          _laserImage(
            left: 90,
            top: 128,
            angle: -0.55,
            width: 255,
            pulse: pulse,
          ),
          _laserImage(
            right: 90,
            top: 128,
            angle: 0.55,
            width: 255,
            pulse: pulse,
          ),
          _laserImage(
            left: 170,
            top: 176,
            angle: -0.25,
            width: 190,
            pulse: pulse,
          ),
          _laserImage(
            right: 170,
            top: 176,
            angle: 0.25,
            width: 190,
            pulse: pulse,
          ),
          Positioned(
            top: 220,
            left: 250,
            right: 250,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF58E28B).withOpacity(0.65),
                    const Color(0xFFB8FFD2).withOpacity(0.75),
                    const Color(0xFF58E28B).withOpacity(0.65),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58E28B).withOpacity(0.40),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_state.selectedEffect == EffectOption.drone) {
      final asset = _effectAsset();
      if (asset == null) return const SizedBox.shrink();

      return Stack(
        children: [
          _droneImage(
            asset,
            left: 118,
            top: 82,
            size: 52,
            pulse: pulse,
            phase: 0,
          ),
          _droneImage(
            asset,
            right: 128,
            top: 104,
            size: 50,
            pulse: pulse,
            phase: 0.25,
          ),
          _droneImage(
            asset,
            left: 260,
            top: 150,
            size: 44,
            pulse: pulse,
            phase: 0.55,
          ),
          _droneImage(
            asset,
            right: 275,
            top: 152,
            size: 44,
            pulse: pulse,
            phase: 0.75,
          ),
        ],
      );
    }

    if (_state.selectedEffect == EffectOption.fireworks) {
      final asset = _effectAsset();
      if (asset == null) return const SizedBox.shrink();

      return Stack(
        children: [
          _fireworkImage(
            asset,
            left: 100,
            top: 65,
            size: 82,
            pulse: pulse,
            phase: 0,
          ),
          _fireworkImage(
            asset,
            right: 110,
            top: 58,
            size: 88,
            pulse: pulse,
            phase: 0.2,
          ),
          _fireworkImage(
            asset,
            left: 280,
            top: 118,
            size: 64,
            pulse: pulse,
            phase: 0.4,
          ),
          _fireworkImage(
            asset,
            right: 290,
            top: 130,
            size: 64,
            pulse: pulse,
            phase: 0.6,
          ),
          _fireworkImage(
            asset,
            left: 430,
            top: 185,
            size: 54,
            pulse: pulse,
            phase: 0.8,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCrowdFeedbackOnStage(double pulse) {
    final messages = _stageFeedbackMessages();

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        if (messages.isNotEmpty)
          _crowdBubble(
            text: messages[0],
            left: 78,
            top: 365 + math.sin(pulse * math.pi * 2) * 4,
            color: const Color(0xFFFDFCF7),
          ),
        if (messages.length > 1)
          _crowdBubble(
            text: messages[1],
            right: 72,
            top: 350 + math.sin((pulse + 0.35) * math.pi * 2) * 4,
            color: const Color(0xFFFFF2C2),
          ),
        if (messages.length > 2)
          _crowdBubble(
            text: messages[2],
            left: 300,
            top: 70 + math.sin((pulse + 0.7) * math.pi * 2) * 4,
            color: const Color(0xFFE6F1E8),
          ),
      ],
    );
  }

  List<String> _stageFeedbackMessages() {
    final messages = <String>[];

    if (_state.selectedSound == SoundOption.cheap) {
      if (_state.soundControlLevel == StageControlLevel.low) {
        messages.add('I can barely hear it!');
      } else if (_state.soundControlLevel == StageControlLevel.medium) {
        messages.add('Weak but usable.');
      } else {
        messages.add('Speaker is breaking!');
      }
    }

    if (_state.selectedSound == SoundOption.eco) {
      if (_state.soundControlLevel == StageControlLevel.low) {
        messages.add('Eco sound is soft.');
      } else if (_state.soundControlLevel == StageControlLevel.medium) {
        messages.add('Nice clean sound!');
      } else {
        messages.add('Eco sound is loud!');
      }
    }

    if (_state.selectedSound == SoundOption.pro) {
      if (_state.soundControlLevel == StageControlLevel.low) {
        messages.add('Clear pro sound!');
      } else if (_state.soundControlLevel == StageControlLevel.medium) {
        messages.add('Powerful sound!');
      } else {
        messages.add('Huge festival sound!');
      }
    }

    if (_state.selectedLight == LightOption.led) {
      if (_state.lightControlLevel == StageControlLevel.low) {
        messages.add('LED is calm.');
      } else if (_state.lightControlLevel == StageControlLevel.medium) {
        messages.add('LED looks safe!');
      } else {
        messages.add('LED is bright!');
      }
    }

    if (_state.selectedLight == LightOption.smart) {
      if (_state.lightControlLevel == StageControlLevel.low) {
        messages.add('Smart light is subtle.');
      } else if (_state.lightControlLevel == StageControlLevel.medium) {
        messages.add('Smart vibe!');
      } else {
        messages.add('Great light show!');
      }
    }

    if (_state.selectedLight == LightOption.halogen) {
      if (_state.lightControlLevel == StageControlLevel.high) {
        messages.add('That light is hot!');
      } else {
        messages.add('Warm light!');
      }
    }

    if (_state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity) {
      messages
        ..clear()
        ..add('Too much power!')
        ..add('Stage is failing!')
        ..add('Fix it fast!');
    }

    if (_logic.canFinish(_state) && messages.length < 3) {
      messages.add('Ready for show!');
    }

    return messages.take(3).toList();
  }

  Widget _crowdBubble({
    required String text,
    double? left,
    double? right,
    required double top,
    required Color color,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: IgnorePointer(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 128),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFD8D0C2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 15,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F2F35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _laserImage({
    double? left,
    double? right,
    required double top,
    required double angle,
    required double width,
    required double pulse,
  }) {
    final asset = _effectAsset();
    if (asset == null) return const SizedBox.shrink();

    final opacity = 0.72 + math.sin(pulse * math.pi * 2).abs() * 0.24;

    return Positioned(
      left: left,
      right: right,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: width,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: const Color(0xFF58E28B).withOpacity(0.16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58E28B).withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Image.asset(
                asset,
                width: width,
                height: 42,
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _droneImage(
    String asset, {
    double? left,
    double? right,
    required double top,
    required double size,
    required double pulse,
    required double phase,
  }) {
    final y = math.sin((pulse + phase) * math.pi * 2) * 8;
    final angle = math.sin((pulse + phase) * math.pi * 2) * 0.08;

    return Positioned(
      left: left,
      right: right,
      top: top + y,
      child: Transform.rotate(
        angle: angle,
        child: Image.asset(
          asset,
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _fireworkImage(
    String asset, {
    double? left,
    double? right,
    required double top,
    required double size,
    required double pulse,
    required double phase,
  }) {
    final local = (pulse + phase) % 1.0;
    final wave = math.sin(local * math.pi);
    final scale = 0.82 + wave * 0.22;
    final opacity = 0.35 + wave * 0.65;

    return Positioned(
      left: left,
      right: right,
      top: top - wave * 8,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _stageAssetImage({
    required String asset,
    required double size,
    required double pulse,
    String? label,
  }) {
    final scale = 1 + math.sin(pulse * math.pi * 2).abs() * 0.03;

    return Transform.scale(
      scale: scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
          if (label != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCF7).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD8D0C2),
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.caveat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2F2F35),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinishButton() {
    final canFinish = _logic.canFinish(_state) && !_isEndingRound;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: canFinish ? _finishRound : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: canFinish
                ? const Color(0xFF4A7C59)
                : const Color(0xFFD8D8D0),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: canFinish
                  ? const Color(0xFF315A3E)
                  : const Color(0xFFBEBEB6),
              width: 1.5,
            ),
          ),
          child: Text(
            _isEndingRound
                ? 'Stage Failed'
                : canFinish
                    ? 'Finish Round'
                    : 'Choose all parts',
            style: GoogleFonts.caveat(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: canFinish ? Colors.white : const Color(0xFF77776F),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRunningScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 1100;

        if (isWide) {
          final boardHeight =
              (constraints.maxHeight - 28).clamp(560.0, 720.0);

          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1700),
                child: SizedBox(
                  height: boardHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPlayerOneConsole(boardHeight),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStageVisualArea(boardHeight),
                      ),
                      const SizedBox(width: 10),
                      _buildPlayerTwoConsole(boardHeight),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            children: [
              _buildMobileOptionsPanel(),
              const SizedBox(height: 16),
              _buildStageVisualArea(420),
              const SizedBox(height: 16),
              StageRightPanel(
                state: _state,
                config: _logic.config,
                onSoundSliderProgressChanged: _handleLiveSoundSlider,
                onLightSliderProgressChanged: _handleLiveLightSlider,
                onSoundLevelChanged: (level) {
                  setState(() {
                    _logic.selectSoundLevel(_state, level);
                    _liveSoundSliderProgress = _progressFromLevel(level);
                  });

                  _handleGameChange();
                },
                onLightLevelChanged: (level) {
                  if (_state.selectedLight == null) return;

                  setState(() {
                    _logic.selectLightLevel(_state, level);
                    _liveLightSliderProgress = _progressFromLevel(level);
                  });

                  _handleGameChange();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4EFF8),
        elevation: 0,
        leading: const BackButton(
          color: Color(0xFF25252B),
        ),
        title: Text(
          'Stage Setup Challenge',
          style: GoogleFonts.caveat(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF25252B),
          ),
        ),
        centerTitle: true,
        actions: [
          _buildFinishButton(),
        ],
      ),
      body: _buildRunningScreen(),
    );
  }
}