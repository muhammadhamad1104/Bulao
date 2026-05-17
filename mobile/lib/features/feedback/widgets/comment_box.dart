import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Large rounded green text field for comments matching the reference.
class CommentBox extends StatelessWidget {
  final TextEditingController controller;

  const CommentBox({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDFF0D8), // Light green matching reference
        gradient: const LinearGradient(
          colors: [Color(0xFFE2F4D9), Color(0xFFD5EBC9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        maxLength: 300,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF0D0D0D),
        ),
        decoration: InputDecoration(
          hintText: 'Add a comment (optional) .....',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF8A95A8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          counterText: '', // Hide default character counter
        ),
      ),
    );
  }
}
