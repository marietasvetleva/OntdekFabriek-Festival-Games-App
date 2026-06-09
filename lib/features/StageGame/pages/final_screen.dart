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
  bool _leftPlayAgainReady = false;
  bool _rightPlayAgainReady = false;

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

  void _setLeftPlayAgainReady() {
    if (_leftPlayAgainReady) return;

    setState(() {
      _leftPlayAgainReady = true;
    });

    _checkBothPlayAgainReady();
  }

  void _setRightPlayAgainReady() {
    if (_rightPlayAgainReady) return;

    setState(() {
      _rightPlayAgainReady = true;
    });

    _checkBothPlayAgainReady();
  }

  void _checkBothPlayAgainReady() {
    if (!_leftPlayAgainReady || !_rightPlayAgainReady) return;

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        ),
        (route) => false,
      );
    });
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

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: SizedBox(
                            width: size.height * 0.78,
                            height: size.width * 0.36,
                            child: _FinalResultPanel(
                              sustainabilityScore: widget.sustainabilityScore,
                              stabilityScore: widget.stabilityScore,
                              audienceScore: widget.audienceScore,
                              crowdReaction: widget.crowdReaction,
                              endComment: widget.endComment,
                              isPlayAgainReady: _leftPlayAgainReady,
                              onPlayAgainReady: _setLeftPlayAgainReady,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: SizedBox(
                            width: size.height * 0.78,
                            height: size.width * 0.36,
                            child: _FinalResultPanel(
                              sustainabilityScore: widget.sustainabilityScore,
                              stabilityScore: widget.stabilityScore,
                              audienceScore: widget.audienceScore,
                              crowdReaction: widget.crowdReaction,
                              endComment: widget.endComment,
                              isPlayAgainReady: _rightPlayAgainReady,
                              onPlayAgainReady: _setRightPlayAgainReady,
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

class _FinalResultPanel extends StatelessWidget {
  final int sustainabilityScore;
  final int stabilityScore;
  final int audienceScore;
  final String crowdReaction;
  final String endComment;
  final bool isPlayAgainReady;
  final VoidCallback onPlayAgainReady;

  const _FinalResultPanel({
    required this.sustainabilityScore,
    required this.stabilityScore,
    required this.audienceScore,
    required this.crowdReaction,
    required this.endComment,
    required this.isPlayAgainReady,
    required this.onPlayAgainReady,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(234, 234, 224, 0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  crowdReaction,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.caveat(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endComment,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                _ScoreRow(
                  label: 'Sustainability Score',
                  value: sustainabilityScore,
                ),
                const SizedBox(height: 8),
                _ScoreRow(
                  label: 'Stability Score',
                  value: stabilityScore,
                ),
                const SizedBox(height: 8),
                _ScoreRow(
                  label: 'Audience Satisfaction',
                  value: audienceScore,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        GestureDetector(
          onTap: isPlayAgainReady ? null : onPlayAgainReady,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 160,
            height: 44,
            decoration: BoxDecoration(
              color: isPlayAgainReady
                  ? const Color(0xFF3F6F4A)
                  : const Color(0xFF4A7C59),
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                isPlayAgainReady ? '✓ Ready' : 'Play Again',
                style: GoogleFonts.caveat(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF9DC4A8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.caveat(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value.toString(),
            style: GoogleFonts.caveat(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}