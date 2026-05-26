import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stage_panel_status.dart';

class StageMeterCard extends StatefulWidget {
  final String title;
  final String iconPath;
  final String valueText;
  final String targetText;
  final double progress;
  final StagePanelStatus status;
  final String meterAssetPath;
  final bool mainWarning;

  const StageMeterCard({
    super.key,
    required this.title,
    required this.iconPath,
    required this.valueText,
    required this.targetText,
    required this.progress,
    required this.status,
    required this.meterAssetPath,
    this.mainWarning = false,
  });

  @override
  State<StageMeterCard> createState() => _StageMeterCardState();
}

class _StageMeterCardState extends State<StageMeterCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _updatePulse();
  }

  @override
  void didUpdateWidget(StageMeterCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updatePulse();

    if (widget.mainWarning &&
        oldWidget.status != StagePanelStatus.warning &&
        widget.status == StagePanelStatus.warning) {
      _shakeController.forward(from: 0);
    }
  }

  void _updatePulse() {
    final shouldPulse = widget.status == StagePanelStatus.caution ||
        widget.status == StagePanelStatus.warning;

    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = StagePanelStatusHelper.statusColor(widget.status);
    final backgroundPath = StagePanelStatusHelper.cardBackground(widget.status);
    final progress = widget.progress.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _shakeController,
      ]),
      builder: (context, child) {
        final pulse = _pulseController.value;
        final shake = widget.mainWarning
            ? math.sin(_shakeController.value * math.pi * 8) * 5
            : 0.0;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Transform.scale(
            scale: 1 + (pulse * 0.012),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundPath),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: statusColor.withOpacity(
              widget.status == StagePanelStatus.neutral ? 0.35 : 0.95,
            ),
            width: widget.status == StagePanelStatus.warning ? 2.6 : 1.8,
          ),
          boxShadow: [
            if (widget.status == StagePanelStatus.caution)
              BoxShadow(
                color: statusColor.withOpacity(0.22),
                blurRadius: 9,
                spreadRadius: 1,
              ),
            if (widget.status == StagePanelStatus.warning)
              BoxShadow(
                color: statusColor.withOpacity(0.35),
                blurRadius: 14,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CardHeader(
              title: widget.title,
              iconPath: widget.iconPath,
              status: widget.status,
              statusColor: statusColor,
              showWarningBadge: widget.status == StagePanelStatus.warning,
            ),
            const SizedBox(height: 8),
            _MeterLine(
              progress: progress,
              meterAssetPath: widget.meterAssetPath,
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    widget.valueText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2F3A32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.targetText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.caveat(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2F3A32),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final String iconPath;
  final StagePanelStatus status;
  final Color statusColor;
  final bool showWarningBadge;

  const _CardHeader({
    required this.title,
    required this.iconPath,
    required this.status,
    required this.statusColor,
    required this.showWarningBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          iconPath,
          width: 30,
          height: 30,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F3A32),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF2F3A32),
              width: 1.5,
            ),
          ),
        ),
        if (showWarningBadge) ...[
          const SizedBox(width: 6),
          Image.asset(
            'assets/StageGameV2-image/right_panel/warning_badge.png',
            width: 25,
            height: 25,
          ),
        ],
      ],
    );
  }
}

class _MeterLine extends StatelessWidget {
  final double progress;
  final String meterAssetPath;

  const _MeterLine({
    required this.progress,
    required this.meterAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const knobWidth = 30.0;
        final left = ((constraints.maxWidth - knobWidth) * progress)
            .clamp(0.0, constraints.maxWidth - knobWidth);

        return SizedBox(
          height: 39,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Image.asset(
                meterAssetPath,
                width: double.infinity,
                height: 36,
                fit: BoxFit.fill,
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                left: left,
                top: 0,
                child: Image.asset(
                  'assets/StageGameV2-image/right_panel/meter_knob.png',
                  width: knobWidth,
                  height: 39,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}