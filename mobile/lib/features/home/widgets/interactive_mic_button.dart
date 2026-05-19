import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive microphone button using mic_home.png asset.
/// AnimatedScale provides tap/hold visual feedback.
/// onTap + onLongPressEnd both trigger [onActivated].
class InteractiveMicButton extends StatefulWidget {
  final VoidCallback onStart;
  final VoidCallback onStop;

  const InteractiveMicButton({
    super.key,
    required this.onStart,
    required this.onStop,
  });

  @override
  State<InteractiveMicButton> createState() => _InteractiveMicButtonState();
}

class _InteractiveMicButtonState extends State<InteractiveMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Max recording time 15s
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressDown() {
    setState(() => _scale = 0.92);
    _controller.forward();
  }

  void _onPressUp() {
    setState(() => _scale = 1.0);
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapDown: (_) {
            _onPressDown();
            widget.onStart();
          },
          onTapUp: (_) {
            _onPressUp();
            widget.onStop();
          },
          onTapCancel: () {
            _onPressUp();
            widget.onStop();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Snapchat-like animated ring
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(120, 120),
                    painter: SnapchatRingPainter(progress: _controller.value),
                  );
                },
              ),
              AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Image.asset(
                  'assets/images/mic_home.png',
                  width: 140,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          'Tap & Hold To Speak',
          style: GoogleFonts.ibmPlexSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8A95A8),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class SnapchatRingPainter extends CustomPainter {
  final double progress;

  SnapchatRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 5;

    // Background track (visible only when animating or always as a faint line)
    final trackPaint = Paint()
      ..color = const Color(0xFFE0E5EC).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      // Progress arc
      final progressPaint = Paint()
        ..color = const Color(0xFFFFCC00) // Snapchat yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      // Start from top (-pi/2)
      canvas.drawArc(rect, -3.14159265 / 2, 2 * 3.14159265 * progress, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant SnapchatRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
