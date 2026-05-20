import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top app bar for the Home screen.
/// Hamburger left | "Find. Book. Relax" center + gradient underline | spacer right.
class HomeAppBar extends StatelessWidget {
  final VoidCallback? onHamburgerTap;

  const HomeAppBar({super.key, this.onHamburgerTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 32,    // pushes heading ~32px below status bar to match Home.png
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Hamburger menu ──────────────────────────────────────────
          GestureDetector(
            onTap: () {
              if (onHamburgerTap != null) {
                onHamburgerTap!();
              } else {
                Scaffold.of(context).openDrawer();
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(20),
                const SizedBox(height: 5),
                _bar(14),
                const SizedBox(height: 5),
                _bar(20),
              ],
            ),
          ),

          // ── Center heading + underline ──────────────────────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Find. Book. Relax',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0A0A0A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                // Gradient underline — blue left, gold right
                Center(
                  child: Container(
                    height: 2.5,
                    width: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6A9FD8), // soft blue
                          Color(0xFFC9A84C), // gold
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Right spacer (mirrors hamburger width for perfect centering) ──
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _bar(double width) => Container(
        width: width,
        height: 2.2,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A5E),
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
