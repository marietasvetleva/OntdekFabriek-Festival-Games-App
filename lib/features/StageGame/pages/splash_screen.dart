import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

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

            // SCENA - foarte mare, ocupa aproape tot
            Positioned.fill(
              child: Image.asset(
                'assets/stage.png',
                fit: BoxFit.contain,
              ),
            ),

            // TITLU - sus, peste scena
            Positioned(
              top: size.height * 0.14,
              left: 0,
              right: 0,
              child: Text(
                'Stage Setup Challenge',
                textAlign: TextAlign.center,
                style: GoogleFonts.caveat(
                  fontSize: 51,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF555555),
                ),
              ),
            ),

            // BUTON - jos, peste scena
            Positioned(
              bottom: size.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RoleSelectionScreen(),
                      ),
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
                    child: const Center(
                      child: Text(
                        'Start',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
