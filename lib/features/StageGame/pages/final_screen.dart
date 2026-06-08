import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/stage_audio_service.dart';
import 'splash_screen.dart';

class FinalScreen extends StatefulWidget {
  final int sustainabilityScore;
  final int stabilityScore;
  final int audienceScore;
  final String crowdReaction;
  final String endComment;

  const FinalScreen({
    super.key,
    required this.sustainabilityScore,
    required this.stabilityScore,
    required this.audienceScore,
    required this.crowdReaction,
    required this.endComment,
  });

  @override
  State<FinalScreen> createState() => _FinalScreenState();
}

class _FinalScreenState extends State<FinalScreen> {
  final StageAudioService _audioService = StageAudioService();

  bool _soundPlayed = false;

  @override
  void initState() {
    super.initState();
    _playResultSound();
  }

  Future<void> _playResultSound() async {
    await _audioService.init();

    if (!mounted || _soundPlayed) return;

    _soundPlayed = true;

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    final reaction = widget.crowdReaction.toLowerCase();
    final comment = widget.endComment.toLowerCase();

    final isBadResult = reaction.contains('boo') ||
        comment.contains('failed') ||
        comment.contains('overload') ||
        widget.audienceScore < 50;

    if (isBadResult) {
      _audioService.playCrowdBoo();
    } else {
      _audioService.playCrowdCheer();
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // FRAME
            Positioned(
              top: -60,
              left: -55,
              right: -84,
              bottom: -55,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/StageGameV2-image/frame.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // STAGE BACKGROUND
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/stage.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // CONTENT
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 30,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(234, 234, 224, 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.crowdReaction,
                            style: GoogleFonts.caveat(
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            widget.endComment,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.caveat(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _ScoreRow(
                            label: 'Sustainability Score',
                            value: widget.sustainabilityScore,
                          ),

                          const SizedBox(height: 12),

                          _ScoreRow(
                            label: 'Stability Score',
                            value: widget.stabilityScore,
                          ),

                          const SizedBox(height: 12),

                          _ScoreRow(
                            label: 'Audience Satisfaction',
                            value: widget.audienceScore,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // PLAY AGAIN BUTTON
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SplashScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      child: Container(
                        width: 180,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Play Again',
                            style: GoogleFonts.caveat(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final int value;

  const _ScoreRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF9DC4A8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.caveat(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            value.toString(),
            style: GoogleFonts.caveat(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}