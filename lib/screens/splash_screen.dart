import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.delayed(const Duration(seconds: 3));

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    // 🚫 No user logged in → go to Onboarding
    if (session == null) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final userId = session.user.id;

    // 🔍 Check if user exists in "furrents"
    final furrent = await supabase
        .from('furrents')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (furrent != null) {
      Navigator.pushReplacementNamed(context, '/furrent_dashboard');
      return;
    }

    // 🔍 Check if user exists in "pawtners"
    final pawtner = await supabase
        .from('pawtners')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (pawtner != null) {
      Navigator.pushReplacementNamed(context, '/pawtner_dashboard');
      return;
    }

    // ❗ User logged in but not in either table → force sign in again
    Navigator.pushReplacementNamed(context, '/sign_in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDC7A9),
      body: Center(
        child: Image.asset(
          'lib/assets/images/logo.png',
          width: 150,
        ),
      ),
    );
  }
}
