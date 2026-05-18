import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A green confirmation message bubble matching the reference.
/// It has a speech-bubble tail on the bottom-right.
class ConfirmationMessageBubble extends StatelessWidget {
  final String message;

  const ConfirmationMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 40), // Push it slightly right
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD4EFC3), // Light green matching reference
          gradient: const LinearGradient(
            colors: [Color(0xFFDCF4CB), Color(0xFFCBEAB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4), // Tail effect
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF0D0D0D),
            height: 1.4,
          ),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
