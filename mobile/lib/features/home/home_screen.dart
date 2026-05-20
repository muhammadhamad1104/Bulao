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
  String _bestRecognizedText = ''; // Tracks longest result seen this session

  // Text input mode
  bool _isTextMode = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
        _bestRecognizedText = ''; // Reset for new session
      });
      _speech.listen(
        listenMode: ListenMode.dictation,
        onResult: (result) {
          final words = result.recognizedWords;
          setState(() {
            _recognizedText = words;
            // Keep the longest version seen — Android can restart mid-session
            // and return only the tail end of what was said
            if (words.trim().length > _bestRecognizedText.trim().length) {
              _bestRecognizedText = words;
            }
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
    // Wait for speech engine to finalize — Android needs time to flush the last segment
    await Future.delayed(const Duration(milliseconds: 600));
    // Use the best (longest) result captured during the full session
    final text = (_bestRecognizedText.trim().isNotEmpty
            ? _bestRecognizedText
            : _recognizedText)
        .trim();
    if (text.isNotEmpty) {
      _navigateToProcessing(context, text);
    } else {
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

  void _submitTextRequest() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _textController.clear();
      _navigateToProcessing(context, text);
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

                  // ── Mode Toggle: Voice ↔ Text ──────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 80),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Voice mode button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTextMode = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: !_isTextMode ? const Color(0xFF2A3A5E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Icon(
                                Icons.mic_rounded,
                                size: 20,
                                color: !_isTextMode ? Colors.white : const Color(0xFF7A8FAE),
                              ),
                            ),
                          ),
                        ),
                        // Text mode button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isTextMode = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeInOut,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _isTextMode ? const Color(0xFF2A3A5E) : Colors.transparent,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Icon(
                                Icons.keyboard_rounded,
                                size: 20,
                                color: _isTextMode ? Colors.white : const Color(0xFF7A8FAE),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Voice mic OR text field depending on mode ──────────────
                  if (!_isTextMode) ...[
                    // Original mic button
                    InteractiveMicButton(
                      onStart: _startListening,
                      onStop: _stopListening,
                    ),
                  ] else ...[
                    // Text input field
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFD0DAE8), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _textController,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _submitTextRequest(),
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 15,
                                  color: const Color(0xFF0D0D0D),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Likhen... (e.g. mechanic chahie Saddar)',
                                  hintStyle: GoogleFonts.ibmPlexSans(
                                    fontSize: 14,
                                    color: const Color(0xFF9AA5B8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _submitTextRequest,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A3A5E),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2A3A5E).withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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

