import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String? privacyPolicy;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacyPolicy();
  }

  Future<void> _loadPrivacyPolicy() async {
    try {
      final response = await Supabase.instance.client
          .from('privacy_policy')
          .select('content')
          .eq('user_type', 'master')
          .single();

      if (!mounted) return;

      setState(() {
        privacyPolicy = response['content'] as String;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        privacyPolicy = 'Unable to load Privacy Policy.';
        isLoading = false;
      });
    }
  }

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
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6E4B3A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6E4B3A),
                  ),
                )
              : SingleChildScrollView(
                  child: SelectableText(
                    privacyPolicy ?? '',
                    style: GoogleFonts.dosis(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6E4B3A),
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
