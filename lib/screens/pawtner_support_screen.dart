import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pawtner_contact_us_screen.dart';
import 'pawtner_faq_screen.dart';

class PawtnerSupportScreen extends StatelessWidget {
  const PawtnerSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Support',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _supportOption(
            context,
            icon: Icons.help_outline,
            title: 'FAQ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerFAQScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _supportOption(
            context,
            icon: Icons.mail_outline,
            title: 'Contact Us',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerContactUsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _supportOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6E4B3A)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Color(0xFF6E4B3A), size: 18),
          ],
        ),
      ),
    );
  }
}
