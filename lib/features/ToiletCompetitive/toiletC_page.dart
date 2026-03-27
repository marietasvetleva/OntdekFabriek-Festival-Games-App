import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'toiletC_movement.dart';

enum _TrashKind { good, bad }

enum _GamePhase { intro, running, finished }

class _TrashItem {
  _TrashItem({
    required this.id,
    required this.kind,
    required this.assetPath,
    required this.x,
    required this.y,
    required this.size,
    required this.fallSpeed,
  });

  final int id;
  final _TrashKind kind;
  final String assetPath;
  double x;
  double y;
  double size;
  double fallSpeed;
  int? draggedByPlayer;

  Rect get rect => Rect.fromLTWH(x, y, size, size);
}

/// Two-player competitive trash game.
class ToiletCompetitivePage extends StatefulWidget {
  const ToiletCompetitivePage({super.key});

  @override
  State<ToiletCompetitivePage> createState() => _ToiletCompetitivePageState();
}

class _ToiletCompetitivePageState extends State<ToiletCompetitivePage> {
  static const int _startHearts = 3;
  static const int _roundSeconds = 60;
  static const double _itemMinSize = 18;
  static const double _itemStartSize = 76;
  static const double _shrinkPerSecond = 10;
  static const double _goodPoints = 1;
  static const double _bucketWidth = 130;
  static const double _bucketHeight = 92;
  static const double _bucketBottomMargin = 24;

  // Swap these with your own assets.
  static const String _bgAsset = 'assets/ToiletCompetitive/bg.png';
  static const String _bucketAssetLeft = 'assets/ToiletCompetitive/bucket_left.png';
  static const String _bucketAssetRight =
      'assets/ToiletCompetitive/bucket_right.png';
  static const String _goodTrashAsset = 'assets/ToiletCompetitive/good_trash.png';
  static const String _badTrashAsset = 'assets/ToiletCompetitive/cigarette.png';

  // Free Mixkit URLs for quick testing.
  static const String _sfxGoodCatch =
      'https://assets.mixkit.co/active_storage/sfx/270/270-preview.mp3';
  static const String _sfxBadCatch =
      'https://assets.mixkit.co/active_storage/sfx/212/212-preview.mp3';
  static const String _sfxRoundEnd =
      'https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  final List<_TrashItem> _items = <_TrashItem>[];
  final Map<int, int> _pointerOwnerById = <int, int>{};
  int _idCounter = 0;

  _GamePhase _phase = _GamePhase.intro;
  int _timeLeft = _roundSeconds;
  int _playerOneHearts = _startHearts;
  int _playerTwoHearts = _startHearts;
  int _playerOneScore = 0;
  int _playerTwoScore = 0;

  Timer? _spawnTimer;
  Timer? _frameTimer;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() {
      _phase = _GamePhase.running;
      _timeLeft = _roundSeconds;
      _playerOneHearts = _startHearts;
      _playerTwoHearts = _startHearts;
      _playerOneScore = 0;
      _playerTwoScore = 0;
      _items.clear();
    });

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      setState(_spawnItem);
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      setState(() => _tick(16 / 1000));
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      setState(() {
        _timeLeft -= 1;
        if (_timeLeft <= 0) {
          _timeLeft = 0;
          _finishGame();
        }
      });
    });
  }

  void _tick(double dt) {
    final toRemove = <int>{};
    for (final item in _items) {
      if (item.draggedByPlayer == null) {
        item.size = nextSize(
          size: item.size,
          shrinkPerSecond: _shrinkPerSecond,
          dt: dt,
          minSize: _itemMinSize,
        );
      }

      if (item.size <= _itemMinSize) {
        toRemove.add(item.id);
      }
    }
    _items.removeWhere((item) => toRemove.contains(item.id));

    if (_playerOneHearts <= 0 || _playerTwoHearts <= 0) {
      _finishGame();
    }
  }

  void _spawnItem() {
    final size = MediaQuery.of(context).size;
    final playArea = _playArea(size);
    final spawnX = playArea.left + _random.nextDouble() * (playArea.width - 90);
    final spawnY = playArea.top + _random.nextDouble() * (playArea.height - 180);
    final isBad = _random.nextInt(6) == 0; // ~16%

    _items.add(
      _TrashItem(
        id: _idCounter++,
        kind: isBad ? _TrashKind.bad : _TrashKind.good,
        assetPath: isBad ? _badTrashAsset : _goodTrashAsset,
        x: spawnX,
        y: spawnY,
        size: _itemStartSize,
        fallSpeed: 0,
      ),
    );
  }

  void _finishGame() {
    if (_phase == _GamePhase.finished) return;
    _phase = _GamePhase.finished;
    _spawnTimer?.cancel();
    _frameTimer?.cancel();
    _countdownTimer?.cancel();
    _safePlaySfx(_sfxRoundEnd);
    _showResultDialog();
  }

  Future<void> _showResultDialog() async {
    if (!mounted) return;
    final winnerText = _winnerText();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return AlertDialog(
          title: const Text('Round klaar!'),
          content: Text(
            '$winnerText\n\nSpeler 1: $_playerOneScore\nSpeler 2: $_playerTwoScore',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(c).pop();
                if (mounted) {
                  setState(() => _phase = _GamePhase.intro);
                }
              },
              child: const Text('Opnieuw'),
            ),
          ],
        );
      },
    );
  }

  String _winnerText() {
    if (_playerOneHearts <= 0 && _playerTwoHearts > 0) return 'Speler 2 wint!';
    if (_playerTwoHearts <= 0 && _playerOneHearts > 0) return 'Speler 1 wint!';
    if (_playerOneScore > _playerTwoScore) return 'Speler 1 wint!';
    if (_playerTwoScore > _playerOneScore) return 'Speler 2 wint!';
    return 'Gelijkspel!';
  }

  Rect _playArea(Size size) {
    final arenaWidth = size.width * 0.72;
    final arenaHeight = size.height * 0.58;
    final left = (size.width - arenaWidth) / 2;
    final top = size.height * 0.19;
    return Rect.fromLTWH(left, top, arenaWidth, arenaHeight);
  }

  Rect _playerBucketRect(Size size, int player) {
    final y = size.height - _bucketBottomMargin - _bucketHeight;
    if (player == 1) {
      return Rect.fromLTWH(16, y, _bucketWidth, _bucketHeight);
    }
    return Rect.fromLTWH(size.width - _bucketWidth - 16, y, _bucketWidth, _bucketHeight);
  }

  _TrashItem? _hitTestItem(Offset globalPosition) {
    for (final item in _items.reversed) {
      if (item.rect.contains(globalPosition)) return item;
    }
    return null;
  }

  int? _playerFromPosition(Offset p, Size size) {
    if (p.dx < 0 || p.dx > size.width) return null;
    return p.dx < size.width / 2 ? 1 : 2;
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    if (_phase != _GamePhase.running) return;
    final player = _playerFromPosition(event.localPosition, size);
    if (player == null) return;
    _pointerOwnerById[event.pointer] = player;
    final item = _hitTestItem(event.localPosition);
    if (item == null) return;
    item.draggedByPlayer = player;
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    if (_phase != _GamePhase.running) return;
    final player = _pointerOwnerById[event.pointer];
    if (player == null) return;

    final dragging = _items.where((item) => item.draggedByPlayer == player);
    if (dragging.isEmpty) return;

    final fullDragArea = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final item in dragging) {
      final desired = Offset(
        event.localPosition.dx - (item.size / 2),
        event.localPosition.dy - (item.size / 2),
      );
      final clamped = clampDragPosition(
        desiredTopLeft: desired,
        itemSize: item.size,
        playArea: fullDragArea,
      );
      item.x = clamped.dx;
      item.y = clamped.dy;
    }
    setState(() {});
  }

  void _releaseDraggedItems({
    required int pointerId,
    required Size size,
  }) {
    if (_phase != _GamePhase.running) return;
    final player = _pointerOwnerById.remove(pointerId);
    if (player == null) return;

    final dropped = _items.where((item) => item.draggedByPlayer == player).toList();
    if (dropped.isEmpty) return;

    final p1Bucket = _playerBucketRect(size, 1);
    final p2Bucket = _playerBucketRect(size, 2);
    final toRemove = <int>{};

    for (final item in dropped) {
      item.draggedByPlayer = null;
      final owner = resolveBucketOwner(
        itemRect: item.rect,
        playerOneBucket: p1Bucket,
        playerTwoBucket: p2Bucket,
      );

      if (owner == null) continue;
      _applyCatch(owner: owner, kind: item.kind);
      toRemove.add(item.id);
    }

    setState(() {
      _items.removeWhere((item) => toRemove.contains(item.id));
    });
  }

  void _applyCatch({required int owner, required _TrashKind kind}) {
    if (kind == _TrashKind.good) {
      if (owner == 1) {
        _playerOneScore += _goodPoints.toInt();
      } else {
        _playerTwoScore += _goodPoints.toInt();
      }
      _safePlaySfx(_sfxGoodCatch);
      return;
    }

    if (owner == 1) {
      _playerOneHearts = max(0, _playerOneHearts - 1);
    } else {
      _playerTwoHearts = max(0, _playerTwoHearts - 1);
    }
    _safePlaySfx(_sfxBadCatch);
  }

  Future<void> _safePlaySfx(String assetPath) async {
    try {
      final isUrl = assetPath.startsWith('http://') || assetPath.startsWith('https://');
      if (isUrl) {
        await _audioPlayer.play(UrlSource(assetPath));
      } else {
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (_) {
      // Silent fallback while asset paths are still placeholders.
    }
  }

  Widget _imageOrFallback({
    required String path,
    required double width,
    required double height,
    required Color fallbackColor,
    BoxShape shape = BoxShape.rectangle,
  }) {
    return Image.asset(
      path,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: fallbackColor,
            shape: shape,
            borderRadius:
                shape == BoxShape.rectangle ? BorderRadius.circular(14) : null,
          ),
        );
      },
    );
  }

  Widget _hearts(int hearts) {
    return Row(
      children: List.generate(3, (i) {
        final alive = i < hearts;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            Icons.favorite,
            size: 28,
            color: alive ? const Color(0xFFE78AA0) : Colors.grey.shade400,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final playArea = _playArea(size);
    final p1Bucket = _playerBucketRect(size, 1);
    final p2Bucket = _playerBucketRect(size, 2);

    if (_phase == _GamePhase.intro) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F4F1),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Toilet Competitive',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Links = Speler 1, Rechts = Speler 2.\n'
                  'Sleep vallend afval naar je eigen emmer.\n'
                  'Sigaret in je emmer = 1 hart kwijt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDCEBD8),
                    foregroundColor: const Color(0xFF1E2A1F),
                  ),
                  child: const Text('Start ronde (60s)'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F1),
      body: SafeArea(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => _onPointerDown(event, size),
          onPointerMove: (event) => _onPointerMove(event, size),
          onPointerUp: (event) => _releaseDraggedItems(
            pointerId: event.pointer,
            size: size,
          ),
          onPointerCancel: (event) => _releaseDraggedItems(
            pointerId: event.pointer,
            size: size,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: _imageOrFallback(
                  path: _bgAsset,
                  width: size.width,
                  height: size.height,
                  fallbackColor: const Color(0xFFF1F0EA),
                ),
              ),
              Positioned(
                left: 20,
                top: 12,
                child: _hearts(_playerOneHearts),
              ),
              Positioned(
                right: 20,
                top: 12,
                child: _hearts(_playerTwoHearts),
              ),
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 180,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBD8),
                      border: Border.all(color: const Color(0xFF6E7A70)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '00:${_timeLeft.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1711),
                      ),
                    ),
                  ),
                ),
              ),
              // Play arena: trash is rendered and clipped only inside this zone.
              Positioned.fromRect(
                rect: playArea,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBD8).withOpacity(0.5),
                      border: Border.all(
                        color: const Color(0xFFB8CBB7),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Stack(
                      children: [
                        for (final item in _items)
                          if (item.draggedByPlayer == null)
                          Positioned(
                            left: item.x - playArea.left,
                            top: item.y - playArea.top,
                            child: _imageOrFallback(
                              path: item.assetPath,
                              width: item.size,
                              height: item.size,
                              fallbackColor: item.kind == _TrashKind.bad
                                  ? const Color(0xFFC88D7A)
                                  : const Color(0xFFDCD3A6),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Dragged items render above the arena so they remain visible
              // when players move them toward the bins outside the playfield.
              for (final item in _items)
                if (item.draggedByPlayer != null)
                  Positioned(
                    left: item.x,
                    top: item.y,
                    child: _imageOrFallback(
                      path: item.assetPath,
                      width: item.size,
                      height: item.size,
                      fallbackColor: item.kind == _TrashKind.bad
                          ? const Color(0xFFC88D7A)
                          : const Color(0xFFDCD3A6),
                      shape: BoxShape.circle,
                    ),
                  ),
              Positioned(
                left: p1Bucket.left,
                top: p1Bucket.top,
                child: _imageOrFallback(
                  path: _bucketAssetLeft,
                  width: p1Bucket.width,
                  height: p1Bucket.height,
                  fallbackColor: const Color(0xFFCFE7CF),
                ),
              ),
              Positioned(
                left: p2Bucket.left,
                top: p2Bucket.top,
                child: _imageOrFallback(
                  path: _bucketAssetRight,
                  width: p2Bucket.width,
                  height: p2Bucket.height,
                  fallbackColor: const Color(0xFFCFE7CF),
                ),
              ),
              Positioned(
                left: 24,
                bottom: 8,
                child: Text(
                  'P1: $_playerOneScore',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 8,
                child: Text(
                  'P2: $_playerTwoScore',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
