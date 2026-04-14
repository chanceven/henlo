import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'furrent_signup_screen.dart';
import 'pawtner_signup_screen.dart';
import 'signin_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Let's Get You Started",
                style: GoogleFonts.dosis(
                  textStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E4B3A),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                "Choose your role",
                style: GoogleFonts.dosis(
                  textStyle: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6E4B3A),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FurrentSignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E4B3A),
                    foregroundColor: const Color(0xFFDDC7A9),
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    shape: buttonShape,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "Furrent",
                        style: GoogleFonts.dosis(
                          textStyle: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PawtnerSignUpScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDDC7A9),
                    foregroundColor: const Color(0xFF6E4B3A),
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    shape: buttonShape,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        "Pawtner",
                        style: GoogleFonts.dosis(
                          textStyle: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: GoogleFonts.dosis(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    child: Text(
                      "Sign In",
                      style: GoogleFonts.dosis(
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6E4B3A),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
