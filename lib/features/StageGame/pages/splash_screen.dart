import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'role_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animatie intro: scena fade + zoom ──
  late AnimationController _introController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // ── Titlu slide in de sus ──
  late AnimationController _titleController;
  late Animation<Offset> _titleSlide;
  late Animation<double> _titleFade;

  // ── Buton pulsare ──
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    // 1. Scena apare cu fade + zoom (0 → 1 in 1.2s)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _introController, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
    );

    // 2. Titlu slide de sus in jos, cu delay dupa scena
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, -0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack),
        );
    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    // 3. Buton pulseaza continuu dupa ce apare
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Secventa: scena → titlu
    _introController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _titleController.forward();
      });
    });
  }

  @override
  void dispose() {
    _introController.dispose();
    _titleController.dispose();
    _pulseController.dispose();
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
            // ── Frame ──
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

            // ── Scena cu fade + zoom ──
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _introController,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(scale: _scaleAnim.value, child: child),
                ),
                child: Image.asset(
                  'assets/StageGameV2-image/stage.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ── Titlu slide in de sus ──
            Positioned(
              top: size.height * 0.14,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _titleController,
                builder: (context, child) => FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(position: _titleSlide, child: child),
                ),
                child: Text(
                  'Stage Setup Challenge',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.caveat(
                    fontSize: 78,
                    fontWeight: FontWeight.w900,
                    color: const Color.fromARGB(255, 14, 14, 14),
                  ),
                ),
              ),
            ),

            // ── Buton Start pulsator ──
            Positioned(
              bottom: size.height * 0.08,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) =>
                      Transform.scale(scale: _pulseAnim.value, child: child),
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A7C59).withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
