import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController retypePasswordController =
      TextEditingController();

  bool isLoading = false;
  bool obscureCurrentPassword = true;
  bool obscureNewPassword = true;
  bool obscureRetypePassword = true;

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    retypePasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Text(
          message,
          style: GoogleFonts.dosis(
            color: const Color(0xFFDDC7A9),
          ),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final retypePassword = retypePasswordController.text;

    if (currentPassword.isEmpty) {
      _showMessage('Please enter your current password.');
      return;
    }

    if (newPassword.isEmpty) {
      _showMessage('Please enter your new password.');
      return;
    }

    if (retypePassword.isEmpty) {
      _showMessage('Please re-type your new password.');
      return;
    }

    if (newPassword != retypePassword) {
      _showMessage('New passwords do not match.');
      return;
    }

    if (currentPassword == newPassword) {
      _showMessage(
          'New password must be different from your current password.');
      return;
    }

    if (newPassword.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    if (newPassword.length > 32) {
      _showMessage('Password must not exceed 32 characters.');
      return;
    }

    if (!newPassword.contains(RegExp(r'[0-9]'))) {
      _showMessage('Password must contain at least one number.');
      return;
    }

    if (!newPassword.contains(RegExp(r'[a-zA-Z]'))) {
      _showMessage('Password must contain at least one letter.');
      return;
    }

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final email = user?.email;

    if (user == null || email == null) {
      _showMessage('Unable to change password. Please try again.');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Verify current password is correct before allowing the change
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      await supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );

      if (!mounted) return;

      _showMessage('Password changed successfully.');

      currentPasswordController.clear();
      newPasswordController.clear();
      retypePasswordController.clear();

      FocusScope.of(context).unfocus();

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pop(context);
    } on AuthException catch (e) {
      debugPrint('Error changing password: ${e.message}');
      if (!mounted) return;

      final message = e.message.toLowerCase();

      if (message.contains('invalid login credentials') ||
          message.contains('invalid credentials')) {
        _showMessage('Current password is incorrect.');
      } else {
        _showMessage(e.message);
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      if (!mounted) return;

      _showMessage('Unable to change password. Please try again.');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  InputDecoration buildInputDecoration({
    required String hint,
    required bool obscure,
    required VoidCallback onVisibilityTap,
  }) {
    return InputDecoration(
      prefixIcon: const Icon(
        Icons.lock_outline,
        color: Color(0xFF6E4B3A),
      ),
      suffixIcon: IconButton(
        onPressed: onVisibilityTap,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: const Color(0xFF6E4B3A),
        ),
      ),
      hintText: hint,
      hintStyle: GoogleFonts.dosis(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFBDBDBD),
      ),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: const Color(0xFF6E4B3A).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF6E4B3A),
          width: 1.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const SizedBox.shrink(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Color(0xFF6E4B3A),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),

                    Text(
                      'Change password',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.dosis(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Enter your current password and choose\na new password',
                      textAlign: TextAlign.left,
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF8A6A5A),
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // CURRENT PASSWORD
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrentPassword,
                      textInputAction: TextInputAction.next,
                      decoration: buildInputDecoration(
                        hint: 'Current Password',
                        obscure: obscureCurrentPassword,
                        onVisibilityTap: () {
                          setState(() {
                            obscureCurrentPassword = !obscureCurrentPassword;
                          });
                        },
                      ),
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // NEW PASSWORD
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      decoration: buildInputDecoration(
                        hint: 'New Password',
                        obscure: obscureNewPassword,
                        onVisibilityTap: () {
                          setState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),

                    const SizedBox(height: 16),

// RE-TYPE NEW PASSWORD
                    TextField(
                      controller: retypePasswordController,
                      obscureText: obscureRetypePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!isLoading) {
                          _changePassword();
                        }
                      },
                      decoration: buildInputDecoration(
                        hint: 'Re-type New Password',
                        obscure: obscureRetypePassword,
                        onVisibilityTap: () {
                          setState(() {
                            obscureRetypePassword = !obscureRetypePassword;
                          });
                        },
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
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  foregroundColor: const Color(0xFFDDC7A9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFDDC7A9),
                        ),
                      )
                    : Text(
                        'Change Password',
                        style: GoogleFonts.dosis(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
