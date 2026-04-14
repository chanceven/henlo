import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'terms_and_conditions_screen.dart';
import 'signin_screen.dart';

class PawtnerReviewDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String contact;
  final String businessName;
  final String typeOfService;
  final String location;
  final String? uploadedProfilePhotoUrl;
  final String? uploadedBusinessPermitUrl;
  final String? uploadedGovernmentIDUrl;

  const PawtnerReviewDetailsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.contact,
    required this.businessName,
    required this.typeOfService,
    required this.location,
    this.uploadedProfilePhotoUrl,
    this.uploadedBusinessPermitUrl,
    this.uploadedGovernmentIDUrl,
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

    final user = Supabase.instance.client.auth.currentUser;
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
      await Supabase.instance.client.from('pawtners').upsert({
        'id': user.id,
        'full_name': widget.name,
        'email': widget.email,
        'contact_number': widget.contact,
        'business_name': widget.businessName,
        'business_address': widget.location,
        'city': null, // Optional: fill if available
        'location_lat': null, // Optional: fill if available
        'location_long': null, // Optional: fill if available
        'profile_picture_url': widget.uploadedProfilePhotoUrl,
        'business_permit_url': widget.uploadedBusinessPermitUrl,
        'govt_id_url': widget.uploadedGovernmentIDUrl,
        'type_of_service': widget.typeOfService,
        'verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'verified_at': null,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You’re all set! Sign in to start using PawPal."),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.dosis(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E4B3A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dosis(
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6E4B3A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRow(String label, String? url) {
    final uploaded = url != null && url.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.dosis(
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6E4B3A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              uploaded ? "Uploaded" : "Not Uploaded",
              style: GoogleFonts.dosis(
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: uploaded
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF8B0000),
                ),
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
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E4B3A),
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  border: Border.all(color: const Color(0xFF6E4B3A), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRow("Full Name", widget.name),
                    _buildRow("Email", widget.email),
                    _buildRow("Contact Number", widget.contact),
                    _buildRow("Business Name", widget.businessName),
                    _buildRow("Type of Service", widget.typeOfService),
                    _buildRow("Business Location", widget.location),
                    _buildUploadRow("Profile Photo", widget.uploadedProfilePhotoUrl),
                    _buildUploadRow(
                        "Business Permit", widget.uploadedBusinessPermitUrl),
                    _buildUploadRow(
                        "Government ID", widget.uploadedGovernmentIDUrl),
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
                            text: "PawPal Terms and Conditions",
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: agreeTerms && !isLoading ? _createAccount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E4B3A),
                    foregroundColor: const Color(0xFFDDC7A9),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFDDC7A9),
                        )
                      : Text(
                          "Create Account",
                          style: GoogleFonts.dosis(
                            textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDDC7A9)),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
