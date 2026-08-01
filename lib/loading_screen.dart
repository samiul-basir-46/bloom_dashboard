import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/admin/presentation/screens/admin_login_screen.dart';
import 'features/admin/presentation/screens/dashboard_shell_screen.dart';
import 'welcome_screen.dart';

final class Loading extends StatelessWidget {
  const Loading({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WelcomeScreen();
        }
        final user = snapshot.data;
        if (user != null) {
          return const DashboardShellScreen();
        } else {
          return const AdminLoginScreen();
        }
      },
    );
  }
}
