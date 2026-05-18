import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable rounded text field card matching the Bulao auth design.
/// Clean flat-glass: gradient fill + small bottom shadow + thin gold border on focus.
/// Used by both Login and Signup screens.
class AuthTextField extends StatefulWidget {
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        // Ice-blue left → warm cream right
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE8EDF7),
            Color(0xFFF2EDE4),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        // Single small bottom shadow only — no side spread, no blur glow
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4), // strictly downward, not sideways
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.ibmPlexSans(
          color: const Color(0xFF1A2A5E),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.ibmPlexSans(
            color: const Color(0xFF3A4E7A).withValues(alpha: 0.55),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              widget.prefixIcon,
              color: const Color(0xFF9AA5BD),
              size: 22,
            ),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFC9A84C),
                    size: 22,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          // All InputDecoration borders set to none — no Material glow/ring
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            // Thin gold border only — no glow, no spread
            borderSide: const BorderSide(
              color: Color(0xFFC9A84C),
              width: 1.4,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 19, horizontal: 8),
        ),
      ),
    );
  }
}
