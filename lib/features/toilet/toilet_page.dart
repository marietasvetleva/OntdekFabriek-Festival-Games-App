import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../CompostCatchGame.dart';
import '../../services/led_service.dart';
import '../../ui_styles.dart';
import 'toilet_logic.dart';

/// UI layer for Toilet game: rendering, timers, and dialogs only.
class ToiletGamePage extends StatefulWidget {
  const ToiletGamePage({super.key});

  @override
  State<ToiletGamePage> createState() => _ToiletGamePageState();
}

class _ToiletGamePageState extends State<ToiletGamePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ToiletGameLogic _logic = ToiletGameLogic();

  Timer? _feedbackTimer;
  Timer? _gameTimer;
  Timer? _spawnTimer;
  late final state = _logic.createInitialState();

  @override
  void initState() {
    super.initState();

    for (final s in _logic.specs) {
      rootBundle
          .load(s.asset)
          .then((_) => debugPrint('FOUND: ${s.asset}'))
          .catchError((e) => debugPrint('MISSING: ${s.asset} -> $e'));
    }
    rootBundle.load('assets/ToiletImage/Bucket.png');
    rootBundle.load('assets/ToiletImage/Sun.png');
    rootBundle.load('assets/ToiletImage/Cloud.png');

    LedService.markMinigameOpened('toilet');
  }

  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _screenHeight => MediaQuery.of(context).size.height;

  /// Starts a fresh round and boots spawn/update timers.
  void _startGame() {
    if (!mounted) return;
    setState(() {
      _logic.startGame(state);
    });

    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!state.isRunning || !mounted) return;
      setState(() {
        _logic.fillEmptySlots(state);
      });
    });

    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!state.isRunning || !mounted) return;
      _updateGame(16 / 1000);
    });
  }

  /// Runs one frame update by delegating gameplay decisions to logic.
  void _updateGame(double dt) {
    setState(() {
      final completePoints = _logic.tick(
        state: state,
        dt: dt,
        screenWidth: _screenWidth,
        screenHeight: _screenHeight,
      );

      if (state.feedbackMessage != null) {
        _audioPlayer.play(AssetSource('ToiletImage/GoodToilet.mp3'));
        _feedbackTimer?.cancel();
        _feedbackTimer = Timer(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              state.feedbackMessage = null;
            });
          }
        });
      }

      if (completePoints != null) {
        _completeGame(completePoints);
      }
    });
  }

  /// Sends score to backend and shows completion dialog.
  Future<void> _completeGame(int points) async {
    if (!mounted) return;
    _audioPlayer.play(AssetSource('ToiletImage/WinToilet.mp3'));

    final cappedPoints = points.clamp(0, 5);
    try {
      await LedService.completeMinigame('toilet', cappedPoints);
    } catch (e) {
      debugPrint('Error registering toilet score: $e');
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Je hebt gewonnen!'),
        content: Text('Goed gedaan! +$cappedPoints punten'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(c).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _feedbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (state.showIntro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toilet Game')),
        backgroundColor: const Color.fromARGB(255, 139, 210, 142),
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tap de vakjes bovenin om items te laten vallen!\n\n'
                      'Vang de juiste spullen met je emmer.\n\n'
                      'Als je 3x foute dingen vangt ben je af',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: kStartButtonStyle,
                      onPressed: _startGame,
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompostCatchGame()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(60, 30),
                ),
                child: const Text('Secret', style: TextStyle(fontSize: 10)),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Toilet Catch')),
      backgroundColor: const Color.fromARGB(255, 135, 206, 235),
      body: Stack(
        children: [
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 80,
                height: 80,
                child: Image.asset(
                  'assets/ToiletImage/Sun.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 120,
            child: SizedBox(
              width: 100,
              height: 60,
              child: Image.asset(
                'assets/ToiletImage/Cloud.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            right: 120,
            top: 140,
            child: SizedBox(
              width: 100,
              height: 60,
              child: Image.asset(
                'assets/ToiletImage/Cloud.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: SizedBox(
              height: ToiletGameLogic.slotHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(ToiletGameLogic.numSlots, (i) {
                  return Listener(
                    onPointerDown: (_) => setState(() {
                      _logic.onSlotTapped(
                        state: state,
                        slotIndex: i,
                        screenWidth: _screenWidth,
                      );
                    }),
                    child: Container(
                      width: ToiletGameLogic.slotWidth,
                      height: ToiletGameLogic.slotHeight,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        border: Border.all(color: Colors.brown, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: state.slots[i] != null
                          ? Image.asset(
                              state.slots[i]!.spec.asset,
                              fit: BoxFit.contain,
                            )
                          : const SizedBox(),
                    ),
                  );
                }),
              ),
            ),
          ),
          for (final it in state.items)
            Positioned(
              left: it.x,
              top: it.y,
              child: SizedBox(
                width: it.size,
                height: it.size,
                child: Image.asset(it.spec.asset, fit: BoxFit.contain),
              ),
            ),
          Positioned(
            left: state.bucketX,
            top: state.bucketY,
            child: Listener(
              onPointerMove: (details) {
                setState(() {
                  _logic.moveBucketBy(
                    state: state,
                    deltaX: details.delta.dx,
                    screenWidth: _screenWidth,
                  );
                });
              },
              child: SizedBox(
                width: ToiletGameLogic.bucketWidth,
                height: 80,
                child: Image.asset('assets/ToiletImage/Bucket.png'),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final alive = i < state.hearts;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.favorite,
                      color: alive ? Colors.red : Colors.grey.shade400,
                      size: 28,
                    ),
                  );
                }),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 100,
            child: Container(
              width: 60,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.brown.shade200,
                border: Border.all(color: Colors.brown.shade800, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    height:
                        (400 - 8) * (state.itemsCaught / ToiletGameLogic.targetToFill),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade600,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 510,
            child: Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                '${state.itemsCaught}/${ToiletGameLogic.targetToFill}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
