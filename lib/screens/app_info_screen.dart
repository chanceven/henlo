import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'App Info',
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'lib/assets/images/bitmap.png',
                  width: 120,
                ),
              ),
              const SizedBox(height: 36),
              Divider(
                color: const Color(0xFF6E4B3A).withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              Text(
                'Version',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1.0.0',
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                color: const Color(0xFF6E4B3A).withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              Text(
                'Support',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'hello@henloapp.com',
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                color: const Color(0xFF6E4B3A).withOpacity(0.2),
              ),
              const SizedBox(height: 20),
              Text(
                'Website',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'henloapp.com',
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  '© 2026 Henlo. All rights reserved.',
                  style: GoogleFonts.dosis(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8A6A5A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
