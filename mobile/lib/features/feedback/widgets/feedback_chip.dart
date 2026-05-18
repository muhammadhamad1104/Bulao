import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A selectable chip for feedback tags ("What went well?").
class FeedbackChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FeedbackChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFF5EDD8) // Subtle cream/gold when selected
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFC9A84C) // Gold border when selected
                : const Color(0xFFD9C9A8), // Thin beige/gold outline
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected 
                ? const Color(0xFF0D0D0D) 
                : const Color(0xFF6B6B6B),
          ),
        ),
      ),
    );
  }
}
