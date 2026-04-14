import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FurrentAppInfoScreen extends StatelessWidget {
  const FurrentAppInfoScreen({super.key});

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _centeredText('App Version: 1.0.0'),
            const SizedBox(height: 12),
            _centeredText('Last Update: Dec 2025'),
            const SizedBox(height: 12),
            _centeredText('Developed By: Chubi Bichu'),
            const SizedBox(height: 12),
            _centeredText('Contact: support@example.com'),
          ],
        ),
      ),
    );
  }

  Widget _centeredText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.dosis(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF6E4B3A),
      ),
    );
  }
}
