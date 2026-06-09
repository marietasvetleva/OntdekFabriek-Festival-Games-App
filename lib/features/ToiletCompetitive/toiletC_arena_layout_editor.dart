import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'toiletC_arena_layout.dart';
import 'toiletC_arena_layout_tune.dart';

/// Figma-style pit placement: drag handles on the arena, copy normalized values.
/// Only intended for debug builds (`kDebugMode`).
class ToiletCompetitiveLayoutEditor extends StatefulWidget {
  const ToiletCompetitiveLayoutEditor({
    super.key,
    required this.screenSize,
    required this.tune,
    required this.onTuneChanged,
    required this.onClose,
  });

  final Size screenSize;
  final ArenaLayoutTune tune;
  final ValueChanged<ArenaLayoutTune> onTuneChanged;
  final VoidCallback onClose;

  @override
  State<ToiletCompetitiveLayoutEditor> createState() =>
      _ToiletCompetitiveLayoutEditorState();
}

class _ToiletCompetitiveLayoutEditorState
    extends State<ToiletCompetitiveLayoutEditor> {
  int? _draggingPlayer;
  String? _copyMessage;

  ArenaLayoutTune get _tune => widget.tune;

  void _setTune(ArenaLayoutTune tune) => widget.onTuneChanged(tune);

  void _dragPit(int player, Offset screenPos) {
    final norm = ToiletCompetitiveArenaLayout.screenToDesignNorm(
      widget.screenSize,
      screenPos,
    );
    final nx = norm.dx.clamp(0.02, 0.98);
    final ny = norm.dy.clamp(0.08, 0.92);
    if (player == 1) {
      _setTune(_tune.copyWith(
        leftBinCenterX: nx,
        leftBinCenterY: ny,
      ));
    } else {
      _setTune(_tune.copyWith(
        rightBinCenterX: nx,
        rightBinCenterY: ny,
      ));
    }
  }

  Future<void> _copySnippet() async {
    await Clipboard.setData(ClipboardData(text: _tune.toDartSnippet()));
    setState(() => _copyMessage = 'Copied to clipboard');
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copyMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.screenSize;
    final tune = _tune;
    final p1Pit = ToiletCompetitiveArenaLayout.binPitRect(size, 1, tune);
    final p2Pit = ToiletCompetitiveArenaLayout.binPitRect(size, 2, tune);

    Widget pitHandle({
      required int player,
      required Rect pit,
      required Color color,
      required String label,
    }) {
      return Positioned(
        left: pit.left,
        top: pit.top,
        width: pit.width,
        height: pit.height,
        child: GestureDetector(
          onPanStart: (_) => setState(() => _draggingPlayer = player),
          onPanUpdate: (d) => _dragPit(player, pit.center + d.delta),
          onPanEnd: (_) => setState(() => _draggingPlayer = null),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: _draggingPlayer == player ? 3 : 2,
                  ),
                  color: color.withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                top: -14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    'P$label',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ),
        // Panel first so it does not block left (P1) pit drag handles.
        Positioned(
          right: 12,
          top: 12,
          child: _panel(tune),
        ),
        pitHandle(
          player: 1,
          pit: p1Pit,
          color: const Color(0xFF5A9E4A),
          label: '1',
        ),
        pitHandle(
          player: 2,
          pit: p2Pit,
          color: const Color(0xFFE08A2E),
          label: '2',
        ),
      ],
    );
  }

  Widget _panel(ArenaLayoutTune tune) {
    Widget sliderRow({
      required String label,
      required double value,
      required double min,
      required double max,
      required ValueChanged<double> onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 118,
              child: Text(label, style: const TextStyle(fontSize: 11)),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                value.toStringAsFixed(3),
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xF0FFFFFF),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Arena layout editor',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: widget.onClose,
                  tooltip: 'Close editor',
                ),
              ],
            ),
            const Text(
              'Drag green/orange handles onto the dirt pits. '
              'Values are normalized to the arena art (1024×571) and scale when you resize the window.',
              style: TextStyle(fontSize: 11, height: 1.35),
            ),
            const SizedBox(height: 8),
            sliderRow(
              label: 'Pit diameter',
              value: tune.binPitDiameter,
              min: 0.06,
              max: 0.18,
              onChanged: (v) => _setTune(tune.copyWith(binPitDiameter: v)),
            ),
            sliderRow(
              label: 'Bucket scale',
              value: tune.bucketFillInPit,
              min: 0.45,
              max: 1.0,
              onChanged: (v) => _setTune(tune.copyWith(bucketFillInPit: v)),
            ),
            sliderRow(
              label: 'P1 anchor X',
              value: tune.leftBucketAnchorX,
              min: 0.35,
              max: 0.65,
              onChanged: (v) => _setTune(tune.copyWith(leftBucketAnchorX: v)),
            ),
            sliderRow(
              label: 'P2 anchor X',
              value: tune.rightBucketAnchorX,
              min: 0.35,
              max: 0.65,
              onChanged: (v) => _setTune(tune.copyWith(rightBucketAnchorX: v)),
            ),
            sliderRow(
              label: 'Anchor Y (base)',
              value: tune.bucketAnchorY,
              min: 0.85,
              max: 1.0,
              onChanged: (v) => _setTune(tune.copyWith(bucketAnchorY: v)),
            ),
            const Divider(height: 16),
            Text(
              'P1: (${tune.leftBinCenterX.toStringAsFixed(3)}, ${tune.leftBinCenterY.toStringAsFixed(3)})\n'
              'P2: (${tune.rightBinCenterX.toStringAsFixed(3)}, ${tune.rightBinCenterY.toStringAsFixed(3)})',
              style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _copySnippet,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy values'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _setTune(ArenaLayoutTune.defaults()),
                  child: const Text('Reset'),
                ),
              ],
            ),
            if (_copyMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _copyMessage!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF2A6B32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Debug-only FAB to toggle the layout editor.
class ToiletCompetitiveLayoutEditorFab extends StatelessWidget {
  const ToiletCompetitiveLayoutEditorFab({
    super.key,
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return FloatingActionButton.small(
      heroTag: 'tc_layout_editor',
      backgroundColor: enabled ? const Color(0xFF3A6B3A) : const Color(0xFF5A5A5A),
      onPressed: onToggle,
      tooltip: enabled ? 'Close layout editor' : 'Tune bucket layout',
      child: Icon(enabled ? Icons.check : Icons.tune),
    );
  }
}
