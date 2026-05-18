import 'package:flutter/material.dart';

/// Displays the login/auth logo image centered at the top.
/// Reusable across Login and Signup screens.
class AuthHeaderLogo extends StatelessWidget {
  final String imagePath;
  final double size;

  const AuthHeaderLogo({
    super.key,
    this.imagePath = 'assets/images/login_logo.png',
    this.size = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
