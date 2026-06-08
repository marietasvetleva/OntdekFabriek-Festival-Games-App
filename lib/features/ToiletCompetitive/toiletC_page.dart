import 'dart:async';
import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'toiletC_arena_layout.dart';
import 'toiletC_arena_layout_editor.dart';
import 'toiletC_arena_layout_tune.dart';
import 'toiletC_arena_scene.dart';
import 'toiletC_item_sprite.dart';
import 'toiletC_logic.dart';
import 'toiletC_models.dart';
import 'toiletC_movement.dart';
import 'toiletC_world_fx.dart';

enum _GamePhase { intro, running, results }
enum _DepositFxType { vacuum, reject }
enum _WorldFxKind { missed, score }
enum _PlayerRoundResult { win, lose, draw }

class _ItemLayout {
  _ItemLayout({
    required this.x,
    required this.y,
  });

  double x;
  double y;
  int? draggedByPlayer;
  double? frozenSize;
  String? frozenAssetPath;
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
    required this.baseRotationRad,
    required this.flipX,
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
  final double baseRotationRad;
  final bool flipX;
}

class _WorldFx {
  _WorldFx({
    required this.id,
    required this.kind,
    required this.center,
    required this.startAtSec,
    required this.durationSec,
    this.baseSize = 120,
  });

  final String id;
  final _WorldFxKind kind;
  final Offset center;
  final double startAtSec;
  final double durationSec;
  final double baseSize;
}

class _FestivalTicketPainter extends CustomPainter {
  _FestivalTicketPainter({
    required this.baseColor,
    this.goldStripe = true,
    this.crackProgress = 0.0,
  });

  final Color baseColor;
  final bool goldStripe;
  final double crackProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w * 0.14;
    final notchR = w * 0.09;

    final body = Path()
      ..moveTo(r, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, h * 0.38 - notchR)
      ..arcToPoint(Offset(w, h * 0.38 + notchR),
          radius: Radius.circular(notchR), clockwise: false)
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: Radius.circular(r))
      ..lineTo(0, h * 0.38 + notchR)
      ..arcToPoint(Offset(0, h * 0.38 - notchR),
          radius: Radius.circular(notchR), clockwise: false)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..close();

    canvas.drawPath(body, Paint()..color = baseColor);

    canvas.drawPath(
      body,
      Paint()
        ..color = baseColor.computeLuminance() > 0.5
            ? Colors.black26
            : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    if (goldStripe) {
      canvas.save();
      canvas.clipPath(body);
      final stripeY = h * 0.34;
      final stripeH = h * 0.20;
      canvas.drawRect(
        Rect.fromLTWH(0, stripeY, w, stripeH),
        Paint()..color = const Color(0xFFD4A537),
      );
      _drawStar(canvas, Offset(w / 2, stripeY + stripeH / 2), stripeH * 0.38);
      canvas.restore();
    }

    if (crackProgress > 0) {
      _drawCrack(canvas, size);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final oA = -pi / 2 + i * 2 * pi / 5;
      final iA = oA + pi / 5;
      final op = Offset(c.dx + r * cos(oA), c.dy + r * sin(oA));
      final ip = Offset(c.dx + r * 0.4 * cos(iA), c.dy + r * 0.4 * sin(iA));
      if (i == 0) {
        path.moveTo(op.dx, op.dy);
      } else {
        path.lineTo(op.dx, op.dy);
      }
      path.lineTo(ip.dx, ip.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFF8DC));
  }

  void _drawCrack(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final h = size.height;
    final crack = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + 2, h * 0.14)
      ..lineTo(cx - 3, h * 0.28)
      ..lineTo(cx + 2.5, h * 0.46)
      ..lineTo(cx - 2, h * 0.62)
      ..lineTo(cx + 1.5, h * 0.78)
      ..lineTo(cx, h);
    canvas.drawPath(
      crack,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.7 * crackProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _FestivalTicketPainter old) =>
      old.baseColor != baseColor ||
      old.goldStripe != goldStripe ||
      old.crackProgress != crackProgress;
}

class _HalfClipper extends CustomClipper<Rect> {
  _HalfClipper({required this.left});
  final bool left;

  @override
  Rect getClip(Size size) => left
      ? Rect.fromLTWH(0, 0, size.width / 2, size.height)
      : Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);

  @override
  bool shouldReclip(covariant _HalfClipper old) => old.left != left;
}

class _AnimatedTicketLife extends StatefulWidget {
  const _AnimatedTicketLife({
    super.key,
    required this.alive,
    required this.binColor,
    required this.fallLeft,
  });

  static const double ticketWidth = 28;

  final bool alive;
  final Color binColor;
  final bool fallLeft;

  @override
  State<_AnimatedTicketLife> createState() => _AnimatedTicketLifeState();
}

class _AnimatedTicketLifeState extends State<_AnimatedTicketLife>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _dying = false;
  bool _dead = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          setState(() {
            _dying = false;
            _dead = true;
          });
        }
      });
    if (!widget.alive) _dead = true;
  }

  @override
  void didUpdateWidget(covariant _AnimatedTicketLife old) {
    super.didUpdateWidget(old);
    if (!old.alive && widget.alive) {
      _dying = false;
      _dead = false;
      _ctrl.reset();
    } else if (old.alive && !widget.alive && !_dying) {
      _dying = true;
      _dead = false;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = _AnimatedTicketLife.ticketWidth;
    final h = w * 1.3;

    if (_dead && !_dying) {
      return SizedBox(width: w, height: h);
    }

    if (!_dying) {
      return SizedBox(
        width: w,
        height: h,
        child: CustomPaint(
          painter: _FestivalTicketPainter(
            baseColor: widget.binColor,
            goldStripe: true,
          ),
        ),
      );
    }

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = _ctrl.value;

          if (t <= 0.35) {
            final pt = t / 0.35;
            final shake = sin(pt * 6 * pi) * (1 - pt) * 3.0;
            final crack = Curves.easeIn.transform(pt);
            return Transform.translate(
              offset: Offset(shake, 0),
              child: CustomPaint(
                size: Size(w, h),
                painter: _FestivalTicketPainter(
                  baseColor: widget.binColor,
                  goldStripe: true,
                  crackProgress: crack,
                ),
              ),
            );
          }

          final pt = ((t - 0.35) / 0.65).clamp(0.0, 1.0);
          final eased = Curves.easeInCubic.transform(pt);
          final dir = widget.fallLeft ? -1.0 : 1.0;
          final fade = (1.0 - Curves.easeIn.transform(pt)).clamp(0.0, 1.0);

          Widget halfPiece({required bool left}) {
            final dx = dir * eased * w * (left ? 0.7 : 1.1);
            final dy = eased * w * (left ? 0.4 : 0.6);
            final rot = dir * eased * (left ? -0.35 : 0.45);
            return Positioned.fill(
              child: Transform(
                alignment:
                    left ? Alignment.centerRight : Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..translate(dx, dy)
                  ..rotateZ(rot),
                child: Opacity(
                  opacity: fade,
                  child: ClipRect(
                    clipper: _HalfClipper(left: left),
                    child: CustomPaint(
                      size: Size(w, h),
                      painter: _FestivalTicketPainter(
                        baseColor: widget.binColor,
                        goldStripe: true,
                        crackProgress: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              halfPiece(left: true),
              halfPiece(left: false),
            ],
          );
        },
      ),
    );
  }
}

class ToiletCompetitivePage extends StatefulWidget {
  const ToiletCompetitivePage({super.key});

  @override
  State<ToiletCompetitivePage> createState() => _ToiletCompetitivePageState();
}

class _ToiletCompetitivePageState extends State<ToiletCompetitivePage> {
  static const double _itemMinSize = 120;
  static const double _itemStartSize = 148;
  static const double _spawnPopDurationSec = 0.42;
  static const double _spawnSettleDurationSec = 0.55;
  static const double _spawnStartScale = 0.68;
  static const String _bucketAssetLeft = 'assets/ToiletCompetitive/bucket_left.png';
  static const String _bucketAssetRight = 'assets/ToiletCompetitive/bucket_right.png';
  /// Bundled assets — Mixkit preview URLs fail on Flutter web (format error).
  static const String _sfxGoodCatch = 'trashGame/audio/binnedTrash.mp3';
  static const String _sfxBadCatch = 'trashGame/audio/appear.mp3';
  static const String _sfxRoundEnd = 'ToiletImage/WinToilet.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ToiletCompetitiveLogic _logic = ToiletCompetitiveLogic();
  late ToiletCompetitiveState _gameState;

  final Map<String, _ItemLayout> _layouts = {};
  final Map<int, int> _pointerOwnerById = {};
  final List<_DepositFx> _depositFx = [];
  final List<_WorldFx> _worldFx = [];
  int _depositFxCounter = 0;
  int _worldFxCounter = 0;
  double _p1BucketBump = 0;
  double _p2BucketBump = 0;

  Timer? _frameTimer;
  Timer? _countdownTimer;

  _GamePhase _phase = _GamePhase.intro;
  bool _p1Ready = false;
  bool _p2Ready = false;
  int? _countdown;
  ArenaLayoutTune? _layoutTune;
  bool _layoutEditorEnabled = false;

  /// Hot-reload on web can leave this unset when State fields change.
  ArenaLayoutTune get _effectiveLayoutTune =>
      _layoutTune ??= ArenaLayoutTune.defaults();

  @override
  void initState() {
    super.initState();
    _layoutTune = ArenaLayoutTune.defaults();
    _gameState = _logic.createInitialState();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _countdownTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _beginCountdown() {
    if (_countdown != null) return;
    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _countdown! - 1;
      if (next <= 0) {
        timer.cancel();
        setState(() => _countdown = null);
        _startGame();
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  void _startGame() {
    _frameTimer?.cancel();
    setState(() {
      _phase = _GamePhase.running;
      _layouts.clear();
      _depositFx.clear();
      _worldFx.clear();
      _p1BucketBump = 0;
      _p2BucketBump = 0;
      _logic.start(_gameState);
    });

    _frameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted || _phase != _GamePhase.running) return;
      final size = MediaQuery.sizeOf(context);
      const dt = 16 / 1000;

      setState(() {
        final prevIds = _gameState.activeItems.map((e) => e.id).toSet();
        _logic.tick(_gameState, dt);
        for (final id in prevIds) {
          if (_gameState.activeItems.any((e) => e.id == id)) continue;
          final layout = _layouts[id];
          if (layout == null) continue;
          final sz = layout.frozenSize ?? _itemStartSize;
          _spawnMissedItemFx(center: _itemCenter(layout, sz), baseSize: sz);
        }
        _syncLayoutsForActiveItems(_playArea(size));
        _pruneFinishedDepositFx();
        _pruneWorldFx();
        _decayBucketBumps(dt);
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
    if (_phase == _GamePhase.results) return;
    _frameTimer?.cancel();
    _safePlaySfx(_sfxRoundEnd);
    setState(() => _phase = _GamePhase.results);
  }

  _PlayerRoundResult _roundResultFor(CompetitivePlayerId playerId) {
    final winner = _logic.winner(_gameState);
    if (winner == null) return _PlayerRoundResult.draw;
    return winner == playerId
        ? _PlayerRoundResult.win
        : _PlayerRoundResult.lose;
  }

  void _returnToIntroLobby() {
    _countdownTimer?.cancel();
    setState(() {
      _phase = _GamePhase.intro;
      _p1Ready = false;
      _p2Ready = false;
      _countdown = null;
      _layouts.clear();
      _depositFx.clear();
      _worldFx.clear();
      _p1BucketBump = 0;
      _p2BucketBump = 0;
      _gameState = _logic.createInitialState();
    });
  }

  Widget _buildResultsScreen() {
    final p1 = _gameState.players[CompetitivePlayerId.p1]!;
    final p2 = _gameState.players[CompetitivePlayerId.p2]!;

    // Full width (same as intro) — rotated sides need half-screen width as
    // their layout height; a narrow card causes bottom overflow.
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F1),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: const Color(0xFF2D3A2E),
              child: const Text(
                'Round complete',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFF4F4F1),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _resultPlayerSide(
                      color: const Color(0xFFAEDC9B),
                      bgGradient: const [
                        Color(0xFFE8F5E3),
                        Color(0xFFC8E6C0),
                      ],
                      quarterTurns: 1,
                      result: _roundResultFor(CompetitivePlayerId.p1),
                      player: p1,
                      opponent: p2,
                      onPlayAgain: _returnToIntroLobby,
                    ),
                  ),
                  Container(width: 2, color: const Color(0xFFB8C5B0)),
                  Expanded(
                    child: _resultPlayerSide(
                      color: const Color(0xFFFFC16A),
                      bgGradient: const [
                        Color(0xFFFFF3E0),
                        Color(0xFFFFE0B2),
                      ],
                      quarterTurns: 3,
                      result: _roundResultFor(CompetitivePlayerId.p2),
                      player: p2,
                      opponent: p1,
                      onPlayAgain: _returnToIntroLobby,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultPlayerSide({
    required Color color,
    required List<Color> bgGradient,
    required int quarterTurns,
    required _PlayerRoundResult result,
    required CompetitivePlayerState player,
    required CompetitivePlayerState opponent,
    required VoidCallback onPlayAgain,
  }) {
    final headline = switch (result) {
      _PlayerRoundResult.win => 'YOU WIN!',
      _PlayerRoundResult.lose => 'YOU LOSE',
      _PlayerRoundResult.draw => "IT'S A DRAW",
    };

    final subtitle = switch (result) {
      _PlayerRoundResult.win => 'You sorted better this round.',
      _PlayerRoundResult.lose => 'Your opponent took this round.',
      _PlayerRoundResult.draw => 'Same score — nobody edged ahead.',
    };

    final headlineColor = switch (result) {
      _PlayerRoundResult.win => const Color(0xFF2A6B32),
      _PlayerRoundResult.lose => const Color(0xFF8A4A4A),
      _PlayerRoundResult.draw => const Color(0xFF4A5A6B),
    };

    final badgeIcon = switch (result) {
      _PlayerRoundResult.win => Icons.emoji_events_rounded,
      _PlayerRoundResult.lose => Icons.sentiment_dissatisfied_rounded,
      _PlayerRoundResult.draw => Icons.handshake_rounded,
    };

    final badgeBg = switch (result) {
      _PlayerRoundResult.win => const Color(0xFF3A8B44),
      _PlayerRoundResult.lose => const Color(0xFF9A6A6A),
      _PlayerRoundResult.draw => const Color(0xFF6A7A88),
    };

    Widget statTile(String label, String value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF5A5A5A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2A1F),
            ),
          ),
        ],
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: badgeBg,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: badgeBg.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(badgeIcon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: headlineColor,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: Color(0xFF4A4A4A),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: 280,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: statTile('Your score', '${player.score}')),
                  Expanded(
                    child: statTile('Sorted right', '${player.correct}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: statTile('Mistakes', '${player.wrong}')),
                  Expanded(
                    child: statTile('Passes left', '${player.lives}'),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: Color(0xFFD0D8D0)),
              ),
              statTile('Opponent score', '${opponent.score}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 280,
          child: FilledButton(
            onPressed: onPlayAgain,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: const Color(0xFF1E2A1F),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'Play again',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGradient,
        ),
      ),
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: content,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Rect _playArea(Size size) => ToiletCompetitiveArenaLayout.playArea(size);

  Rect _playerBucketRect({required Size size, required int player}) {
    return ToiletCompetitiveArenaLayout.playerBucketRect(
      screen: size,
      player: player,
      tune: _effectiveLayoutTune,
    );
  }

  Rect _bucketCatchRect(Rect bucketRect, int player) {
    return ToiletCompetitiveArenaLayout.bucketCatchRect(
      bucketRect,
      player,
      _effectiveLayoutTune,
    );
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

  void _pruneWorldFx() {
    if (_worldFx.isEmpty) return;
    final now = _gameState.elapsedSec;
    _worldFx.removeWhere((fx) => now - fx.startAtSec >= fx.durationSec);
  }

  void _decayBucketBumps(double dt) {
    _p1BucketBump = max(0, _p1BucketBump - dt * 4.2);
    _p2BucketBump = max(0, _p2BucketBump - dt * 4.2);
  }

  void _pulseBucket(int bucketOwner) {
    if (bucketOwner == 1) {
      _p1BucketBump = 1;
    } else {
      _p2BucketBump = 1;
    }
  }

  void _spawnMissedItemFx({
    required Offset center,
    required double baseSize,
  }) {
    final now = _gameState.elapsedSec;
    _worldFx.add(
      _WorldFx(
        id: 'miss_${_worldFxCounter++}',
        kind: _WorldFxKind.missed,
        center: center,
        startAtSec: now,
        durationSec: 0.55,
        baseSize: baseSize,
      ),
    );
  }

  void _spawnScorePopupFx({required Offset center}) {
    final now = _gameState.elapsedSec;
    _worldFx.add(
      _WorldFx(
        id: 'score_${_worldFxCounter++}',
        kind: _WorldFxKind.score,
        center: center,
        startAtSec: now,
        durationSec: 0.75,
      ),
    );
  }

  void _spawnDepositFx({
    required CompetitiveItemSpawn item,
    required String assetPath,
    required Offset startCenter,
    required Offset targetCenter,
    required DepositOutcome outcome,
    required int bucketOwner,
  }) {
    final now = _gameState.elapsedSec;
    final isCorrect = outcome == DepositOutcome.correct;
    _pulseBucket(bucketOwner);
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
        assetPath: assetPath,
        fallbackColor: _bubbleColorForType(item.type),
        startAtSec: now,
        durationSec: isCorrect ? 0.24 : 0.30,
        startCenter: startCenter,
        targetCenter: targetCenter,
        endCenter: rejectEnd,
        baseSize: _itemSizePixels(item),
        artScale: _itemArtScaleForType(item.type),
        baseRotationRad: item.spawnRotationRad,
        flipX: item.spawnFlipX,
      ),
    );
    if (isCorrect) {
      _spawnScorePopupFx(center: targetCenter);
    }
  }

  String _assetForItem(CompetitiveItemSpawn item) {
    final layout = _layouts[item.id];
    if (layout?.frozenAssetPath != null) {
      return layout!.frozenAssetPath!;
    }
    return _logic.itemAssetPath(_gameState, item);
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

  Offset _itemCenter(_ItemLayout layout, double size) {
    return Offset(layout.x + size / 2, layout.y + size / 2);
  }

  Offset _rotateOffset(Offset v, double angleRad) {
    final c = cos(angleRad);
    final s = sin(angleRad);
    return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
  }

  bool _pointHitsRotatedItem({
    required Offset point,
    required Offset center,
    required double size,
    required double angleRad,
  }) {
    final local = _rotateOffset(point - center, -angleRad);
    final half = size / 2 * 0.9;
    return local.dx.abs() <= half && local.dy.abs() <= half;
  }

  CompetitiveItemSpawn? _hitTestItem(Offset localPosition) {
    for (final item in _gameState.activeItems.reversed) {
      final layout = _layouts[item.id];
      if (layout == null) continue;

      final sz = _itemSizePixels(item);
      if (_pointHitsRotatedItem(
        point: localPosition,
        center: _itemCenter(layout, sz),
        size: sz,
        angleRad: item.spawnRotationRad,
      )) {
        return item;
      }
    }
    return null;
  }

  Widget _orientedItemArt({
    required String path,
    required double size,
    required Color fallbackColor,
    required double rotationRad,
    required bool flipX,
    required double displayScale,
    double spawnPhase = 1,
    double ttlUrgency = 0,
    bool isHeld = false,
  }) {
    return CompetitiveTrashSprite(
      assetPath: path,
      size: size,
      rotationRad: rotationRad,
      flipX: flipX,
      displayScale: displayScale,
      spawnPhase: spawnPhase,
      ttlUrgency: ttlUrgency,
      isHeld: isHeld,
      fallbackColor: fallbackColor,
    );
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
    layout.frozenAssetPath ??= _logic.itemAssetPath(_gameState, spawn);

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
    // Positions refresh on the 16ms game tick — avoids rebuilding the
    // whole tree on every pointer-move event (major lag with many items).
  }

  void _releaseDraggedItems({
    required int pointerId,
    required Size size,
  }) {
    if (_phase != _GamePhase.running) return;

    final player = _pointerOwnerById.remove(pointerId);
    if (player == null) return;

    final p1Bucket = _playerBucketRect(size: size, player: 1);
    final p2Bucket = _playerBucketRect(size: size, player: 2);
    final p1CatchRect = _bucketCatchRect(p1Bucket, 1);
    final p2CatchRect = _bucketCatchRect(p2Bucket, 2);

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
        layout.frozenAssetPath = null;
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
            assetPath:
                layout.frozenAssetPath ??
                _logic.itemAssetPath(_gameState, spawn),
            startCenter: itemCenter,
            targetCenter: bucketOwner == 1
                ? _rectCenter(p1CatchRect)
                : _rectCenter(p2CatchRect),
            outcome: outcome,
            bucketOwner: bucketOwner,
          );
          break;
        case DepositOutcome.wrong:
          _safePlaySfx(_sfxBadCatch);
          _spawnDepositFx(
            item: spawn,
            assetPath:
                layout.frozenAssetPath ??
                _logic.itemAssetPath(_gameState, spawn),
            startCenter: itemCenter,
            targetCenter: bucketOwner == 1
                ? _rectCenter(p1CatchRect)
                : _rectCenter(p2CatchRect),
            outcome: outcome,
            bucketOwner: bucketOwner,
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
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Missing asset or web audio blocked — game continues without sound.
    }
  }

  Widget _introPlayerSide({
    required String playerLabel,
    required String binLabel,
    required String instruction,
    required Color color,
    required List<Color> bgGradient,
    required bool isReady,
    required VoidCallback onReady,
    required int quarterTurns,
    required String statusText,
    required bool otherReady,
    int? countdown,
  }) {
    final maxLives = _logic.config.startLives;

    final Widget statusBadge;
    if (countdown != null) {
      statusBadge = Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFF3A6B3A),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x44000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$countdown',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF4F4F1),
          ),
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: otherReady
              ? const Color(0xFF3A6B3A)
              : const Color(0xFF2D3A2E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF4F4F1),
            letterSpacing: 0.3,
          ),
        ),
      );
    }

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          playerLabel,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2A1F),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$binLabel bin',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color.computeLuminance() > 0.5
                ? const Color(0xFF3A5A30)
                : const Color(0xFF6B4400),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxLives, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(
                width: 32,
                height: 32 * 1.3,
                child: CustomPaint(
                  painter: _FestivalTicketPainter(
                    baseColor: color,
                    goldStripe: true,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Text(
          instruction,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF3A3A3A),
          ),
        ),
        const SizedBox(height: 28),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isReady
              ? Container(
                  key: const ValueKey('ready'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: color, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Ready!',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: color.computeLuminance() > 0.5
                              ? const Color(0xFF2A4A20)
                              : const Color(0xFF6B4400),
                        ),
                      ),
                    ],
                  ),
                )
              : ElevatedButton(
                  key: const ValueKey('join'),
                  onPressed: onReady,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: const Color(0xFF1E2A1F),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Join!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGradient,
        ),
      ),
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: statusBadge,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scoreBadge(int score, Color binColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F1),
        shape: BoxShape.circle,
        border: Border.all(color: binColor, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: binColor.computeLuminance() > 0.5
              ? const Color(0xFF1E2A1F)
              : binColor,
        ),
      ),
    );
  }

  Widget _tickets(int lives, BinType binType, {required bool fallLeft}) {
    final maxL = _logic.config.startLives;
    final color = _binTintFor(binType);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxL, (i) {
        final alive = fallLeft ? i < lives : i >= (maxL - lives);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _AnimatedTicketLife(
            key: ValueKey('ticket_${fallLeft ? "p1" : "p2"}_$i'),
            alive: alive,
            binColor: color,
            fallLeft: fallLeft,
          ),
        );
      }),
    );
  }

  Widget _binTimerPuck({
    required double progress,
    required int secsLeft,
    required double diameter,
    required double pulsePhase,
  }) {
    final danger = progress < 0.25;
    final dangerPulse =
        danger ? 1.0 + 0.06 * sin(pulsePhase * 9.5) : 1.0;
    final ringColor = Color.lerp(
      const Color(0xFFE46C6C),
      const Color(0xFF4FAE64),
      progress,
    )!;
    final ringSize = diameter * 0.84;
    final strokeWidth = (diameter * 0.10).clamp(7.0, 12.0);
    final fontSize = (diameter * 0.30).clamp(24.0, 38.0);

    return Transform.scale(
      scale: dangerPulse,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3ED),
          shape: BoxShape.circle,
          border: Border.all(
            color: danger ? const Color(0xFFA74747) : const Color(0xFF6E7A70),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: danger
                  ? const Color(0x44A74747)
                  : const Color(0x22000000),
              blurRadius: danger ? 14 : 8,
              offset: const Offset(0, 2),
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
                color:
                    danger ? const Color(0xFFA74747) : const Color(0xFF1E2A1F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _worldFxWidgets() {
    if (_worldFx.isEmpty) return const [];
    final now = _gameState.elapsedSec;
    final widgets = <Widget>[];

    for (final fx in _worldFx) {
      final progress =
          ((now - fx.startAtSec) / fx.durationSec).clamp(0.0, 1.0);
      switch (fx.kind) {
        case _WorldFxKind.missed:
          widgets.add(
            CompetitiveMissedItemFx(
              center: fx.center,
              progress: progress,
              baseSize: fx.baseSize,
            ),
          );
        case _WorldFxKind.score:
          widgets.add(
            CompetitiveScorePopupFx(
              center: fx.center,
              progress: progress,
            ),
          );
      }
    }

    return widgets;
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
      final spawnPhase =
          (activeAge / _spawnSettleDurationSec).clamp(0.0, 1.0);
      final ttlUrgency = _logic.itemAgeProgress(_gameState, item);

      widgets.add(
        Positioned(
          left: layout.x,
          top: layout.y,
          width: sz,
          height: sz,
          child: Opacity(
              opacity: spawnOpacity,
              child: _orientedItemArt(
                path: _assetForItem(item),
                size: sz,
                fallbackColor: _bubbleColorForType(item.type),
                rotationRad: item.spawnRotationRad,
                flipX: item.spawnFlipX,
                displayScale: scale * popScale,
                spawnPhase: spawnPhase,
                ttlUrgency: ttlUrgency,
                isHeld: item.isBeingHeld,
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
        rotation = fx.baseRotationRad + t * pi * 1.6;
      } else {
        // Wrong bin: impact + hard deflection away from bin.
        const hitPoint = 0.46;
        if (t < hitPoint) {
          final s = Curves.easeIn.transform((t / hitPoint).clamp(0.0, 1.0));
          center = Offset.lerp(fx.startCenter, fx.targetCenter, s)!;
          scale = 1.0;
          opacity = 1.0;
          rotation = fx.baseRotationRad;
        } else {
          final phase = ((t - hitPoint) / (1.0 - hitPoint)).clamp(0.0, 1.0);
          final s = Curves.easeOutCubic.transform(phase);
          center = Offset.lerp(fx.targetCenter, fx.endCenter, s)!;
          scale = lerpDouble(1.0, 0.76, Curves.easeOut.transform(phase))!;
          opacity = lerpDouble(1.0, 0.0, Curves.easeOut.transform(phase))!;
          rotation = lerpDouble(
            fx.baseRotationRad,
            fx.baseRotationRad - pi * 0.22,
            Curves.easeOut.transform(phase),
          )!;
        }
      }

      final fxSize = fx.baseSize * fx.artScale * scale;
      widgets.add(
        Positioned(
          left: center.dx - fxSize / 2,
          top: center.dy - fxSize / 2,
          width: fxSize,
          height: fxSize,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: CompetitiveTrashFxSprite(
              assetPath: fx.assetPath,
              size: fxSize,
              fallbackColor: fx.fallbackColor,
              rotationRad: rotation,
              flipX: fx.flipX,
              displayScale: 1.0,
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
    final p1Bucket = _playerBucketRect(size: size, player: 1);
    final p2Bucket = _playerBucketRect(size: size, player: 2);
    final p1 = _gameState.players[CompetitivePlayerId.p1]!;
    final p2 = _gameState.players[CompetitivePlayerId.p2]!;
    final timeLeft = _logic.timeLeftSec(_gameState);
    final secsLeft = timeLeft.ceil().clamp(0, 99999);
    final timerProgress = (timeLeft / _logic.config.gameDurationSec).clamp(
      0.0,
      1.0,
    );
    final timerDiameter = (size.shortestSide * 0.12).clamp(96.0, 120.0);
    final anyItemHeld =
        _gameState.activeItems.any((item) => item.isBeingHeld);

    if (_phase == _GamePhase.results) {
      return _buildResultsScreen();
    }

    if (_phase == _GamePhase.intro) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F4F1),
        body: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: _introPlayerSide(
                  playerLabel: 'Player 1',
                  binLabel: 'Organic',
                  instruction:
                      'Drag waste to your bin (Organic).\n'
                      'Wrong bin or non-recyclable\n= festival pass lost!',
                  color: const Color(0xFFAEDC9B),
                  bgGradient: const [Color(0xFFE8F5E3), Color(0xFFC8E6C0)],
                  isReady: _p1Ready,
                  onReady: () {
                    setState(() => _p1Ready = true);
                    if (_p2Ready) _beginCountdown();
                  },
                  quarterTurns: 1,
                  otherReady: _p2Ready,
                  countdown: _countdown,
                  statusText: _p2Ready
                      ? 'Player 2 joined!'
                      : 'Waiting for Player 2...',
                ),
              ),
              Container(width: 2, color: const Color(0xFFB8C5B0)),
              Expanded(
                child: _introPlayerSide(
                  playerLabel: 'Player 2',
                  binLabel: 'Plastic',
                  instruction:
                      'Drag waste to your bin (Plastic).\n'
                      'Wrong bin or non-recyclable\n= festival pass lost!',
                  color: const Color(0xFFFFC16A),
                  bgGradient: const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
                  isReady: _p2Ready,
                  onReady: () {
                    setState(() => _p2Ready = true);
                    if (_p1Ready) _beginCountdown();
                  },
                  quarterTurns: 3,
                  otherReady: _p1Ready,
                  countdown: _countdown,
                  statusText: _p1Ready
                      ? 'Player 1 joined!'
                      : 'Waiting for Player 1...',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gameStack = Stack(
      clipBehavior: Clip.none,
      children: [
        ToiletCompetitiveArenaScene(
          screenSize: size,
          p1Bucket: p1Bucket,
          p2Bucket: p2Bucket,
          p1Score: p1.score,
          p2Score: p2.score,
          p1BinType: p1.binType,
          p2BinType: p2.binType,
          bucketAssetLeft: _bucketAssetLeft,
          bucketAssetRight: _bucketAssetRight,
          binTintFor: _binTintFor,
          scoreBadge: _scoreBadge,
          layoutTune: _effectiveLayoutTune,
          worldTimeSec: _gameState.elapsedSec,
          p1BucketBump: _p1BucketBump,
          p2BucketBump: _p2BucketBump,
        ),
        if (anyItemHeld)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: const Color(0xFF1A1408).withValues(alpha: 0.07),
              ),
            ),
          ),
        Positioned(
          left: 8,
          top: max(8.0, playArea.top - 8),
          child: _tickets(p1.lives, p1.binType, fallLeft: true),
        ),
        Positioned(
          right: 8,
          top: max(8.0, playArea.top - 8),
          child: _tickets(p2.lives, p2.binType, fallLeft: false),
        ),
        Positioned(
          top: max(12.0, playArea.top - timerDiameter - 12),
          left: 0,
          right: 0,
          child: Center(
            child: _binTimerPuck(
              progress: timerProgress,
              secsLeft: secsLeft,
              diameter: timerDiameter,
              pulsePhase: _gameState.elapsedSec,
            ),
          ),
        ),
        ..._itemWidgets(),
        ..._worldFxWidgets(),
        ..._depositFxWidgets(),
        if (kDebugMode && _layoutEditorEnabled)
          ToiletCompetitiveLayoutEditor(
            screenSize: size,
            tune: _effectiveLayoutTune,
            onTuneChanged: (t) => setState(() => _layoutTune = t),
            onClose: () => setState(() => _layoutEditorEnabled = false),
          ),
        if (kDebugMode)
          Positioned(
            right: 16,
            bottom: 16,
            child: ToiletCompetitiveLayoutEditorFab(
              enabled: _layoutEditorEnabled,
              onToggle: () => setState(
                () => _layoutEditorEnabled = !_layoutEditorEnabled,
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F1),
      body: SafeArea(
        child: _layoutEditorEnabled
            ? gameStack
            : Listener(
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
                child: gameStack,
              ),
      ),
    );
  }
}