import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/animated_audio_waveform.dart';
import 'processing_screen.dart';

/// Processing Loading screen — shown immediately after mic tap/hold on HomeScreen.
///
/// Flow:
///   HomeScreen (mic tap) → ProcessingLoadingScreen → ProcessingScreen
///
/// Backend integration point:
///   When real audio recording is wired, replace the mock Timer delay with
///   actual STT completion callback. The waveform already accepts a
///   List<double> amplitudes parameter for real mic amplitude data.
class ProcessingLoadingScreen extends StatefulWidget {
  const ProcessingLoadingScreen({super.key});

  @override
  State<ProcessingLoadingScreen> createState() =>
      _ProcessingLoadingScreenState();
}

class _ProcessingLoadingScreenState extends State<ProcessingLoadingScreen> {
  Timer? _mockTimer;
  bool _hasNavigated = false;
  // ── Mock delay before auto-navigating to ProcessingScreen ─────────────────
  // Replace this with real STT/backend completion callback when integrating.
  static const _mockProcessingDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _startMockProcessing();
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }

  void _startMockProcessing() {
    _mockTimer = Timer(_mockProcessingDuration, () {
      _navigateToProcessing();
    });
  }

  void _navigateToProcessing() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _mockTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProcessingScreen(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // ── Bulao unified app background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Warm gold glow — top-right ──────────────────────────
          Positioned(
            top: -size.height * 0.08,
            right: -size.width * 0.15,
            child: Container(
              width: size.width * 0.85,
              height: size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width),
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 0.80,
                  colors: [
                    const Color(0xFFD4A84B).withValues(alpha: 0.28),
                    const Color(0xFFE8C97A).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 2: Cool blue glow — bottom-left ─────────────────────────
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.85,
              height: size.height * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size.width),
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 0.80,
                  colors: [
                    const Color(0xFF7A9EC8).withValues(alpha: 0.32),
                    const Color(0xFFB8CCEC).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 3: Main content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Back button — circular outlined ────────────────────────
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFFCCCCCC), // neutral light grey border
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back, // plain left arrow, not iOS chevron
                          size: 20,
                          color: Color(0xFF555555), // dark grey matching reference
                        ),
                      ),
                    ),
                  ),
                ),

                // ── "Processing Your Audio ..." title ─────────────────────
                SizedBox(height: size.height * 0.14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Processing Your Audio ...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D0D0D),
                      height: 1.3,
                    ),
                  ),
                ),

                // ── Animated waveform — centered vertically ────────────────
                SizedBox(height: size.height * 0.09),
                // AnimatedAudioWaveform accepts optional amplitudes list.
                // When real mic integration happens, replace with:
                //   AnimatedAudioWaveform(amplitudes: _micAmplitudes)
                const AnimatedAudioWaveform(
                  barCount: 19,
                  maxBarHeight: 130,
                  barWidth: 9,
                  barSpacing: 4,
                ),

                const Spacer(),

                // ── Send/Action Button ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: _SendActionButton(
                    onTap: _navigateToProcessing,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A sleek, circular send/action button with a scale animation on tap.
class _SendActionButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SendActionButton({required this.onTap});

  @override
  State<_SendActionButton> createState() => _SendActionButtonState();
}

class _SendActionButtonState extends State<_SendActionButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2A3A5E), Color(0xFF1E2A45)], // Navy base
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.5), // Subtle gold
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A3A5E).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 32,
              color: Colors.white, // High contrast cream/white
            ),
          ),
        ),
      ),
    );
  }
}
