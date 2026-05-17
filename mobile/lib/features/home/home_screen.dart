import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/service_chip.dart';
import 'widgets/interactive_mic_button.dart';
import '../booking/processing_loading_screen.dart';

import 'widgets/home_drawer.dart';

class HomeScreen extends StatelessWidget {
  // ── Backend-ready: replace with actual logged-in user's name later ──────
  // When backend/auth integration happens, pass this from the auth result
  // e.g. HomeScreen(userName: authResult.name)
  final String userName;

  const HomeScreen({
    super.key,
    this.userName = 'Wajeeha', // mock default — swap on auth integration
  });

  // ── Only the mic triggers processing navigation ──────────────────────────
  void _navigateToProcessing(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProcessingLoadingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ── Service chip tap: informational only, no processing navigation ───────
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF7), // ── Bulao unified app background
      drawer: HomeDrawer(userName: userName), // Drawer attached here
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
                          'Hey $userName ,',
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
                  // Row 1: Plumbing left-aligned
                  _ChipRow(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 20),
                      ServiceChip(
                        label: 'Plumbing',
                        onTap: () => _onServiceChipTapped(context, 'Plumbing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Electrical centered
                  _ChipRow(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ServiceChip(
                        label: 'Electrical',
                        onTap: () => _onServiceChipTapped(context, 'Electrical'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 3: Painting left + HVAC right (like reference)
                  _ChipRow(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: ServiceChip(
                          label: 'Painting',
                          onTap: () => _onServiceChipTapped(context, 'Painting'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: ServiceChip(
                          label: 'HVAC',
                          onTap: () => _onServiceChipTapped(context, 'HVAC'),
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
                        label: 'Locksmith',
                        onTap: () => _onServiceChipTapped(context, 'Locksmith'),
                      ),
                      ServiceChip(
                        label: 'Carpentry',
                        onTap: () => _onServiceChipTapped(context, 'Carpentry'),
                      ),
                    ],
                  ),

                  SizedBox(height: size.height * 0.015),

                  // ── Microphone — ONLY this navigates to processing ─────────
                  InteractiveMicButton(
                    onActivated: () => _navigateToProcessing(context),
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
