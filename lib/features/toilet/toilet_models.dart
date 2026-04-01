/// Describes an item type that can appear in Toilet game.
class ToiletItemSpec {
  final String name;
  final String asset;
  final bool good;

  const ToiletItemSpec(this.name, this.asset, this.good);
}

/// Represents one tappable slot entry at the top bar.
class ToiletSlotItem {
  final ToiletItemSpec spec;

  const ToiletSlotItem({required this.spec});
}

/// Represents one spawned item currently falling on screen.
class ToiletFallingItem {
  double x;
  double y;
  final double size;
  final double speed;
  final ToiletItemSpec spec;

  ToiletFallingItem({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.spec,
  });
}

/// Mutable runtime state used by the Toilet game loop.
class ToiletGameState {
  bool showIntro;
  bool isRunning;
  int hearts;
  int itemsCaught;
  bool winGame;
  bool gameOver;
  double bucketX;
  double bucketY;
  final List<ToiletFallingItem> items;
  final List<ToiletSlotItem?> slots;
  String? feedbackMessage;
  bool feedbackIsGood;

  ToiletGameState({
    required this.showIntro,
    required this.isRunning,
    required this.hearts,
    required this.itemsCaught,
    required this.winGame,
    required this.gameOver,
    required this.bucketX,
    required this.bucketY,
    required this.items,
    required this.slots,
    required this.feedbackMessage,
    required this.feedbackIsGood,
  });
}
