import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'reset_password_screen.dart';

class PasswordResetCodeScreen extends StatefulWidget {
  final String email;

  const PasswordResetCodeScreen({super.key, required this.email});

  @override
  State<PasswordResetCodeScreen> createState() =>
      _PasswordResetCodeScreenState();
}

class _PasswordResetCodeScreenState extends State<PasswordResetCodeScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
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
    _otpFocusNode.dispose();
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

  Future<void> _resendCode() async {
    if (!_canResend) return;
    setState(() => _isResending = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      _otpController.clear();
      _startTimer();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("A new code has been sent to your email.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to resend code. Please try again.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter the 6-digit code.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: widget.email,
        token: _otpController.text.trim(),
        type: OtpType.recovery,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid or expired code. Please try again.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9))),
          backgroundColor: const Color(0xFF6E4B3A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: const BackButton(color: Color(0xFF6E4B3A)),
        title: const SizedBox.shrink(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "Enter the 6-digit code\nwe sent to",
                    textAlign: TextAlign.left,
                    style: GoogleFonts.dosis(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6E4B3A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    textAlign: TextAlign.left,
                    style: GoogleFonts.dosis(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_otpFocusNode);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            width: 1,
                            height: 1,
                            child: TextField(
                              controller: _otpController,
                              autofocus: true,
                              focusNode: _otpFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              maxLength: 6,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            final text = _otpController.text;
                            return Container(
                              width: 48,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF6E4B3A),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                index < text.length ? text[index] : '',
                                style: GoogleFonts.dosis(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                        onTap: _isResending ? null : _resendCode,
                        child: Text(
                          'Resend code',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dosis(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E4B3A),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
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
            ],
          ),
        ),
      ),
    );
  }
}
