import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single keyword pill chip with gold border and warm cream fill.
/// Used inside the TranscriptCard keyword row.
class KeywordChip extends StatelessWidget {
  final String label;

  const KeywordChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8EC), // warm cream fill
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC9A84C), // gold border
          width: 1.1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansCondensed(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF8A6820), // dark gold text
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
