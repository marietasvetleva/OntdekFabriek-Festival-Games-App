import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stage_panel_status.dart';

class StageFeedbackCard extends StatefulWidget {
  final String message;
  final StagePanelStatus status;

  const StageFeedbackCard({
    super.key,
    required this.message,
    required this.status,
  });

  @override
  State<StageFeedbackCard> createState() => _StageFeedbackCardState();
}

class _StageFeedbackCardState extends State<StageFeedbackCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(StageFeedbackCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.status == StagePanelStatus.warning) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundPath = StagePanelStatusHelper.cardBackground(widget.status);
    final statusColor = StagePanelStatusHelper.statusColor(widget.status);

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              if (widget.status == StagePanelStatus.warning)
                BoxShadow(
                  color: statusColor.withOpacity(0.18 + pulse * 0.15),
                  blurRadius: 10 + pulse * 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundPath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: statusColor.withOpacity(
              widget.status == StagePanelStatus.neutral ? 0.3 : 0.9,
            ),
            width: 1.7,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/StageGameV2-image/right_panel/icon_feedback.png',
              width: 34,
              height: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.message,
                  key: ValueKey(widget.message),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2F3A32),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}