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
import 'toiletC_arena_viewport.dart';
import 'toiletC_item_sprite.dart';
import 'toiletC_logic.dart';
import 'toiletC_models.dart';
import 'toiletC_movement.dart';
import 'toiletC_world_fx.dart';
import 'package:deontdekfabriek/QR.dart';

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

class _TicketFallFx {
  _TicketFallFx({
    required this.id,
    required this.origin,
    required this.binColor,
    required this.driftRight,
    required this.startAtSec,
    required this.fallDistance,
  });

  final String id;
  final Offset origin;
  final Color binColor;
  final bool driftRight;
  final double startAtSec;
  final double fallDistance;
  static const double durationSec = 1.5;
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
    final cy = size.height * 0.38;
    final w = size.width;
    final p = crackProgress.clamp(0.0, 1.0);
    if (p <= 0) return;

    final perfPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22 * p)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 11; i++) {
      final x = w * (0.06 + i * 0.088);
      if (x / w > p * 1.08) break;
      canvas.drawCircle(Offset(x, cy), 0.75, perfPaint);
    }

    final points = <Offset>[
      Offset(0, cy),
      Offset(w * 0.14, cy + 1.2),
      Offset(w * 0.28, cy - 1.8),
      Offset(w * 0.46, cy + 1.4),
      Offset(w * 0.62, cy - 1.2),
      Offset(w * 0.78, cy + 0.9),
      Offset(w, cy),
    ];

    var totalLen = 0.0;
    for (var i = 1; i < points.length; i++) {
      totalLen += (points[i] - points[i - 1]).distance;
    }
    final targetLen = totalLen * p;

    final crack = Path()..moveTo(points[0].dx, points[0].dy);
    var walked = 0.0;
    for (var i = 1; i < points.length; i++) {
      final segLen = (points[i] - points[i - 1]).distance;
      if (walked + segLen >= targetLen) {
        final segT = ((targetLen - walked) / segLen).clamp(0.0, 1.0);
        final end = Offset.lerp(points[i - 1], points[i], segT)!;
        crack.lineTo(end.dx, end.dy);
        break;
      }
      walked += segLen;
      crack.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(
      crack,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.75 * p)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
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
  _HalfClipper({required this.topHalf});
  final bool topHalf;

  @override
  Rect getClip(Size size) => topHalf
      ? Rect.fromLTWH(0, 0, size.width, size.height / 2)
      : Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2);

  @override
  bool shouldReclip(covariant _HalfClipper old) => old.topHalf != topHalf;
}

/// Static ticket icon in the HUD row (break animation runs in screen overlay).
class _AnimatedTicketLife extends StatelessWidget {
  const _AnimatedTicketLife({
    required this.slotIndex,
    required this.lives,
    required this.maxLives,
    required this.binColor,
    required this.fallLeft,
  });

  static const double ticketWidth = 28;

  final int slotIndex;
  final int lives;
  final int maxLives;
  final Color binColor;
  final bool fallLeft;

  bool get _alive =>
      fallLeft ? slotIndex < lives : slotIndex >= maxLives - lives;

  @override
  Widget build(BuildContext context) {
    final w = ticketWidth;
    final h = w * 1.3;
    if (!_alive) {
      return SizedBox(width: w, height: h);
    }
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        size: Size(w, h),
        painter: _FestivalTicketPainter(
          baseColor: binColor,
          goldStripe: true,
        ),
      ),
    );
  }
}

/// Full-screen break + fall — not clipped by the ticket HUD row.
class _TicketBreakAndFall extends StatelessWidget {
  const _TicketBreakAndFall({
    required this.progress,
    required this.binColor,
    required this.driftRight,
    required this.fallDistance,
  });

  final double progress;
  final Color binColor;
  final bool driftRight;
  final double fallDistance;

  @override
  Widget build(BuildContext context) {
    final w = _AnimatedTicketLife.ticketWidth;
    final h = w * 1.3;
    final t = progress.clamp(0.0, 1.0);
    final dir = driftRight ? 1.0 : -1.0;

    Widget ticketHalf({required bool topHalf, required double crack}) {
      return ClipRect(
        clipper: _HalfClipper(topHalf: topHalf),
        child: CustomPaint(
          size: Size(w, h),
          painter: _FestivalTicketPainter(
            baseColor: binColor,
            goldStripe: true,
            crackProgress: crack,
          ),
        ),
      );
    }

    // Phase 1 — perforation tear spreads, then a tiny give (0–30%)
    if (t <= 0.30) {
      final pt = t / 0.30;
      final crack = Curves.easeInCubic.transform(pt);
      // One soft dip when the tear completes — not a buzzy shake.
      final give = pt > 0.82
          ? Curves.easeOut.transform(((pt - 0.82) / 0.18).clamp(0.0, 1.0)) * 2.0
          : 0.0;
      final voiding = 1.0 - pt * 0.12;
      return Transform.translate(
        offset: Offset(0, give),
        child: Opacity(
          opacity: voiding.clamp(0.85, 1.0),
          child: CustomPaint(
            size: Size(w, h),
            painter: _FestivalTicketPainter(
              baseColor: binColor,
              goldStripe: true,
              crackProgress: crack,
            ),
          ),
        ),
      );
    }

    // Phase 2 — halves part at the tear line (30–45%)
    if (t <= 0.45) {
      final pt = (t - 0.30) / 0.15;
      final split = Curves.easeOutCubic.transform(pt);
      final gap = split * h * 0.22;
      final topPeel = -gap * 0.55;
      final bottomPeel = gap * 0.55;
      return SizedBox(
        width: w,
        height: h + gap * 2 + 4,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, topPeel),
              child: ticketHalf(topHalf: true, crack: 1.0),
            ),
            Transform.translate(
              offset: Offset(0, bottomPeel),
              child: ticketHalf(topHalf: false, crack: 1.0),
            ),
          ],
        ),
      );
    }

    // Phase 3 — halves drop and drift away (45–100%)
    final pt = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    final fall = Curves.easeInCubic.transform(pt);
    final fade = (1.0 - Curves.easeIn.transform(pt)).clamp(0.0, 1.0);
    final gap = h * 0.22;
    final drop = fall * fallDistance;
    final drift = dir * fall * max(100.0, fallDistance * 0.22);
    final rot = dir * fall * 0.42;

    Widget fallingHalf({required bool topHalf}) {
      final peel = topHalf ? -gap * 0.55 : gap * 0.55;
      final halfRot = rot * (topHalf ? 0.85 : 1.05);
      return Transform.translate(
        offset: Offset(drift, peel + drop),
        child: Transform.rotate(
          angle: halfRot,
          alignment: topHalf ? Alignment.bottomCenter : Alignment.topCenter,
          child: Opacity(
            opacity: fade,
            child: ticketHalf(topHalf: topHalf, crack: 1.0),
          ),
        ),
      );
    }

    final maxDrift = max(100.0, fallDistance * 0.22);
    return SizedBox(
      width: w + maxDrift,
      height: h + fallDistance + gap + 8,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          fallingHalf(topHalf: true),
          fallingHalf(topHalf: false),
        ],
      ),
    );
  }
}

class _AnimatedCountdownBadge extends StatelessWidget {
  const _AnimatedCountdownBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final flash = count == 1 ? 1.0 : (count == 2 ? 0.55 : 0.25);
    final bgColor = Color.lerp(
      const Color(0xFF3A6B3A),
      const Color(0xFF5AAB5A),
      flash,
    )!;

    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 1.4, end: 1.0).animate(animation);
          return ScaleTransition(
            scale: scale,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(
          '$count',
          key: ValueKey(count),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: Color(0xFFF4F4F1),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBinTimerPuck extends StatefulWidget {
  const _AnimatedBinTimerPuck({
    required this.progress,
    required this.secsLeft,
    required this.diameter,
    required this.pulsePhase,
  });

  final double progress;
  final int secsLeft;
  final double diameter;
  final double pulsePhase;

  @override
  State<_AnimatedBinTimerPuck> createState() => _AnimatedBinTimerPuckState();
}

class _AnimatedBinTimerPuckState extends State<_AnimatedBinTimerPuck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _digitCtrl;
  late final Animation<double> _digitScale;
  double _milestoneBump = 0.0;

  @override
  void initState() {
    super.initState();
    _digitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _digitScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.84), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _digitCtrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _AnimatedBinTimerPuck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.secsLeft != oldWidget.secsLeft) {
      _digitCtrl.forward(from: 0);
      if ((oldWidget.secsLeft > 30 && widget.secsLeft <= 30) ||
          (oldWidget.secsLeft > 10 && widget.secsLeft <= 10)) {
        _milestoneBump = 1.0;
      }
    }
    if (_milestoneBump > 0) {
      _milestoneBump = max(0.0, _milestoneBump - 0.08);
    }
  }

  @override
  void dispose() {
    _digitCtrl.dispose();
    super.dispose();
  }

  double _pulseRate() {
    if (widget.secsLeft <= 5) return 16.0;
    if (widget.secsLeft <= 10) return 12.0;
    if (widget.progress < 0.25) return 9.5;
    return 0.0;
  }

  double _pulseAmp() {
    if (widget.secsLeft <= 5) return 0.12;
    if (widget.secsLeft <= 10) return 0.09;
    if (widget.progress < 0.25) return 0.06;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final rate = _pulseRate();
    final danger = rate > 0;
    final dangerPulse =
        danger ? 1.0 + _pulseAmp() * sin(widget.pulsePhase * rate) : 1.0;
    final milestoneScale = 1.0 + _milestoneBump * 0.1;
    final ringColor = Color.lerp(
      const Color(0xFFE46C6C),
      const Color(0xFF4FAE64),
      widget.progress,
    )!;
    final tickBoost = 1.0 - _digitCtrl.value;
    final emphasizedRing = Color.lerp(ringColor, Colors.white, tickBoost * 0.3)!;
    final ringSize = widget.diameter * 0.84;
    final strokeWidth = (widget.diameter * 0.10).clamp(7.0, 12.0);
    final fontSize = (widget.diameter * 0.30).clamp(24.0, 38.0);
    final borderColor = widget.secsLeft <= 5
        ? const Color(0xFFA74747)
        : widget.secsLeft <= 10
            ? const Color(0xFFB87A30)
            : danger
                ? const Color(0xFFA74747)
                : const Color(0xFF6E7A70);

    return AnimatedBuilder(
      animation: _digitCtrl,
      builder: (context, _) {
        return Transform.scale(
          scale: dangerPulse * milestoneScale,
          child: Container(
            width: widget.diameter,
            height: widget.diameter,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3ED),
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
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
                    value: widget.progress,
                    strokeWidth: strokeWidth,
                    backgroundColor: const Color(0xFFD8DED4),
                    valueColor: AlwaysStoppedAnimation<Color>(emphasizedRing),
                  ),
                ),
                Transform.scale(
                  scale: _digitScale.value,
                  child: Text(
                    '${widget.secsLeft}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      color: danger
                          ? const Color(0xFFA74747)
                          : const Color(0xFF1E2A1F),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Festival arena backdrop for intro and results — same art as gameplay.
class _FestivalSplitLobby extends StatelessWidget {
  const _FestivalSplitLobby({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final layoutSize = MediaQuery.sizeOf(context);
    final viewport = ArenaViewport.fromScreen(layoutSize);
    final arena = viewport.arenaRect;

    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned.fill(
          child: ColoredBox(color: ToiletCompetitiveArenaLayout.edgeFillColor),
        ),
        Positioned(
          left: arena.left,
          top: arena.top,
          width: arena.width,
          height: arena.height,
          child: ClipRect(
            child: Image.asset(
              ToiletCompetitiveArenaLayout.arenaAsset,
              fit: viewport.imageFit,
              alignment: Alignment.center,
              width: arena.width,
              height: arena.height,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFD4C4A8),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFF1A1408).withValues(alpha: 0.08),
          ),
        ),
        Positioned.fill(child: child),
      ],
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
  static const String _sfxDeposit = 'trashGame/audio/binnedTrash.mp3';
  static const String _sfxRoundEnd = 'ToiletImage/GoodToilet.mp3';

  final AudioPlayer _audioPlayer = AudioPlayer();
  final ToiletCompetitiveLogic _logic = ToiletCompetitiveLogic();
  late ToiletCompetitiveState _gameState;

  final Map<String, _ItemLayout> _layouts = {};
  final Map<int, int> _pointerOwnerById = {};
  final List<_DepositFx> _depositFx = [];
  final List<_WorldFx> _worldFx = [];
  final List<_TicketFallFx> _ticketFallFx = [];
  int _depositFxCounter = 0;
  int _worldFxCounter = 0;
  int _ticketFallFxCounter = 0;
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
  bool _finishScheduled = false;

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
      _finishScheduled = false;
      _layouts.clear();
      _depositFx.clear();
      _worldFx.clear();
      _ticketFallFx.clear();
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
        _syncLayoutsForActiveItems(
          _playArea(ArenaViewport.fromScreen(size)),
        );
        _pruneFinishedDepositFx();
        _pruneWorldFx();
        _pruneTicketFallFx();
        _decayBucketBumps(dt);
      });

      if (_gameState.finished) {
        _scheduleFinishGame();
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
    _finishScheduled = false;
    _playRoundEndSfx();
    setState(() => _phase = _GamePhase.results);
  }

  void _scheduleFinishGame() {
    if (_phase == _GamePhase.results || _finishScheduled) return;
    _finishScheduled = true;
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted || _phase == _GamePhase.results) return;
      if (_gameState.finished) {
        _finishGame();
      } else {
        _finishScheduled = false;
      }
    });
  }

  Future<void> _playRoundEndSfx() async {
    try {
      await _safePlaySfx(_sfxRoundEnd, volume: 0.7);
    } finally {
      try {
        await _audioPlayer.setVolume(1.0);
      } catch (_) {}
    }
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
      _finishScheduled = false;
      _p1Ready = false;
      _p2Ready = false;
      _countdown = null;
      _layouts.clear();
      _depositFx.clear();
      _worldFx.clear();
      _ticketFallFx.clear();
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
  backgroundColor: ToiletCompetitiveArenaLayout.edgeFillColor,
  body: _FestivalSplitLobby(
    child: Stack(
      children: [
        Padding(
          padding: MediaQuery.viewPaddingOf(context),
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

        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const QRScannerPage(),
                  ),
                );
              },
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F4F1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF8AA06B),
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_rounded,
                  size: 34,
                  color: Color(0xFF6F8454),
                ),
              ),
            ),
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
            color: const Color(0xFFF0F3ED).withValues(alpha: 0.92),
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
          colors: bgGradient
              .map((c) => c.withValues(alpha: 0.50))
              .toList(growable: false),
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

  Rect _playArea(ArenaViewport viewport) =>
      ToiletCompetitiveArenaLayout.playArea(viewport);

  Rect _playerBucketRect({
    required ArenaViewport viewport,
    required int player,
  }) {
    return ToiletCompetitiveArenaLayout.playerBucketRect(
      viewport: viewport,
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

  void _pruneTicketFallFx() {
    if (_ticketFallFx.isEmpty) return;
    final now = _gameState.elapsedSec;
    _ticketFallFx.removeWhere(
      (fx) => now - fx.startAtSec >= _TicketFallFx.durationSec,
    );
  }

  double _ticketHudWidth() {
    const pad = 6.0;
    const ticketPad = 2.0;
    const ticketW = _AnimatedTicketLife.ticketWidth;
    final maxL = _logic.config.startLives;
    return pad * 2 + maxL * (ticketW + ticketPad * 2);
  }

  Offset _ticketOriginForSlot({
    required Size screenSize,
    required double hudTop,
    required int player,
    required int slotIndex,
  }) {
    const hudInset = 8.0;
    const panelPadH = 6.0;
    const panelPadV = 5.0;
    const ticketPad = 2.0;
    const ticketW = _AnimatedTicketLife.ticketWidth;
    final ticketSpan = ticketW + ticketPad * 2;

    final y = hudTop + panelPadV;
    if (player == 1) {
      return Offset(
        hudInset + panelPadH + slotIndex * ticketSpan + ticketPad,
        y,
      );
    }
    final hudWidth = _ticketHudWidth();
    return Offset(
      screenSize.width - hudInset - hudWidth + slotIndex * ticketSpan + ticketPad,
      y,
    );
  }

  void _spawnTicketFallFx({
    required int player,
    required int slotIndex,
    required Color binColor,
    required bool driftRight,
    required Size screenSize,
    required double hudTop,
  }) {
    _ticketFallFx.add(
      _TicketFallFx(
        id: 'ticket_fall_${_ticketFallFxCounter++}',
        origin: _ticketOriginForSlot(
          screenSize: screenSize,
          hudTop: hudTop,
          player: player,
          slotIndex: slotIndex,
        ),
        binColor: binColor,
        driftRight: driftRight,
        startAtSec: _gameState.elapsedSec,
        fallDistance: screenSize.height * 0.72,
      ),
    );
  }

  List<Widget> _ticketFallFxWidgets(Size screenSize) {
    if (_ticketFallFx.isEmpty) return const [];
    final now = _gameState.elapsedSec;
    final widgets = <Widget>[];

    for (final fx in _ticketFallFx) {
      final progress =
          ((now - fx.startAtSec) / _TicketFallFx.durationSec).clamp(0.0, 1.0);
      if (progress >= 1.0) continue;

      widgets.add(
        Positioned(
          left: fx.origin.dx,
          top: fx.origin.dy,
          child: IgnorePointer(
            child: _TicketBreakAndFall(
              progress: progress,
              binColor: fx.binColor,
              driftRight: fx.driftRight,
              fallDistance: fx.fallDistance,
            ),
          ),
        ),
      );
    }

    return widgets;
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

    final viewport = ArenaViewport.fromScreen(size);
    final p1Bucket = _playerBucketRect(viewport: viewport, player: 1);
    final p2Bucket = _playerBucketRect(viewport: viewport, player: 2);
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

      final penalizedId = _bucketOwnerToPlayerId(bucketOwner);
      final livesBefore = _gameState.players[penalizedId]!.lives;
      final outcome = _logic.depositItem(
        state: _gameState,
        playerId: penalizedId,
        itemId: spawn.id,
      );

      if (outcome == DepositOutcome.wrong) {
        final playerState = _gameState.players[penalizedId]!;
        if (playerState.lives < livesBefore) {
          final maxL = _logic.config.startLives;
          final lostSlot = penalizedId == CompetitivePlayerId.p1
              ? playerState.lives
              : maxL - playerState.lives - 1;
          _spawnTicketFallFx(
            player: penalizedId == CompetitivePlayerId.p1 ? 1 : 2,
            slotIndex: lostSlot,
            binColor: _binTintFor(playerState.binType),
            driftRight: playerState.binType == BinType.organic,
            screenSize: size,
            hudTop: MediaQuery.viewPaddingOf(context).top + 8,
          );
        }
      }

      switch (outcome) {
        case DepositOutcome.correct:
          _safePlaySfx(_sfxDeposit);
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
          _safePlaySfx(_sfxDeposit);
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
      _syncLayoutsForActiveItems(_playArea(viewport));
    });

    if (_gameState.finished) {
      _scheduleFinishGame();
    }
  }

  Future<void> _safePlaySfx(String assetPath, {double volume = 1.0}) async {
    try {
      await _audioPlayer.setVolume(volume);
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
      statusBadge = _AnimatedCountdownBadge(count: countdown);
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: otherReady
              ? const Color(0xFF3A8B44)
              : const Color(0xFF2D3A2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF0F3ED).withValues(alpha: 0.35),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          statusText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF4F4F1),
            letterSpacing: 0.4,
          ),
        ),
      );
    }

    final joinButton = isReady
        ? Container(
            key: const ValueKey('ready'),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3ED),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF3A8B44), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A8B44).withValues(alpha: 0.45),
                  blurRadius: 14,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF3A8B44), size: 26),
                SizedBox(width: 10),
                Text(
                  'Ready!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E2A1F),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          )
        : FilledButton(
            key: const ValueKey('join'),
            onPressed: onReady,
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: const Color(0xFF1E2A1F),
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              elevation: 6,
              shadowColor: Colors.black.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: const Color(0xFF1E2A1F).withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ),
            child: const Text(
              'Join!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          );

    final content = Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3ED).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF6E7A70).withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerLabel,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E2A1F),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Text(
              '$binLabel bin',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E2A1F),
                letterSpacing: 0.5,
              ),
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
          const SizedBox(height: 18),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E2A1F),
            ),
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1.0).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: joinButton,
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bgGradient
              .map((c) => c.withValues(alpha: 0.50))
              .toList(growable: false),
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

  Widget _ticketHud(int lives, BinType binType, {required bool fallLeft}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3ED).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF6E7A70).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: _tickets(lives, binType, fallLeft: fallLeft),
      ),
    );
  }

  Widget _tickets(int lives, BinType binType, {required bool fallLeft}) {
    final maxL = _logic.config.startLives;
    final color = _binTintFor(binType);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxL, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _AnimatedTicketLife(
            slotIndex: i,
            lives: lives,
            maxLives: maxL,
            binColor: color,
            fallLeft: fallLeft,
          ),
        );
      }),
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
      final spawnOpacity =
          max(0.9, Curves.easeOut.transform(popT));
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
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewport = ArenaViewport.fromScreen(size);
    final playArea = _playArea(viewport);
    final p1Bucket = _playerBucketRect(viewport: viewport, player: 1);
    final p2Bucket = _playerBucketRect(viewport: viewport, player: 2);
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
    backgroundColor: ToiletCompetitiveArenaLayout.edgeFillColor,
    body: _FestivalSplitLobby(
      child: Stack(
        children: [
          Padding(
            padding: viewPadding,
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
                    bgGradient: const [
                      Color(0xFFE8F5E3),
                      Color(0xFFC8E6C0),
                    ],
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
                    bgGradient: const [
                      Color(0xFFFFF3E0),
                      Color(0xFFFFE0B2),
                    ],
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

          Positioned(
            top: 12,
            left: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF8AA06B),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF6F8454),
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

    final hudTop = viewPadding.top + 8;
    final hudBottom = viewPadding.bottom + 8;

    final gameStack = Stack(
      clipBehavior: Clip.none,
      children: [
        ToiletCompetitiveArenaScene(
          viewport: viewport,
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
          top: max(viewPadding.top + 12, playArea.top - timerDiameter - 12),
          left: 0,
          right: 0,
          child: Center(
            child: _AnimatedBinTimerPuck(
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
        Positioned(
          top: hudTop,
          left: 8,
          child: _ticketHud(p1.lives, p1.binType, fallLeft: true),
        ),
        Positioned(
          top: hudTop,
          right: 8,
          child: _ticketHud(p2.lives, p2.binType, fallLeft: false),
        ),
        ..._ticketFallFxWidgets(size),
        if (kDebugMode && _layoutEditorEnabled)
          ToiletCompetitiveLayoutEditor(
            viewport: viewport,
            tune: _effectiveLayoutTune,
            onTuneChanged: (t) => setState(() => _layoutTune = t),
            onClose: () => setState(() => _layoutEditorEnabled = false),
          ),
        if (kDebugMode)
          Positioned(
            left: 8,
            bottom: hudBottom,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xCC1E2A1F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    viewport.debugLabel,
                    style: const TextStyle(
                      color: Color(0xFFE8F0E4),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (kDebugMode)
          Positioned(
            right: 16,
            bottom: hudBottom + 8,
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
      backgroundColor: ToiletCompetitiveArenaLayout.edgeFillColor,
      body: _layoutEditorEnabled
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
    );
  }
}