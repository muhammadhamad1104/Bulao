import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TrackingHeader extends StatelessWidget {
  const TrackingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Back Button ──────────────────────────────────────────────────
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.70),
              border: Border.all(
                color: const Color(0xFFD8D8D8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back,
              size: 20,
              color: Color(0xFF3A3A3A),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // ── Title ────────────────────────────────────────────────────────
        Expanded(
          child: Text(
            'Live Tracking',
            style: GoogleFonts.ibmPlexSansCondensed(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D0D0D),
              letterSpacing: 0.3,
            ),
          ),
        ),

        // ── Tracking Logo ────────────────────────────────────────────────
        Image.asset(
          'assets/images/tracking_logo.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
