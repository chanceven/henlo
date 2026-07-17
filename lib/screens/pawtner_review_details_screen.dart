// ignore_for_file: use_build_context_synchronously

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'terms_and_conditions_screen.dart';
import 'otp_screen.dart';

class PawtnerReviewDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String contact;
  final String password;
  final String businessName;
  final String typeOfService;
  final String businessType;
  final String availableAreas;
  final String location;

  const PawtnerReviewDetailsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.contact,
    required this.password,
    required this.businessName,
    required this.typeOfService,
    required this.businessType,
    required this.availableAreas,
    required this.location,
  });

  @override
  State<PawtnerReviewDetailsScreen> createState() =>
      _PawtnerReviewDetailsScreenState();
}

class _PawtnerReviewDetailsScreenState
    extends State<PawtnerReviewDetailsScreen> {
  bool agreeTerms = false;
  bool isLoading = false;

  Future<void> _createAccount() async {
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please agree to the Terms and Conditions"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    late final AuthResponse res;
    try {
      res = await Supabase.instance.client.auth.signUp(
        email: widget.email,
        password: widget.password,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please wait a moment before trying again.",
            style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
      return;
    }
    final user = res.user;
    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Oops! Something went wrong. Please try again."),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: widget.email,
            name: widget.name,
            contact: widget.contact,
            businessName: widget.businessName,
            location: widget.location,
            typeOfService: widget.typeOfService,
            businessType: widget.businessType,
            availableAreas: widget.availableAreas,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Review Your Details",
          style: GoogleFonts.dosis(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E4B3A),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      border: Border.all(
                          color: const Color(0xFF6E4B3A), width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRow("Full Name", widget.name),
                        _buildRow("Email", widget.email),
                        _buildRow("Contact Number", widget.contact),
                        _buildRow("Business Name", widget.businessName),
                        _buildRow("Service Type", widget.typeOfService),
                        _buildRow("Business Type", widget.businessType),
                        if (widget.businessType.contains("Home"))
                          _buildRow("Available Areas", widget.availableAreas),
                        _buildRow("Business Location", widget.location),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: agreeTerms,
                        onChanged: (val) =>
                            setState(() => agreeTerms = val ?? false),
                        activeColor: const Color(0xFF6E4B3A),
                        side: const BorderSide(
                            color: Color(0xFF6E4B3A), width: 1.5),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.dosis(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF6E4B3A),
                              ),
                            ),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Henlo Terms and Conditions",
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TermsAndConditionsScreen(),
                                      ),
                                    );
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: agreeTerms && !isLoading ? _createAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  foregroundColor: const Color(0xFFDDC7A9),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Color(0xFFDDC7A9))
                    : Text(
                        "Create Account",
                        style: GoogleFonts.dosis(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDC7A9),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
