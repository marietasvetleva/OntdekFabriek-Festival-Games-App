import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'Festival_name_page.dart';

class IntroVideoPage extends StatefulWidget {
  const IntroVideoPage({super.key});

  @override
  State<IntroVideoPage> createState() => _IntroVideoPageState();
}

class _IntroVideoPageState extends State<IntroVideoPage> {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/Introvideo.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _controller!
          ..setLooping(false)
          ..play();
      });
    _controller?.addListener(() {
      final c = _controller;
      if (c == null || !c.value.isInitialized) return;
      final dur = c.value.duration;
      final pos = c.value.position;
      if (dur > Duration.zero && pos >= dur && !_ended) {
        setState(() => _ended = true);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const FestivalNamePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_initialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),

          // Skip while playing
          if (!_ended)
            Positioned(
              top: 40,
              right: 20,
              child: TextButton(
                onPressed: () => setState(() => _ended = true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black.withOpacity(0.3),
                ),
                child: const Text('Sla over'),
              ),
            ),

          // Continue when finished or skipped
          if (_ended)
            Positioned(
              left: 20,
              right: 20,
              bottom: 40,
              child: ElevatedButton.icon(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ga verder'),
              ),
            ),
        ],
      ),
    );
  }
}
