import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'otp_screen.dart';

class FurrentSignUpScreen extends StatefulWidget {
  const FurrentSignUpScreen({super.key});

  @override
  State<FurrentSignUpScreen> createState() => _FurrentSignUpScreenState();
}

class _FurrentSignUpScreenState extends State<FurrentSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(
      r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$',
    ).hasMatch(trimmed);
  }

  Future<void> _signUpFurrent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: _passwordController.text.trim(),
      );

      final user = response.user;
      final session = response.session;

      if (user == null ||
          (session == null &&
              (user.identities == null || user.identities!.isEmpty))) {
        if (!mounted) return;

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: email,
            name: _fullNameController.text.trim(),
            contact: _contactController.text.trim(),
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message,
            style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please wait a moment before trying again.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                                controller: _fullNameController,
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
                                controller: _emailController,
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
                                decoration:
                                    buildInputDecoration('Email', Icons.email),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactController,
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
                                    'Contact Number', Icons.phone),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
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
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
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
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please confirm your password';
                                  }

                                  if (value != _passwordController.text) {
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
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(
                                      () => _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible,
                                    ),
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
                                onPressed: _isLoading ? null : _signUpFurrent,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6E4B3A),
                                  foregroundColor: const Color(0xFFDDC7A9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFFDDC7A9)),
                                      )
                                    : Text(
                                        'Create Account',
                                        style: GoogleFonts.dosis(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: GoogleFonts.dosis(
                                    fontSize: 16,
                                    color: const Color(0xFF6E4B3A),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/sign_in'),
                                  child: Text(
                                    "Sign In",
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6E4B3A),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
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
