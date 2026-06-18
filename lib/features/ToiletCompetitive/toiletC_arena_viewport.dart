import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'toiletC_arena_layout.dart';

/// How the festival arena is fitted on screen.
enum ArenaDeviceClass {
  /// Laptops, wide desktop browsers — width-fit (existing behaviour).
  desktopWide,

  /// iPad 10th gen, Air 11", mini — height-fill so mud fills the screen.
  compactTablet,

  /// iPad Pro 12.9"/13" — falls back to width-fit letterboxing.
  largeTablet,
}

/// Screen fitting policy: image + bucket math share one arena rect.
class ArenaViewport {
  ArenaViewport({
    required this.screenSize,
    required this.deviceClass,
    required this.arenaRect,
    required this.scale,
    required this.imageFit,
  });

  final Size screenSize;
  final ArenaDeviceClass deviceClass;
  final Rect arenaRect;
  final double scale;
  final BoxFit imageFit;

  double get arenaWidth => arenaRect.width;
  double get arenaHeight => arenaRect.height;

  /// Picks layout mode from screen shape and platform (no extra plugins).
  static ArenaDeviceClass detectDeviceClass(Size screen) {
    if (screen.width < screen.height) {
      return ArenaDeviceClass.desktopWide;
    }

    final aspect = screen.width / screen.height;
    final shortSide = screen.shortestSide;

    // Pro 12.9"/13" (~1024 pt short side in landscape) — not targeted for cover.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        shortSide >= 950) {
      return ArenaDeviceClass.largeTablet;
    }

    // iPad 10 / Air 11 / mini on device, or Chrome devtools iPad preset.
    final iosCompact = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        shortSide >= 744 &&
        shortSide < 950;
    final aspectCompact = aspect >= 1.35 && aspect <= 1.58;

    if (iosCompact || aspectCompact) {
      return ArenaDeviceClass.compactTablet;
    }

    return ArenaDeviceClass.desktopWide;
  }

  factory ArenaViewport.fromScreen(
    Size screen, {
    ArenaDeviceClass? overrideClass,
  }) {
    final deviceClass = overrideClass ?? detectDeviceClass(screen);

    switch (deviceClass) {
      case ArenaDeviceClass.compactTablet:
        final scale = screen.height / ToiletCompetitiveArenaLayout.designHeight;
        final w = ToiletCompetitiveArenaLayout.designWidth * scale;
        final left = (screen.width - w) / 2;
        return ArenaViewport(
          screenSize: screen,
          deviceClass: deviceClass,
          arenaRect: Rect.fromLTWH(left, 0, w, screen.height),
          scale: scale,
          imageFit: BoxFit.cover,
        );
      case ArenaDeviceClass.desktopWide:
      case ArenaDeviceClass.largeTablet:
        final scale = screen.width / ToiletCompetitiveArenaLayout.designWidth;
        final h = ToiletCompetitiveArenaLayout.designHeight * scale;
        final top = (screen.height - h) / 2;
        return ArenaViewport(
          screenSize: screen,
          deviceClass: deviceClass,
          arenaRect: Rect.fromLTWH(0, top, screen.width, h),
          scale: scale,
          imageFit: BoxFit.fitWidth,
        );
    }
  }

  String get debugLabel {
    switch (deviceClass) {
      case ArenaDeviceClass.compactTablet:
        return 'iPad (compact)';
      case ArenaDeviceClass.largeTablet:
        return 'iPad Pro (letterbox)';
      case ArenaDeviceClass.desktopWide:
        return 'Desktop';
    }
  }
}
