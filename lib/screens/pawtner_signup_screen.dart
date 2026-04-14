import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showTopToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
        backgroundColor: isError ? const Color(0xFFFF3B30) : const Color(0xFF000000),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF6E4B3A)),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1.5),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1.5),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordCtrl.text != _confirmCtrl.text) {
      _showTopToast("Passwords do not match", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await supabase.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = res.user;
      if (user == null) throw Exception("Sign up failed");

      if (!mounted) return;

      // Navigate to Business Details and await for data return
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PawtnerBusinessDetailsScreen(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            contact: _contactCtrl.text.trim(),
          ),
        ),
      );

      // If user navigates back from Business Details, retain data
      if (result != null && result is Map<String, dynamic>) {
        _nameCtrl.text = result['name'] ?? _nameCtrl.text;
        _emailCtrl.text = result['email'] ?? _emailCtrl.text;
        _contactCtrl.text = result['contact'] ?? _contactCtrl.text;
      }
    } catch (e) {
      _showTopToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(
          color: Color(0xFF6E4B3A),
        ),
        title: Text(
          'Sign Up',
          style: GoogleFonts.dosis(
            fontSize: 28,
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
                                decoration: buildInputDecoration('Full Name', Icons.person),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: buildInputDecoration('Email', Icons.email),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: buildInputDecoration('Contact Number', Icons.phone),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: !_showPassword,
                                decoration: buildInputDecoration('Password', Icons.lock)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showPassword ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () =>
                                        setState(() => _showPassword = !_showPassword),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmCtrl,
                                obscureText: !_showConfirm,
                                decoration: buildInputDecoration('Confirm Password', Icons.lock)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _showConfirm ? Icons.visibility_off : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () =>
                                        setState(() => _showConfirm = !_showConfirm),
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
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
                                  const TextSpan(text: "Already have an account? "),
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
                                              builder: (_) => const SignInScreen()),
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
