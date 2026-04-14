import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final emailFieldValid =
        _emailController.text.trim().isNotEmpty && _isEmailValid(_emailController.text.trim());
    final subjectValid = _subjectController.text.trim().isNotEmpty;
    final messageValid = _messageController.text.trim().isNotEmpty;
    return nameValid && emailFieldValid && subjectValid && messageValid;
  }

  void _validateForm() {
    setState(() {
      emailValid = _emailController.text.isEmpty || _isEmailValid(_emailController.text.trim());
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
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isFormValid && !isSubmitting ? _submitForm : null,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Color(0xFFDDC7A9))
                    : Text(
                        'Submit',
                        style: GoogleFonts.dosis(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDC7A9),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Widget _buildEmailField(TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!emailValid)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'Please enter a valid email',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
        _buildTextField(controller, placeholder, keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildMessageField(TextEditingController controller, String placeholder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: TextField(
        controller: controller,
        maxLines: 6,
        style: const TextStyle(color: Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: Colors.grey[500]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _submitForm() {
    setState(() => isSubmitting = true);

    // Placeholder for submission logic (Supabase, email API, etc.)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message submitted!')),
        );
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          emailValid = true;
        });
      }
    });
  }
}
