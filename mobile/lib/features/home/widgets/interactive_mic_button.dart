import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive microphone button using mic_home.png asset.
/// AnimatedScale provides tap/hold visual feedback.
/// onTap + onLongPressEnd both trigger [onActivated].
class InteractiveMicButton extends StatefulWidget {
  final VoidCallback onActivated;

  const InteractiveMicButton({
    super.key,
    required this.onActivated,
  });

  @override
  State<InteractiveMicButton> createState() => _InteractiveMicButtonState();
}

class _InteractiveMicButtonState extends State<InteractiveMicButton> {
  double _scale = 1.0;

  void _onPressDown() => setState(() => _scale = 0.92);
  void _onPressUp() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            _onPressUp();
            widget.onActivated();
          },
          onTapDown: (_) => _onPressDown(),
          onTapUp: (_) => _onPressUp(),
          onTapCancel: _onPressUp,
          onLongPressStart: (_) => _onPressDown(),
          onLongPressEnd: (_) {
            _onPressUp();
            widget.onActivated();
          },
          child: AnimatedScale(
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
