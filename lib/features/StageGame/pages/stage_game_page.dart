import 'package:flutter/material.dart';
import '../services/led_service.dart';
import '../logic/stage_game_logic.dart';
import '../logic/stage_game_models.dart';
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

    // START GAME DIRECTLY
    _logic.start(_state);
  }

  Future<void> _finishRound() async {
    setState(() {
      _logic.finishRound(_state);
    });

    // Optional: send total result to LED service
    final totalScore = _state.stabilityScore +
        _state.sustainabilityScore +
        _state.audienceSatisfactionScore;

    try {
      await LedService.completeMinigame('stage', totalScore);
    } catch (_) {
      // Ignore LED errors so the game still works
    }

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

  void _restartGame() {
    setState(() {
      _state = _logic.createInitialState();
      _logic.start(_state);
    });
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

  Widget _buildOptionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SoundOption.values.map((option) {
        return ChoiceChip(
          label: Text(_soundOptionLabel(option)),
          selected: _state.selectedSound == option,
          onSelected: (_) {
            setState(() {
              _logic.selectSound(_state, option);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildLightOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: LightOption.values.map((option) {
        return ChoiceChip(
          label: Text(_lightOptionLabel(option)),
          selected: _state.selectedLight == option,
          onSelected: (_) {
            setState(() {
              _logic.selectLight(_state, option);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildPowerOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PowerSourceOption.values.map((option) {
        return ChoiceChip(
          label: Text(_powerSourceLabel(option)),
          selected: _state.selectedPowerSource == option,
          onSelected: (_) {
            setState(() {
              _logic.selectPowerSource(_state, option);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEffectOptions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EffectOption.values.map((option) {
        return ChoiceChip(
          label: Text(_effectOptionLabel(option)),
          selected: _state.selectedEffect == option,
          onSelected: (_) {
            setState(() {
              _logic.selectEffect(_state, option);
            });
          },
        );
      }).toList(),
    );
  }


  Widget _buildLiveFeedbackPanel() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Live Feedback',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildFeedbackRow(
              label: 'Sound',
              value: '${_state.currentSoundDb.toStringAsFixed(0)} dB',
              feedback: _state.soundFeedback,
            ),
            const SizedBox(height: 8),
            _buildFeedbackRow(
              label: 'Light',
              value: _state.currentLightIntensity.toStringAsFixed(0),
              feedback: _state.lightFeedback,
            ),
            const SizedBox(height: 8),
            _buildFeedbackRow(
              label: 'Power',
              value:
                  '${_state.totalPowerLoad}/${_state.currentPowerCapacity}',
              feedback: _state.powerFeedback,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackRow({
    required String label,
    required String value,
    required String feedback,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(value),
        ),
        Expanded(
          flex: 3,
          child: Text(
            feedback,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

Widget _buildStageVisualArea() {
  final isOverloaded =
      _state.currentPowerCapacity > 0 && _state.totalPowerLoad > _state.currentPowerCapacity;

  Color lightColor = Colors.grey;

  if (_state.selectedLight == LightOption.led) {
    lightColor = Colors.blueAccent;
  } else if (_state.selectedLight == LightOption.smart) {
    lightColor = Colors.purpleAccent;
  } else if (_state.selectedLight == LightOption.halogen) {
    lightColor = Colors.orangeAccent;
  }

  return Card(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    ),
    child: Container(
      height: 420,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        'assets/StageGameV2-image/Stage_top_view.png',
        fit: BoxFit.contain,
      ),

      Container(
        color: lightColor.withOpacity(0.25),
      ),
    ],
  ),
),
          Positioned(
            top: 25,
            left: 40,
            child: Icon(Icons.lightbulb, color: lightColor, size: 45),
          ),
          Positioned(
            top: 25,
            right: 40,
            child: Icon(Icons.lightbulb, color: lightColor, size: 45),
          ),

          // if (_state.selectedLight != null)
          //   Positioned(
          //     top: 75,
          //     child: Text(
          //       '${_lightOptionLabel(_state.selectedLight!)} Lighting',
          //       style: const TextStyle(
          //         color: Colors.white,
          //         fontSize: 18,
          //         fontWeight: FontWeight.bold,
          //       ),
          //     ),
          //   ), 

          // Positioned(
          //   bottom: 80,
          //   child: Container(
          //     width: 260,
          //     height: 95,
          //     decoration: BoxDecoration(
          //       color: Colors.grey.shade900,
          //       borderRadius: BorderRadius.circular(16),
          //       border: Border.all(color: Colors.white24, width: 2),
          //     ),
          //     child: const Center(
          //       child: Text(
          //         'CENTER STAGE',
          //         style: TextStyle(
          //           color: Colors.white,
          //           fontSize: 22,
          //           fontWeight: FontWeight.bold,
          //           letterSpacing: 2,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),

          // Positioned(
          //   bottom: 45,
          //   child: Container(
          //     width: 330,
          //     height: 25,
          //     decoration: BoxDecoration(
          //       color: Colors.black,
          //       borderRadius: BorderRadius.circular(8),
          //     ),
          //   ),
          // ),

          if (_state.selectedEffect == EffectOption.laser) ...[
            Positioned(
              top: 130,
              left: 45,
              child: Transform.rotate(
                angle: -0.6,
                child: Container(
                  width: 220,
                  height: 5,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            Positioned(
              top: 130,
              right: 45,
              child: Transform.rotate(
                angle: 0.6,
                child: Container(
                  width: 220,
                  height: 5,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ],

          if (_state.selectedEffect == EffectOption.drone) ...[
            const Positioned(
              top: 120,
              left: 80,
              child: Icon(Icons.airplanemode_active, color: Colors.white, size: 34),
            ),
            const Positioned(
              top: 105,
              right: 90,
              child: Icon(Icons.airplanemode_active, color: Colors.white, size: 34),
            ),
          ],

          if (_state.selectedEffect == EffectOption.fireworks) ...[
            const Positioned(
              top: 115,
              left: 75,
              child: Text('🎆', style: TextStyle(fontSize: 45)),
            ),
            const Positioned(
              top: 95,
              right: 85,
              child: Text('🎇', style: TextStyle(fontSize: 45)),
            ),
          ],

          // if (_state.selectedEffect != null)
          //   Positioned(
          //     bottom: 15,
          //     child: Text(
          //       'Effect: ${_effectOptionLabel(_state.selectedEffect!)}',
          //       style: const TextStyle(
          //         color: Colors.white70,
          //         fontSize: 16,
          //         fontWeight: FontWeight.w600,
          //       ),
          //     ),
          //   ),

          if (isOverloaded)
            Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  '⚠ POWER OVERLOAD ⚠',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

 Widget _buildRunningScreen() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 760;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildOptionCard(
                          title: 'Sound',
                          child: _buildSoundOptions(),
                        ),
                        _buildOptionCard(
                          title: 'Lighting',
                          child: _buildLightOptions(),
                        ),
                        _buildOptionCard(
                          title: 'Power Source',
                          child: _buildPowerOptions(),
                        ),
                        _buildOptionCard(
                          title: 'Effects',
                          child: _buildEffectOptions(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: _buildStageVisualArea(),
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      children: [
                        _buildLiveFeedbackPanel(),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _logic.canFinish(_state)
                                ? _finishRound
                                : null,
                            child: const Text('Finish Round'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildOptionCard(
                  title: 'Sound',
                  child: _buildSoundOptions(),
                ),
                _buildOptionCard(
                  title: 'Lighting',
                  child: _buildLightOptions(),
                ),
                _buildOptionCard(
                  title: 'Power Source',
                  child: _buildPowerOptions(),
                ),
                _buildOptionCard(
                  title: 'Effects',
                  child: _buildEffectOptions(),
                ),

                const SizedBox(height: 16),

                _buildStageVisualArea(),

                const SizedBox(height: 16),

                _buildLiveFeedbackPanel(),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _logic.canFinish(_state) ? _finishRound : null,
                    child: const Text('Finish Round'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4EF),
      appBar: AppBar(
        title: const Text(
          'Stage Setup Challenge',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildRunningScreen(),
    );
  }
}