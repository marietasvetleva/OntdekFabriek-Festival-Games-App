import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedGarden extends StatefulWidget {
  final int stage;

  const AnimatedGarden({super.key, required this.stage});

  @override
  State<AnimatedGarden> createState() => _AnimatedGardenState();
}

class _AnimatedGardenState extends State<AnimatedGarden>
    with TickerProviderStateMixin {
  late final AnimationController _butterflyCtrl;

  @override
  void initState() {
    super.initState();
    _butterflyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _butterflyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stage.clamp(0, 8);

    final showGrassLines = s >= 1;
    final showFlowersSmall = s >= 2;
    final showButterflies = s >= 3;
    final showBeesLow = s >= 4;
    final showBeesHigh = s >= 5;
    final showGlow = s >= 6;
    final showFireflies = s >= 7;
    final showCenterAura = s >= 8;

    return Container(
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/garden/Hangout_minigame.jpg",
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: _OverlaySprout(
                visible: showGrassLines,
                asset: "assets/garden/grass_lines.png",
                durationMs: 900,
                curve: Curves.easeOutCubic,
              ),
            ),
            if (showFlowersSmall) ...[
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                left: -52,
                bottom: 115,
                scale: 0.28,
                durationMs: 850,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                left: 22,
                bottom: 62,
                scale: 0.22,
                durationMs: 950,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                left: 48,
                bottom: 8,
                scale: 0.30,
                durationMs: 1050,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                left: 110,
                bottom: 18,
                scale: 0.16,
                durationMs: 1150,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                right: 18,
                bottom: 112,
                scale: 0.26,
                durationMs: 900,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                right: 28,
                bottom: 66,
                scale: 0.22,
                durationMs: 1000,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                right: 44,
                bottom: 14,
                scale: 0.28,
                durationMs: 1100,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                left: 200,
                bottom: 6,
                scale: 0.18,
                durationMs: 1200,
              ),
              _FlowerPatch(
                visible: showFlowersSmall,
                asset: "assets/garden/flowers_small.png",
                right: 120,
                bottom: 4,
                scale: 0.14,
                durationMs: 1300,
              ),
            ],
            if (showButterflies) ...[
              _FlyingButterfly(
                controller: _butterflyCtrl,
                asset: "assets/garden/butterfly_1.png",
                baseX: 0.2,
                baseY: 0.2,
                ampX: 0.10,
                ampY: 0.05,
                size: 45,
              ),
              _FlyingButterfly(
                controller: _butterflyCtrl,
                asset: "assets/garden/butterfly_1.png",
                baseX: 0.78,
                baseY: 0.42,
                ampX: 0.08,
                ampY: 0.07,
                size: 36,
                phase: pi / 2,
              ),
            ],
            if (showBeesLow)
              _BeeLayer(
                controller: _butterflyCtrl,
                baseY: 0.45,
                spreadY: 0.10,
                count: 6,
                size: 12,
                asset: "assets/garden/bee.png",
              ),
            if (showBeesHigh)
              _BeeLayer(
                controller: _butterflyCtrl,
                baseY: 0.15,
                spreadY: 0.08,
                count: 5,
                size: 10,
                asset: "assets/garden/bee.png",
              ),
            if (showGlow)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _butterflyCtrl,
                    builder: (context, _) {
                      final t = (sin(_butterflyCtrl.value * 2 * pi) + 1) / 2;
                      return Container(
                        color: Colors.yellow.withOpacity(0.05 + 0.07 * t),
                      );
                    },
                  ),
                ),
              ),
            if (showFireflies)
              _FireflyLayer(controller: _butterflyCtrl, count: 10, size: 9),
            if (showCenterAura)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _butterflyCtrl,
                    builder: (context, _) {
                      final t = (sin(_butterflyCtrl.value * 2 * pi) + 1) / 2;
                      return Center(
                        child: Container(
                          width: 220 + 40 * t,
                          height: 220 + 40 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.yellowAccent.withOpacity(0.25 + 0.2 * t),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 1.0],
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
    );
  }
}

class _OverlaySprout extends StatelessWidget {
  final bool visible;
  final String asset;
  final int durationMs;
  final Curve curve;

  const _OverlaySprout({
    required this.visible,
    required this.asset,
    required this.durationMs,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: Duration(milliseconds: durationMs),
      curve: curve,
      builder: (context, t, child) {
        final clampedT = t.clamp(0.0, 1.0);

        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: clampedT,
            child: Opacity(
              opacity: clampedT,
              child: Transform.scale(
                scale: 0.95 + 0.05 * t,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          ),
        );
      },
      child: Image.asset(asset, fit: BoxFit.cover),
    );
  }
}

class _FlowerPatch extends StatelessWidget {
  final bool visible;
  final String asset;
  final double? left;
  final double? right;
  final double bottom;
  final double scale;
  final int durationMs;

  const _FlowerPatch({
    required this.visible,
    required this.asset,
    this.left,
    this.right,
    required this.bottom,
    required this.scale,
    required this.durationMs,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      bottom: bottom,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: visible ? 1 : 0),
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          final clampedT = t.clamp(0.0, 1.0);
          return Opacity(
            opacity: clampedT,
            child: Transform.scale(
              scale: (0.7 + 0.3 * clampedT) * scale,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: Image.asset(asset),
      ),
    );
  }
}

class _FlyingButterfly extends StatelessWidget {
  final AnimationController controller;
  final String asset;
  final double baseX;
  final double baseY;
  final double ampX;
  final double ampY;
  final double size;
  final double phase;

  const _FlyingButterfly({
    required this.controller,
    required this.asset,
    required this.baseX,
    required this.baseY,
    required this.ampX,
    required this.ampY,
    required this.size,
    this.phase = 0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final v = controller.value * 2 * pi + phase;
        final dx = sin(v) * ampX;
        final dy = cos(v) * ampY;
        final flap = 0.92 + (sin(v * 2) * 0.07);

        return Positioned.fill(
          child: Align(
            alignment: Alignment(baseX + dx, baseY + dy),
            child: Transform.scale(scale: flap, child: child),
          ),
        );
      },
      child: Image.asset(asset, width: size),
    );
  }
}

class _BeeLayer extends StatelessWidget {
  final AnimationController controller;
  final double baseY;
  final double spreadY;
  final int count;
  final double size;
  final String asset;

  const _BeeLayer({
    required this.controller,
    required this.baseY,
    required this.spreadY,
    required this.count,
    required this.size,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = controller.value * 2 * pi;

            return Stack(
              children: List.generate(count, (i) {
                final phase = t + i * 0.7;
                final x = -0.9 + (i / (count - 1)) * 1.8;
                final y = baseY + sin(phase) * spreadY;
                final opacity = 0.4 + 0.5 * (sin(phase * 3) + 1) / 2;

                return Align(
                  alignment: Alignment(x, y),
                  child: Opacity(
                    opacity: opacity,
                    child: SizedBox(
                      width: size * 1.5,
                      height: size * 3.0,
                      child: Image.asset(asset, fit: BoxFit.contain),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _FireflyLayer extends StatelessWidget {
  final AnimationController controller;
  final int count;
  final double size;

  const _FireflyLayer({
    required this.controller,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = controller.value * 2 * pi;

            return Stack(
              children: List.generate(count, (i) {
                final phase = t + i * 0.9;
                final x = -0.9 + (i / (count - 1)) * 1.8;
                final y = 0.25 + sin(phase * 1.2) * 0.25;
                final opacity = 0.3 + 0.7 * (sin(phase * 2.5) + 1) / 2;

                return Align(
                  alignment: Alignment(x, y),
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(opacity * 0.8),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}