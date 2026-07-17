import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pawtner_business_details_screen.dart';
import 'signin_screen.dart';

class PawtnerSignUpScreen extends StatefulWidget {
  const PawtnerSignUpScreen({super.key});

  @override
  State<PawtnerSignUpScreen> createState() => _PawtnerSignUpScreenState();
}

class _PawtnerSignUpScreenState extends State<PawtnerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(
      r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$',
    ).hasMatch(trimmed);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF6E4B3A)),
      hintText: hint,
      hintStyle: GoogleFonts.dosis(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.grey[400],
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim().toLowerCase();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: _passwordCtrl.text.trim(),
      );

      final user = response.user;
      final session = response.session;

      if (user == null ||
          (session == null &&
              (user.identities == null || user.identities!.isEmpty))) {
        if (!mounted) return;

        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "This email is already registered. Please sign in instead.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
            ),
            backgroundColor: const Color(0xFF6E4B3A),
          ),
        );

        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PawtnerBusinessDetailsScreen(
            name: _nameCtrl.text.trim(),
            email: email,
            contact: _contactCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Try again."),
          backgroundColor: Color(0xFF6E4B3A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: const BackButton(
          color: Color(0xFF6E4B3A),
        ),
        title: Text(
          'Sign Up',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: buildInputDecoration(
                                    'Full Name', Icons.person),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }

                                  final emailRegex =
                                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Please enter a valid email';
                                  }

                                  return null;
                                },
                                decoration: buildInputDecoration(
                                  'Email',
                                  Icons.email,
                                ),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactCtrl,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[\d+]'),
                                  ),
                                  LengthLimitingTextInputFormatter(13),
                                ],
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your contact number';
                                  }

                                  if (!_isValidContactNumber(value.trim())) {
                                    return 'Please enter a valid contact number';
                                  }

                                  return null;
                                },
                                decoration: buildInputDecoration(
                                  'Contact Number',
                                  Icons.phone,
                                ),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_showPassword,
                                maxLength: 32,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your password';
                                  }

                                  if (value.trim().length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }

                                  if (value.trim().length > 32) {
                                    return 'Password must not exceed 32 characters';
                                  }

                                  if (!value
                                      .trim()
                                      .contains(RegExp(r'[0-9]'))) {
                                    return 'Password must contain at least one number';
                                  }

                                  if (!value
                                      .trim()
                                      .contains(RegExp(r'[a-zA-Z]'))) {
                                    return 'Password must contain at least one letter';
                                  }

                                  return null;
                                },
                                decoration: buildInputDecoration(
                                  'Password',
                                  Icons.lock,
                                ).copyWith(
                                  counterText: '',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                                  ),
                                ),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: !_showConfirm,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please confirm your password';
                                  }

                                  if (value != _passwordCtrl.text) {
                                    return 'Passwords do not match';
                                  }

                                  return null;
                                },
                                decoration: buildInputDecoration(
                                  'Confirm Password',
                                  Icons.lock,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(
                                        () => _showConfirm = !_showConfirm),
                                  ),
                                ),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(flex: 1),
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _continue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6E4B3A),
                                  foregroundColor: const Color(0xFFDDC7A9),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFFDDC7A9)))
                                    : Text(
                                        'Continue',
                                        style: GoogleFonts.dosis(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: GoogleFonts.dosis(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF6E4B3A),
                                  ),
                                ),
                                children: [
                                  const TextSpan(
                                      text: "Already have an account? "),
                                  TextSpan(
                                    text: "Sign In",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  const SignInScreen()),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
