import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Secondary outlined button for auth screens (e.g. "Cancel").
/// Transparent fill, navy border, navy text. Matches width of the primary
/// button when used in a side-by-side row layout.
class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  /// Optional explicit pixel width — mirror AuthPrimaryButton's width.
  final double? width;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width ?? screenWidth * 0.38,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xFF3A5BA8), // navy outline
            width: 1.6,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.ibmPlexSansCondensed(
            color: const Color(0xFF1E3A72), // navy text
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
