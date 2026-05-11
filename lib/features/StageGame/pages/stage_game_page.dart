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

  Widget _buildRunningScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
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