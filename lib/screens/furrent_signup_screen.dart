import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _signUpFurrent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = response.user;

      if (!mounted) return;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Sign up successful! Check your email to confirm your account.",
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 20, left: 16, right: 16),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        await supabase.from('furrents').insert({
          'id': user.id,
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'contact_number': _contactController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You’re all set! Sign in to start using PawPal.",
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(top: 20, left: 16, right: 16),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 3),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/sign_in', (route) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Oops! Something went wrong: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400], // gray placeholder style
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6E4B3A)),
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
                                controller: _fullNameController,
                                decoration:
                                    buildInputDecoration('Full Name', Icons.person),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration:
                                    buildInputDecoration('Email', Icons.email),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactController,
                                keyboardType: TextInputType.phone,
                                decoration: buildInputDecoration(
                                    'Contact Number', Icons.phone),
                                style: const TextStyle(
                                  color: Color(0xFF6E4B3A),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: buildInputDecoration('Password', Icons.lock)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(
                                        () => _isPasswordVisible = !_isPasswordVisible),
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
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: buildInputDecoration(
                                        'Confirm Password', Icons.lock)
                                    .copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    onPressed: () => setState(() =>
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible),
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
