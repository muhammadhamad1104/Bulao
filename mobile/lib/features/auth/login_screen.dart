import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';
import 'widgets/auth_header_logo.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_wave_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // TODO: Validate credentials against backend before navigating.
    // When backend is ready: HomeScreen(userName: authResult.name)
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(userName: 'Wajeeha'),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  void _onSignUpPressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SignUpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _onForgotPasswordPressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ForgotPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthWaveBackground(
        waveTopPercent: 0.22, // Move wave UP above "Log In" heading
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Upper section: logo sits in top ~40% ─────────────
                    SizedBox(height: size.height * 0.065),
                    const AuthHeaderLogo(size: 160),
                    // Space between logo base and where wave intersects
                    SizedBox(height: size.height * 0.075),

                    // ── "Log In" heading ──────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Log In',
                        style: GoogleFonts.ibmPlexSansCondensed(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A0A0A),
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Email field ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AuthTextField(
                        hint: 'Email',
                        prefixIcon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Password field ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AuthTextField(
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline_rounded,
                        isPassword: true,
                        controller: _passwordController,
                      ),
                    ),

                    // ── Forgot Password — right-aligned tappable text ─────
                    Padding(
                      padding: const EdgeInsets.only(right: 26, top: 9),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _onForgotPasswordPressed,
                          child: Text(
                            'Forgot Password ?',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 13,
                              color: const Color(0xFF8A95A8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    // ── Log In button (centered, 78% wide) ────────────────
                    AuthPrimaryButton(
                      label: 'Log In',
                      onPressed: _onLoginPressed,
                    ),
                    const SizedBox(height: 22),

                    // ── "Don't Have An Account?" + "Sign Up Now!" ─────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Don't Have An Account ?",
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: const Color(0xFF4A5568),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: _onSignUpPressed,
                            child: Text(
                              'Sign Up Now !',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 15,
                                color: const Color(0xFFC9A84C), // golden
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(height: size.height * 0.025),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
