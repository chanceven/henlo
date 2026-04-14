import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pawtner_app_info_screen.dart';
import 'pawtner_privacy_policy_screen.dart';
import 'pawtner_terms_and_conditions_screen.dart';
import 'pawtner_licenses_screen.dart';

class PawtnerLegalScreen extends StatelessWidget {
  const PawtnerLegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Legal & App Info',
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
          _legalOption(
            context,
            icon: Icons.info_outline,
            title: 'App Info',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerAppInfoScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legalOption(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerPrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legalOption(
            context,
            icon: Icons.rule_folder_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerTermsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _legalOption(
            context,
            icon: Icons.book_outlined,
            title: 'Licenses',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PawtnerLicensesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legalOption(BuildContext context,
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
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF6E4B3A), size: 18),
          ],
        ),
      ),
    );
  }
}
