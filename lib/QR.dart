import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'HangOutGame.dart';
import 'FoodGame.dart';
import 'FestivalCleanerApp.dart';
import 'scores_page.dart';

import 'features/ToiletCompetitive/toiletC_page.dart';
import 'features/StageGame/pages/splash_screen.dart';

import 'services/led_service.dart';

class QRScannerPage extends StatefulWidget {
  final String festivalName;

  const QRScannerPage({
    super.key,
    required this.festivalName,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late MobileScannerController controller;
  bool _alreadyScanned = false;

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      facing: CameraFacing.front,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _navigate(Widget page) async {
    _alreadyScanned = true;

    await controller.stop();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    _alreadyScanned = false;

    _checkAndNavigateToScores(context);

    await controller.start();
  }

  Future<void> _handleQRCode(String qrValue) async {
    if (_alreadyScanned) return;

    final v = qrValue.trim().toLowerCase();

    // Hangout
    if (v.contains('hangout')) {
      await _navigate(const HangoutQuizPage());
      return;
    }

    // Stage Game
    if (v.contains('stage') || v.contains('podium')) {
      await _navigate(const SplashScreen());
      return;
    }

    // Toilet
    if (v.contains('toilet') || v.contains('wc')) {
      await _navigate(const ToiletCompetitivePage());
      return;
    }

    // Food
    if (v.contains('food') || v.contains('eten')) {
      await _navigate(const FoodTruckPage());
      return;
    }

    // Cleaner
    if (v.contains('waste') ||
        v.contains('cleaner') ||
        v.contains('schoon')) {
      await _navigate(const FestivalCleanerApp());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Onbekende QR: $qrValue'),
      ),
    );
  }

  void _checkAndNavigateToScores(BuildContext context) {
    final completed = LedService.getCompletedStatus();

    if (completed.values.every((v) => v)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ScoresPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 139, 210, 142),

      appBar: AppBar(
        title: Text('${widget.festivalName} - Scan QR Codes'),
        backgroundColor: const Color(0xFF2E7D32),

        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: controller,

            onDetect: (capture) {
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;

                if (raw != null) {
                  _handleQRCode(raw);
                  break;
                }
              }
            },
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: QRFramePainter(),
              ),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,

            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Container(
                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Text(
                      'Scan een QR code om een minigame te spelen',
                      textAlign: TextAlign.center,

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () =>
                        _navigate(const ToiletCompetitivePage()),
                    child: const Text('Test Toilet Competitive'),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () =>
                        _navigate(const SplashScreen()),
                    child: const Text('Test Stage Game'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    const frameSize = 250.0;

    final frameLeft = (width - frameSize) / 2;
    final frameTop = (height - frameSize) / 2;

    final paint = Paint()
      ..color = Colors.black.withOpacity(0.4);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, frameTop),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        frameTop + frameSize,
        width,
        height - frameTop - frameSize,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        frameTop,
        frameLeft,
        frameSize,
      ),
      paint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        frameLeft + frameSize,
        frameTop,
        width - frameLeft - frameSize,
        frameSize,
      ),
      paint,
    );

    final framePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(
        frameLeft,
        frameTop,
        frameSize,
        frameSize,
      ),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(QRFramePainter oldDelegate) => false;
}