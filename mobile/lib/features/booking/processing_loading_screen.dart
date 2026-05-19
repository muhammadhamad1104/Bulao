import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/animated_audio_waveform.dart';
import 'processing_screen.dart';
import '../../core/services/api_service.dart';
import '../../core/models/orchestrate_models.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Processing Loading screen — shown after the user submits a request.
///
/// Flow:
///   HomeScreen (input dialog) → ProcessingLoadingScreen → ProcessingScreen
///
/// Backend wiring:
///   Calls POST /orchestrate with [requestText] and [userId].
///   Passes the full [OrchestrateResponse] to [ProcessingScreen].
///   On error, shows a Snackbar and pops back to HomeScreen.
class ProcessingLoadingScreen extends StatefulWidget {
  final String requestText;
  final String userId;

  const ProcessingLoadingScreen({
    super.key,
    this.requestText = "G-13 mein plumber chahiye",
    this.userId = "anonymous",
  });

  @override
  State<ProcessingLoadingScreen> createState() =>
      _ProcessingLoadingScreenState();
}

class _ProcessingLoadingScreenState extends State<ProcessingLoadingScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  bool _hasNavigated = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            _callBackend(_recognizedText.isNotEmpty ? _recognizedText : widget.requestText);
          }
        },
        onError: (errorNotification) {
          print('Speech error: $errorNotification');
          _callBackend(widget.requestText);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _recognizedText = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
              _callBackend(_recognizedText.isNotEmpty ? _recognizedText : widget.requestText);
            }
          },
        );
      } else {
        _callBackend(widget.requestText);
      }
    } catch (e) {
      print('Speech init exception: $e');
      _callBackend(widget.requestText);
    }
  }

  Future<void> _callBackend(String text) async {
    try {
      final response = await ApiService.instance.orchestrate(
        text: text,
        userId: widget.userId,
      );
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      _navigateToProcessing(response);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.userFriendlyMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Kuch masla aa gaya. Dobara try karein.';
      });
    }
  }

  void _navigateToProcessing(OrchestrateResponse response) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProcessingScreen(response: response, originalText: widget.requestText),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
                            color: const Color(0xFFCCCCCC),
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.14),

                // ── Status title ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    _isListening 
                        ? 'Bolain, sun raha hoon...' 
                        : (_isLoading ? 'Processing Your Request ...' : 'Something went wrong'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0D0D0D),
                      height: 1.3,
                    ),
                  ),
                ),

                // ── Request preview ────────────────────────────────────────
                if (_isLoading) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _recognizedText.isNotEmpty 
                          ? '"$_recognizedText"' 
                          : '"${widget.requestText}"',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 14,
                        color: const Color(0xFF9AA5B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                // ── Animated waveform / error state ───────────────────────
                SizedBox(height: size.height * 0.09),

                if (_isLoading)
                  const AnimatedAudioWaveform(
                    barCount: 19,
                    maxBarHeight: 130,
                    barWidth: 9,
                    barSpacing: 4,
                  )
                else ...[
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 56,
                    color: Color(0xFFB0BAC8),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        color: const Color(0xFF9AA5B8),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // ── Retry / Cancel button ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 50),
                  child: _isLoading
                      ? const SizedBox.shrink()
                      : _RetryButton(onRetry: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                            _hasNavigated = false;
                          });
                          _callBackend(_recognizedText.isNotEmpty ? _recognizedText : widget.requestText);
                        }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Retry button shown when the backend call fails.
class _RetryButton extends StatelessWidget {
  final VoidCallback onRetry;
  const _RetryButton({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A3A5E), Color(0xFF1E2A45)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.5),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Dobara Try Karein',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
