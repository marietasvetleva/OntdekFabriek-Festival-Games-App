import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/led_service.dart';
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
  late StageGameState _state;

  /*
    AANWIJZING:
    Alle nieuwe middle-stage assets staan direct in:
    assets/StageGameV2-image/

    Deze assets komen van je klasgenoot:
    - cheapspeaker.png
    - ecospeaker-removebg-preview.png
    - prospeaker.png
    - led.png
    - smart.png
    - halogen.png
    - solar.png
    - hybrid.png
    - generator.png
    - laser.png
    - drone.png
    - firewoks.png

    Let op:
    In jouw screenshot heet het bestand firewoks.png.
    Als jouw bestand anders heet, pas alleen de naam aan in _effectAsset().
  */
  static const String _assetBase = 'assets/StageGameV2-image';

  late final AnimationController _stageFxController;

  bool _isEndingRound = false;

  @override
  void initState() {
    super.initState();

    _state = _logic.createInitialState();
    _logic.start(_state);

    _stageFxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _stageFxController.dispose();
    super.dispose();
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

    setState(() {
      /*
        AANWIJZING:
        Bij power overload locken we direct de keuzes.
        De speler kan dus 7 seconden kijken naar de fout,
        maar niks meer aanpassen.
      */
      _isEndingRound = true;
    });

    await Future.delayed(const Duration(seconds: 7));

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

    final totalScore = _state.stabilityScore +
        _state.sustainabilityScore +
        _state.audienceSatisfactionScore;

    try {
      await LedService.completeMinigame('stage', totalScore);
    } catch (_) {}

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

  /*
    AANWIJZING:
    Deze asset methodes zijn gebaseerd op het werk van je klasgenoot,
    maar aangepast naar jouw huidige enums en juiste Flutter asset paths.
  */
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
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: options.map((option) {
        final isSelected = selected == option;

        return ChoiceChip(
          label: Text(labelBuilder(option)),
          selected: isSelected,
          onSelected: _isEndingRound ? null : (_) => onSelected(option),
          selectedColor: const Color(0xFFE2D5F2),
          backgroundColor: const Color(0xFFFAF8FC),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFB9A7D6)
                : const Color(0xFFCFC8D5),
            width: 1.1,
          ),
          labelStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: const Color(0xFF3A3940),
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
      labelBuilder: _soundOptionLabel,
      onSelected: (option) {
        setState(() {
          _logic.selectSound(_state, option);
        });
        _checkForInstantPowerFailure();
      },
    );
  }

  Widget _buildLightOptions({double fontSize = 12}) {
    return _buildChoiceWrap<LightOption>(
      options: LightOption.values,
      selected: _state.selectedLight,
      fontSize: fontSize,
      labelBuilder: _lightOptionLabel,
      onSelected: (option) {
        setState(() {
          _logic.selectLight(_state, option);
        });
        _checkForInstantPowerFailure();
      },
    );
  }

  Widget _buildPowerOptions({double fontSize = 12}) {
    return _buildChoiceWrap<PowerSourceOption>(
      options: PowerSourceOption.values,
      selected: _state.selectedPowerSource,
      fontSize: fontSize,
      labelBuilder: _powerSourceLabel,
      onSelected: (option) {
        setState(() {
          _logic.selectPowerSource(_state, option);
        });
        _checkForInstantPowerFailure();
      },
    );
  }

  Widget _buildEffectOptions({double fontSize = 12}) {
    return _buildChoiceWrap<EffectOption>(
      options: EffectOption.values,
      selected: _state.selectedEffect,
      fontSize: fontSize,
      labelBuilder: _effectOptionLabel,
      onSelected: (option) {
        setState(() {
          _logic.selectEffect(_state, option);
        });
        _checkForInstantPowerFailure();
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
            'Pick parts for the stage',
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
  }) {
    return GestureDetector(
      onTap: _isEndingRound ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 1),
        decoration: BoxDecoration(
          color: selected ? iconBg : const Color(0xFFFDFCF7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accentColor : const Color(0xFFE1DCCB),
            width: selected ? 1.7 : 1,
          ),
          boxShadow: [
            if (selected)
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
                  color: selected ? accentColor : const Color(0xFF5E665C),
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
                color:
                    selected ? const Color(0xFF263524) : const Color(0xFF333333),
              ),
            ),
          ],
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
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.solar);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Hybrid',
        icon: Icons.bolt_rounded,
        accentColor: const Color(0xFF6B9E66),
        iconBg: const Color(0xFFE5F3D6),
        selected: _state.selectedPowerSource == PowerSourceOption.hybrid,
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.hybrid);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Generator',
        icon: Icons.factory_rounded,
        accentColor: const Color(0xFF9A7AB8),
        iconBg: const Color(0xFFF0E6F5),
        selected: _state.selectedPowerSource == PowerSourceOption.generator,
        onTap: () {
          setState(() {
            _logic.selectPowerSource(_state, PowerSourceOption.generator);
          });
          _checkForInstantPowerFailure();
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
        onTap: () {
          setState(() {
            _logic.selectSound(_state, SoundOption.cheap);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Eco',
        icon: Icons.eco_rounded,
        accentColor: const Color(0xFF6B9E66),
        iconBg: const Color(0xFFE5F3D6),
        selected: _state.selectedSound == SoundOption.eco,
        onTap: () {
          setState(() {
            _logic.selectSound(_state, SoundOption.eco);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Pro',
        icon: Icons.speaker_rounded,
        accentColor: const Color(0xFF5B8FA8),
        iconBg: const Color(0xFFDDEFF4),
        selected: _state.selectedSound == SoundOption.pro,
        onTap: () {
          setState(() {
            _logic.selectSound(_state, SoundOption.pro);
          });
          _checkForInstantPowerFailure();
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
        onTap: () {
          setState(() {
            _logic.selectEffect(_state, EffectOption.laser);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Drone',
        icon: Icons.flight_rounded,
        accentColor: const Color(0xFF9A7AB8),
        iconBg: const Color(0xFFF0E6F5),
        selected: _state.selectedEffect == EffectOption.drone,
        onTap: () {
          setState(() {
            _logic.selectEffect(_state, EffectOption.drone);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Firework',
        icon: Icons.auto_awesome_rounded,
        accentColor: const Color(0xFFD47B4D),
        iconBg: const Color(0xFFFBE4D3),
        selected: _state.selectedEffect == EffectOption.fireworks,
        onTap: () {
          setState(() {
            _logic.selectEffect(_state, EffectOption.fireworks);
          });
          _checkForInstantPowerFailure();
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
        onTap: () {
          setState(() {
            _logic.selectLight(_state, LightOption.led);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Smart',
        icon: Icons.memory_rounded,
        accentColor: const Color(0xFF5B8FA8),
        iconBg: const Color(0xFFDDEFF4),
        selected: _state.selectedLight == LightOption.smart,
        onTap: () {
          setState(() {
            _logic.selectLight(_state, LightOption.smart);
          });
          _checkForInstantPowerFailure();
        },
      ),
      _assistantOptionButton(
        label: 'Halogen',
        icon: Icons.local_fire_department_rounded,
        accentColor: const Color(0xFFD47B4D),
        iconBg: const Color(0xFFFBE4D3),
        selected: _state.selectedLight == LightOption.halogen,
        onTap: () {
          setState(() {
            _logic.selectLight(_state, LightOption.halogen);
          });
          _checkForInstantPowerFailure();
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
      _logic.selectEffect(_state, EffectOption.laser);
    });

    _checkForInstantPowerFailure();
  }

  void _applyBalancedPreset() {
    if (_isEndingRound) return;

    setState(() {
      _logic.selectPowerSource(_state, PowerSourceOption.hybrid);
      _logic.selectSound(_state, SoundOption.eco);
      _logic.selectLight(_state, LightOption.smart);
      _logic.selectEffect(_state, EffectOption.drone);
    });

    _checkForInstantPowerFailure();
  }

  void _applyPerformancePreset() {
    if (_isEndingRound) return;

    setState(() {
      _logic.selectPowerSource(_state, PowerSourceOption.generator);
      _logic.selectSound(_state, SoundOption.pro);
      _logic.selectLight(_state, LightOption.halogen);
      _logic.selectEffect(_state, EffectOption.fireworks);
    });

    _checkForInstantPowerFailure();
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
          ),
        ),
      ),
    );
  }

  Widget _buildStageVisualArea(double height) {
    final isOverloaded = _state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity;

    final lightColor = _selectedLightColor();
    final lightOpacity = _state.selectedLight == null ? 0.04 : 0.18;

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

                /*
                  AANWIJZING:
                  Kleurlaag afhankelijk van gekozen light.
                  Dit blijft subtiel zodat de stage image zichtbaar blijft.
                */
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
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
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Image.asset(
                          '$_assetBase/Stage_top_view.png',
                        ),
                      ),
                    ),
                  ),
                ),

                /*
                  AANWIJZING:
                  Nieuwe middle stage:
                  Hier plaatsen we de assets van je klasgenoot op de stage.
                */
                _buildSelectedPowerOnStage(pulse),
                _buildSelectedSoundOnStage(pulse),
                _buildSelectedLightOnStage(pulse),
                _buildSelectedEffectOnStage(pulse),
                _buildCrowdReactionBubbles(pulse),

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
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 0.95,
          colors: [
            color.withOpacity(0.22),
            color.withOpacity(0.10),
            Colors.transparent,
          ],
          stops: const [0.0, 0.48, 1.0],
        ),
      ),
    );
  }

  /*
    AANWIJZING:
    Power source asset wordt linksvoor naast de stage gezet.
    Zo ziet speler dat de gekozen stroombron actief is.
  */
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

  /*
    AANWIJZING:
    Speakers worden links en rechts van de stage gezet.
    Dit past beter dan één klein icoon midden in de stage.
  */
  Widget _buildSelectedSoundOnStage(double pulse) {
    final asset = _soundAsset();
    if (asset == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          left: 135,
          top: 215 + math.sin(pulse * math.pi * 2) * 2,
          child: _stageAssetImage(
            asset: asset,
            size: 72,
            pulse: pulse,
          ),
        ),
        Positioned(
          right: 135,
          top: 215 + math.sin((pulse + 0.3) * math.pi * 2) * 2,
          child: Transform.scale(
            scaleX: -1,
            child: _stageAssetImage(
              asset: asset,
              size: 72,
              pulse: pulse,
            ),
          ),
        ),
      ],
    );
  }

  /*
    AANWIJZING:
    Light assets worden bij de bovenkant van het podium gezet.
    De lampen hebben glow in de kleur van de gekozen light.
  */
  Widget _buildSelectedLightOnStage(double pulse) {
    final asset = _lightAsset();
    if (asset == null) return const SizedBox.shrink();

    final color = _selectedLightColor();
    final glow = 0.28 + math.sin(pulse * math.pi * 2).abs() * 0.12;

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
                color: color.withOpacity(glow),
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

  /*
    AANWIJZING:
    Effect assets worden per type anders geplaatst:
    - laser: meerdere laser assets met glow
    - drone: meerdere drones die rond de stage zweven
    - fireworks: meerdere vuurwerk bursts boven/achter de stage
  */
  Widget _buildSelectedEffectOnStage(double pulse) {
    if (_state.selectedEffect == null) {
      return const SizedBox.shrink();
    }

    if (_state.selectedEffect == EffectOption.laser) {
      return Stack(
        children: [
          _laserImage(left: 90, top: 128, angle: -0.55, width: 255, pulse: pulse),
          _laserImage(right: 90, top: 128, angle: 0.55, width: 255, pulse: pulse),
          _laserImage(left: 170, top: 176, angle: -0.25, width: 190, pulse: pulse),
          _laserImage(right: 170, top: 176, angle: 0.25, width: 190, pulse: pulse),
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
          _droneImage(asset, left: 118, top: 82, size: 52, pulse: pulse, phase: 0),
          _droneImage(asset, right: 128, top: 104, size: 50, pulse: pulse, phase: 0.25),
          _droneImage(asset, left: 260, top: 150, size: 44, pulse: pulse, phase: 0.55),
          _droneImage(asset, right: 275, top: 152, size: 44, pulse: pulse, phase: 0.75),
        ],
      );
    }

    if (_state.selectedEffect == EffectOption.fireworks) {
      final asset = _effectAsset();
      if (asset == null) return const SizedBox.shrink();

      return Stack(
        children: [
          _fireworkImage(asset, left: 100, top: 65, size: 82, pulse: pulse, phase: 0),
          _fireworkImage(asset, right: 110, top: 58, size: 88, pulse: pulse, phase: 0.2),
          _fireworkImage(asset, left: 280, top: 118, size: 64, pulse: pulse, phase: 0.4),
          _fireworkImage(asset, right: 290, top: 130, size: 64, pulse: pulse, phase: 0.6),
          _fireworkImage(asset, left: 430, top: 185, size: 54, pulse: pulse, phase: 0.8),
        ],
      );
    }

    return const SizedBox.shrink();
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

  /*
    AANWIJZING:
    Crowd bubbles staan nu echt in de crowd/front area.
    Ze poppen in/out en verdwijnen zodra het probleem is opgelost.
  */
  List<String> _stageReactionMessages() {
    final isOverloaded = _state.currentPowerCapacity > 0 &&
        _state.totalPowerLoad > _state.currentPowerCapacity;

    if (isOverloaded) {
      return ['Power overload!', 'Too much power!', 'Stage is risky!'];
    }

    if (_state.selectedSound != null &&
        _state.currentSoundDb > _logic.config.soundTargetMax) {
      return ['Too loud!', 'My ears!', 'Lower sound!'];
    }

    if (_state.selectedSound != null &&
        _state.currentSoundDb < _logic.config.soundTargetMin) {
      return ['Can’t hear it!', 'More sound!'];
    }

    if (_state.selectedLight != null &&
        _state.currentLightIntensity > _logic.config.lightTargetMax) {
      return ['Lights too strong!', 'Too bright!', 'Dim lights!'];
    }

    if (_state.selectedLight != null &&
        _state.currentLightIntensity < _logic.config.lightTargetMin) {
      return ['Too dark!', 'More light!'];
    }

    if (_state.hasAllSelections) {
      return ['Nice stage!', 'Looks good!'];
    }

    if (_state.selectedEffect != null) {
      return ['Cool effect!'];
    }

    if (_state.selectedLight != null || _state.selectedSound != null) {
      return ['Keep tuning!'];
    }

    return [];
  }

  Widget _buildCrowdReactionBubbles(double pulse) {
    final messages = _stageReactionMessages();

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    final isBad = messages.first.contains('overload') ||
        messages.first.contains('Too') ||
        messages.first.contains('ears') ||
        messages.first.contains('Lower') ||
        messages.first.contains('dark') ||
        messages.first.contains('hear') ||
        messages.first.contains('risky') ||
        messages.first.contains('Dim');

    final positions = [
      _BubblePosition(left: 170, bottom: 90, phase: 0.00),
      _BubblePosition(right: 170, bottom: 86, phase: 0.28),
      _BubblePosition(left: 340, bottom: 52, phase: 0.56),
      _BubblePosition(right: 360, bottom: 54, phase: 0.78),
    ];

    return Stack(
      children: [
        for (int i = 0; i < messages.length && i < positions.length; i++)
          _buildSingleCrowdBubble(
            message: messages[i],
            position: positions[i],
            pulse: pulse,
            isBad: isBad,
          ),
      ],
    );
  }

  Widget _buildSingleCrowdBubble({
    required String message,
    required _BubblePosition position,
    required double pulse,
    required bool isBad,
  }) {
    final localPulse = ((pulse + position.phase) % 1.0);
    final wave = math.sin(localPulse * math.pi);
    final scale = 0.82 + wave * 0.18;
    final opacity = 0.35 + wave * 0.65;
    final yOffset = -wave * 8;

    return Positioned(
      left: position.left,
      right: position.right,
      bottom: position.bottom + yOffset,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isBad
                  ? const Color(0xFFFFE3DD).withOpacity(0.95)
                  : const Color(0xFFE8F5D0).withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isBad ? const Color(0xFFD26455) : const Color(0xFF6B9E66),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (isBad ? const Color(0xFFD26455) : const Color(0xFF6B9E66))
                          .withOpacity(0.16 + wave * 0.10),
                  blurRadius: 10 + wave * 4,
                  spreadRadius: 0.4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBad
                      ? Icons.warning_amber_rounded
                      : Icons.sentiment_satisfied_alt_rounded,
                  size: 15,
                  color:
                      isBad ? const Color(0xFFD26455) : const Color(0xFF4A7C59),
                ),
                const SizedBox(width: 5),
                Text(
                  message,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
                    height: 0.9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2F2F35),
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _BubblePosition {
  final double? left;
  final double? right;
  final double bottom;
  final double phase;

  const _BubblePosition({
    this.left,
    this.right,
    required this.bottom,
    required this.phase,
  });
}