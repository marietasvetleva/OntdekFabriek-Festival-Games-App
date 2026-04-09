import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'features/hangout/presentation/pages/hangout_quiz_page.dart';
import 'stage_page.dart';
import 'features/toilet/toilet_page.dart';
import 'FoodGame.dart';
import 'FestivalCleanerApp.dart';
import 'services/led_service.dart';
import 'scores_page.dart';
import 'home_page.dart';

class QRScannerPage extends StatefulWidget {
  final String festivalName;

  const QRScannerPage({super.key, required this.festivalName});

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
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _navigate(Widget page) async {
    _alreadyScanned = true;

    try {
      await controller.stop();
    } catch (_) {}

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );

    _alreadyScanned = false;

    _checkAndNavigateToScores(context);

    try {
      await controller.start();
    } catch (_) {}
  }

  Future<void> _handleQRCode(String qrValue) async {
    if (_alreadyScanned) return;

    final v = qrValue.trim().toLowerCase();

    if (v.contains('home') || v.contains('homepage') || v.contains('start')) {
      await _navigate(MyHomePage(festivalName: widget.festivalName));
      return;
    }

    if (v.contains('hangout')) {
      await _navigate(
        HangoutQuizPage(festivalName: widget.festivalName),
      );
      return;
    }

    if (v.contains('stage') || v.contains('podium')) {
      await _navigate(
        StagePage(
          festivalName: widget.festivalName,
          onMinigameCompleted: () {},
        ),
      );
      return;
    }

    if (v.contains('toilet') || v.contains('wc')) {
      await _navigate(ToiletGamePage());
      return;
    }

    if (v.contains('food') || v.contains('eten')) {
      await _navigate(const FoodTruckPage());
      return;
    }

    if (v.contains('waste') || v.contains('cleaner') || v.contains('schoon')) {
      await _navigate(const FestivalCleanerApp());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unknown QR: $qrValue')),
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

  Future<void> _openHome() async {
    await _navigate(MyHomePage(festivalName: widget.festivalName));
  }

  Future<void> _openStage() async {
    await _navigate(
      StagePage(
        festivalName: widget.festivalName,
        onMinigameCompleted: () {},
      ),
    );
  }

  Future<void> _openHangout() async {
    await _navigate(
      HangoutQuizPage(festivalName: widget.festivalName),
    );
  }

  Future<void> _openToilet() async {
    await _navigate(ToiletGamePage());
  }

  Future<void> _openFood() async {
    await _navigate(const FoodTruckPage());
  }

  Future<void> _openCleaner() async {
    await _navigate(const FestivalCleanerApp());
  }

  Widget _buildGameButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 120,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Choose a page or minigame',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildGameButton(
                label: 'Home',
                icon: Icons.home,
                onTap: _openHome,
              ),
              _buildGameButton(
                label: 'Stage',
                icon: Icons.music_note,
                onTap: _openStage,
              ),
              _buildGameButton(
                label: 'Hangout',
                icon: Icons.park,
                onTap: _openHangout,
              ),
              _buildGameButton(
                label: 'Toilet',
                icon: Icons.wc,
                onTap: _openToilet,
              ),
              _buildGameButton(
                label: 'Food',
                icon: Icons.fastfood,
                onTap: _openFood,
              ),
              _buildGameButton(
                label: 'Cleaner',
                icon: Icons.delete_sweep,
                onTap: _openCleaner,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection() {
    return SizedBox(
      height: 380,
      child: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
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
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: QRFramePainter(),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.70),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Scan a QR code or use the buttons below',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildScannerSection(),
              _buildQuickAccessPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    const frameSize = 220.0;
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
    canvas.drawRect(Rect.fromLTWH(0, frameTop, frameLeft, frameSize), paint);
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