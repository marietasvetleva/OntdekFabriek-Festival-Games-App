import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'toiletC_arena_art.dart';

/// How the festival arena is fitted on screen.
enum ArenaDeviceClass {
  /// Wide screens — 16∶9 arena art.
  desktopWide,

  /// Tablets / 4∶3 — 4∶3 arena art.
  compactTablet,

  /// Legacy — unused.
  largeTablet,
}

/// Screen fitting policy: image + bucket math share one arena rect.
class ArenaViewport {
  ArenaViewport({
    required this.screenSize,
    required this.deviceClass,
    required this.artSpec,
    required this.arenaRect,
    required this.scale,
    required this.imageFit,
  });

  final Size screenSize;
  final ArenaDeviceClass deviceClass;
  final ArenaArtSpec artSpec;
  final Rect arenaRect;
  final double scale;
  final BoxFit imageFit;

  double get arenaWidth => arenaRect.width;
  double get arenaHeight => arenaRect.height;
  double get designWidth => artSpec.designWidth;
  double get designHeight => artSpec.designHeight;

  factory ArenaViewport.fromScreen(
    Size screen, {
    ArenaDeviceClass? overrideClass,
  }) {
    final artSpec = overrideClass != null
        ? ArenaArtSpec.forDeviceClass(overrideClass)
        : ArenaArtSpec.pickForScreen(screen);
    final deviceClass = artSpec.variant == ArenaArtVariant.tablet43
        ? ArenaDeviceClass.compactTablet
        : ArenaDeviceClass.desktopWide;

    // Always cover — image fills the screen, excess cropped, no letterbox bars.
    final scale = math.max(
      screen.width / artSpec.designWidth,
      screen.height / artSpec.designHeight,
    );
    final w = artSpec.designWidth * scale;
    final h = artSpec.designHeight * scale;
    final left = (screen.width - w) / 2;
    final top = (screen.height - h) / 2;

    return ArenaViewport(
      screenSize: screen,
      deviceClass: deviceClass,
      artSpec: artSpec,
      arenaRect: Rect.fromLTWH(left, top, w, h),
      scale: scale,
      imageFit: BoxFit.cover,
    );
  }

  String get debugLabel {
    switch (deviceClass) {
      case ArenaDeviceClass.compactTablet:
        return 'Tablet';
      case ArenaDeviceClass.largeTablet:
        return 'iPad Pro';
      case ArenaDeviceClass.desktopWide:
        return 'Desktop';
    }
  }

  String get debugMetricsLine {
    final w = screenSize.width;
    final h = screenSize.height;
    final aspect = w / h;
    final short = screenSize.shortestSide;
    return '${w.toInt()}×${h.toInt()} · short ${short.toInt()} · '
        'aspect ${aspect.toStringAsFixed(2)} · cover · ${artSpec.debugLabel}';
  }
}
