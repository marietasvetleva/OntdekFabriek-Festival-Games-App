import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';

class FinalScreen extends StatelessWidget {
  const FinalScreen({super.key});

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
                  'assets/frame.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),

            // STAGE IN SPATE - mai transparent
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/stage.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // CONTINUT
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PATRAT CU SCORURI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 30, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(234, 234, 224, 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          // YOUR SCORE
                          // YOUR SCORE - titlu mare
                          Text(
                            'Your Score',
                            style: GoogleFonts.caveat(
                              fontSize: 48, // era 32
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // SUSTAINABILITY
                          _ScoreRow(label: 'Sustainability Score:'),
                          const SizedBox(height: 12),

                          // STABILITY
                          _ScoreRow(label: 'Stability Score:'),
                          const SizedBox(height: 12),

                          // AUDIENCE
                          _ScoreRow(label: 'Audience Satisfaction:'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // BUTON PLAY AGAIN
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SplashScreen()),
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

  const _ScoreRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF9DC4A8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.caveat(
          fontSize: 30, // era 20, mai mare
          fontWeight: FontWeight.w800, // era w700, mai gros
          color: Colors.black,
        ),
      ),
    );
  }
}
