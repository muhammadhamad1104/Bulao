import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'keyword_chip.dart';

/// Outer + inner layered card matching the Processing.png reference.
///
/// Structure (matching reference exactly):
///   ┌─────────────────────────────────────────┐  ← outer card (cream glass)
///   │  ┌─────────────────────────────────────┐│  ← inner box (white, thin border)
///   │  │  [🎤]  "transcript text here..."    ││
///   │  └─────────────────────────────────────┘│
///   │                                          │
///   │  [Chip] [Chip] [Chip] [Chip]             │  ← chips inside outer card
///   │  [Chip] [Chip]                           │
///   └─────────────────────────────────────────┘
///
/// Backend integration:
///   [transcript] → replace with STT engine result.
///   [keywords]   → replace with backend keyword extraction result.
class TranscriptCard extends StatelessWidget {
  final String transcript;
  final List<String> keywords;

  const TranscriptCard({
    super.key,
    required this.transcript,
    required this.keywords,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ── Outer card: warm cream gradient with a very subtle blue-gold border glow
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF5F2EB), // warm cream top
            Color(0xFFEDE9E0), // slightly deeper cream bottom — stays close to #FAFAF7 page bg
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD8CEB8), // warm beige border
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
          // Subtle warm glow
          BoxShadow(
            color: const Color(0xFFC9A84C).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Inner transcript box ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE4E4E4),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Mic icon in outlined circle ──────────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF5F5F5),
                    border: Border.all(
                      color: const Color(0xFFD8D8D8),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    size: 22,
                    color: Color(0xFF6B7A99),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Transcript text in Inter ─────────────────────────────────
                Expanded(
                  child: Text(
                    '"$transcript"',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2A2A2A),
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Keyword chips — inside outer card, below inner box ───────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords.map((kw) => KeywordChip(label: kw)).toList(),
          ),
        ],
      ),
    );
  }
}
