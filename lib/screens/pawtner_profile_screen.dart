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

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Choose source'),
          content: const Text('Select image from:'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(_, ImageSource.camera),
                child: const Text('Camera')),
            TextButton(
                onPressed: () => Navigator.pop(_, ImageSource.gallery),
                child: const Text('Gallery')),
          ],
        ),
      );

      if (source == null) return;

      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final userId = supabase.auth.currentUser!.id;
        final fileExt = image.name.split('.').last;
        final filePath = '$userId.$fileExt';

        // Upload to Supabase Storage
        await supabase.storage.from('profile_pictures').uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(cacheControl: '3600'),
            );

        // Get public URL
        final publicUrl =
            supabase.storage.from('profile_pictures').getPublicUrl(filePath);

        // Update Pawtner table
        await supabase
            .from('pawtners')
            .update({'profile_picture': publicUrl})
            .eq('id', userId);

        setState(() {
          profileImageBytes = bytes;
          pawtnerData?['profile_picture'] = publicUrl;
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
      Color color = const Color(0xFF6E4B3A)}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
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
                        backgroundColor: pawtnerData?['profile_picture'] != null
                            ? Colors.transparent
                            : const Color(0xFFDDC7A9),
                        backgroundImage: pawtnerData?['profile_picture'] != null
                            ? NetworkImage(pawtnerData!['profile_picture'])
                            : null,
                        child: pawtnerData?['profile_picture'] == null
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
                        MaterialPageRoute(
                            builder: (_) => const SignInScreen()),
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
