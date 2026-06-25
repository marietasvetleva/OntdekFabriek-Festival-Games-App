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
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController controller;
  bool _alreadyScanned = false;
  bool _cameraStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    controller = MobileScannerController(
      facing: CameraFacing.front,
      autoStart: false,
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted || _cameraStarted) return;

    try {
      await controller.start();
      _cameraStarted = true;
    } catch (e) {
      debugPrint('Camera start error: $e');
    }
  }

  Future<void> _stopCamera() async {
    if (!_cameraStarted) return;

    try {
      await controller.stop();
      _cameraStarted = false;
    } catch (e) {
      debugPrint('Camera stop error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    if (state == AppLifecycleState.resumed) {
      _startCamera();
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    }
  }

  Future<void> _navigate(Widget page) async {
    if (_alreadyScanned || !mounted) return;

    _alreadyScanned = true;

    await _stopCamera();

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;

    _alreadyScanned = false;

    await _startCamera();

    if (!mounted) return;

    _checkAndNavigateToScores();
  }

  Future<void> _handleQRCode(String qrValue) async {
    final v = qrValue.trim().toLowerCase();

    if (v.contains('hangout')) {
      await _navigate(const HangoutQuizPage());
      return;
    }

    if (v.contains('stage') || v.contains('podium')) {
      await _navigate(
        const SplashScreen(),
      );
      return;
    }

    if (v.contains('toilet') || v.contains('wc')) {
      await _navigate(
        const ToiletCompetitivePage(),
      );
      return;
    }

    if (v.contains('food') || v.contains('eten')) {
      await _navigate(const FoodTruckPage());
      return;
    }

    if (v.contains('waste') ||
        v.contains('cleaner') ||
        v.contains('schoon')) {
      await _navigate(const FestivalCleanerApp());
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Onbekende QR: $qrValue'),
      ),
    );
  }

  void _checkAndNavigateToScores() {
    if (!mounted) return;

    final completed = LedService.getCompletedStatus();

    if (completed.values.every((v) => v)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScoresPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 139, 210, 142),
      appBar: AppBar(
        title: const Text('Scan QR Codes'),
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
          Positioned.fill(
            child: MobileScanner(
              controller: controller,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text(
                    'Camera error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              },
              onDetect: (capture) {
                if (_alreadyScanned) return;

                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue;

                  if (raw != null) {
                    _handleQRCode(raw);
                    break;
                  }
                }
              },
            ),
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
                  // const SizedBox(height: 10),
                  // ElevatedButton(
                  //   onPressed: () => _navigate(
                  //     const ToiletCompetitivePage(),
                  //   ),
                  //   child: const Text('Test Toilet Competitive'),
                  // ),

                  // const SizedBox(height: 10),

                  // ElevatedButton(
                  //   onPressed: () => _navigate(
                  //     const SplashScreen(),
                  //   ),
                  //   child: const Text('Test Stage Game'),
                  // ),
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

    final paint = Paint()..color = Colors.black.withOpacity(0.4);

    canvas.drawRect(Rect.fromLTWH(0, 0, width, frameTop), paint);

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
      Rect.fromLTWH(0, frameTop, frameLeft, frameSize),
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
      Rect.fromLTWH(frameLeft, frameTop, frameSize, frameSize),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(QRFramePainter oldDelegate) => false;
}