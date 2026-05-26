import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/stage_game_models.dart';
import 'stage_panel_status.dart';

class StageRightPanel extends StatefulWidget {
  final StageGameState state;
  final StageGameConfig config;

  const StageRightPanel({
    super.key,
    required this.state,
    required this.config,
  });

  @override
  State<StageRightPanel> createState() => _StageRightPanelState();
}

class _StageRightPanelState extends State<StageRightPanel>
    with SingleTickerProviderStateMixin {
  static const String _assetBase = 'assets/StageGameV2-image/right_panel';

  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();

    /*
      AANWIJZING:
      Deze controller maakt de rechter console levendiger:
      - kleine scan-line over actieve cards
      - meter knob pulse
      - icon pulse
      - feedback glow
      - ready sparkles
    */
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final soundStatus = StagePanelStatusHelper.soundStatus(
      widget.state,
      widget.config,
    );

    final lightStatus = StagePanelStatusHelper.lightStatus(
      widget.state,
      widget.config,
    );

    final powerStatus = StagePanelStatusHelper.powerStatus(widget.state);

    final feedbackStatus = _mainStatus(
      soundStatus,
      lightStatus,
      powerStatus,
    );

    final feedbackMessage = StagePanelStatusHelper.feedbackMessage(
      widget.state,
      widget.config,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F4EA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF435245),
          width: 2.4,
        ),
      ),

      /*
        BELANGRIJKE AANWIJZING:

        StageGamePage draait deze hele panel met:
        RotatedBox(quarterTurns: 3)

        Daarom is deze volgorde expres:
        1. STAGE BUILDER
        2. POWER MANAGEMENT
        3. LIGHT CONTROL
        4. SOUND CONTROL
        5. FEEDBACK / COMMAND BOX

        Nieuwe fix:
        - Rechter panel is nu smaller in StageGamePage.
        - Daarom zijn iconen, label boxen en feedback kleiner gemaakt.
        - Dit zorgt dat het niet meer voelt als groot dashboard.
        - De controls blijven leesbaar maar pakken minder ruimte.
      */
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: _buildStageBuilderBar(),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey:
                  'power-${widget.state.totalPowerLoad}-${widget.state.currentPowerCapacity}-$powerStatus',
              title: 'POWER\nMANAGEMENT',
              icon: Icons.bolt_rounded,
              meterTrackPath: '$_assetBase/meter_track_power.png',
              mainText: 'Power Load',
              valueText: widget.state.currentPowerCapacity <= 0
                  ? '- W'
                  : '${widget.state.totalPowerLoad}/${widget.state.currentPowerCapacity} W',
              targetText: 'Do not overload',
              lowLabel: 'safe',
              highLabel: 'max',
              progress: _powerProgress(),
              status: powerStatus,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey:
                  'light-${widget.state.currentLightIntensity}-$lightStatus',
              title: 'LIGHT\nCONTROL',
              icon: Icons.lightbulb_outline_rounded,
              meterTrackPath: '$_assetBase/meter_track_light.png',
              mainText: 'Light Intensity',
              valueText: widget.state.currentLightIntensity <= 0
                  ? '-'
                  : widget.state.currentLightIntensity.toStringAsFixed(0),
              targetText:
                  'Target: ${widget.config.lightTargetMin.toStringAsFixed(0)}-${widget.config.lightTargetMax.toStringAsFixed(0)}',
              lowLabel: 'low',
              highLabel: 'high',
              progress: _lightProgress(),
              status: lightStatus,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _buildControlCard(
              cardKey: 'sound-${widget.state.currentSoundDb}-$soundStatus',
              title: 'SOUND\nCONTROL',
              icon: Icons.volume_up_rounded,
              meterTrackPath: '$_assetBase/meter_track_sound.png',
              mainText: 'Sound (dB)',
              valueText: widget.state.currentSoundDb <= 0
                  ? '- dB'
                  : '${widget.state.currentSoundDb.toStringAsFixed(0)} dB',
              targetText:
                  'Target: ${widget.config.soundTargetMin.toStringAsFixed(0)}-${widget.config.soundTargetMax.toStringAsFixed(0)} dB',
              lowLabel: '0',
              highLabel: '100 dB',
              progress: _soundProgress(),
              status: soundStatus,
            ),
          ),
          const SizedBox(height: 7),

          /*
            AANWIJZING:
            Feedback box is kleiner gemaakt.

            Eerst: 78
            Nu: 64

            Waarom?
            - Rechter panel is smaller geworden.
            - Feedback hoeft niet zo veel ruimte te pakken.
            - Hierdoor krijgen de meters meer ademruimte.
          */
          SizedBox(
            height: 64,
            child: _buildFeedbackBar(
              message: feedbackMessage,
              status: feedbackStatus,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageBuilderBar() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFCF7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD8D0C2),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF435245).withOpacity(0.04 + pulse * 0.05),
                blurRadius: 7 + pulse * 3,
                spreadRadius: 0.2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: Text(
          'STAGE BUILDER',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.caveat(
            fontSize: 28,
            height: 0.9,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2F2F35),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String cardKey,
    required String title,
    required IconData icon,
    required String meterTrackPath,
    required String mainText,
    required String valueText,
    required String targetText,
    required String lowLabel,
    required String highLabel,
    required double progress,
    required StagePanelStatus status,
  }) {
    final statusColor = StagePanelStatusHelper.statusColor(status);
    final cardBackground = StagePanelStatusHelper.cardBackground(status);

    return TweenAnimationBuilder<double>(
      key: ValueKey(cardKey),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, popValue, child) {
        final popScale = 1.0 + math.sin(popValue * math.pi) * 0.014;

        return Transform.scale(
          scale: popScale,
          child: child,
        );
      },
      child: _WarningShake(
        enabled: status == StagePanelStatus.warning,
        child: AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            final pulse = _loopController.value;
            final isActive = status != StagePanelStatus.neutral;

            return ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(8, 7, 22, 7),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(cardBackground),
                    fit: BoxFit.fill,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: statusColor.withOpacity(
                      status == StagePanelStatus.neutral ? 0.35 : 0.95,
                    ),
                    width: status == StagePanelStatus.warning ? 2.0 : 1.35,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: statusColor.withOpacity(
                          status == StagePanelStatus.warning
                              ? 0.13 + pulse * 0.09
                              : 0.05 + pulse * 0.04,
                        ),
                        blurRadius: status == StagePanelStatus.warning
                            ? 10 + pulse * 5
                            : 7 + pulse * 3,
                        spreadRadius:
                            status == StagePanelStatus.warning ? 0.8 : 0.2,
                      ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: child ?? const SizedBox.shrink(),
                    ),
                    if (isActive)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _buildScanLine(status),
                        ),
                      ),
                    if (status == StagePanelStatus.good)
                      Positioned(
                        right: 14,
                        top: 10,
                        child: _buildGoodSparkle(),
                      ),
                  ],
                ),
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLabelBox(
                title: title,
                icon: icon,
                status: status,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _buildCompactInfoBlock(
                  mainText: mainText,
                  valueText: valueText,
                  targetText: targetText,
                  lowLabel: lowLabel,
                  highLabel: highLabel,
                  progress: progress,
                  meterTrackPath: meterTrackPath,
                  status: status,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanLine(StagePanelStatus status) {
    final color = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final x = _loopController.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  left: constraints.maxWidth * x - 16,
                  top: 6,
                  bottom: 6,
                  child: Container(
                    width: 9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.12),
                          color.withOpacity(0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGoodSparkle() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = 1.0 + _loopController.value * 0.13;

        return Transform.scale(
          scale: pulse,
          child: Text(
            '✦',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF79A982).withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabelBox({
    required String title,
    required IconData icon,
    required StagePanelStatus status,
  }) {
    final statusColor = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;
        final iconScale =
            status == StagePanelStatus.neutral ? 1.0 : 1.0 + (pulse * 0.05);

        return Container(
          /*
            AANWIJZING:
            Label box kleiner gemaakt.

            Eerst: 118
            Nu: 100

            Hierdoor passen de meters beter in het smallere right panel.
          */
          width: 100,
          height: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F0F3).withOpacity(0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: status == StagePanelStatus.neutral
                  ? const Color(0xFFC9D4D8)
                  : statusColor.withOpacity(0.45 + pulse * 0.18),
              width: 1.1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Transform.scale(
                    scale: iconScale,
                    child: Icon(
                      icon,
                      /*
                        AANWIJZING:
                        Icon kleiner gemaakt.

                        Eerst: 31
                        Nu: 25
                      */
                      size: 25,
                      color: status == StagePanelStatus.warning
                          ? statusColor
                          : const Color(0xFF5F6E64),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    top: -4,
                    child: _buildStatusDot(status),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        /*
                          AANWIJZING:
                          Control label font kleiner gemaakt.

                          Eerst: 20
                          Nu: 17
                        */
                        fontSize: 17,
                        height: 0.84,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F2F35),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusDot(StagePanelStatus status) {
    if (status == StagePanelStatus.neutral) {
      return const SizedBox.shrink();
    }

    final color = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = 1.0 + (_loopController.value * 0.10);

        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.9),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactInfoBlock({
    required String mainText,
    required String valueText,
    required String targetText,
    required String lowLabel,
    required String highLabel,
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final blockWidth = constraints.maxWidth.clamp(295.0, 360.0).toDouble();

        return Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: blockWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitleAndValueRow(
                  mainText: mainText,
                  valueText: valueText,
                  status: status,
                ),
                const SizedBox(height: 3),
                _buildMeterRow(
                  lowLabel: lowLabel,
                  highLabel: highLabel,
                  progress: progress,
                  meterTrackPath: meterTrackPath,
                  status: status,
                ),
                const SizedBox(height: 3),
                Text(
                  targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    height: 0.9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF63655E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitleAndValueRow({
    required String mainText,
    required String valueText,
    required StagePanelStatus status,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            mainText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.caveat(
              fontSize: 22,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F3A32),
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 96,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: FittedBox(
              key: ValueKey(valueText),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                valueText,
                maxLines: 1,
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  height: 0.9,
                  fontWeight: FontWeight.w900,
                  color: status == StagePanelStatus.warning
                      ? const Color(0xFFD26455)
                      : const Color(0xFF2F3A32),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeterRow({
    required String lowLabel,
    required String highLabel,
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              lowLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF63655E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: _buildAssetMeter(
            progress: progress,
            meterTrackPath: meterTrackPath,
            status: status,
          ),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 40,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              highLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF63655E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetMeter({
    required double progress,
    required String meterTrackPath,
    required StagePanelStatus status,
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const knobWidth = 20.0;
        const knobHeight = 28.0;

        final knobLeft = ((constraints.maxWidth - knobWidth) * safeProgress)
            .clamp(0.0, constraints.maxWidth - knobWidth);

        return AnimatedBuilder(
          animation: _loopController,
          builder: (context, child) {
            final pulse = _loopController.value;
            final knobScale =
                status == StagePanelStatus.neutral ? 1.0 : 1.0 + (pulse * 0.06);

            return SizedBox(
              height: 34,
              child: Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 11,
                    child: Image.asset(
                      meterTrackPath,
                      height: 15,
                      fit: BoxFit.fill,
                    ),
                  ),
                  if (status != StagePanelStatus.neutral)
                    Positioned(
                      left: (constraints.maxWidth - 16) * pulse,
                      top: 12,
                      child: Container(
                        width: 14,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    left: knobLeft,
                    top: 3,
                    child: Transform.scale(
                      scale: knobScale,
                      child: Image.asset(
                        '$_assetBase/meter_knob.png',
                        width: knobWidth,
                        height: knobHeight,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFeedbackBar({
    required String message,
    required StagePanelStatus status,
  }) {
    final isWarning = status == StagePanelStatus.warning;
    final isReady =
        status == StagePanelStatus.good && widget.state.hasAllSelections;
    final statusColor = StagePanelStatusHelper.statusColor(status);

    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isReady
                      ? '$_assetBase/card_bg_good.png'
                      : '$_assetBase/card_bg_caution.png',
                ),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWarning
                    ? const Color(0xFFD26455)
                    : isReady
                        ? const Color(0xFF79A982)
                        : const Color(0xFFE0D39E),
                width: isWarning ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(
                    isWarning ? 0.15 + pulse * 0.10 : 0.05 + pulse * 0.04,
                  ),
                  blurRadius: isWarning ? 10 + pulse * 4 : 7 + pulse * 3,
                  spreadRadius: isWarning ? 0.6 : 0.2,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isReady)
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildReadySparkles(),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _loopController,
                  builder: (context, child) {
                    final scale = 1.0 + _loopController.value * 0.07;

                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Image.asset(
                    isWarning
                        ? '$_assetBase/warning_badge.png'
                        : '$_assetBase/icon_feedback.png',
                    /*
                      AANWIJZING:
                      Feedback icon kleiner gemaakt.

                      Eerst: 24
                      Nu: 20
                    */
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      _consoleFeedbackMessage(message),
                      key: ValueKey(_consoleFeedbackMessage(message)),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.caveat(
                        /*
                          AANWIJZING:
                          Feedback tekst kleiner gemaakt.

                          Eerst: 25
                          Nu: 21
                        */
                        fontSize: 21,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2F3A32),
                      ),
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

  Widget _buildReadySparkles() {
    return AnimatedBuilder(
      animation: _loopController,
      builder: (context, child) {
        final pulse = _loopController.value;

        return Stack(
          children: [
            Positioned(
              left: 12 + pulse * 10,
              top: 7,
              child: _sparkle(8),
            ),
            Positioned(
              right: 16 + pulse * 8,
              bottom: 7,
              child: _sparkle(7),
            ),
          ],
        );
      },
    );
  }

  Widget _sparkle(double size) {
    return Text(
      '✦',
      style: TextStyle(
        fontSize: size,
        color: const Color(0xFF79A982).withOpacity(0.65),
      ),
    );
  }

  String _consoleFeedbackMessage(String message) {
    if (message.contains('Power overload')) {
      return 'POWER OVERLOAD!';
    }
    if (message.contains('Power is getting risky')) {
      return 'POWER RISKY!';
    }
    if (message.contains('Sound is too loud')) {
      return 'SOUND TOO LOUD!';
    }
    if (message.contains('Sound is too low')) {
      return 'SOUND TOO LOW!';
    }
    if (message.contains('Lighting is too intense')) {
      return 'LIGHT TOO HIGH!';
    }
    if (message.contains('Lighting is too low')) {
      return 'LIGHT TOO LOW!';
    }
    if (message.contains('Nice balance')) {
      return 'STAGE READY!';
    }
    return 'CHOOSE PARTS!';
  }

  StagePanelStatus _mainStatus(
    StagePanelStatus sound,
    StagePanelStatus light,
    StagePanelStatus power,
  ) {
    if (power == StagePanelStatus.warning ||
        sound == StagePanelStatus.warning ||
        light == StagePanelStatus.warning) {
      return StagePanelStatus.warning;
    }

    if (power == StagePanelStatus.caution ||
        sound == StagePanelStatus.caution ||
        light == StagePanelStatus.caution) {
      return StagePanelStatus.caution;
    }

    if (widget.state.hasAllSelections) {
      return StagePanelStatus.good;
    }

    return StagePanelStatus.neutral;
  }

  double _soundProgress() {
    if (widget.state.currentSoundDb <= 0) {
      return 0;
    }
    return widget.state.currentSoundDb / 100;
  }

  double _lightProgress() {
    if (widget.state.currentLightIntensity <= 0) {
      return 0;
    }
    return widget.state.currentLightIntensity / 100;
  }

  double _powerProgress() {
    if (widget.state.currentPowerCapacity <= 0) {
      return 0;
    }
    return widget.state.powerUsageRatio.clamp(0.0, 1.0);
  }
}

class _WarningShake extends StatefulWidget {
  final bool enabled;
  final Widget child;

  const _WarningShake({
    required this.enabled,
    required this.child,
  });

  @override
  State<_WarningShake> createState() => _WarningShakeState();
}

class _WarningShakeState extends State<_WarningShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(_WarningShake oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled && !oldWidget.enabled) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shake = math.sin(_controller.value * math.pi * 8) * 2.4;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}