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

class _StageGamePageState extends State<StageGamePage> {
  final StageGameLogic _logic = StageGameLogic();
  late StageGameState _state;

  @override
  void initState() {
    super.initState();

    _state = _logic.createInitialState();
    _logic.start(_state);
  }

  Future<void> _finishRound() async {
    setState(() {
      _logic.finishRound(_state);
    });

    final totalScore = _state.stabilityScore +
        _state.sustainabilityScore +
        _state.audienceSatisfactionScore;

    try {
      await LedService.completeMinigame('stage', totalScore);
    } catch (_) {}

    if (!mounted) return;

    Navigator.push(
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
          onSelected: (_) => onSelected(option),
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

  Widget _buildLeftSideCard({
    required String title,
    required Widget child,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF2EEF6),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD8D0DF),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: RotatedBox(
          quarterTurns: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2F2F35),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(child: child),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerOneConsole(double boardHeight) {
    return SizedBox(
      width: 170,
      height: boardHeight,
      child: Column(
        children: [
          _buildLeftSideCard(
            title: 'Sound',
            child: _buildSoundOptions(fontSize: 12),
          ),
          _buildLeftSideCard(
            title: 'Lighting',
            child: _buildLightOptions(fontSize: 12),
          ),
          _buildLeftSideCard(
            title: 'Power Source',
            child: _buildPowerOptions(fontSize: 12),
          ),
          _buildLeftSideCard(
            title: 'Effects',
            child: _buildEffectOptions(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTwoConsole(double boardHeight) {
    /*
      AANPASSING:
      455 was net te smal voor de nieuwe image-assets.
      480 geeft de rechter panel iets meer ademruimte,
      zodat de meters en teksten minder clippen.
    */
    const panelWidth = 550.0;

    return SizedBox(
      width: panelWidth,
      height: boardHeight,

      /*
        BELANGRIJK:
        quarterTurns: 3 is de juiste kijkrichting voor de rechterspeler.
        Niet veranderen, anders draait de panel weer verkeerd.
      */
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
    final lightOpacity = _state.selectedLight == null ? 0.06 : 0.22;

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
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Container(
                color: const Color(0xFFF2EEE4),
              ),
            ),
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOut,
                color: lightColor.withOpacity(lightOpacity),
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
                      'assets/StageGameV2-image/Stage_top_view.png',
                    ),
                  ),
                ),
              ),
            ),
            _buildStageLight(
              top: 48,
              left: 90,
              color: lightColor,
            ),
            _buildStageLight(
              top: 48,
              right: 90,
              color: lightColor,
            ),
            if (_state.selectedEffect == EffectOption.laser) ...[
              _buildLaserBeam(
                left: 105,
                top: 130,
                angle: -0.55,
              ),
              _buildLaserBeam(
                right: 105,
                top: 130,
                angle: 0.55,
              ),
            ],
            if (_state.selectedEffect == EffectOption.drone) ...[
              const Positioned(
                top: 92,
                left: 130,
                child: Icon(
                  Icons.airplanemode_active,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const Positioned(
                top: 112,
                right: 140,
                child: Icon(
                  Icons.airplanemode_active,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ],
            if (_state.selectedEffect == EffectOption.fireworks) ...[
              const Positioned(
                top: 105,
                left: 145,
                child: Text(
                  '🎆',
                  style: TextStyle(fontSize: 44),
                ),
              ),
              const Positioned(
                top: 90,
                right: 150,
                child: Text(
                  '🎇',
                  style: TextStyle(fontSize: 44),
                ),
              ),
            ],
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
        ),
      ),
    );
  }

  Color _selectedLightColor() {
    if (_state.selectedLight == LightOption.led) {
      return const Color(0xFF7AB7E8);
    }

    if (_state.selectedLight == LightOption.smart) {
      return const Color(0xFFD15AF0);
    }

    if (_state.selectedLight == LightOption.halogen) {
      return const Color(0xFFF0A23E);
    }

    return const Color(0xFFBFC0B4);
  }

  Widget _buildStageLight({
    required double top,
    double? left,
    double? right,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(
          begin: 0.75,
          end: _state.selectedLight == null ? 0.75 : 1,
        ),
        duration: const Duration(milliseconds: 500),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Icon(
          Icons.lightbulb,
          color: color,
          size: 44,
        ),
      ),
    );
  }

  Widget _buildLaserBeam({
    double? left,
    double? right,
    required double top,
    required double angle,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 230,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF58E28B).withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF58E28B).withOpacity(0.45),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishButton() {
    final canFinish = _logic.canFinish(_state);

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
            canFinish ? 'Finish Round' : 'Choose all parts',
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildStageVisualArea(boardHeight),
                      ),
                      const SizedBox(width: 14),
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