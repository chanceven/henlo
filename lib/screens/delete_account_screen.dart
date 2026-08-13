import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otherReasonController = TextEditingController();

  bool _obscurePassword = true;
  bool _isDeleting = false;
  int _currentStep = 0;

  String? _selectedReason;

  final List<String> _reasons = [
    'I no longer need Henlo.',
    'I found another pet services app.',
    'I experienced technical issues.',
    'I couldn\'t find the services I needed.',
    'I\'m concerned about my privacy.',
    'I created another account.',
    'Other',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otherReasonController.dispose();
    super.dispose();
  }

  TextStyle get _titleStyle => GoogleFonts.dosis(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6E4B3A),
      );

  TextStyle get _bodyStyle => GoogleFonts.dosis(
        fontSize: 16,
        color: const Color(0xFF6E4B3A),
      );

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dosis(
        color: Colors.grey,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6E4B3A),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6E4B3A),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF6E4B3A),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Delete Account',
          style: _titleStyle,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF6E4B3A),
          ),
          onPressed: () {
            if (_currentStep == 0) {
              Navigator.pop(context);
            } else {
              setState(() {
                _currentStep--;
              });
            }
          },
        ),
      ),
      body: _currentStep == 0
          ? _buildStep1()
          : _currentStep == 1
              ? _buildStep2()
              : _buildStep3(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _buildBottomButton(),
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '•  ',
            style: TextStyle(
              color: Color(0xFF6E4B3A),
              fontSize: 18,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: _bodyStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Step 1 of 3',
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            value: 1 / 3,
            backgroundColor: Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation(Color(0xFF6E4B3A)),
          ),
          const SizedBox(height: 32),
          Text(
            'Deleting your account is permanent and cannot be undone.',
            style: GoogleFonts.dosis(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF8B0000),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The following data will be permanently deleted:',
            style: _bodyStyle,
          ),
          const SizedBox(height: 12),
          _bullet('Your profile'),
          _bullet('Your pets'),
          _bullet('Your bookings'),
          _bullet('Your messages'),
          _bullet('Any other data associated with your account'),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Step 2 of 3',
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            value: 2 / 3,
            backgroundColor: Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation(Color(0xFF6E4B3A)),
          ),
          const SizedBox(height: 32),
          Text(
            'Why are you deleting your account?',
            style: GoogleFonts.dosis(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: _selectedReason,
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
              });
            },
            child: Column(
              children: _reasons
                  .map(
                    (reason) => RadioListTile<String>(
                      value: reason,
                      activeColor: const Color(0xFF6E4B3A),
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (states) {
                          return const Color(0xFF6E4B3A);
                        },
                      ),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reason,
                        style: _bodyStyle,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (_selectedReason == 'Other') ...[
            TextField(
              controller: _otherReasonController,
              maxLines: 4,
              style: _bodyStyle,
              decoration: _inputDecoration('Tell us why you\'re leaving'),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Step 3 of 3',
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            value: 1,
            backgroundColor: Color(0xFFE0E0E0),
            valueColor: AlwaysStoppedAnimation(Color(0xFF6E4B3A)),
          ),
          const SizedBox(height: 32),
          Text(
            'Email Address',
            style: GoogleFonts.dosis(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            style: _bodyStyle,
            decoration: _inputDecoration(''),
          ),
          const SizedBox(height: 24),
          Text(
            'Password',
            style: GoogleFonts.dosis(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: _bodyStyle,
            decoration: _inputDecoration('').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF6E4B3A),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentStep == 2
              ? const Color(0xFF8B0000)
              : const Color(0xFF6E4B3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isDeleting
            ? null
            : () {
                if (_currentStep == 0) {
                  setState(() {
                    _currentStep = 1;
                  });
                  return;
                }

                if (_currentStep == 1) {
                  if (_selectedReason == null) {
                    _showToast('Please select a reason.');
                    return;
                  }

                  if (_selectedReason == 'Other' &&
                      _otherReasonController.text.trim().isEmpty) {
                    _showToast('Please tell us why you\'re leaving.');
                    return;
                  }

                  setState(() {
                    _currentStep = 2;
                  });
                  return;
                }

                _deleteAccount();
              },
        child: _isDeleting
            ? const CircularProgressIndicator(
                color: Colors.white,
              )
            : Text(
                _currentStep == 2 ? 'Delete Account' : 'Continue',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _currentStep == 2
                      ? Colors.white
                      : const Color(0xFFDDC7A9),
                ),
              ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (_selectedReason == null) {
      _showToast('Please select a reason.');
      return;
    }

    if (_selectedReason == 'Other' &&
        _otherReasonController.text.trim().isEmpty) {
      _showToast('Please tell us why you\'re leaving.');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showToast('Please enter your email address.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showToast('Please enter your password.');
      return;
    }

    final user = supabase.auth.currentUser;

    if (user == null) {
      _showToast('User not found.');
      return;
    }

    if (_emailController.text.trim() != user.email) {
      _showToast('Email address does not match your account.');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete Account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E4B3A),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFFDDC7A9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: const Color(0xFFF8F8F8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await supabase.functions.invoke(
        'delete-account',
        body: {
          'reason': _selectedReason,
          'other_reason': _otherReasonController.text.trim(),
        },
      );

      if (response.data == null ||
          (response.data is Map && response.data['success'] != true)) {
        throw Exception(
          response.data?['error'] ?? 'Failed to delete account.',
        );
      }

      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } on AuthException catch (e) {
      _showToast(e.message);
    } catch (e) {
      _showToast(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: const Color(0xFF6E4B3A),
        content: Text(
          message,
          style: GoogleFonts.dosis(
            color: const Color(0xFFDDC7A9),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
