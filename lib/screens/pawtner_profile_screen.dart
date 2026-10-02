import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'signin_screen.dart';
import 'pawtner_edit_profile_screen.dart';
import 'pawtner_services_screen.dart';
import 'support_screen.dart';
import 'settings_screen.dart';
import 'account_screen.dart';

class PawtnerProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated; // <-- NEW

  const PawtnerProfileScreen({super.key, this.onProfileUpdated}); // <-- UPDATED

  @override
  State<PawtnerProfileScreen> createState() => _PawtnerProfileScreenState();
}

class _PawtnerProfileScreenState extends State<PawtnerProfileScreen> {
  final supabase = Supabase.instance.client;
  Uint8List? profileImageBytes;

  Map<String, dynamic>? pawtnerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final resp = await supabase
          .from('pawtners')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        pawtnerData = resp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
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
                    fontSize: 16, fontWeight: FontWeight.w600),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
                title: customText('Take a photo',
                    fontSize: 16, fontWeight: FontWeight.w600),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                title: customText('Remove profile picture',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B0000)),
                onTap: () => Navigator.pop(_, 'remove'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (choice == null) return;

      if (choice == 'remove') {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) return;
        final oldUrl = pawtnerData?['profile_picture_url'] as String?;
        try {
          await supabase
              .from('pawtners')
              .update({'profile_picture_url': null}).eq('id', userId);
          await _deleteOldProfilePhoto(oldUrl);
          if (!mounted) return;
          setState(() => pawtnerData?['profile_picture_url'] = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile picture has been removed',
                style: GoogleFonts.dosis(
                  color: const Color(0xFFDDC7A9),
                ),
              ),
              backgroundColor: const Color(0xFF6E4B3A),
            ),
          );
          if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
        } catch (e) {
          debugPrint('Error removing profile picture: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to remove profile picture. Please try again.',
                style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
              ),
              backgroundColor: const Color(0xFF6E4B3A),
            ),
          );
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

      if (image != null) {
        if (source == ImageSource.camera) {
          // Let Android fully reattach the Activity/surface after the
          // external camera Activity closes before we touch context or
          // start network I/O. Gallery already works, so it's untouched.
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
        }

        final bytes = await image.readAsBytes();

        if (bytes.length > 3 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image must be smaller than 3MB',
                  style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
                ),
                backgroundColor: const Color(0xFF6E4B3A),
              ),
            );
          }
          return;
        }

        final userId = supabase.auth.currentUser?.id;
        if (userId == null) return;
        final ext = image.path.split('.').last.toLowerCase();
        final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
        final filePath =
            '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final oldUrl = pawtnerData?['profile_picture_url'] as String?;

        try {
          await supabase.storage.from('profile_pictures').uploadBinary(
                filePath,
                bytes,
                fileOptions: FileOptions(
                    cacheControl: '3600',
                    upsert: true,
                    contentType: contentType),
              );

          final publicUrl =
              supabase.storage.from('profile_pictures').getPublicUrl(filePath);

          await supabase
              .from('pawtners')
              .update({'profile_picture_url': publicUrl}).eq('id', userId);

          await _deleteOldProfilePhoto(oldUrl);

          if (!mounted) return;
          setState(() {
            profileImageBytes = bytes;
            pawtnerData?['profile_picture_url'] = publicUrl;
          });

          if (widget.onProfileUpdated != null) {
            widget.onProfileUpdated!();
          }
        } catch (e) {
          debugPrint('Error uploading profile picture: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload profile picture. Please try again.',
                style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
              ),
              backgroundColor: const Color(0xFF6E4B3A),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
    }
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF6E4B3A),
      TextAlign textAlign = TextAlign.start}) {
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title:
            customText('My Profile', fontSize: 24, fontWeight: FontWeight.w600),
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 75,
                        backgroundColor:
                            pawtnerData?['profile_picture_url'] != null
                                ? Colors.transparent
                                : const Color(0xFF6E4B3A),
                        backgroundImage:
                            pawtnerData?['profile_picture_url'] != null
                                ? NetworkImage(
                                    '${pawtnerData!['profile_picture_url']}')
                                : null,
                        child: pawtnerData?['profile_picture_url'] == null
                            ? const Icon(Icons.person,
                                size: 75, color: Color(0xFFDDC7A9))
                            : null,
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
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
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  customText(pawtnerData?['full_name'] ?? '',
                      fontSize: 20, fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  customText(pawtnerData?['email'] ?? '',
                      fontSize: 16, fontWeight: FontWeight.w400),
                  const SizedBox(height: 24),

                  // EDIT PROFILE
                  _buildCard(
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    onTap: () async {
                      if (pawtnerData == null) return;

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PawtnerEditProfileScreen(
                            pawtnerData: pawtnerData!,
                            onProfileUpdated: (updated) {
                              if (!mounted) return;
                              setState(() {
                                pawtnerData = updated;
                              });
                              if (widget.onProfileUpdated != null) {
                                widget.onProfileUpdated!();
                              }
                            },
                          ),
                        ),
                      );

                      if (!mounted) return;
                      await _loadProfile();
                    },
                  ),

                  // SERVICES & AVAILABILITY
                  _buildCard(
                    icon: Icons.access_time,
                    label: 'My Services',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PawtnerServicesScreen(),
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
                            userType: 'pawtner',
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
                              .from('pawtners')
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
