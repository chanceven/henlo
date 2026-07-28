import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'furrent_app_info_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';
import 'licenses_screen.dart';
import 'delete_account_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
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
                  builder: (_) => const FurrentAppInfoScreen(),
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
                  builder: (_) => const PrivacyPolicyScreen(),
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
                  builder: (_) => const TermsAndConditionsScreen(),
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
                  builder: (_) => const LicensesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _legalOption(
            context,
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            color: const Color(0xFF8B0000),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeleteAccountScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legalOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = const Color(0xFF6E4B3A),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Flat container, no border or shadow
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: title == 'Delete Account'
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
