import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'toiletC_logic.dart';
import 'toiletC_models.dart';
import 'toiletC_movement.dart';

enum _GamePhase { intro, running, finished }

/// Screen-space layout for one spawned item (logic only stores id/type/ttl).
class _ItemLayout {
  _ItemLayout({required this.x, required this.y});

  double x;
  double y;
  int? draggedByPlayer;
}

/// Two-player competitive trash game.
class ToiletCompetitivePage extends StatefulWidget {
  const ToiletCompetitivePage({super.key});

  @override
  State<ToiletCompetitivePage> createState() => _ToiletCompetitivePageState();
}

class _ToiletCompetitivePageState extends State<ToiletCompetitivePage> {
  static const double _itemMinSize = 25;
  static const double _itemStartSize = 150;
  static const double _bucketWidth = 200;
  static const double _bucketHeight = 160;
  static const double _bucketAspect = _bucketWidth / _bucketHeight;
  static const double _arenaSideGapMin = 14;

  static const String _bgAsset = 'assets/ToiletCompetitive/bg.png';
  static const String _bucketAssetLeft = 'assets/ToiletCompetitive/bucket_left.png';
  static const String _bucketAssetRight = 'assets/ToiletCompetitive/bucket_right.png';
  static const String _cigaretteAsset =
      'assets/ToiletCompetitive/items/cigarette_bud.png';
  static const String _gumAsset = 'assets/ToiletCompetitive/items/gum.png';
  static const String _bananaPeelAsset =
      'assets/ToiletCompetitive/items/banana_peel.png';
  static const String _appleCoreAsset =
      'assets/ToiletCompetitive/items/apple_core.png';
  static const String _leafAsset = 'assets/ToiletCompetitive/items/leaf.png';
  static const String _metalCanAsset =
      'assets/ToiletCompetitive/items/metal_can.png';
  static const String _juiceBoxAsset =
      'assets/ToiletCompetitive/items/juice_box.png';
  static const String _waterBottleAsset =
      'assets/ToiletCompetitive/items/water_bottle.png';

  static const String _sfxGoodCatch =
      'https://assets.mixkit.co/active_storage/sfx/270/270-preview.mp3';
  static const String _sfxBadCatch =
      'https://assets.mixkit.co/active_storage/sfx/212/212-preview.mp3';
  static const String _sfxRoundEnd =
      'https://assets.mixkit.co/active_storage/sfx/1435/1435-preview.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ToiletCompetitiveLogic _logic = ToiletCompetitiveLogic();
  late ToiletCompetitiveState _gameState;

  final Map<String, _ItemLayout> _layouts = {};
  final Map<int, int> _pointerOwnerById = {};

  Timer? _frameTimer;

  _GamePhase _phase = _GamePhase.intro;

  @override
  void initState() {
    super.initState();
    _gameState = _logic.createInitialState();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() {
    _frameTimer?.cancel();
    setState(() {
      _phase = _GamePhase.running;
      _layouts.clear();
      _logic.start(_gameState);
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      final size = MediaQuery.sizeOf(context);
      final dt = 16 / 1000;
      setState(() {
        _logic.tick(_gameState, dt);
        _syncLayoutsForActiveItems(_playArea(size));
      });
      if (_gameState.finished) {
        _finishGame();
      }
    });
  }

  void _syncLayoutsForActiveItems(Rect playArea) {
    final activeIds = _gameState.activeItems.map((e) => e.id).toSet();
    _layouts.removeWhere((id, _) => !activeIds.contains(id));

    for (final item in _gameState.activeItems) {
      _layouts.putIfAbsent(item.id, () {
        final margin = max(0.0, playArea.width - _itemStartSize);
        final vmargin = max(0.0, playArea.height - _itemStartSize);
        final xNorm = item.spawnXNorm.clamp(0.0, 1.0);
        final yNorm = item.spawnYNorm.clamp(0.0, 1.0);
        return _ItemLayout(
          x: playArea.left + xNorm * margin,
          y: playArea.top + yNorm * vmargin,
        );
      });
    }
  }

  void _finishGame() {
    if (_phase == _GamePhase.finished) return;
    _phase = _GamePhase.finished;
    _frameTimer?.cancel();
    _safePlaySfx(_sfxRoundEnd);
    _showResultDialog();
  }

  Future<void> _showResultDialog() async {
    if (!mounted) return;
    final winnerText = _winnerText();
    final p1 = _gameState.players[CompetitivePlayerId.p1]!;
    final p2 = _gameState.players[CompetitivePlayerId.p2]!;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return AlertDialog(
          title: const Text('Round klaar!'),
          content: Text(
            '$winnerText\n\nSpeler 1: ${p1.score}\nSpeler 2: ${p2.score}',
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
    final p1 = _gameState.players[CompetitivePlayerId.p1]!;
    final p2 = _gameState.players[CompetitivePlayerId.p2]!;
    if (p1.lives <= 0 && p2.lives > 0) return 'Speler 2 wint!';
    if (p2.lives <= 0 && p1.lives > 0) return 'Speler 1 wint!';
    final w = _logic.winner(_gameState);
    if (w == CompetitivePlayerId.p1) return 'Speler 1 wint!';
    if (w == CompetitivePlayerId.p2) return 'Speler 2 wint!';
    return 'Gelijkspel!';
  }

  Size _bucketSize(Size screen) {
    // Keep buckets visually similar across phones/tablets and
    // independent from the arena so we can reserve horizontal space.
    final height = (screen.height * 0.34).clamp(190.0, 320.0).toDouble();
    final width = height * _bucketAspect;
    return Size(width, height);
  }

  double _arenaSideGap(Size screen) {
    // A small responsive gap between bucket and arena.
    return max(_arenaSideGapMin, screen.width * 0.02);
  }

  Rect _playArea(Size size) {
    final bucket = _bucketSize(size);
    final gap = _arenaSideGap(size);

    // Reserve horizontal space so buckets never overlap the arena.
    final left = bucket.width + gap;
    final right = size.width - bucket.width - gap;
    final arenaWidth = max(0.0, right - left);

    final arenaHeight = size.height * 0.66;
    final top = size.height * 0.18; // a bit lower under timer
    return Rect.fromLTWH(left, top, arenaWidth, arenaHeight);
  }

  Rect _playerBucketRect({
    required Size size,
    required Rect playArea,
    required int player,
  }) {
    // Buckets centered vertically on each side (like prototype).
    // Size is derived from the screen so we can guarantee spacing to the arena.
    final bucket = _bucketSize(size);
    final height = bucket.height;
    final width = bucket.width;

    final centerY = playArea.center.dy;
    final y = (centerY - height / 2).clamp(0.0, size.height - height);

    if (player == 1) {
      return Rect.fromLTWH(0, y, width, height);
    }
    return Rect.fromLTWH(size.width - width, y, width, height);
  }

  double _itemArtScaleForType(CompetitiveItemType type) {
    // Most sprites have extra transparent padding; scale them up a bit to feel tighter.
    // Banana has less padding, so keep it unscaled to avoid cropping.
    switch (type) {
      case CompetitiveItemType.bananaPeel:
        return 1.0;
      default:
        return 1.18;
    }
  }

  double _itemSizePixels(CompetitiveItemSpawn item) {
    return _logic.itemDisplaySizePixels(
      state: _gameState,
      item: item,
      maxSize: _itemStartSize,
      minSize: _itemMinSize,
    );
  }

  String _assetForType(CompetitiveItemType type) {
    switch (type) {
      case CompetitiveItemType.cigaretteBud:
        return _cigaretteAsset;
      case CompetitiveItemType.gum:
        return _gumAsset;
      case CompetitiveItemType.bananaPeel:
        return _bananaPeelAsset;
      case CompetitiveItemType.appleCore:
        return _appleCoreAsset;
      case CompetitiveItemType.leaf:
        return _leafAsset;
      case CompetitiveItemType.metalCan:
        return _metalCanAsset;
      case CompetitiveItemType.juiceBox:
        return _juiceBoxAsset;
      case CompetitiveItemType.waterBottle:
        return _waterBottleAsset;
    }
  }

  Color _bubbleColorForType(CompetitiveItemType type) {
    switch (_logic.wasteTypeForItem(type)) {
      case WasteType.organic:
        return const Color(0xFF7CCB63);
      case WasteType.recycling:
        return const Color(0xFF7DB7F4);
      case WasteType.unrecyclable:
        return const Color(0xFFC88D7A);
    }
  }

  Color _binTintFor(BinType binType) {
    switch (binType) {
      case BinType.organic:
        return const Color(0xFFAEDC9B);
      case BinType.recycling:
        return const Color(0xFFFFC16A);
    }
  }

  String _binLabelFor(BinType binType) {
    switch (binType) {
      case BinType.organic:
        return 'ORGANIC';
      case BinType.recycling:
        return 'RECYCLING';
    }
  }

  CompetitiveItemSpawn? _hitTestItem(Offset localPosition) {
    for (final item in _gameState.activeItems.reversed) {
      final layout = _layouts[item.id];
      if (layout == null) continue;
      final sz = _itemSizePixels(item);
      final rect = Rect.fromLTWH(layout.x, layout.y, sz, sz);
      if (rect.contains(localPosition)) return item;
    }
    return null;
  }

  int? _playerFromPosition(Offset p, Size size) {
    if (p.dx < 0 || p.dx > size.width) return null;
    return p.dx < size.width / 2 ? 1 : 2;
  }

  CompetitivePlayerId _bucketOwnerToPlayerId(int bucketOwner) {
    return bucketOwner == 1 ? CompetitivePlayerId.p1 : CompetitivePlayerId.p2;
  }

  void _onPointerDown(PointerDownEvent event, Size size) {
    if (_phase != _GamePhase.running) return;
    final player = _playerFromPosition(event.localPosition, size);
    if (player == null) return;
    _pointerOwnerById[event.pointer] = player;
    final spawn = _hitTestItem(event.localPosition);
    if (spawn == null) return;
    _layouts[spawn.id]?.draggedByPlayer = player;
  }

  void _onPointerMove(PointerMoveEvent event, Size size) {
    if (_phase != _GamePhase.running) return;
    final player = _pointerOwnerById[event.pointer];
    if (player == null) return;

    final fullScreen = Rect.fromLTWH(0, 0, size.width, size.height);
    for (final item in _gameState.activeItems) {
      final layout = _layouts[item.id];
      if (layout?.draggedByPlayer != player) continue;

      final sz = _itemSizePixels(item);
      final desired = Offset(
        event.localPosition.dx - sz / 2,
        event.localPosition.dy - sz / 2,
      );
      final clamped = clampDragPosition(
        desiredTopLeft: desired,
        itemSize: sz,
        playArea: fullScreen,
      );
      layout!.x = clamped.dx;
      layout.y = clamped.dy;
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

    final playArea = _playArea(size);
    final p1Bucket = _playerBucketRect(size: size, playArea: playArea, player: 1);
    final p2Bucket = _playerBucketRect(size: size, playArea: playArea, player: 2);

    for (final spawn in _gameState.activeItems.toList()) {
      final layout = _layouts[spawn.id];
      if (layout?.draggedByPlayer != player) continue;

      layout!.draggedByPlayer = null;
      final sz = _itemSizePixels(spawn);
      final itemRect = Rect.fromLTWH(layout.x, layout.y, sz, sz);
      final bucketOwner = resolveBucketOwner(
        itemRect: itemRect,
        playerOneBucket: p1Bucket,
        playerTwoBucket: p2Bucket,
      );
      if (bucketOwner == null) continue;

      final outcome = _logic.depositItem(
        state: _gameState,
        playerId: _bucketOwnerToPlayerId(bucketOwner),
        itemId: spawn.id,
      );
      switch (outcome) {
        case DepositOutcome.correct:
          _safePlaySfx(_sfxGoodCatch);
          break;
        case DepositOutcome.wrong:
          _safePlaySfx(_sfxBadCatch);
          break;
        case DepositOutcome.ignored:
          break;
      }
    }

    setState(() {
      _syncLayoutsForActiveItems(_playArea(size));
    });

    if (_gameState.finished) {
      _finishGame();
    }
  }

  Future<void> _safePlaySfx(String assetPath) async {
    try {
      final isUrl =
          assetPath.startsWith('http://') || assetPath.startsWith('https://');
      if (isUrl) {
        await _audioPlayer.play(UrlSource(assetPath));
      } else {
        await _audioPlayer.play(AssetSource(assetPath));
      }
    } catch (_) {}
  }

  Widget _imageOrFallback({
    required String path,
    required double width,
    required double height,
    required Color fallbackColor,
    BoxShape shape = BoxShape.rectangle,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    bool flipX = false,
  }) {
    final image = Image.asset(
      path,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
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

    if (shape == BoxShape.circle) {
      return ClipOval(
        child: Transform.scale(
          scale: 1.0,
          child: image,
        ),
      );
    }
    if (!flipX) return image;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: image,
    );
  }

  Widget _hearts(int lives) {
    final maxL = _logic.config.startLives;
    return Row(
      children: List.generate(maxL, (i) {
        final alive = i < lives;
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

  List<Widget> _itemWidgets() {
    final widgets = <Widget>[];

    for (final item in _gameState.activeItems) {
      final layout = _layouts[item.id];
      if (layout == null) continue;

      final sz = _itemSizePixels(item);
      final scale = _itemArtScaleForType(item.type);

      widgets.add(
        Positioned(
          left: layout.x,
          top: layout.y,
          child: Transform.scale(
            scale: scale,
            child: _imageOrFallback(
              path: _assetForType(item.type),
              width: sz,
              height: sz,
              fallbackColor: _bubbleColorForType(item.type),
              shape: BoxShape.circle,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final playArea = _playArea(size);
    final p1Bucket = _playerBucketRect(size: size, playArea: playArea, player: 1);
    final p2Bucket = _playerBucketRect(size: size, playArea: playArea, player: 2);
    final p1 = _gameState.players[CompetitivePlayerId.p1]!;
    final p2 = _gameState.players[CompetitivePlayerId.p2]!;
    final secsLeft = _logic.timeLeftSec(_gameState).ceil().clamp(0, 99999);

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
                  'Sleep afval naar je eigen emmer.\n'
                  'Foute bak of niet-recyclebaar afval = hart kwijt.',
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
                  child: Text(
                    'Start ronde (${_logic.config.gameDurationSec}s)',
                  ),
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
                child: _hearts(p1.lives),
              ),
              Positioned(
                right: 20,
                top: 12,
                child: _hearts(p2.lives),
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
                      '${(secsLeft ~/ 60).toString().padLeft(2, '0')}:'
                      '${(secsLeft % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F1711),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: playArea,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBD8).withValues(alpha: 0.5),
                      border: Border.all(
                        color: const Color(0xFFB8CBB7),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              ..._itemWidgets(),
              // Scores under the hearts near each side
              Positioned(
                left: 20,
                top: 12 + 28 + 8,
                child: Text(
                  'P1: ${p1.score}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2A1F),
                  ),
                ),
              ),
              // Buckets on top of everything
              Positioned(
                left: p1Bucket.left,
                top: p1Bucket.top,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _imageOrFallback(
                      path: _bucketAssetLeft,
                      width: p1Bucket.width,
                      height: p1Bucket.height,
                      fallbackColor: _binTintFor(p1.binType),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      flipX: false,
                    ),
                    Positioned(
                      top: 8,
                      child: Text(
                        _binLabelFor(p1.binType),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2A1F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: p2Bucket.left,
                top: p2Bucket.top,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _imageOrFallback(
                      path: _bucketAssetRight,
                      width: p2Bucket.width,
                      height: p2Bucket.height,
                      fallbackColor: _binTintFor(p2.binType),
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      flipX: false,
                    ),
                    Positioned(
                      top: 8,
                      child: Text(
                        _binLabelFor(p2.binType),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2A1F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                top: 12 + 28 + 8,
                child: Text(
                  'P2: ${p2.score}',
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