import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C4DFF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_rounded,
                color: Color(0xFF7C4DFF),
                size: 54,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Bloom Control Panel',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Initializing Web Admin Environment...',
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF7C4DFF),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
