import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Header row for ProviderScreen:
///   [Back Arrow]  "5 Providers Found" + underline  [provider_logo.png]
///
/// [providerCount] is backend-ready — pass the real count when API integrates.
class ProviderHeader extends StatelessWidget {
  final VoidCallback onBack;
  final int providerCount;

  const ProviderHeader({
    super.key,
    required this.onBack,
    required this.providerCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Back arrow — circular outline button ───────────────────────────
          GestureDetector(
            onTap: onBack,
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

          const SizedBox(width: 14),

          // ── Heading + gradient underline ────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$providerCount Providers Found',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexSansCondensed(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D0D),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 3),
                // Gradient underline
                Container(
                  height: 2.5,
                  width: 160,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2A3A5E), Color(0xFFC9A84C)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ── Provider logo + small sparkle ───────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                'assets/images/provider_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
              // Tiny sparkle top-right
              Positioned(
                top: -4,
                right: -4,
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.80),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
