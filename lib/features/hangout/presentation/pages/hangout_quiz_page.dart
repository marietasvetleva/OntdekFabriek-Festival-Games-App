import 'dart:math' as math;
import 'package:flutter/material.dart';

enum HangoutViewState {
  ready,
  playing,
  result,
  finished,
}

class HangoutAnswer {
  final String label;
  final String feedback;

  const HangoutAnswer({
    required this.label,
    required this.feedback,
  });
}

class HangoutQuestion {
  final String prompt;
  final List<HangoutAnswer> answers;
  final int correctIndex;
  final int seconds;
  final int points;

  const HangoutQuestion({
    required this.prompt,
    required this.answers,
    required this.correctIndex,
    this.seconds = 8,
    this.points = 10,
  });
}

class HangoutQuizPage extends StatefulWidget {
  final String festivalName;

  const HangoutQuizPage({
    super.key,
    this.festivalName = 'OntdekFabriek',
  });

  @override
  State<HangoutQuizPage> createState() => _HangoutQuizPageState();
}

class _HangoutQuizPageState extends State<HangoutQuizPage>
    with TickerProviderStateMixin {
  static const int _readySeconds = 5;
  static const int _maxPlantStage = 5;

  static const String _readyBackgroundAsset =
      'assets/hangout_redesign/backgrounds/ready_side_bg.png';
  static const String _quizBackgroundAsset =
      'assets/hangout_redesign/backgrounds/quiz_side_bg.png';

  final List<Color> _playerAccents = const [
    Color(0xFF2E6EA7),
    Color(0xFFD8612B),
  ];

  final List<Color> _ticketColors = const [
    Color(0xFFE5A53A),
    Color(0xFF97B858),
    Color(0xFF5B8ED7),
  ];

  final List<String> _playerNames = const ['PLAYER 1', 'PLAYER 2'];

  final math.Random _random = math.Random();

  late final AnimationController _phaseController;
  late final AnimationController _orbitController;

  final List<HangoutQuestion> _questions = const [
    HangoutQuestion(
      prompt: 'How are you getting\nto the festival?',
      correctIndex: 2,
      answers: [
        HangoutAnswer(
          label: 'By car\nwith friends',
          feedback:
              'Cars still create CO₂ and pollution, even when multiple people share the ride.',
        ),
        HangoutAnswer(
          label: 'By public\ntransport',
          feedback:
              'Public transport is better than cars because many people share one vehicle.',
        ),
        HangoutAnswer(
          label: 'By bike\nor walking',
          feedback:
              'No pollution, healthier for you, and the most sustainable way to travel.',
        ),
      ],
    ),
    HangoutQuestion(
      prompt: 'What should you do\nwith a cigarette butt?',
      correctIndex: 0,
      answers: [
        HangoutAnswer(
          label: 'Put it in a pocket\nashtray or cigarette bin',
          feedback:
              'This keeps toxic waste out of the ground and helps keep the festival clean.',
        ),
        HangoutAnswer(
          label: 'Ignore it,\nit is just one',
          feedback:
              'Even one cigarette butt pollutes the area and can harm nature and animals.',
        ),
        HangoutAnswer(
          label: 'Push it into the\nsoil with your shoe',
          feedback:
              'That still leaves pollution behind and is harmful for the environment.',
        ),
      ],
    ),
    HangoutQuestion(
      prompt: 'Your water bottle is empty.\nWhat is the best choice?',
      correctIndex: 1,
      answers: [
        HangoutAnswer(
          label: 'Buy a new\nplastic bottle',
          feedback:
              'Single-use plastic creates extra waste and is not the best eco option.',
        ),
        HangoutAnswer(
          label: 'Refill your reusable\nbottle',
          feedback:
              'Refilling reduces plastic waste and is the smartest sustainable choice.',
        ),
        HangoutAnswer(
          label: 'Throw the bottle away\nand wait',
          feedback:
              'Throwing it away creates waste and does not help reduce festival litter.',
        ),
      ],
    ),
    HangoutQuestion(
      prompt: 'You finished your snack.\nWhat now?',
      correctIndex: 2,
      answers: [
        HangoutAnswer(
          label: 'Drop the wrapper\nnext to a bench',
          feedback:
              'Litter stays in the environment and makes the festival dirty.',
        ),
        HangoutAnswer(
          label: 'Leave it on the table\nfor someone else',
          feedback:
              'Someone else should not have to clean up your waste.',
        ),
        HangoutAnswer(
          label: 'Sort it in the\ncorrect bin',
          feedback:
              'Sorting waste correctly helps recycling and keeps the grounds clean.',
        ),
      ],
    ),
    HangoutQuestion(
      prompt: 'You are leaving the hangout area.\nWhat is the best final action?',
      correctIndex: 1,
      answers: [
        HangoutAnswer(
          label: 'Leave fast and let the\nstaff handle it',
          feedback:
              'Leaving your mess for others is not a sustainable festival habit.',
        ),
        HangoutAnswer(
          label: 'Take your waste and\ncheck the area',
          feedback:
              'A quick final check keeps the space clean and helps everyone after you.',
        ),
        HangoutAnswer(
          label: 'Hide your trash\nunder the table',
          feedback:
              'Hidden trash still pollutes and creates extra cleaning work.',
        ),
      ],
    ),
  ];

  HangoutViewState _viewState = HangoutViewState.ready;

  int _roundIndex = 0;
  List<int> _scores = [0, 0];
  List<int> _plantStages = [0, 0];
  List<int?> _selectedAnswerIndices = [null, null];
  List<bool> _confirmedResult = [false, false];
  List<PlayerRoundResult> _roundResults = const [];

  late List<int> _optionOrder;
  double _baseOrbitAngle = 0;
  bool _roundClosed = false;

  HangoutQuestion get _currentQuestion => _questions[_roundIndex];

  @override
  void initState() {
    super.initState();

    _phaseController = AnimationController(vsync: this)
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_viewState == HangoutViewState.ready) {
            _startRoundPhase();
          } else if (_viewState == HangoutViewState.playing) {
            _finishRound();
          }
        }
      });

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _optionOrder = [0, 1, 2];
    _startReadyPhase();
  }

  @override
  void dispose() {
    _phaseController.dispose();
    _orbitController.dispose();
    super.dispose();
  }

  int get _readyTimeLeft {
    final remaining = (_readySeconds - (_phaseController.value * _readySeconds))
        .ceil()
        .clamp(0, _readySeconds);
    return remaining;
  }

  int get _roundTimeLeft {
    final total = _currentQuestion.seconds;
    final remaining =
        (total - (_phaseController.value * total)).ceil().clamp(0, total);
    return remaining;
  }

  double get _phaseRemainingProgress => 1 - _phaseController.value;

  void _startReadyPhase() {
    _roundClosed = false;
    _selectedAnswerIndices = [null, null];
    _confirmedResult = [false, false];
    _roundResults = const [];
    _phaseController
      ..stop()
      ..duration = const Duration(seconds: _readySeconds);

    setState(() {
      _viewState = HangoutViewState.ready;
    });

    _phaseController.forward(from: 0);
  }

  void _startRoundPhase() {
    _roundClosed = false;
    _selectedAnswerIndices = [null, null];
    _confirmedResult = [false, false];
    _roundResults = const [];

    _optionOrder = [0, 1, 2]..shuffle(_random);
    _baseOrbitAngle = _random.nextDouble() * math.pi * 2;

    _phaseController
      ..stop()
      ..duration = Duration(seconds: _currentQuestion.seconds);

    setState(() {
      _viewState = HangoutViewState.playing;
    });

    _phaseController.forward(from: 0);
  }

  void _onAnswerTap({
    required int playerIndex,
    required int answerIndex,
  }) {
    if (_viewState != HangoutViewState.playing) return;
    if (_selectedAnswerIndices[playerIndex] != null) return;

    setState(() {
      _selectedAnswerIndices[playerIndex] = answerIndex;
    });

    if (_selectedAnswerIndices.every((item) => item != null)) {
      _finishRound();
    }
  }

  void _finishRound() {
    if (_roundClosed) return;
    _roundClosed = true;

    _phaseController.stop();

    final results = List<PlayerRoundResult>.generate(
      2,
      _buildPlayerResult,
    );

    for (int player = 0; player < 2; player++) {
      if (results[player].isCorrect) {
        _scores[player] += _currentQuestion.points;
        _plantStages[player] =
            math.min(_plantStages[player] + 1, _maxPlantStage);
      }
    }

    setState(() {
      _roundResults = results;
      _viewState = HangoutViewState.result;
    });
  }

  PlayerRoundResult _buildPlayerResult(int playerIndex) {
    final selectedIndex = _selectedAnswerIndices[playerIndex];

    if (selectedIndex == _currentQuestion.correctIndex) {
      final nextStage = math.min(_plantStages[playerIndex] + 1, _maxPlantStage);

      return PlayerRoundResult(
        isCorrect: true,
        title: 'Great choice!',
        lines: [
          _currentQuestion.answers[selectedIndex!].feedback,
          nextStage >= _maxPlantStage
              ? 'Your plant reaches its final bloom.'
              : 'Your plant grows to the next stage.',
        ],
        points: _currentQuestion.points,
        buttonLabel: 'Continue',
      );
    }

    if (selectedIndex == null) {
      return PlayerRoundResult(
        isCorrect: false,
        title: 'Oops!',
        lines: [
          'Time is up. No answer was selected.',
          'The best choice was "${_currentQuestion.answers[_currentQuestion.correctIndex].label.replaceAll('\n', ' ')}".',
        ],
        points: 0,
        buttonLabel: 'Try again',
      );
    }

    return PlayerRoundResult(
      isCorrect: false,
      title: 'Oops!',
      lines: [
        _currentQuestion.answers[selectedIndex].feedback,
        'Your plant stops growing this round.',
      ],
      points: 0,
      buttonLabel: 'Try again',
    );
  }

  void _confirmPlayerResult(int playerIndex) {
    if (_viewState != HangoutViewState.result) return;
    if (_confirmedResult[playerIndex]) return;

    setState(() {
      _confirmedResult[playerIndex] = true;
    });

    if (_confirmedResult.every((item) => item)) {
      final isFinalRound = _roundIndex >= _questions.length - 1;
      final hasFullBloom = _plantStages.any((stage) => stage >= _maxPlantStage);

      if (isFinalRound || hasFullBloom) {
        setState(() {
          _viewState = HangoutViewState.finished;
        });
      } else {
        _roundIndex += 1;
        _startReadyPhase();
      }
    }
  }

  void _restartGame() {
    setState(() {
      _roundIndex = 0;
      _scores = [0, 0];
      _plantStages = [0, 0];
      _selectedAnswerIndices = [null, null];
      _confirmedResult = [false, false];
      _roundResults = const [];
      _viewState = HangoutViewState.ready;
    });

    _startReadyPhase();
  }

  int? _winnerIndex() {
    if (_plantStages[0] > _plantStages[1]) return 0;
    if (_plantStages[1] > _plantStages[0]) return 1;
    if (_scores[0] > _scores[1]) return 0;
    if (_scores[1] > _scores[0]) return 1;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_viewState == HangoutViewState.finished) {
      return Scaffold(
        backgroundColor: const Color(0xFF22362F),
        body: SafeArea(
          child: _FinishedScreen(
            festivalName: widget.festivalName,
            winnerIndex: _winnerIndex(),
            playerNames: _playerNames,
            playerColors: _playerAccents,
            scores: _scores,
            plantStages: _plantStages,
            onRestart: _restartGame,
            onExit: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF22362F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _buildSide(
                  playerIndex: 0,
                  mirror: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSide(
                  playerIndex: 1,
                  mirror: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSide({
    required int playerIndex,
    required bool mirror,
  }) {
    switch (_viewState) {
      case HangoutViewState.ready:
        return _buildReadySide(playerIndex: playerIndex, mirror: mirror);
      case HangoutViewState.playing:
      case HangoutViewState.result:
        return _buildRoundSide(playerIndex: playerIndex, mirror: mirror);
      case HangoutViewState.finished:
        return const SizedBox.shrink();
    }
  }

  Widget _buildReadySide({
    required int playerIndex,
    required bool mirror,
  }) {
    final accent = _playerAccents[playerIndex];

    return _BoardShell(
      backgroundAssetPath: _readyBackgroundAsset,
      mirrorBackground: mirror,
      fallbackTint: accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: 22,
                left: 22,
                right: 22,
                child: Center(
                  child: _TopInfoPill(
                    label:
                        '${widget.festivalName} • Round ${_roundIndex + 1}/${_questions.length}',
                  ),
                ),
              ),
              Align(
                alignment:
                    mirror ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _VerticalTimerRail(
                    progress: _phaseRemainingProgress,
                    secondsText: _readyTimeLeft.toString(),
                    accent: accent,
                    mirror: mirror,
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(mirror ? -80 : 80, 0),
                  child: RotatedBox(
                    quarterTurns: mirror ? 1 : 3,
                    child: Text(
                      '${_playerNames[playerIndex]} TURN',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: accent.withOpacity(0.95),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.55),
                        border: Border.all(
                          color: accent,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.18),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        size: 64,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PlayerRibbon(
                      label: _playerNames[playerIndex],
                      color: accent,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Get ready...',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: accent.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoundSide({
    required int playerIndex,
    required bool mirror,
  }) {
    final accent = _playerAccents[playerIndex];
    final selectedIndex = _selectedAnswerIndices[playerIndex];
    final isResultVisible = _viewState == HangoutViewState.result;

    return _BoardShell(
      backgroundAssetPath: _quizBackgroundAsset,
      mirrorBackground: mirror,
      fallbackTint: accent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final ringSize = math.min(size.width, size.height) * 0.44;
          final answerWidth = math.min(180.0, size.width * 0.34);
          const answerHeight = 60.0;
          final orbitRadius = math.min(size.width, size.height) * 0.29;
          final center = Offset(size.width / 2, size.height / 2.1);
          final orbitOffset = _orbitController.value * math.pi * 2 * 0.16;

          return Stack(
            children: [
              Positioned(
                top: 18,
                left: mirror ? null : 20,
                right: mirror ? 20 : null,
                child: _ScoreBadge(
                  label: _playerNames[playerIndex],
                  score: _scores[playerIndex],
                  accent: accent,
                ),
              ),
              Positioned(
                bottom: 18,
                left: mirror ? 18 : null,
                right: mirror ? null : 18,
                child: _PlantPreview(
                  stage: _plantStages[playerIndex],
                  accent: accent,
                ),
              ),
              for (int slot = 0; slot < _optionOrder.length; slot++)
                Builder(
                  builder: (context) {
                    final answerIndex = _optionOrder[slot];
                    final angle = _baseOrbitAngle +
                        orbitOffset +
                        (slot * ((math.pi * 2) / _optionOrder.length));

                    double x =
                        center.dx + math.cos(angle) * orbitRadius - answerWidth / 2;
                    double y =
                        center.dy + math.sin(angle) * orbitRadius - answerHeight / 2;

                    x = x.clamp(20.0, size.width - answerWidth - 20.0);
                    y = y.clamp(64.0, size.height - answerHeight - 24.0);

                    if (mirror) {
                      x = size.width - answerWidth - x;
                    }

                    final rotation = mirror
                        ? -_ticketRotationForSlot(slot)
                        : _ticketRotationForSlot(slot);

                    return Positioned(
                      left: x,
                      top: y,
                      width: answerWidth,
                      height: answerHeight,
                      child: _FloatingAnswerTicket(
                        label: _currentQuestion.answers[answerIndex].label,
                        fillColor: _ticketColors[slot % _ticketColors.length],
                        selected: selectedIndex == answerIndex,
                        enabled: !isResultVisible && selectedIndex == null,
                        rotation: rotation,
                        onTap: () => _onAnswerTap(
                          playerIndex: playerIndex,
                          answerIndex: answerIndex,
                        ),
                      ),
                    );
                  },
                ),
              Align(
                child: SizedBox(
                  width: ringSize,
                  height: ringSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(ringSize),
                        painter: _TimerRingPainter(
                          progress: _viewState == HangoutViewState.playing
                              ? _phaseController.value
                              : 1,
                        ),
                      ),
                      Container(
                        width: ringSize * 0.66,
                        height: ringSize * 0.66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF7EEDC).withOpacity(0.97),
                          border: Border.all(
                            color: const Color(0xFFA58B64),
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            _currentQuestion.prompt,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              height: 1.15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5B4B37),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: mirror ? null : 8,
                        right: mirror ? 8 : null,
                        child: _TimerCoin(
                          value: _viewState == HangoutViewState.playing
                              ? _roundTimeLeft.toString()
                              : '0',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isResultVisible)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: _ResultPopup(
                      result: _roundResults[playerIndex],
                      accent: accent,
                      plantStage: _plantStages[playerIndex],
                      confirmed: _confirmedResult[playerIndex],
                      onPressed: () => _confirmPlayerResult(playerIndex),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  double _ticketRotationForSlot(int slot) {
    switch (slot) {
      case 0:
        return -0.10;
      case 1:
        return 0.06;
      default:
        return 0.10;
    }
  }
}

class PlayerRoundResult {
  final bool isCorrect;
  final String title;
  final List<String> lines;
  final int points;
  final String buttonLabel;

  const PlayerRoundResult({
    required this.isCorrect,
    required this.title,
    required this.lines,
    required this.points,
    required this.buttonLabel,
  });
}

class _BoardShell extends StatelessWidget {
  final String backgroundAssetPath;
  final bool mirrorBackground;
  final Color fallbackTint;
  final Widget child;

  const _BoardShell({
    required this.backgroundAssetPath,
    required this.mirrorBackground,
    required this.fallbackTint,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEADCC0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF2F4E47),
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.flip(
              flipX: mirrorBackground,
              child: Image.asset(
                backgroundAssetPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _FallbackBackground(tint: fallbackTint);
                },
              ),
            ),
            Container(
              color: Colors.white.withOpacity(0.06),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF6D614C).withOpacity(0.5),
                  width: 2,
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  final Color tint;

  const _FallbackBackground({
    required this.tint,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF8EFD9),
            const Color(0xFFEAD9B5),
            tint.withOpacity(0.15),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _PaperTexturePainter(),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (index) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFFE5A53A),
                      const Color(0xFF97B858),
                      const Color(0xFF5B8ED7),
                    ][index % 3],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x0F6B5A46);
    final random = math.Random(4);

    for (int i = 0; i < 160; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.6 + 0.4;
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TopInfoPill extends StatelessWidget {
  final String label;

  const _TopInfoPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEDC).withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF9A8560),
          width: 2,
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5A4A37),
        ),
      ),
    );
  }
}

class _PlayerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PlayerRibbon({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _VerticalTimerRail extends StatelessWidget {
  final double progress;
  final String secondsText;
  final Color accent;
  final bool mirror;

  const _VerticalTimerRail({
    required this.progress,
    required this.secondsText,
    required this.accent,
    required this.mirror,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 290,
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EEDC),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF76634B),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 24,
              color: Color(0xFF5A4A37),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: 34,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7EEDC).withOpacity(0.96),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFF76634B),
                  width: 2,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: progress.clamp(0, 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF7EEDC),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF76634B),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                secondsText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A4A37),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int score;
  final Color accent;

  const _ScoreBadge({
    required this.label,
    required this.score,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEDC).withOpacity(0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent,
          width: 2.5,
        ),
      ),
      child: Text(
        '$label • $score pts',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _PlantPreview extends StatelessWidget {
  final int stage;
  final Color accent;

  const _PlantPreview({
    required this.stage,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final path = 'assets/hangout_redesign/plants/plant_stage_$stage.png';

    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: const Color(0xFFF7EEDC).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withOpacity(0.85),
          width: 2.5,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.local_florist_rounded,
                  size: 48,
                  color: accent,
                );
              },
            ),
          ),
          Text(
            'Stage $stage/5',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerCoin extends StatelessWidget {
  final String value;

  const _TimerCoin({
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFE79D2F),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFF7EEDC),
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FloatingAnswerTicket extends StatelessWidget {
  final String label;
  final Color fillColor;
  final bool selected;
  final bool enabled;
  final double rotation;
  final VoidCallback onTap;

  const _FloatingAnswerTicket({
    required this.label,
    required this.fillColor,
    required this.selected,
    required this.enabled,
    required this.rotation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: AnimatedScale(
        scale: selected ? 1.06 : 1,
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: fillColor.withOpacity(enabled ? 0.96 : 0.70),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF4C3928)
                      : Colors.white.withOpacity(0.90),
                  width: selected ? 3 : 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF533F2A),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultPopup extends StatelessWidget {
  final PlayerRoundResult result;
  final Color accent;
  final int plantStage;
  final bool confirmed;
  final VoidCallback onPressed;

  const _ResultPopup({
    required this.result,
    required this.accent,
    required this.plantStage,
    required this.confirmed,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        result.isCorrect ? const Color(0xFF8BB35B) : const Color(0xFFD76358);

    final buttonColor =
        result.isCorrect ? const Color(0xFF8BB35B) : const Color(0xFFD76358);

    final plantAsset =
        'assets/hangout_redesign/plants/plant_stage_$plantStage.png';

    return Container(
      width: 350,
      constraints: const BoxConstraints(minHeight: 250),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF8ED),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: borderColor,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7EEDC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF9A8560),
                    width: 2,
                  ),
                ),
                child: Text(
                  result.points == 0
                      ? '0 Points'
                      : '+${result.points} Points',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF5A4A37),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final line in result.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: borderColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5A4A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: confirmed ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: buttonColor.withOpacity(0.55),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    confirmed ? 'Waiting...' : result.buttonLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 86,
                height: 86,
                child: Image.asset(
                  plantAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.local_florist_rounded,
                      size: 56,
                      color: accent,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;

  const _TimerRingPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );

    const colors = [
      Color(0xFFE59F39),
      Color(0xFFD8BE5C),
      Color(0xFF8AB05A),
    ];

    const gap = 0.14;
    final totalSweep = (math.pi * 2) - (gap * 3);
    final segmentSweep = totalSweep / 3;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    double start = -math.pi / 2;

    for (final color in colors) {
      basePaint.color = color.withOpacity(0.36);
      canvas.drawArc(rect, start, segmentSweep, false, basePaint);
      start += segmentSweep + gap;
    }

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF6E8C43);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2) * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _FinishedScreen extends StatelessWidget {
  final String festivalName;
  final int? winnerIndex;
  final List<String> playerNames;
  final List<Color> playerColors;
  final List<int> scores;
  final List<int> plantStages;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  const _FinishedScreen({
    required this.festivalName,
    required this.winnerIndex,
    required this.playerNames,
    required this.playerColors,
    required this.scores,
    required this.plantStages,
    required this.onRestart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final winnerText =
        winnerIndex == null ? 'It is a draw!' : '${playerNames[winnerIndex!]} wins!';

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1100),
        margin: const EdgeInsets.all(18),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7EEDC),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF6D614C),
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              festivalName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C684F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hangout Challenge Complete',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F3F2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              winnerText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF7E9F4D),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: List.generate(
                2,
                (index) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 0 : 8,
                      right: index == 0 ? 8 : 0,
                    ),
                    child: _PlayerSummaryCard(
                      playerName: playerNames[index],
                      accent: playerColors[index],
                      score: scores[index],
                      stage: plantStages[index],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onRestart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8AB05A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                OutlinedButton(
                  onPressed: onExit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F3F2E),
                    side: const BorderSide(
                      color: Color(0xFF6D614C),
                      width: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerSummaryCard extends StatelessWidget {
  final String playerName;
  final Color accent;
  final int score;
  final int stage;

  const _PlayerSummaryCard({
    required this.playerName,
    required this.accent,
    required this.score,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final path = 'assets/hangout_redesign/plants/plant_stage_$stage.png';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent,
          width: 2.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            playerName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.local_florist_rounded,
                  size: 86,
                  color: accent,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Score: $score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4F3F2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Plant stage: $stage/5',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6E5C45),
            ),
          ),
        ],
      ),
    );
  }
}