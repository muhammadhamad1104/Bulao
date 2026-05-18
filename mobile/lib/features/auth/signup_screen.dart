import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/widgets/bulao_toast.dart';
import '../../core/utils/firebase_error_helper.dart';
import 'widgets/auth_header_logo.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_wave_background.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignUpPressed() async {
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.isEmpty) {
      BulaoToast.show(context, message: 'Please fill all fields', type: ToastType.error);
      return;
    }

    if (_passwordController.text.length < 6) {
      BulaoToast.show(context, message: 'Password must be at least 6 characters', type: ToastType.error);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await credential.user?.updateDisplayName(_nameController.text.trim());
      
      // Sign out so they have to log in manually
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        BulaoToast.show(context, message: 'Account created successfully. Please log in.', type: ToastType.success);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        BulaoToast.show(context, message: FirebaseErrorHelper.getMessage(e), type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _onLoginNowPressed() {
    // Pop back to LoginScreen — works whether pushed or replaced
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthWaveBackground(
        // Warm golden/amber glow — visually distinct from Login's blue glow
        glowColor: const Color(0xFFD4A84B),
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
                    // ── Logo: signup_logo.png centered at top ─────────────
                    SizedBox(height: size.height * 0.065),
                    AuthHeaderLogo(
                      imagePath: 'assets/images/signup_logo.png',
                      size: 160,
                    ),
                    // Space between logo base and wave line
                    SizedBox(height: size.height * 0.075),

                    // ── "Sign Up" heading ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Sign Up',
                        style: GoogleFonts.ibmPlexSansCondensed(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0A0A0A),
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── Name field ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AuthTextField(
                        hint: 'Name',
                        prefixIcon: Icons.person_outline_rounded,
                        keyboardType: TextInputType.name,
                        controller: _nameController,
                      ),
                    ),
                    const SizedBox(height: 14),

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
                    const SizedBox(height: 30),

                    // ── Sign Up button ────────────────────────────────────
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C)))
                        : AuthPrimaryButton(
                            label: 'Sign Up',
                            onPressed: _onSignUpPressed,
                          ),
                    const SizedBox(height: 22),

                    // ── "Already Have An Account?" + "Log In Now!" ────────
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Already Have An Account ?',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: const Color(0xFF4A5568),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 5),
                          GestureDetector(
                            onTap: _onLoginNowPressed,
                            child: Text(
                              'Log In Now !',
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
