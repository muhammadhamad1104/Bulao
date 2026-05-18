import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Green outlined "Best Match" badge matching Provider.png reference.
class BestMatchBadge extends StatelessWidget {
  const BestMatchBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEFBF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 13,
            color: Color(0xFF2E7D32),
          ),
          const SizedBox(width: 5),
          Text(
            'Best Match',
            style: GoogleFonts.ibmPlexSansCondensed(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
