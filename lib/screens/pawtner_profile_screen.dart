import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import 'signin_screen.dart';
import 'pawtner_edit_profile_screen.dart';
import 'pawtner_services_screen.dart';
import 'pawtner_support_screen.dart';
import 'pawtner_legal_and_app_info_screen.dart';

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

      setState(() {
        pawtnerData = resp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
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
        final userId = supabase.auth.currentUser!.id;
        await supabase
            .from('pawtners')
            .update({'profile_picture_url': null}).eq('id', userId);
        setState(() => pawtnerData?['profile_picture_url'] = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              content: Text(
                'Profile picture has been removed',
                style: GoogleFonts.dosis(
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              backgroundColor: const Color(0xFFDDC7A9),
            ),
          );
        }
        if (widget.onProfileUpdated != null) widget.onProfileUpdated!();
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
        final userId = supabase.auth.currentUser!.id;
        final filePath = '$userId/profile.png';

        // Upload to Supabase Storage
        await supabase.storage.from('profile_pictures').uploadBinary(
              filePath,
              bytes,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );

        // Get public URL
        final publicUrl =
            supabase.storage.from('profile_pictures').getPublicUrl(filePath);
        debugPrint('URL: $publicUrl');

        // Update Pawtner table
        await supabase
            .from('pawtners')
            .update({'profile_picture_url': publicUrl}).eq('id', userId);

        setState(() {
          profileImageBytes = bytes;
          pawtnerData?['profile_picture_url'] = publicUrl;
        });

        // Trigger callback to dashboard
        if (widget.onProfileUpdated != null) {
          widget.onProfileUpdated!();
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
                                : const Color(0xFFDDC7A9),
                        backgroundImage: pawtnerData?['profile_picture_url'] !=
                                null
                            ? NetworkImage(
                                '${pawtnerData!['profile_picture_url']}?t=${DateTime.now().millisecondsSinceEpoch}')
                            : null,
                        child: pawtnerData?['profile_picture_url'] == null
                            ? const Icon(Icons.person,
                                size: 75, color: Color(0xFF6E4B3A))
                            : null,
                      ),
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF6E4B3A),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.camera_alt,
                              color: Color(0xFFDDC7A9), size: 20),
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
                  const SizedBox(height: 32),

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
                              setState(() {
                                pawtnerData = updated;
                              });
                              // Trigger callback to dashboard
                              if (widget.onProfileUpdated != null) {
                                widget.onProfileUpdated!();
                              }
                            },
                          ),
                        ),
                      );

                      // Refresh profile after returning from edit
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

                  // SUPPORT
                  _buildCard(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PawtnerSupportScreen(),
                        ),
                      );
                    },
                  ),

                  _buildCard(
                    icon: Icons.info,
                    label: 'Legal & App Info',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PawtnerLegalScreen(),
                        ),
                      );
                    },
                  ),

                  // LOGOUT
                  _buildCard(
                    icon: Icons.logout,
                    label: 'Logout',
                    onTap: () {
                      supabase.auth.signOut();
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
