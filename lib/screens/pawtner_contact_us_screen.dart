import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PawtnerContactUsScreen extends StatefulWidget {
  const PawtnerContactUsScreen({super.key});

  @override
  State<PawtnerContactUsScreen> createState() => _PawtnerContactUsScreenState();
}

class _PawtnerContactUsScreenState extends State<PawtnerContactUsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool isSubmitting = false;
  bool emailValid = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _subjectController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
  }

  bool get isFormValid {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final emailFieldValid = _emailController.text.trim().isNotEmpty &&
        _isEmailValid(_emailController.text.trim());
    final subjectValid = _subjectController.text.trim().isNotEmpty;
    final messageValid = _messageController.text.trim().isNotEmpty;
    return nameValid && emailFieldValid && subjectValid && messageValid;
  }

  void _validateForm() {
    setState(() {
      emailValid = _emailController.text.isEmpty ||
          _isEmailValid(_emailController.text.trim());
    });
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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
          'Contact Us',
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
          children: [
            _buildTextField(_nameController, 'Full Name'),
            _buildEmailField(_emailController, 'Email'),
            _buildTextField(_subjectController, 'Subject'),
            _buildMessageField(_messageController, 'Enter your message'),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDDC7A9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isFormValid && !isSubmitting ? _submitForm : null,
            child: isSubmitting
                ? const CircularProgressIndicator(
                    color: Color(0xFF6E4B3A),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.dosis(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFFFF),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.dosis(
            color: const Color(0xFFBDBDBD),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(
      TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!emailValid)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'Please enter a valid email',
              style: GoogleFonts.dosis(
                color: const Color(0xFF8B0000),
                fontSize: 12,
              ),
            ),
          ),
        _buildTextField(controller, placeholder,
            keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildMessageField(
      TextEditingController controller, String placeholder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFFFF),
      child: TextField(
        controller: controller,
        maxLines: 6,
        style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.dosis(
            color: const Color(0xFFBDBDBD),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => isSubmitting = true);

    try {
      await Supabase.instance.client.functions.invoke(
        'contact-us',
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'subject': _subjectController.text.trim(),
          'message': _messageController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(
            'Message submitted successfully',
            style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
            ),
          ),
          backgroundColor: const Color(0xFFDDC7A9),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _subjectController.clear();
      _messageController.clear();

      setState(() {
        emailValid = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(
            'Failed to submit message',
            style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
            ),
          ),
          backgroundColor: const Color(0xFFDDC7A9),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}
