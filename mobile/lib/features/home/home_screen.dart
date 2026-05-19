import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/service_chip.dart';
import 'widgets/interactive_mic_button.dart';
import '../booking/processing_loading_screen.dart';
import '../../core/services/api_service.dart';
import 'widgets/home_drawer.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({
    super.key,
    this.userName = 'Wajeeha',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
    );
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onError: (error) => setState(() => _isListening = false),
    );
    if (available) {
      setState(() {
        _isListening = true;
        _recognizedText = '';
      });
      _speech.listen(
        listenMode: ListenMode.dictation,
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    // Small delay to allow the speech engine to finalize the last words
    await Future.delayed(const Duration(milliseconds: 300));
    final text = _recognizedText.trim();
    if (text.isNotEmpty) {
      _navigateToProcessing(context, text);
    } else {
      // Show a snackbar instead of silently sending a hardcoded fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kuch sunai nahi diya. Dobara try karein.',
                style: GoogleFonts.ibmPlexSans(color: Colors.white)),
            backgroundColor: const Color(0xFF2A3A5E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _navigateToProcessing(BuildContext context, String text) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProcessingLoadingScreen(requestText: text),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _onServiceChipTapped(BuildContext context, String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Use the mic to request $service',
          style: GoogleFonts.ibmPlexSans(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2A3A5E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = FirebaseAuth.instance.currentUser;
    final nameToShow = (user?.displayName != null && user!.displayName!.isNotEmpty) ? user.displayName! : widget.userName;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // ── Bulao unified app background
      drawer: HomeDrawer(userName: nameToShow), // Drawer attached here
      body: SafeArea(
        child: Stack(
          children: [
            // ── Main scrollable column ──────────────────────────────────────
            SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── App Bar (hamburger + heading + underline) ──────────────
                  const HomeAppBar(),
                  SizedBox(height: size.height * 0.025),

                  // ── Decorative icons row (bolt left, snowflake right) ──────
                  // Purely visual — in the scrollable column, above the greeting.
                  // Only bolt + snowflake here; wrench is near chips (overlay below).
                  SizedBox(
                    height: 40,
                    width: size.width,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 22,
                          top: 2,
                          child: Icon(
                            Icons.bolt,
                            size: 32,
                            color: const Color(0xFFB0C0D8).withValues(alpha: 0.55),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          top: 4,
                          child: Icon(
                            Icons.ac_unit_rounded,
                            size: 28,
                            color: const Color(0xFFB0C0D8).withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Greeting — CENTERED to match Home.png ─────────────────
                  // "Hey Wajeeha ," in muted grey, small weight
                  // "How can I help you ?" in bold dark
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Hey $nameToShow ,',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF9AA5B8),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How can I help you ?',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0D0D0D),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: size.height * 0.025),

                  // ── Large decorative wave through the middle ───────────────
                  Image.asset(
                    'assets/images/home_wave.png',
                    width: size.width,
                    fit: BoxFit.fitWidth,
                  ),

                  const SizedBox(height: 4),

                  // ── Service chips — scattered layout matching Home.png ──────
                  FutureBuilder<List<String>>(
                    future: ApiService.instance.getServices(),
                    builder: (context, snapshot) {
                      final services = snapshot.data ?? [];
                      
                      // Helper to get service safely
                      String getService(int index, String fallback) {
                        if (index < services.length) return services[index];
                        return fallback;
                      }

                      return Column(
                        children: [
                          // Row 1: Plumbing left-aligned
                          _ChipRow(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(width: 20),
                              ServiceChip(
                                label: getService(0, 'Plumbing'),
                                onTap: () => _onServiceChipTapped(context, getService(0, 'Plumbing')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Row 2: Electrical centered
                          _ChipRow(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ServiceChip(
                                label: getService(1, 'Electrical'),
                                onTap: () => _onServiceChipTapped(context, getService(1, 'Electrical')),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Row 3: Painting left + HVAC right
                          _ChipRow(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 20),
                                child: ServiceChip(
                                  label: getService(2, 'Painting'),
                                  onTap: () => _onServiceChipTapped(context, getService(2, 'Painting')),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: ServiceChip(
                                  label: getService(3, 'HVAC'),
                                  onTap: () => _onServiceChipTapped(context, getService(3, 'HVAC')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Row 4: Locksmith + Carpentry spaced
                          _ChipRow(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ServiceChip(
                                label: getService(4, 'Locksmith'),
                                onTap: () => _onServiceChipTapped(context, getService(4, 'Locksmith')),
                              ),
                              ServiceChip(
                                label: getService(5, 'Carpentry'),
                                onTap: () => _onServiceChipTapped(context, getService(5, 'Carpentry')),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: size.height * 0.015),

                  // ── Microphone — ONLY this navigates to processing ─────────
                  InteractiveMicButton(
                    onStart: _startListening,
                    onStop: _stopListening,
                  ),

                  SizedBox(height: size.height * 0.035),
                ],
              ),
            ),

            // ── Decorative overlay icons — chip zone (screen-fixed) ───────────
            // Anchored via `bottom` so they reliably sit in the chip+mic zone
            // regardless of how the scrollable content renders.
            // Positions chosen so none overlap chip labels.

            // Wrench — center-right, between chip rows
            Positioned(
              right: size.width * 0.12,
              bottom: size.height * 0.32,
              child: Icon(
                Icons.handyman_outlined,
                size: 32,
                color: const Color(0xFFB0C0D8).withValues(alpha: 0.45),
              ),
            ),
            // Snowflake — left side, near but BELOW the Painting/Plumbing row
            // bottom: 0.28 puts it between Locksmith row and mic area
            Positioned(
              left: 16,
              bottom: size.height * 0.26,
              child: Icon(
                Icons.ac_unit_rounded,
                size: 26,
                color: const Color(0xFFB0C0D8).withValues(alpha: 0.42),
              ),
            ),
            // Gold lightning bolt — lower-right, safely near mic area
            Positioned(
              right: 24,
              bottom: size.height * 0.18,
              child: Icon(
                Icons.bolt,
                size: 28,
                color: const Color(0xFFD4A84B).withValues(alpha: 0.40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin helper to lay out chip rows cleanly.
class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;

  const _ChipRow({
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: children,
    );
  }
}

