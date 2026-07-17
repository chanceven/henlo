import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for input formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FurrentEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? furrentData;
  final void Function(Map<String, dynamic>) onProfileUpdated;

  const FurrentEditProfileScreen({
    super.key,
    required this.furrentData,
    required this.onProfileUpdated,
  });

  @override
  State<FurrentEditProfileScreen> createState() =>
      _FurrentEditProfileScreenState();
}

class _FurrentEditProfileScreenState extends State<FurrentEditProfileScreen> {
  final supabase = Supabase.instance.client;

  Uint8List? _profileImageBytes; // ← was File? _profileImage

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late final TextEditingController _contactNumberController =
      TextEditingController();

  bool _isPasswordObscured = true;
  bool isLoading = false;

  String? _contactNumberError;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.furrentData?['full_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.furrentData?['email'] ?? '');
    _passwordController = TextEditingController();
    _contactNumberController.text = widget.furrentData?['contact_number'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$').hasMatch(trimmed);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();

      final choice = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF6E4B3A)),
                title: Text(
                  'Select profile picture',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A)),
                ),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A)),
                ),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                title: Text(
                  'Remove profile picture',
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B0000),
                  ),
                ),
                onTap: () => Navigator.pop(_, 'remove'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (choice == null) return;

      if (choice == 'remove') {
        setState(() {
          _profileImageBytes = null;
          widget.furrentData?['profile_picture_url'] = null;
        });
        return;
      }

      final source =
          choice == 'camera' ? ImageSource.camera : ImageSource.gallery;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() => _profileImageBytes = bytes);
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _contactNumberError = null;
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;

    if (!_isValidContactNumber(_contactNumberController.text)) {
      _contactNumberError = 'Please enter a valid contact number';
      hasError = true;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (_emailController.text.trim().isEmpty ||
        !emailRegex.hasMatch(_emailController.text.trim())) {
      _emailError = 'Please enter a valid email';
      hasError = true;
    }

    if (_passwordController.text.isNotEmpty) {
      if (_passwordController.text.trim().length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        hasError = true;
      } else if (_passwordController.text.trim().length > 32) {
        _passwordError = 'Password must not exceed 32 characters';
        hasError = true;
      } else if (!_passwordController.text.trim().contains(RegExp(r'[0-9]'))) {
        _passwordError = 'Password must contain at least one number';
        hasError = true;
      } else if (!_passwordController.text
          .trim()
          .contains(RegExp(r'[a-zA-Z]'))) {
        _passwordError = 'Password must contain at least one letter';
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      Map<String, dynamic> updatedData = {
        'full_name': _fullNameController.text,
        'email': _emailController.text,
        'contact_number': _contactNumberController.text,
        if (widget.furrentData?['profile_picture_url'] == null &&
            _profileImageBytes == null)
          'profile_picture_url': null,
      };

      if (_profileImageBytes != null) {
        const fileExt = 'png';
        final fileName = '${user.id}/profile.$fileExt';

        await supabase.storage.from('profile_pictures').uploadBinary(
              fileName,
              _profileImageBytes!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );

        final publicUrl =
            supabase.storage.from('profile_pictures').getPublicUrl(fileName);

        updatedData['profile_picture_url'] = publicUrl;
      }

      await supabase.from('furrents').update(updatedData).eq('id', user.id);

      if (_passwordController.text.isNotEmpty) {
        await supabase.auth
            .updateUser(UserAttributes(password: _passwordController.text));
      }

      widget.onProfileUpdated(updatedData);

      if (mounted) {
        _showToast('Profile updated successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        _showToast('Failed to update profile.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget customTextField({
    required TextEditingController controller,
    required String label,
    String? errorText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dosis(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.dosis(
            color: const Color(0xFF6E4B3A),
          ),
          decoration: InputDecoration(
            errorText: errorText,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPicUrl = widget.furrentData?['profile_picture_url'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 0, 16, 24 + MediaQuery.of(context).padding.bottom),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E4B3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isLoading ? null : _saveProfile,
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Save Changes',
                    style: GoogleFonts.dosis(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDDC7A9),
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 75,
                  backgroundColor:
                      _profileImageBytes != null || currentPicUrl != null
                          ? Colors.transparent
                          : const Color(0xFF6E4B3A),
                  backgroundImage: _profileImageBytes != null
                      ? MemoryImage(_profileImageBytes!) // ← MemoryImage
                      : (currentPicUrl != null
                          ? NetworkImage(
                              '$currentPicUrl?t=${DateTime.now().millisecondsSinceEpoch}')
                          : null) as ImageProvider?,
                  child: _profileImageBytes == null && currentPicUrl == null
                      ? const Icon(Icons.person,
                          size: 75, color: Color(0xFFDDC7A9))
                      : null,
                ),
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFDDC7A9),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.camera_alt,
                        color: Color(0xFF6E4B3A), size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            customTextField(
                controller: _fullNameController, label: 'Full Name'),
            customTextField(
              controller: _contactNumberController,
              label: 'Contact Number',
              errorText: _contactNumberError,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // Allow digits and a leading "+" (for +63 format).
                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                LengthLimitingTextInputFormatter(13),
              ],
            ),
            customTextField(
                controller: _emailController,
                label: 'Email',
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress),
            customTextField(
              controller: _passwordController,
              label: 'Password',
              errorText: _passwordError,
              isPassword: true,
              obscureText: _isPasswordObscured,
              onTap: () {
                if (_isPasswordObscured) {
                  setState(() {
                    _isPasswordObscured = false;
                    _passwordController.text = '';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
