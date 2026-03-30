import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../services/led_service.dart';
import '../../../../home_page.dart';
import '../../data/eco_question.dart';
import '../widgets/animated_garden.dart';

class HangoutQuizPage extends StatefulWidget {
  const HangoutQuizPage({super.key});

  @override
  State<HangoutQuizPage> createState() => _HangoutQuizPageState();
}

class _HangoutQuizPageState extends State<HangoutQuizPage>
    with SingleTickerProviderStateMixin {
  final List<EcoQuestion> _questions = const [
    EcoQuestion(
      text: 'How are you getting to the festival?',
      options: [
        'By car with friends',
        'By public transport',
        'By bike or walking',
      ],
      ecoOptionIndex: 2,
    ),
    EcoQuestion(
      text: 'What do you do with your empty drink cup?',
      options: [
        'Leave it on the grass for staff to pick up',
        'Return it to the bar for recycling',
        'Throw it in a random bin.',
      ],
      ecoOptionIndex: 1,
    ),
    EcoQuestion(
      text: 'How do you charge your phone?',
      options: [
        'Plug into a random staff-only socket.',
        'I dont charge it at all',
        'Use the shared solar charging station.',
      ],
      ecoOptionIndex: 2,
    ),
    EcoQuestion(
      text: 'How do you keep the hangout area chill?',
      options: [
        'Sing and shout over the music all the time.',
        'Talk to your friends and enjoy the music',
        'Blast your own speaker loudly next to people relaxing.',
      ],
      ecoOptionIndex: 1,
    ),
    EcoQuestion(
      text: 'You see a cigarette butt on the ground. What do you do?',
      options: [
        'Put it in a pocket ashtray or cigarette bin.',
        'Ignore it, it\'s just one.',
        'Push it into the soil with your shoe.',
      ],
      ecoOptionIndex: 0,
    ),
    EcoQuestion(
      text: 'Snack time! What do you choose?',
      options: [
        'Take food and throw half away.',
        'Many tiny snacks, each wrapped in plastic.',
        'Food with minimal or reusable packaging.',
      ],
      ecoOptionIndex: 2,
    ),
    EcoQuestion(
      text: 'How do you light the hangout area at night?',
      options: [
        'Leave all lights on even when nobody is there.',
        'Use cosy LED string lights powered by solar power.',
        'Use big old floodlights',
      ],
      ecoOptionIndex: 1,
    ),
    EcoQuestion(
      text: 'You are leaving the hangout park. What do you do?',
      options: [
        'Hide trash under the grass or behind trees.',
        'Leave cups and blankets behind for cleaners.',
        'Take your things, sort waste and leave it clean.',
      ],
      ecoOptionIndex: 2,
    ),
  ];

  int _currentIndex = 0;
  int _gardenStage = 0;
  bool _showIntro = true;
  bool _muted = false;
  int _ecoScore = 0;
  int _comfortScore = 0;

  late final AnimationController _ecoPulseCtrl;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _ecoPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    LedService.markMinigameOpened('hangout');
  }

  @override
  void dispose() {
    _ecoPulseCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _goBackToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MyHomePage(festivalName: 'EcoFest'),
      ),
      (route) => false,
    );
  }

  Future<void> _playSfx(String fileName) async {
    if (_muted) return;

    try {
      await _audioPlayer.play(AssetSource('audio/$fileName'));
    } catch (_) {}
  }

  void _playStageSound() {
    final s = _gardenStage.clamp(1, 8);

    switch (s) {
      case 1:
        _playSfx('grass.mp3');
        break;
      case 2:
        _playSfx('blooming.mp3');
        break;
      case 3:
        _playSfx('bubbles.mp3');
        break;
      case 4:
        _playSfx('bees.mp3');
        break;
      case 5:
        _playSfx('droplet.mp3');
        break;
      case 6:
        _playSfx('glow.mp3');
        break;
      case 7:
        _playSfx('twinkle.mp3');
        break;
      case 8:
        _playSfx('music.mp3');
        break;
      default:
        break;
    }
  }

  void _onOptionSelected(int optionIndex) {
    final question = _questions[_currentIndex];
    final bool isEco = optionIndex == question.ecoOptionIndex;

    setState(() {
      if (isEco) {
        _ecoScore += 2;
        _comfortScore += 1;
        _gardenStage++;
      } else {
        _ecoScore -= 1;
      }

      if (_currentIndex < _questions.length - 1) {
        _currentIndex++;
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return _buildEndDialog();
          },
        );
      }
    });

    if (isEco) {
      _playStageSound();
    }
  }

  Widget _buildEndDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF4E6A4B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Thanks!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _summaryMessage(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: const Color(0xFF2E4A2A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
              onPressed: () async {
                final score = _calculateScore();

                try {
                  await LedService.completeMinigame('hangout', score);
                } catch (e) {
                  debugPrint('Error registering hangout score: $e');
                }

                _goBackToMain();
              },
              child: const Text(
                "Back to main page",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateScore() {
    final rawScore = (_ecoScore / 16.0) * 5.0;
    final finalScore = (rawScore.ceil()).clamp(1, 5);
    return finalScore;
  }

  Widget _buildIntro() {
    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF4E6A4B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Welcome to the Hangout Area!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "For each eco-friendly choice,\nwatch the garden bloom 🌿",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showIntro = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: const Color(0xFF2E4A2A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Start",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryMessage() {
    return 'Your eco choices helped the hangout garden grow! 🌿\n\n'
        'Eco Score: $_ecoScore\n'
        'Comfort Score: $_comfortScore\n\n'
        'At real festivals, small actions like sorting waste, using clean '
        'transport and keeping the park tidy make the hangout area calmer, '
        'cleaner and more fun for everyone.';
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.black.withOpacity(0.20),
          title: const Text(
            'Hangout Park Eco Quiz',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
              onPressed: () {
                setState(() {
                  _muted = !_muted;
                });
                if (_muted) _audioPlayer.stop();
              },
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50), Color(0xFF81C784)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: _buildIntro(),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.black.withOpacity(0.20),
        title: const Text(
          'Hangout Park Eco Quiz',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
            onPressed: () {
              setState(() => _muted = !_muted);
              if (_muted) _audioPlayer.stop();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth.clamp(600.0, 900.0);
              final cardHeight = (constraints.maxHeight * 0.90).clamp(
                650.0,
                790.0,
              );

              return Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                      Color(0xFF81C784),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth,
                      maxHeight: cardHeight,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: cardHeight * 0.56,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: AnimatedGarden(stage: _gardenStage),
                                    ),
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _muted = !_muted);
                                          if (_muted) _audioPlayer.stop();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.35),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _muted
                                                ? Icons.volume_off
                                                : Icons.volume_up,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Question ${_currentIndex + 1} of ${_questions.length}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                question.text,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(
                                    question.options.length,
                                    (index) {
                                      final text = question.options[index];
                                      final ecoIdx = question.ecoOptionIndex;
                                      final isEco = index == ecoIdx;

                                      return Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 3,
                                          ),
                                          child: InkWell(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            onTap: () => _onOptionSelected(index),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 160,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 18,
                                                vertical: 10,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                                color: isEco
                                                    ? Colors.greenAccent
                                                        .withOpacity(0.12)
                                                    : Colors.black
                                                        .withOpacity(0.22),
                                                border: Border.all(
                                                  color: isEco
                                                      ? Colors.greenAccent
                                                          .withOpacity(0.9)
                                                      : Colors.white24,
                                                  width: isEco ? 2.0 : 1.2,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  if (isEco)
                                                    AnimatedBuilder(
                                                      animation: _ecoPulseCtrl,
                                                      builder: (context, child) {
                                                        final t =
                                                            _ecoPulseCtrl.value;
                                                        final scaleY =
                                                            1 +
                                                                sin(
                                                                      t *
                                                                          2 *
                                                                          pi,
                                                                    ) *
                                                                    0.25;
                                                        return Transform.scale(
                                                          scaleY: scaleY,
                                                          child: Container(
                                                            width: 8,
                                                            height: double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                4,
                                                              ),
                                                              color: Colors
                                                                  .greenAccent
                                                                  .shade400,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  else
                                                    Container(
                                                      width: 6,
                                                      height: double.infinity,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          4,
                                                        ),
                                                        color: Colors.white
                                                            .withOpacity(0.35),
                                                      ),
                                                    ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Text(
                                                      text,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}