import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'signin_screen.dart';
import 'furrent_my_pets_screen.dart';
import 'account_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';

class FurrentProfileScreen extends StatefulWidget {
  const FurrentProfileScreen({super.key});

  @override
  State<FurrentProfileScreen> createState() => _FurrentProfileScreenState();
}

class _FurrentProfileScreenState extends State<FurrentProfileScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? furrentData;
  bool isLoading = true;
  bool _isSaving = false;

  bool _editingName = false;
  bool _editingContact = false;
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  String? _nameError;
  String? _contactError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final resp = await supabase
          .from('furrents')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        furrentData = resp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
      ),
    );
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF6E4B3A),
      TextAlign textAlign = TextAlign.center}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textAlign: textAlign,
    );
  }

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$').hasMatch(trimmed);
  }

  // ---------- Profile picture ----------

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
                title: customText('Select profile picture',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.start),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
                title: customText('Take a photo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.start),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                title: customText('Remove profile picture',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B0000),
                    textAlign: TextAlign.start),
                onTap: () => Navigator.pop(_, 'remove'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (choice == null) return;

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final oldUrl = furrentData?['profile_picture_url'] as String?;

      if (choice == 'remove') {
        try {
          await _deleteOldProfilePhoto(oldUrl);
          await supabase
              .from('furrents')
              .update({'profile_picture_url': null}).eq('id', userId);
          if (!mounted) return;
          setState(() => furrentData?['profile_picture_url'] = null);
          _showToast('Profile picture removed');
        } catch (e) {
          debugPrint('Error removing profile picture: $e');
          if (mounted) _showToast('Failed to remove profile picture');
        }
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

      if (image == null) return;

      if (source == ImageSource.camera) {
        // Let Android fully reattach the Activity/surface after the
        // external camera Activity closes before we touch context or
        // start network I/O. Gallery already works, so it's untouched.
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
      }

      final bytes = await image.readAsBytes();

      if (bytes.length > 3 * 1024 * 1024) {
        if (mounted) _showToast('Image must be smaller than 3MB');
        return;
      }

      final ext = image.path.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final fileName =
          '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

      try {
        await supabase.storage.from('profile_pictures').uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                  cacheControl: '3600', upsert: true, contentType: contentType),
            );

        final publicUrl =
            supabase.storage.from('profile_pictures').getPublicUrl(fileName);

        await supabase
            .from('furrents')
            .update({'profile_picture_url': publicUrl}).eq('id', userId);

        await _deleteOldProfilePhoto(oldUrl);

        if (!mounted) return;
        setState(() => furrentData?['profile_picture_url'] = publicUrl);
        _showToast('Profile picture updated');
      } catch (e) {
        debugPrint('Error uploading profile picture: $e');
        if (mounted) _showToast('Failed to upload profile picture');
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Future<void> _deleteOldProfilePhoto(String? oldUrl) async {
    if (oldUrl == null || oldUrl.isEmpty) return;
    try {
      const marker = '/profile_pictures/';
      final markerIndex = oldUrl.indexOf(marker);
      if (markerIndex == -1) return;
      final oldPath = oldUrl.substring(markerIndex + marker.length);
      await supabase.storage.from('profile_pictures').remove([oldPath]);
    } catch (e) {
      debugPrint('Error deleting old profile photo: $e');
    }
  }

  // ---------- Inline edit: name / contact number ----------

  Future<void> _saveField(String column, String value) async {
    setState(() => _isSaving = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      await supabase.from('furrents').update({column: value}).eq('id', user.id);

      if (!mounted) return;
      setState(() {
        furrentData?[column] = value;
        if (column == 'full_name') _editingName = false;
        if (column == 'contact_number') _editingContact = false;
      });
      _showToast('Updated successfully');
    } catch (e) {
      debugPrint('Error updating $column: $e');
      if (mounted) _showToast('Failed to update. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _editableField({
    required bool isEditing,
    required String value,
    required TextEditingController controller,
    required String? errorText,
    required TextInputType keyboardType,
    required VoidCallback onEditTap,
    required VoidCallback onConfirm,
    required VoidCallback onCancel,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    if (!isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: customText(value,
                fontSize: fontSize,
                fontWeight: fontWeight,
                textAlign: TextAlign.start),
          ),
          InkWell(
            onTap: _isSaving ? null : onEditTap,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit, size: 16, color: Color(0xFF6E4B3A)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: keyboardType,
            style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
            decoration: InputDecoration(
              isDense: true,
              errorText: errorText,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6E4B3A)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 2),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.green),
          onPressed: _isSaving ? null : onConfirm,
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF8B0000)),
          onPressed: _isSaving ? null : onCancel,
        ),
      ],
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color color = const Color(0xFF6E4B3A)}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            customText(label,
                fontSize: 16, fontWeight: FontWeight.w600, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 36, 12, 0),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // PROFILE PICTURE
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.bottomRight,
                              children: [
                                SizedBox(
                                  width: 110,
                                  height: 110,
                                  child: CircleAvatar(
                                    backgroundColor:
                                        furrentData?['profile_picture_url'] !=
                                                null
                                            ? Colors.transparent
                                            : const Color(0xFF6E4B3A),
                                    backgroundImage:
                                        furrentData?['profile_picture_url'] !=
                                                null
                                            ? NetworkImage(
                                                '${furrentData!['profile_picture_url']}',
                                              )
                                            : null,
                                    child:
                                        furrentData?['profile_picture_url'] ==
                                                null
                                            ? const Icon(
                                                Icons.person,
                                                size: 45,
                                                color: Color(0xFFDDC7A9),
                                              )
                                            : null,
                                  ),
                                ),
                                Positioned(
                                  right: 4,
                                  bottom: 4,
                                  child: GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFDDC7A9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Color(0xFF6E4B3A),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(width: 18),

                            // NAME + CONTACT + EMAIL
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // NAME
                                  _editableField(
                                    isEditing: _editingName,
                                    value: furrentData?['full_name'] ?? '',
                                    controller: _nameController,
                                    errorText: _nameError,
                                    keyboardType: TextInputType.name,
                                    fontSize: 24,
                                    onEditTap: () {
                                      _nameController.text =
                                          furrentData?['full_name'] ?? '';

                                      setState(() {
                                        _nameError = null;
                                        _editingName = true;
                                      });
                                    },
                                    onConfirm: () {
                                      if (_nameController.text.trim().isEmpty) {
                                        setState(() {
                                          _nameError = 'Name cannot be empty';
                                        });
                                        return;
                                      }

                                      _saveField(
                                        'full_name',
                                        _nameController.text.trim(),
                                      );
                                    },
                                    onCancel: () {
                                      setState(() => _editingName = false);
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // CONTACT NUMBER
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.phone_outlined,
                                        size: 18,
                                        color: Color(0xFF6E4B3A),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _editableField(
                                          isEditing: _editingContact,
                                          value:
                                              furrentData?['contact_number'] ??
                                                  '',
                                          controller: _contactController,
                                          errorText: _contactError,
                                          keyboardType: TextInputType.phone,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          onEditTap: () {
                                            _contactController.text =
                                                furrentData?[
                                                        'contact_number'] ??
                                                    '';

                                            setState(() {
                                              _contactError = null;
                                              _editingContact = true;
                                            });
                                          },
                                          onConfirm: () {
                                            if (!_isValidContactNumber(
                                              _contactController.text,
                                            )) {
                                              setState(() {
                                                _contactError =
                                                    'Please enter a valid contact number';
                                              });
                                              return;
                                            }

                                            _saveField(
                                              'contact_number',
                                              _contactController.text.trim(),
                                            );
                                          },
                                          onCancel: () {
                                            setState(
                                                () => _editingContact = false);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // EMAIL
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        size: 18,
                                        color: Color(0xFF6E4B3A),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: customText(
                                          furrentData?['email'] ?? '',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          textAlign: TextAlign.start,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 70),

                  // MY PETS
                  _buildCard(
                    icon: Icons.pets,
                    label: 'My Pets',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FurrentMyPetsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildCard(
                    icon: Icons.manage_accounts_outlined,
                    label: 'Account',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountScreen(),
                        ),
                      );
                    },
                  ),

                  _buildCard(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),

                  _buildCard(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SupportScreen(
                            userType: 'furrent',
                          ),
                        ),
                      );
                    },
                  ),

                  _buildCard(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Are you sure you want to log out?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dosis(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                            ],
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6E4B3A)),
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.dosis(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFFDDC7A9)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B0000)),
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.dosis(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: const Color(0xFFF8F8F8)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;
                      if (!context.mounted) return;

                      try {
                        final uid = supabase.auth.currentUser?.id;
                        if (uid != null) {
                          await supabase
                              .from('furrents')
                              .update({'fcm_token': null}).eq('id', uid);
                        }
                      } catch (e) {
                        debugPrint('Error clearing FCM token: $e');
                      }

                      try {
                        await supabase.auth.signOut();
                      } catch (e) {
                        debugPrint('Error signing out: $e');
                      }
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (route) => false,
                      );
                    },
                    color: const Color(0xFF8B0000),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
