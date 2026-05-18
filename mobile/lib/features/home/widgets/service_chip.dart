import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Oval/pill service category chip matching the Home.png reference.
/// Clean white/cream pill with thin border, service name in navy.
class ServiceChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const ServiceChip({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFFD0D8E8),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2A3A5E),
          ),
        ),
      ),
    );
  }
}
