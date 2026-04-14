import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'signin_screen.dart';
import 'furrent_edit_profile_screen.dart';
import 'furrent_my_pets_screen.dart';
import 'furrent_support_screen.dart';
import 'furrent_legal_and_app_info_screen.dart';

class FurrentProfileScreen extends StatefulWidget {
  const FurrentProfileScreen({super.key});

  @override
  State<FurrentProfileScreen> createState() => _FurrentProfileScreenState();
}

class _FurrentProfileScreenState extends State<FurrentProfileScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? furrentData;
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
          .from('furrents')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        furrentData = resp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => isLoading = false);
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
        automaticallyImplyLeading: false, // <-- back arrow removed
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
                  CircleAvatar(
                    radius: 75,
                    backgroundColor: furrentData?['profile_picture'] != null
                        ? Colors.transparent
                        : const Color(0xFF6E4B3A),
                    backgroundImage: furrentData?['profile_picture'] != null
                        ? NetworkImage(furrentData!['profile_picture'])
                        : null,
                    child: furrentData?['profile_picture'] == null
                        ? const Icon(Icons.person,
                            size: 75, color: Color(0xFFDDC7A9))
                        : null,
                  ),
                  const SizedBox(height: 16),
                  customText(furrentData?['full_name'] ?? '',
                      fontSize: 20, fontWeight: FontWeight.w600),
                  const SizedBox(height: 4),
                  customText(furrentData?['email'] ?? '',
                      fontSize: 16, fontWeight: FontWeight.w400),
                  const SizedBox(height: 32),

                  // EDIT PROFILE
                  _buildCard(
                    icon: Icons.edit,
                    label: 'Edit Profile',
                    onTap: () async {
                      if (furrentData == null) return;

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FurrentEditProfileScreen(
                            furrentData: furrentData!,
                            onProfileUpdated: (updated) {
                              setState(() {
                                furrentData = updated;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),

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

                  // SUPPORT
                  _buildCard(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FurrentSupportScreen(),
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
                          builder: (_) => const FurrentLegalScreen(),
                        ),
                      );                      
                    },
                  ),
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
