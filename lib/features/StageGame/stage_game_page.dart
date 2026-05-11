import 'package:flutter/material.dart';
import '../../services/led_service.dart';
import 'stage_game_logic.dart';
import 'stage_game_models.dart';

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
  }

  void _startGame() {
    setState(() {
      _logic.start(_state);
    });
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
    _showEndDialog();
  }

  void _restartGame() {
    setState(() {
      _state = _logic.createInitialState();
      _logic.start(_state);
    });
  }

  void _showEndDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(_state.endCrowdReaction),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _state.endComment,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildScoreLine(
                label: 'Sustainability Score',
                value: _state.sustainabilityScore,
              ),
              _buildScoreLine(
                label: 'Stability Score',
                value: _state.stabilityScore,
              ),
              _buildScoreLine(
                label: 'Audience Satisfaction',
                value: _state.audienceSatisfactionScore,
              ),
              const SizedBox(height: 12),
              Text(
                _logic.stabilityLabel(_state.stabilityScore),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(_logic.sustainabilityLabel(_state.sustainabilityScore)),
              Text(_logic.audienceLabel(_state.audienceSatisfactionScore)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _state = _logic.createInitialState();
                });
              },
              child: const Text('Back to start'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              child: const Text('Play again'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreLine({
    required String label,
    required int value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
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

  Widget _buildIntroScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Stage Setup Challenge',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Build a stage that sounds good, looks good, and stays within the power limit.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Player 1 chooses the setup.\n'
                    'Player 2 reads the feedback and helps improve the stage.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Targets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('• Sound must be between 80 and 90 dB'),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('• Light must be between 70 and 85 intensity'),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('• Power must stay below the selected capacity'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _startGame,
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
              value:
                  '${_state.currentSoundDb.toStringAsFixed(0)} dB',
              feedback: _state.soundFeedback,
            ),
            const SizedBox(height: 8),
            _buildFeedbackRow(
              label: 'Light',
              value:
                  _state.currentLightIntensity.toStringAsFixed(0),
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

  Widget _buildScorePanel() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Current Scores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildScoreBar(
              label: 'Sustainability Score',
              value: _state.sustainabilityScore,
            ),
            const SizedBox(height: 10),
            _buildScoreBar(
              label: 'Stability Score',
              value: _state.stabilityScore,
            ),
            const SizedBox(height: 10),
            _buildScoreBar(
              label: 'Audience Satisfaction',
              value: _state.audienceSatisfactionScore,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBar({
    required String label,
    required int value,
  }) {
    final clamped = value.clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: $clamped'),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: clamped / 100,
          minHeight: 12,
          borderRadius: BorderRadius.circular(12),
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
          child: Column(
            children: [
              const Text(
                'Stage Setup Challenge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
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
                              _buildScorePanel(),
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
                      _buildScorePanel(),
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
            ],
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
        title: const Text('Stage Game'),
        centerTitle: true,
      ),
      body: _state.phase == StageGamePhase.intro
          ? _buildIntroScreen()
          : _buildRunningScreen(),
    );
  }
}