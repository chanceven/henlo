import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/furrent_signup_screen.dart';
import 'screens/pawtner_signup_screen.dart';
import 'screens/furrent_dashboard_screen.dart';
import 'screens/pawtner_dashboard_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/terms_and_conditions_screen.dart';
import 'screens/furrent_search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lyjxzdcapqdvwxyamcbz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx5anh6ZGNhcHFkdnd4eWFtY2J6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4ODk3OTgsImV4cCI6MjA3NzQ2NTc5OH0.3Gik4uMpKD5rztuFkFsLX6MeDqsRQp0rC02F4Ug4EmY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PawPal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF6E4B3A),
        scaffoldBackgroundColor: const Color(0xFFF8F8F8),
      ),
      home: const SplashScreen(),
      routes: {
        '/sign_in': (_) => const SignInScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/furrent_signup': (_) => const FurrentSignUpScreen(),
        '/pawtner_signup': (_) => const PawtnerSignUpScreen(),
        '/furrent_dashboard': (_) => const FurrentDashboardScreen(),
        '/pawtner_dashboard': (_) => const PawtnerDashboardScreen(),
        '/forgot_password': (_) => const ForgotPasswordScreen(),
        '/terms': (_) => const TermsAndConditionsScreen(),
        '/search': (_) => const FurrentSearchScreen(),
      },
      // Optional: handle unknown routes
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => const SplashScreen(),
      ),
    );
  }
}
