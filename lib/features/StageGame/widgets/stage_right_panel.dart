import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/stage_game_models.dart';
import 'stage_panel_status.dart';

class StageRightPanel extends StatelessWidget {
  final StageGameState state;
  final StageGameConfig config;

  const StageRightPanel({
    super.key,
    required this.state,
    required this.config,
  });

  static const String _assetBase = 'assets/StageGameV2-image/right_panel';

  @override
  Widget build(BuildContext context) {
    final soundStatus = StagePanelStatusHelper.soundStatus(state, config);
    final lightStatus = StagePanelStatusHelper.lightStatus(state, config);
    final powerStatus = StagePanelStatusHelper.powerStatus(state);

    final feedbackStatus = _mainStatus(
      soundStatus,
      lightStatus,
      powerStatus,
    );

    final feedbackMessage = StagePanelStatusHelper.feedbackMessage(
      state,
      config,
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
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

        StageGamePage draait deze HELE panel met:

        RotatedBox(quarterTurns: 3)

        Daarom is de volgorde hier expres:

        1. STAGE BUILDER
        2. POWER MANAGEMENT
        3. LIGHT CONTROL
        4. SOUND CONTROL
        5. FEEDBACKBALK

        Na rotatie zie je:
        STAGE BUILDER links,
        3 control cards in het midden,
        feedbackbalk rechts.

        Deze versie fixt:
        - geen overflow tekst boven de cards
        - meter niet extreem lang, maar ook niet te klein
        - titel/value/target dichter bij elkaar
        - grotere leesbare fonts
        - iconen zijn nu Flutter icons, want image-icons zagen klein/raar uit
        - card-inhoud is gecentreerd en rustiger
        - meer Figma-achtige structuur: labelbox + compact info blok
      */
      child: Column(
        children: [
          SizedBox(
            height: 58,
            child: _buildStageBuilderBar(),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildControlCard(
              title: 'POWER\nMANAGEMENT',
              icon: Icons.bolt_rounded,
              meterTrackPath: '$_assetBase/meter_track_power.png',
              mainText: 'Power Load',
              valueText: state.currentPowerCapacity <= 0
                  ? '- W'
                  : '${state.totalPowerLoad}/${state.currentPowerCapacity} W',
              targetText: 'Do not overload',
              lowLabel: 'safe',
              highLabel: 'max',
              progress: _powerProgress(),
              status: powerStatus,
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildControlCard(
              title: 'LIGHT\nCONTROL',
              icon: Icons.lightbulb_outline_rounded,
              meterTrackPath: '$_assetBase/meter_track_light.png',
              mainText: 'Light Intensity',
              valueText: state.currentLightIntensity <= 0
                  ? '-'
                  : state.currentLightIntensity.toStringAsFixed(0),
              targetText:
                  'Target: ${config.lightTargetMin.toStringAsFixed(0)}-${config.lightTargetMax.toStringAsFixed(0)}',
              lowLabel: 'low',
              highLabel: 'high',
              progress: _lightProgress(),
              status: lightStatus,
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: _buildControlCard(
              title: 'SOUND\nCONTROL',
              icon: Icons.volume_up_rounded,
              meterTrackPath: '$_assetBase/meter_track_sound.png',
              mainText: 'Sound (dB)',
              valueText: state.currentSoundDb <= 0
                  ? '- dB'
                  : '${state.currentSoundDb.toStringAsFixed(0)} dB',
              targetText:
                  'Target: ${config.soundTargetMin.toStringAsFixed(0)}-${config.soundTargetMax.toStringAsFixed(0)} dB',
              lowLabel: '0',
              highLabel: '100 dB',
              progress: _soundProgress(),
              status: soundStatus,
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 96,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFDFCF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8D0C2),
          width: 1.3,
        ),
      ),
      child: Center(
        child: Text(
          'STAGE BUILDER',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.caveat(
            fontSize: 30,
            height: 0.9,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF2F2F35),
          ),
        ),
      ),
    );
  }

  Widget _buildControlCard({
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

    return _WarningShake(
      enabled: status == StagePanelStatus.warning,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          width: double.infinity,

          /*
            Extra rechter padding:
            Door quarterTurns: 3 wordt deze rechterkant de bovenkant.
            Hierdoor komt tekst zoals "84 dB" niet tegen/buiten de bovenrand.
          */
          padding: const EdgeInsets.fromLTRB(10, 8, 30, 8),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(cardBackground),
              fit: BoxFit.fill,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: statusColor.withOpacity(
                status == StagePanelStatus.neutral ? 0.35 : 0.92,
              ),
              width: status == StagePanelStatus.warning ? 2.1 : 1.4,
            ),
            boxShadow: [
              if (status == StagePanelStatus.warning)
                BoxShadow(
                  color: statusColor.withOpacity(0.16),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLabelBox(
                title: title,
                icon: icon,
                status: status,
              ),

              const SizedBox(width: 14),

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

  Widget _buildLabelBox({
    required String title,
    required IconData icon,
    required StagePanelStatus status,
  }) {
    final statusColor = StagePanelStatusHelper.statusColor(status);

    return Container(
      width: 118,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0F3).withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC9D4D8),
          width: 1.1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /*
            AANPASSING:
            Flutter icon gebruikt in plaats van image asset.
            Dit leest veel duidelijker in deze gedraaide rechter panel.
          */
          Icon(
            icon,
            size: 31,
            color: status == StagePanelStatus.warning
                ? statusColor
                : const Color(0xFF5F6E64),
          ),

          const SizedBox(height: 6),

          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.caveat(
                    fontSize: 20,
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
        /*
          AANPASSING:
          Compact blok met vaste max-breedte.
          Hierdoor verspreidt de info niet meer over de hele card.
          Het lijkt daardoor meer op de Figma-card.
        */
        final blockWidth = constraints.maxWidth.clamp(340.0, 430.0).toDouble();

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

                const SizedBox(height: 6),

                _buildMeterRow(
                  lowLabel: lowLabel,
                  highLabel: highLabel,
                  progress: progress,
                  meterTrackPath: meterTrackPath,
                ),

                const SizedBox(height: 6),

                Text(
                  targetText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 18,
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
              fontSize: 25,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2F3A32),
            ),
          ),
        ),

        const SizedBox(width: 8),

        if (status == StagePanelStatus.warning)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Image.asset(
              '$_assetBase/warning_badge.png',
              width: 18,
              height: 18,
              fit: BoxFit.contain,
            ),
          ),

        SizedBox(
          width: 110,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              valueText,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 23,
                height: 0.9,
                fontWeight: FontWeight.w900,
                color: status == StagePanelStatus.warning
                    ? const Color(0xFFD26455)
                    : const Color(0xFF2F3A32),
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
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              lowLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF63655E),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        /*
          AANPASSING:
          Meter is langer dan vorige versie,
          maar niet zo lang dat de card weer een rare kolom wordt.
        */
        Expanded(
          child: _buildAssetMeter(
            progress: progress,
            meterTrackPath: meterTrackPath,
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          width: 72,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              highLabel,
              maxLines: 1,
              style: GoogleFonts.caveat(
                fontSize: 17,
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
  }) {
    final safeProgress = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        const knobWidth = 22.0;
        const knobHeight = 30.0;

        final knobLeft = ((constraints.maxWidth - knobWidth) * safeProgress)
            .clamp(0.0, constraints.maxWidth - knobWidth);

        return SizedBox(
          height: 36,
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
                  height: 16,
                  fit: BoxFit.fill,
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                left: knobLeft,
                top: 3,
                child: Image.asset(
                  '$_assetBase/meter_knob.png',
                  width: knobWidth,
                  height: knobHeight,
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackBar({
    required String message,
    required StagePanelStatus status,
  }) {
    final isWarning = status == StagePanelStatus.warning;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 10, 24, 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('$_assetBase/card_bg_caution.png'),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWarning
                ? const Color(0xFFD26455)
                : const Color(0xFFE0D39E),
            width: isWarning ? 2.0 : 1.3,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              isWarning
                  ? '$_assetBase/warning_badge.png'
                  : '$_assetBase/icon_feedback.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Center(
                child: Text(
                  _shortFeedbackMessage(message),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 26,
                    height: 0.95,
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

  String _shortFeedbackMessage(String message) {
    if (message.contains('Power overload')) {
      return 'Power overload!';
    }

    if (message.contains('Power is getting risky')) {
      return 'Power is getting risky.';
    }

    if (message.contains('Sound is too loud')) {
      return 'Sound is too loud.';
    }

    if (message.contains('Sound is too low')) {
      return 'Sound is too low.';
    }

    if (message.contains('Lighting is too intense')) {
      return 'Light is too intense.';
    }

    if (message.contains('Lighting is too low')) {
      return 'Light is too low.';
    }

    if (message.contains('Nice balance')) {
      return 'Nice balance. Stage is ready.';
    }

    return 'Choose parts and watch the panel update.';
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

    if (state.hasAllSelections) {
      return StagePanelStatus.good;
    }

    return StagePanelStatus.neutral;
  }

  double _soundProgress() {
    if (state.currentSoundDb <= 0) {
      return 0;
    }

    return state.currentSoundDb / 100;
  }

  double _lightProgress() {
    if (state.currentLightIntensity <= 0) {
      return 0;
    }

    return state.currentLightIntensity / 100;
  }

  double _powerProgress() {
    if (state.currentPowerCapacity <= 0) {
      return 0;
    }

    return state.powerUsageRatio.clamp(0.0, 1.0);
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
      duration: const Duration(milliseconds: 360),
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
        final shake = math.sin(_controller.value * math.pi * 8) * 2.2;

        return Transform.translate(
          offset: Offset(shake, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}