import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'signin_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String name;
  final String contact;
  final String? businessName;
  final String? location;
  final String? typeOfService;
  final String? businessType;
  final String? availableAreas;

  const OtpScreen({
    super.key,
    required this.email,
    required this.name,
    required this.contact,
    this.businessName,
    this.location,
    this.typeOfService,
    this.businessType,
    this.availableAreas,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  int _secondsRemaining = 300; // 5 minutes
  Timer? _timer;
  bool get _canResend => _secondsRemaining == 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsRemaining = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      _otpController.clear();
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("A new code has been sent to your email.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to resend code. Please try again.",
              style: GoogleFonts.dosis(color: Colors.white)),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter the 6-digit OTP.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otpController.text.trim(),
        type: OtpType.signup,
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (widget.businessName != null) {
          // pawtner
          await Supabase.instance.client.from('pawtners').upsert({
            'id': user.id,
            'full_name': widget.name,
            'email': widget.email,
            'contact_number': widget.contact,
            'business_name': widget.businessName,
            'business_address': widget.location,
            'city': null,
            'location_lat': null,
            'location_long': null,
            'service_type': widget.typeOfService,
            'business_type': widget.businessType,
            'available_areas': widget.availableAreas,
            'verified': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'verified_at': null,
          });
        } else {
          // furrent
          await Supabase.instance.client.from('furrents').insert({
            'id': user.id,
            'full_name': widget.name,
            'email': widget.email,
            'contact_number': widget.contact,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }

      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Email verified! Please sign in.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid or expired OTP. Please try again.",
              style: GoogleFonts.dosis(color: Colors.white)),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: BackButton(
          color: const Color(0xFF6E4B3A),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            }
          },
        ),
        title: Text(
          'Verify Email',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              'Enter the 6-digit code sent to',
              textAlign: TextAlign.center,
              style: GoogleFonts.dosis(
                fontSize: 16,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: GoogleFonts.dosis(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6E4B3A),
                letterSpacing: 16,
              ),
              decoration: const InputDecoration(
                counterText: '',
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 2),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timer and resend
            if (!_canResend)
              Text(
                'Code expires in $_timerText',
                textAlign: TextAlign.center,
                style: GoogleFonts.dosis(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              )
            else
              GestureDetector(
                onTap: _isResending ? null : _resendOtp,
                child: Text(
                  _isResending ? 'Sending...' : 'Resend code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dosis(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

            const SizedBox(height: 40),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  foregroundColor: const Color(0xFFDDC7A9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFFDDC7A9),
                        strokeWidth: 2.5,
                      )
                    : Text(
                        'Verify',
                        style: GoogleFonts.dosis(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
