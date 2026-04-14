import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart';
import 'onboarding_screen.dart';
import 'furrent_dashboard_screen.dart';
import 'pawtner_dashboard_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;
  bool _autoLoginChecked = false; // ✅ prevent repeated auto-login

  @override
  void initState() {
    super.initState();
    // Only attempt auto-login once, after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_autoLoginChecked) {
        _autoLogin();
        _autoLoginChecked = true;
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _showMessage(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _autoLogin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final userId = user.id;

    // Check furrents table
    final furrentResp = await Supabase.instance.client
        .from('furrents')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (furrentResp != null && furrentResp.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FurrentDashboardScreen()),
      );
      return;
    }

    // Check pawtners table
    final pawtnerResp = await Supabase.instance.client
        .from('pawtners')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (pawtnerResp != null && pawtnerResp.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PawtnerDashboardScreen()),
      );
      return;
    }
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      await _showMessage("Incorrect email or password");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        await _showMessage("Incorrect email or password");
        return;
      }

      final userId = user.id;

      // Check furrents table
      final furrentResp = await Supabase.instance.client
          .from('furrents')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (furrentResp != null && furrentResp.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FurrentDashboardScreen()),
        );
        return;
      }

      // Check pawtners table
      final pawtnerResp = await Supabase.instance.client
          .from('pawtners')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (pawtnerResp != null && pawtnerResp.isNotEmpty) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PawtnerDashboardScreen()),
        );
        return;
      }

      await _showMessage("Oops! Something went wrong. Please try again.");
    } catch (e) {
      await _showMessage("Oops! Something went wrong. Please try again.");
    }

    if (!mounted) return;
    setState(() => isLoading = false);
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
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1.0),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1.0),
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LOGO
                      SizedBox(
                        width: double.infinity,
                        height: constraints.maxHeight * 0.45,
                        child: Image.asset(
                          'lib/assets/images/logo.png',
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      SizedBox(height: constraints.maxHeight * 0.02),
                      // FORM + BUTTON
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: emailController,
                              decoration:
                                  buildInputDecoration('Email', Icons.email),
                              style: const TextStyle(
                                color: Color(0xFF6E4B3A),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration:
                                  buildInputDecoration('Password', Icons.lock)
                                      .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    showPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: const Color(0xFF6E4B3A),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      showPassword = !showPassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF6E4B3A),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.dosis(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6E4B3A),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6E4B3A),
                                  foregroundColor: const Color(0xFFDDC7A9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(
                                        color: Color(0xFFDDC7A9),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: GoogleFonts.dosis(
                                          textStyle: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.dosis(
                                    textStyle: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6E4B3A),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const OnboardingScreen()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "Sign Up",
                                    style: GoogleFonts.dosis(
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        color: Color(0xFF6E4B3A),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
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
