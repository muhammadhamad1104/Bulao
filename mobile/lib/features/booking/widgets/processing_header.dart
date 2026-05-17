import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top header row for the ProcessingScreen.
/// Contains: circular back arrow | "Finding Your Service ....." | gradient underline | sparkle icon.
class ProcessingHeader extends StatelessWidget {
  final VoidCallback onBack;

  const ProcessingHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Circular back arrow — same style as ProcessingLoadingScreen ──
              GestureDetector(
                onTap: onBack,
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
              const SizedBox(width: 14),

              // ── Heading text ────────────────────────────────────────────────
              Expanded(
                child: Text(
                  'Finding Your Service .....',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 19, // narrowed so it fits on one line on 360dp+
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D0D),
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // ── Sparkle icon ────────────────────────────────────────────────
              const SizedBox(width: 8),
              const Icon(
                Icons.auto_awesome,
                size: 22,
                color: Color(0xFF8A9BB8),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Gradient underline (starts after back button width) ─────────────
          Padding(
            padding: const EdgeInsets.only(left: 58), // aligns under heading text
            child: Container(
              height: 2.5,
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
    );
  }
}
