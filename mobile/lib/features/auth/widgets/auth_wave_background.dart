import 'package:flutter/material.dart';

/// Full-screen decorative background for auth screens.
/// Clean: cream base + soft top-right glow (colour customisable) + wave divider.
/// Login uses the default blue glow; Signup passes a warm golden glow.
class AuthWaveBackground extends StatelessWidget {
  final Widget child;

  /// Top-right glow colour. Defaults to pale blue (Login style).
  /// Pass a warm amber/gold tint for Signup style.
  final Color glowColor;

  /// Vertical position of the wave as a fraction of screen height.
  final double waveTopPercent;

  const AuthWaveBackground({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFFB8CCEC), // pale blue default
    this.waveTopPercent = 0.35, // default safe position
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: Solid clean cream base ─────────────────────────────
        Container(color: const Color(0xFFF4F6FA)),

        // ── Layer 2: Soft glow — top-right only ──────────────────────────
        // Colour is injected via glowColor so each screen can brand itself.
        Positioned(
          top: -size.height * 0.10,
          right: -size.width * 0.20,
          child: Container(
            width: size.width * 0.90,
            height: size.height * 0.55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size.width),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 0.85,
                colors: [
                  glowColor.withValues(alpha: 0.50),
                  glowColor.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Layer 3: auth_vector.png wave — sits between logo and heading ─
        Positioned(
          top: size.height * waveTopPercent,
          left: 0,
          right: 0,
          child: Image.asset(
            'assets/images/auth_vector.png',
            width: size.width,
            fit: BoxFit.fitWidth,
          ),
        ),

        // ── Layer 4: screen content ──────────────────────────────────────
        child,
      ],
    );
  }
}

