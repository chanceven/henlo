import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Terms and Conditions",
          style: GoogleFonts.dosis(
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6E4B3A),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Text(
            """
Welcome to PawPal!

1. User Accounts: All users must provide accurate information when creating an account.
2. Services & Transactions: PawPal is a platform connecting pet owners and service providers. We are not responsible for any disputes between users.
3. Payments: Payments must be completed through PawPal’s approved methods. Refunds and cancellations are subject to provider policies.
4. Privacy: User data is collected and processed according to our Privacy Policy.
5. Content: Users must not post illegal, offensive, or inappropriate content.
6. Liability: PawPal is not liable for injuries, damages, or losses incurred through use of the platform.
7. Updates: Terms and conditions may change; continued use of the app constitutes agreement.
8. Termination: PawPal may suspend or terminate accounts violating the terms.
9. Contact: For inquiries, reach us at support@pawpal.com.

By using PawPal, you agree to abide by these terms and conditions.
""",
            style: GoogleFonts.dosis(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF6E4B3A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}