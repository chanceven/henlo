import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FurrentPrivacyPolicyScreen extends StatelessWidget {
  const FurrentPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Privacy Policy',
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
            _buildHeading('Introduction'),
            _buildBody(
                'We respect your privacy and are committed to protecting your personal information.'),
            _buildHeading('Information We Collect'),
            _buildBody(
                '- Personal information you provide (name, email, profile, pet info)\n- Usage data (how you use the app)'),
            _buildHeading('How We Use Your Information'),
            _buildBody(
                '- To provide and improve our services\n- To communicate with you about updates or support\n- To comply with legal requirements'),
            _buildHeading('Sharing Your Information'),
            _buildBody(
                '- We do NOT sell your information\n- We may share data with service providers to operate the app'),
            _buildHeading('Data Security'),
            _buildBody(
                '- We implement reasonable measures to protect your data'),
            _buildHeading('Your Rights'),
            _buildBody(
                '- You can access, update, or delete your personal information'),
            _buildHeading('Contact'),
            _buildBody(
                'If you have questions about this Privacy Policy, contact us at support@example.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeading(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.dosis(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6E4B3A),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.dosis(
          fontSize: 16,
          color: const Color(0xFF6E4B3A),
          height: 1.5,
        ),
      ),
    );
  }
}
