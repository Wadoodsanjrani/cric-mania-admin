import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'admin_login_screen.dart';
import '../dashboard_screen.dart';

/// AuthGate — decides whether to show Login or Dashboard based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A1931),
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        // Logged in
        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardScreen();
        }

        // Not logged in
        return const AdminLoginScreen();
      },
    );
  }
}