import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

/// Wraps the app routing based on authentication state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while Firebase checks the user's session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAF7),
            body: Center(child: CircularProgressIndicator(color: Color(0xFFC9A84C))),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // If logged in, go to home screen.
        // Try to use displayName, fallback to email prefix, fallback to 'Wajeeha'.
        String greetingName = 'Wajeeha';
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          greetingName = user.displayName!;
        } else if (user.email != null) {
          greetingName = user.email!.split('@')[0];
        }

        return HomeScreen(userName: greetingName);
      },
    );
  }
}
