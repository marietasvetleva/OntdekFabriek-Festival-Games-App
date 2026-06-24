import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'toiletC_arena_viewport.dart';

/// Which festival arena background art matches the screen shape.
enum ArenaArtVariant {
  /// 1024×571 — desktop / wide web (16∶9-ish).
  widescreen,

  /// 1024×764 — iPad / 4∶3 tablet.
  tablet43,
}

/// Design-time dimensions + asset path for one arena background.
class ArenaArtSpec {
  const ArenaArtSpec({
    required this.variant,
    required this.designWidth,
    required this.designHeight,
    required this.assetPath,
    required this.playLeft,
    required this.playTop,
    required this.playWidth,
    required this.playHeight,
  });

  final ArenaArtVariant variant;
  final double designWidth;
  final double designHeight;
  final String assetPath;
  final double playLeft;
  final double playTop;
  final double playWidth;
  final double playHeight;

  static const double _tabletAspect = 1024 / 764;
  static const double _wideAspect = 1024 / 571;

  static const widescreen = ArenaArtSpec(
    variant: ArenaArtVariant.widescreen,
    designWidth: 1024,
    designHeight: 571,
    assetPath: 'assets/ToiletCompetitive/festival_arena.jpg',
    playLeft: 0.22,
    playTop: 0.29,
    playWidth: 0.56,
    playHeight: 0.43,
  );

  static const tablet43 = ArenaArtSpec(
    variant: ArenaArtVariant.tablet43,
    designWidth: 1024,
    designHeight: 764,
    assetPath: 'assets/ToiletCompetitive/festival_arena_4x3.jpg',
    playLeft: 0.22,
    playTop: 0.38,
    playWidth: 0.56,
    playHeight: 0.32,
  );

  /// Picks arena art — 4∶3 only on real iPads or when the window is clearly 4∶3.
  static ArenaArtSpec pickForScreen(Size screen) {
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        screen.shortestSide >= 744) {
      return tablet43;
    }

    if (screen.width <= screen.height) {
      return widescreen;
    }

    final aspect = screen.width / screen.height;

    // Stay on 16∶9 until the window is genuinely near 4∶3 (~1.33), not just
    // "a bit squarer" than widescreen.
    const maxTabletAspect = 1.38;
    if (aspect > maxTabletAspect) {
      return widescreen;
    }

    final distTablet = (aspect - _tabletAspect).abs();
    final distWide = (aspect - _wideAspect).abs();
    return distTablet < distWide ? tablet43 : widescreen;
  }

  static ArenaArtSpec forDeviceClass(ArenaDeviceClass deviceClass) {
    switch (deviceClass) {
      case ArenaDeviceClass.compactTablet:
        return tablet43;
      case ArenaDeviceClass.desktopWide:
      case ArenaDeviceClass.largeTablet:
        return widescreen;
    }
  }

  String get debugLabel {
    switch (variant) {
      case ArenaArtVariant.widescreen:
        return '16∶9 art';
      case ArenaArtVariant.tablet43:
        return '4∶3 art';
    }
  }
}
