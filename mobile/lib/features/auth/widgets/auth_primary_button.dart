import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable navy-glass primary button for auth screens.
/// Matches the 3D glass capsule look in the login reference:
///   - narrower than full width, centered
///   - diagonal top-left (lighter) → bottom-right (darker) gradient
///   - top-edge white shimmer for glass depth
///   - rich drop shadow
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  /// Optional explicit pixel width. When null, defaults to 78% of screen width.
  /// Pass a value when using inside a Row (e.g. Forgot Password two-button row).
  final double? width;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          // Use explicit width if provided, otherwise default to 78% of screen
          width: width ?? screenWidth * 0.78,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Diagonal gradient: lighter steel-blue top-left → deep navy bottom-right
            // This recreates the 3D glass/glossy capsule from the reference
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5B7EC4), // lighter steel-blue (top-left highlight)
                Color(0xFF3A5BA8), // mid navy-blue
                Color(0xFF1E3A72), // deep navy (bottom-right depth)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              // Primary depth shadow
              BoxShadow(
                color: const Color(0xFF1A2A5E).withValues(alpha: 0.40),
                blurRadius: 22,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              // Soft ambient glow
              BoxShadow(
                color: const Color(0xFF3A5BA8).withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // Clip so the inner shimmer doesn't bleed outside rounded corners
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Top white shimmer strip — creates the glass/gloss effect
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 26,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.22),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Button label centered over the shimmer
                Center(
                  child: Text(
                    label,
                    style: GoogleFonts.ibmPlexSansCondensed(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
