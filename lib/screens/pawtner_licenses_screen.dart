import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PawtnerLicensesScreen extends StatelessWidget {
  const PawtnerLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Licenses',
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
              '1. Flutter',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Flutter is an open-source UI software development kit created by Google.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '2. Google Fonts',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pawtner uses Google Fonts for typography, which are licensed under the Open Font License.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '3. Supabase',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Supabase is an open-source backend as a service, licensed under the Apache License 2.0.',
              style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '4. Other Packages',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All other dependencies used in Pawtner are licensed according to their respective licenses. Please check the pub.dev page of each package for details.',
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
