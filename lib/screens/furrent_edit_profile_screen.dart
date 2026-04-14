import 'dart:io';
import 'package:flutter/material.dart';
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
  State<FurrentEditProfileScreen> createState() => _FurrentEditProfileScreenState();
}

class _FurrentEditProfileScreenState extends State<FurrentEditProfileScreen> {
  final supabase = Supabase.instance.client;

  File? _profileImage;
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late final TextEditingController _contactNumberController = TextEditingController(); // NEW

  bool _isPasswordObscured = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fullNameController =
        TextEditingController(text: widget.furrentData?['full_name'] ?? '');
    _emailController =
        TextEditingController(text: widget.furrentData?['email'] ?? '');
    _passwordController = TextEditingController();
    _contactNumberController.text =
        widget.furrentData?['contact_number'] ?? ''; // NEW: prefill
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _contactNumberController.dispose(); // NEW
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      Map<String, dynamic> updatedData = {
        'full_name': _fullNameController.text,
        'email': _emailController.text,
        'contact_number': _contactNumberController.text, // NEW
      };

      if (_profileImage != null) {
        final fileBytes = await _profileImage!.readAsBytes();
        final fileName = 'profile_${user.id}.png';

        await supabase.storage
            .from('profile_pictures')
            .uploadBinary(fileName, fileBytes, fileOptions: const FileOptions(upsert: true));

        final publicUrl = supabase.storage
            .from('profile_pictures')
            .getPublicUrl(fileName);

        updatedData['profile_picture'] = publicUrl;
      }

      await supabase.from('furrents').update(updatedData).eq('id', user.id);

      if (_passwordController.text.isNotEmpty) {
        await supabase.auth.updateUser(UserAttributes(password: _passwordController.text));
      }

      widget.onProfileUpdated(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to update profile."),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget customTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTap,
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
          style: const TextStyle(color: Color(0xFF6E4B3A)),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6E4B3A),
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 75,
                  backgroundColor: const Color(0xFF6E4B3A),
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : (widget.furrentData?['profile_picture'] != null
                          ? NetworkImage(widget.furrentData!['profile_picture'])
                          : null) as ImageProvider<Object>?,
                  child: _profileImage == null &&
                          widget.furrentData?['profile_picture'] == null
                      ? const Icon(Icons.person, size: 75, color: Color(0xFFDDC7A9))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDDC7A9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            customTextField(controller: _fullNameController, label: 'Full Name'),
            customTextField(controller: _contactNumberController, label: 'Contact Number'),
            customTextField(controller: _emailController, label: 'Email'),
            customTextField(
              controller: _passwordController,
              label: 'Password',
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

            const SizedBox(height: 90),

            SizedBox(
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

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
