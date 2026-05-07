import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'toiletC_logic.dart';
import 'toiletC_models.dart';
import 'toiletC_movement.dart';

enum _GamePhase { intro, running, finished }
enum _DepositFxType { vacuum, reject }

class _ItemLayout {
  _ItemLayout({
    required this.x,
    required this.y,
  });

  double x;
  double y;
  int? draggedByPlayer;
  double? frozenSize;
}

class _DepositFx {
  _DepositFx({
    required this.id,
    required this.type,
    required this.assetPath,
    required this.fallbackColor,
    required this.startAtSec,
    required this.durationSec,
    required this.startCenter,
    required this.targetCenter,
    required this.endCenter,
    required this.baseSize,
    required this.artScale,
  });

  final String id;
  final _DepositFxType type;
  final String assetPath;
  final Color fallbackColor;
  final double startAtSec;
  final double durationSec;
  final Offset startCenter;
  final Offset targetCenter;
  final Offset endCenter;
  final double baseSize;
  final double artScale;
}

class ToiletCompetitivePage extends StatefulWidget {
  const ToiletCompetitivePage({super.key});

  @override
  State<ToiletCompetitivePage> createState() => _ToiletCompetitivePageState();
}

class _ToiletCompetitivePageState extends State<ToiletCompetitivePage> {
  static const double _itemMinSize = 110;
  static const double _itemStartSize = 135;
  static const double _spawnPopDurationSec = 0.24;
  static const double _spawnStartScale = 0.72;
  static const double _bucketWidth = 200;
  static const double _bucketHeight = 160;
  static const double _bucketAspect = _bucketWidth / _bucketHeight;
  static const double _arenaSideGapMin = 6;

  static const String _bucketAssetLeft = 'assets/ToiletCompetitive/bucket_left.png';
  static const String _bucketAssetRight = 'assets/ToiletCompetitive/bucket_right.png';
  static const String _cigaretteAsset =
      'assets/ToiletCompetitive/items/cigarette_bud.png';
  static const String _gumAsset = 'assets/ToiletCompetitive/items/gum.png';
  static const String _bananaPeelAsset =
      'assets/ToiletCompetitive/items/banana_peel.png';
  static const String _bananaSlightlyAgedAsset =
      'assets/ToiletCompetitive/items/slightly_aged_banana.png';
  static const String _bananaVeryAgedAsset =
      'assets/ToiletCompetitive/items/very_aged_banana.png';
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
  final List<_DepositFx> _depositFx = [];
  int _depositFxCounter = 0;

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
      _depositFx.clear();
      _logic.start(_gameState);
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      final size = MediaQuery.sizeOf(context);
      const dt = 16 / 1000;

      setState(() {
        _logic.tick(_gameState, dt);
        _syncLayoutsForActiveItems(_playArea(size));
        _pruneFinishedDepositFx();
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
    final shortestSide = min(screen.width, screen.height);
    final height = (shortestSide * 0.33).clamp(140.0, 300.0).toDouble();
    final width = height * _bucketAspect;
    return Size(width, height);
  }

  double _arenaSideGap(Size screen) {
    return max(_arenaSideGapMin, screen.width * 0.01);
  }

  Rect _playArea(Size size) {
    final bucket = _bucketSize(size);
    final gap = _arenaSideGap(size);

    final sideInset = bucket.width * 0.88 + gap;
    final left = sideInset;
    final right = size.width - sideInset;
    final arenaWidth = max(0.0, right - left);

    final arenaHeight = size.height * 0.66;
    final top = size.height * 0.18;

    return Rect.fromLTWH(left, top, arenaWidth, arenaHeight);
  }

  Rect _playerBucketRect({
    required Size size,
    required Rect playArea,
    required int player,
  }) {
    final bucket = _bucketSize(size);
    final height = bucket.height;
    final width = bucket.width;
    final edgeOverflow = min(18.0, width * 0.10);

    final centerY = playArea.center.dy;
    final y = (centerY - height / 2).clamp(0.0, size.height - height);

    if (player == 1) {
      return Rect.fromLTWH(-edgeOverflow, y, width, height);
    }

    return Rect.fromLTWH(size.width - width + edgeOverflow, y, width, height);
  }

  Rect _bucketCatchRect(Rect bucketRect) {
    final catchWidth = bucketRect.width * 0.15;
    final catchHeight = bucketRect.height * 0.12;

    final left = bucketRect.left + (bucketRect.width - catchWidth) / 2;
    final top = bucketRect.top + bucketRect.height * 0.40;

    return Rect.fromLTWH(left, top, catchWidth, catchHeight);
  }

  double _itemArtScaleForType(CompetitiveItemType type) {
    switch (type) {
      case CompetitiveItemType.bananaPeel:
        return 1.0;
      default:
        return 1.18;
    }
  }

  double _itemSizePixels(CompetitiveItemSpawn item) {
    final layout = _layouts[item.id];
    if (layout?.frozenSize != null) {
      return layout!.frozenSize!;
    }

    return _logic.itemDisplaySizePixels(
      state: _gameState,
      item: item,
      maxSize: _itemStartSize,
      minSize: _itemMinSize,
    );
  }

  Offset _rectCenter(Rect rect) {
    return Offset(rect.left + rect.width / 2, rect.top + rect.height / 2);
  }

  void _pruneFinishedDepositFx() {
    if (_depositFx.isEmpty) return;
    final now = _gameState.elapsedSec;
    _depositFx.removeWhere((fx) => now - fx.startAtSec >= fx.durationSec);
  }

  void _spawnDepositFx({
    required CompetitiveItemSpawn item,
    required Offset startCenter,
    required Offset targetCenter,
    required DepositOutcome outcome,
  }) {
    final now = _gameState.elapsedSec;
    final isCorrect = outcome == DepositOutcome.correct;
    final direction = (targetCenter - startCenter);
    final directionNorm = direction.distance <= 0.001
        ? const Offset(1, 0)
        : direction / direction.distance;
    final perpendicular = Offset(-directionNorm.dy, directionNorm.dx);
    final rejectEnd =
        targetCenter - (directionNorm * 96) + (perpendicular * 22);
    _depositFx.add(
      _DepositFx(
        id: 'fx_${_depositFxCounter++}',
        type: isCorrect ? _DepositFxType.vacuum : _DepositFxType.reject,
        assetPath: _assetForItem(item),
        fallbackColor: _bubbleColorForType(item.type),
        startAtSec: now,
        durationSec: isCorrect ? 0.24 : 0.30,
        startCenter: startCenter,
        targetCenter: targetCenter,
        endCenter: rejectEnd,
        baseSize: _itemSizePixels(item),
        artScale: _itemArtScaleForType(item.type),
      ),
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

  String _assetForItem(CompetitiveItemSpawn item) {
    if (item.type != CompetitiveItemType.bananaPeel) {
      return _assetForType(item.type);
    }

    // Bananas visibly age in 3 distinct steps across their lifetime.
    final progress = _logic.itemAgeProgress(_gameState, item);
    if (progress < 0.34) return _bananaPeelAsset;
    if (progress < 0.67) return _bananaSlightlyAgedAsset;
    return _bananaVeryAgedAsset;
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

    final layout = _layouts[spawn.id];
    if (layout == null) return;

    layout.draggedByPlayer = player;
    layout.frozenSize ??= _logic.itemDisplaySizePixels(
      state: _gameState,
      item: spawn,
      maxSize: _itemStartSize,
      minSize: _itemMinSize,
    );

    if (!spawn.isBeingHeld) {
      spawn.isBeingHeld = true;
      spawn.holdStartedAtSec = _gameState.elapsedSec;
    }
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
    final p1CatchRect = _bucketCatchRect(p1Bucket);
    final p2CatchRect = _bucketCatchRect(p2Bucket);

    for (final spawn in _gameState.activeItems.toList()) {
      final layout = _layouts[spawn.id];
      if (layout?.draggedByPlayer != player) continue;

      final sz = _itemSizePixels(spawn);
      final itemRect = Rect.fromLTWH(layout!.x, layout.y, sz, sz);
      final itemCenter = _rectCenter(itemRect);

      layout.draggedByPlayer = null;

      if (spawn.isBeingHeld && spawn.holdStartedAtSec != null) {
        spawn.totalHeldSec += _gameState.elapsedSec - spawn.holdStartedAtSec!;
      }
      spawn.isBeingHeld = false;
      spawn.holdStartedAtSec = null;

      final bucketOwner = resolveBucketOwner(
        itemRect: itemRect,
        playerOneBucket: p1CatchRect,
        playerTwoBucket: p2CatchRect,
      );

      if (bucketOwner == null) {
        layout.frozenSize = null;
        continue;
      }

      final outcome = _logic.depositItem(
        state: _gameState,
        playerId: _bucketOwnerToPlayerId(bucketOwner),
        itemId: spawn.id,
      );

      switch (outcome) {
        case DepositOutcome.correct:
          _safePlaySfx(_sfxGoodCatch);
          _spawnDepositFx(
            item: spawn,
            startCenter: itemCenter,
            targetCenter: bucketOwner == 1
                ? _rectCenter(p1CatchRect)
                : _rectCenter(p2CatchRect),
            outcome: outcome,
          );
          break;
        case DepositOutcome.wrong:
          _safePlaySfx(_sfxBadCatch);
          _spawnDepositFx(
            item: spawn,
            startCenter: itemCenter,
            targetCenter: bucketOwner == 1
                ? _rectCenter(p1CatchRect)
                : _rectCenter(p2CatchRect),
            outcome: outcome,
          );
          break;
        case DepositOutcome.ignored:
          break;
      }

      _layouts.remove(spawn.id);
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
      return ClipOval(child: image);
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

  Widget _binTimerPuck({
    required double progress,
    required int secsLeft,
    required double diameter,
  }) {
    final danger = progress < 0.25;
    final ringColor = Color.lerp(
      const Color(0xFFE46C6C),
      const Color(0xFF4FAE64),
      progress,
    )!;
    final ringSize = diameter * 0.84;
    final strokeWidth = (diameter * 0.10).clamp(7.0, 12.0);
    final fontSize = (diameter * 0.30).clamp(24.0, 38.0);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3ED),
        shape: BoxShape.circle,
        border: Border.all(
          color: danger ? const Color(0xFFA74747) : const Color(0xFF6E7A70),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: ringSize,
            height: ringSize,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              backgroundColor: const Color(0xFFD8DED4),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Text(
            '$secsLeft',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: danger ? const Color(0xFFA74747) : const Color(0xFF1E2A1F),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _itemWidgets() {
    final widgets = <Widget>[];

    for (final item in _gameState.activeItems) {
      final layout = _layouts[item.id];
      if (layout == null) continue;

      final sz = _itemSizePixels(item);
      final scale = _itemArtScaleForType(item.type);
      final activeAge = _logic.itemActiveAgeSec(_gameState, item);
      final popT = (activeAge / _spawnPopDurationSec).clamp(0.0, 1.0);
      final popScale =
          _spawnStartScale +
          (1.0 - _spawnStartScale) * Curves.easeOutBack.transform(popT);
      final spawnOpacity = Curves.easeOut.transform(popT);
      final phase = (item.id.hashCode % 360) * (pi / 180.0);
      final wobbleX = item.isBeingHeld
          ? 0.0
          : sin(_gameState.elapsedSec * 4.4 + phase) * 3.0;
      final wobbleY = item.isBeingHeld
          ? 0.0
          : cos(_gameState.elapsedSec * 3.5 + phase) * 2.0;

      widgets.add(
        Positioned(
          left: layout.x,
          top: layout.y,
          child: Transform.translate(
            offset: Offset(wobbleX, wobbleY),
            child: Opacity(
              opacity: spawnOpacity,
              child: Transform.scale(
                scale: scale * popScale,
                child: _imageOrFallback(
                  path: _assetForItem(item),
                  width: sz,
                  height: sz,
                  fallbackColor: _bubbleColorForType(item.type),
                  shape: BoxShape.circle,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _depositFxWidgets() {
    if (_depositFx.isEmpty) return const [];
    final now = _gameState.elapsedSec;
    final widgets = <Widget>[];

    for (final fx in _depositFx) {
      final t = ((now - fx.startAtSec) / fx.durationSec).clamp(0.0, 1.0);
      final isVacuum = fx.type == _DepositFxType.vacuum;
      late final Offset center;
      late final double scale;
      late final double opacity;
      late final double rotation;

      if (isVacuum) {
        final move = Curves.easeInCubic.transform(t);
        center = Offset.lerp(fx.startCenter, fx.targetCenter, move)!;
        scale = lerpDouble(1.0, 0.18, Curves.easeIn.transform(t))!;
        opacity = lerpDouble(1.0, 0.0, Curves.easeIn.transform(t))!;
        rotation = t * pi * 1.6;
      } else {
        // Wrong bin: impact + hard deflection away from bin.
        const hitPoint = 0.46;
        if (t < hitPoint) {
          final s = Curves.easeIn.transform((t / hitPoint).clamp(0.0, 1.0));
          center = Offset.lerp(fx.startCenter, fx.targetCenter, s)!;
          scale = 1.0;
          opacity = 1.0;
          rotation = 0.0;
        } else {
          final phase = ((t - hitPoint) / (1.0 - hitPoint)).clamp(0.0, 1.0);
          final s = Curves.easeOutCubic.transform(phase);
          center = Offset.lerp(fx.targetCenter, fx.endCenter, s)!;
          scale = lerpDouble(1.0, 0.76, Curves.easeOut.transform(phase))!;
          opacity = lerpDouble(1.0, 0.0, Curves.easeOut.transform(phase))!;
          rotation = lerpDouble(0.0, -pi * 0.22, Curves.easeOut.transform(phase))!;
        }
      }

      final fxSize = fx.baseSize * fx.artScale * scale;
      widgets.add(
        Positioned(
          left: center.dx - fxSize / 2,
          top: center.dy - fxSize / 2,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: rotation,
              child: _imageOrFallback(
                path: fx.assetPath,
                width: fxSize,
                height: fxSize,
                fallbackColor: fx.fallbackColor,
                shape: BoxShape.circle,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );

      if (isVacuum) {
        final ringScale = 0.75 + t * 0.95;
        final ringAlpha = (1 - t) * 0.95;
        widgets.add(
          Positioned(
            left: fx.targetCenter.dx - 28 * ringScale,
            top: fx.targetCenter.dy - 28 * ringScale,
            child: IgnorePointer(
              child: Opacity(
                opacity: ringAlpha.clamp(0.0, 1.0),
                child: Container(
                  width: 56 * ringScale,
                  height: 56 * ringScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xAA66CC7A),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        widgets.add(
          Positioned(
            left: fx.targetCenter.dx - 20 * ringScale,
            top: fx.targetCenter.dy - 20 * ringScale,
            child: IgnorePointer(
              child: Opacity(
                opacity: (ringAlpha * 0.9).clamp(0.0, 1.0),
                child: Container(
                  width: 40 * ringScale,
                  height: 40 * ringScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF42C763),
                      width: 3.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else if (t > 0.30 && t < 0.88) {
        final phase = ((t - 0.30) / 0.58).clamp(0.0, 1.0);
        final ringScale = 0.75 + phase * 0.95;
        final ringAlpha = ((1.0 - phase) * 0.95).clamp(0.0, 1.0);
        widgets.add(
          Positioned(
            left: fx.targetCenter.dx - 28 * ringScale,
            top: fx.targetCenter.dy - 28 * ringScale,
            child: IgnorePointer(
              child: Opacity(
                opacity: ringAlpha,
                child: Container(
                  width: 56 * ringScale,
                  height: 56 * ringScale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xAAC14848),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        widgets.add(
          Positioned(
            left: fx.targetCenter.dx - 20 * ringScale,
            top: fx.targetCenter.dy - 20 * ringScale,
            child: IgnorePointer(
              child: Opacity(
                opacity: (ringAlpha * 0.9).clamp(0.0, 1.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40 * ringScale,
                      height: 40 * ringScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFC14848),
                          width: 3.5,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.close_rounded,
                      size: 18 * ringScale,
                      color: const Color(0xFFC14848),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
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
    final timeLeft = _logic.timeLeftSec(_gameState);
    final secsLeft = timeLeft.ceil().clamp(0, 99999);
    final timerProgress = (timeLeft / _logic.config.gameDurationSec).clamp(
      0.0,
      1.0,
    );
    final timerDiameter = (size.shortestSide * 0.12).clamp(96.0, 120.0);

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
                child: Container(
                  color: const Color(0xFFF1F0EA),
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
                top: max(18.0, playArea.top - timerDiameter - 50.0),
                left: 0,
                right: 0,
                child: Center(
                  child: _binTimerPuck(
                    progress: timerProgress,
                    secsLeft: secsLeft,
                    diameter: timerDiameter,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: playArea,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCEBD8).withAlpha(128),
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
                  ],
                ),
              ),
              ..._itemWidgets(),
              ..._depositFxWidgets(),
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