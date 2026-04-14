import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FurrentTermsScreen extends StatelessWidget {
  const FurrentTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Terms & Conditions',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Acceptance of Terms',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By using this app, you agree to these terms and conditions. Please read them carefully.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '2. User Responsibilities',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users are responsible for maintaining the confidentiality of their account information and for all activities under their account.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '3. Limitation of Liability',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We are not liable for any damages arising from the use of this app, including but not limited to loss of data or service interruptions.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '4. Changes to Terms',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We reserve the right to update these terms at any time. Continued use of the app constitutes acceptance of the new terms.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
