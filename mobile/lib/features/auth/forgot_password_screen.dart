import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/auth_header_logo.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_secondary_button.dart';
import 'widgets/auth_wave_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _onSendLinkPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Password reset backend will be connected later',
          style: GoogleFonts.ibmPlexSans(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A2A5E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Each button takes ~44% of screen width, with a gap between them
    final btnWidth = size.width * 0.42;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthWaveBackground(
        // Blue glow — consistent with Login screen
        glowColor: const Color(0xFFB8CCEC),
        child: SafeArea(
          child: Stack(
            children: [
              // ── Main scrollable content ────────────────────────────────
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.top,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Space to clear the back arrow
                        const SizedBox(height: 8),

                        // ── Logo ────────────────────────────────────────
                        SizedBox(height: size.height * 0.055),
                        const AuthHeaderLogo(
                          imagePath: 'assets/images/login_logo.png',
                          size: 150,
                        ),
                        SizedBox(height: size.height * 0.075),

                        // ── "Forget Password" heading ────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Forget Password',
                            style: GoogleFonts.ibmPlexSansCondensed(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0A0A0A),
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Instruction text ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Enter your registered email to receive a password reset link.',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: const Color(0xFF6B7A99),
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ── Email field ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: AuthTextField(
                            hint: 'Email',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Cancel + Send Link row ───────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cancel — secondary outlined button
                              AuthSecondaryButton(
                                label: 'Cancel',
                                width: btnWidth,
                                onPressed: _goBack,
                              ),
                              // Send Link — primary gradient button
                              AuthPrimaryButton(
                                label: 'Send Link',
                                width: btnWidth,
                                onPressed: _onSendLinkPressed,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        SizedBox(height: size.height * 0.04),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Back arrow — overlaid top-left inside SafeArea ─────────
              Positioned(
                top: 4,
                left: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _goBack,
                    borderRadius: BorderRadius.circular(50),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: const Color(0xFF1E3A72),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
