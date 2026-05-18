import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium glass-style submit button for FeedbackScreen.
class FeedbackSendButton extends StatelessWidget {
  final VoidCallback onTap;

  const FeedbackSendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E2D4E).withValues(alpha: 0.95), // Navy
              const Color(0xFF2A3A5E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E2D4E).withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Send Feedback',
              style: GoogleFonts.ibmPlexSansCondensed(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.send_rounded,
              color: Color(0xFFC9A84C), // Gold accent
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
