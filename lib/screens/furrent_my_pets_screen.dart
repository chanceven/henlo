import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'furrent_add_pet_screen.dart';
import 'furrent_edit_pet_screen.dart';

class FurrentMyPetsScreen extends StatefulWidget {
  const FurrentMyPetsScreen({super.key});

  @override
  State<FurrentMyPetsScreen> createState() => _FurrentMyPetsScreenState();
}

class _FurrentMyPetsScreenState extends State<FurrentMyPetsScreen> {
  final supabase = Supabase.instance.client;

  List<dynamic> pets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw "No user found";

      final resp = await supabase
          .from('pets')
          .select()
          .eq('furrent_id', user.id);

      setState(() {
        pets = resp;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading pets: $e");
      setState(() => isLoading = false);
    }
  }

  // -----------------------
  // AGE CALCULATION
  // -----------------------
  String calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return "";

    final date = DateTime.tryParse(birthDate);
    if (date == null) return "";

    final now = DateTime.now();

    int years = now.year - date.year;
    int months = now.month - date.month;

    if (now.day < date.day) {
      months--;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years == 0 && months == 0) return "0m";
    if (years == 0) return "${months}m";
    if (months == 0) return "${years}y";

    return "${years}y ${months}m";
  }

  // -----------------------
  // DELETE PET
  // -----------------------
  Future<void> deletePet(String petId) async {
    try {
      await supabase.from('pets').delete().eq('id', petId);

      // Show toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Pet deleted successfully!",
              style: TextStyle(color: Color(0xFF6E4B3A)),
            ),
            backgroundColor: Color(0xFFFFDDDD),
            duration: Duration(seconds: 2),
          ),
        );
      }

      _loadPets();
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  Text styledText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.w400,
      Color color = const Color(0xFF6E4B3A)}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle:
            TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
    );
  }

  // ------------------------
  // PET CARD WITH SWIPE LEFT DELETE + SMOOTH ANIMATION
  // ------------------------
  Widget _petCard(Map<String, dynamic> pet) {
    final age = calculateAge(pet['birth_date']);
    final breed = (pet['breed']?.isNotEmpty == true) ? pet['breed'] : 'N/A';

    return Dismissible(
      key: Key(pet['id']),
      direction: DismissDirection.endToStart, // LEFT ONLY
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: styledText(
              "Delete this pet?",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
            content: styledText(
              "This action cannot be undone.",
              fontSize: 16,
              color: const Color(0xFF6E4B3A),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: styledText("Cancel",
                    fontSize: 16, color: const Color(0xFF6E4B3A)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: styledText("Delete",
                    fontSize: 16, color: const Color(0xFFFF3B30)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await deletePet(pet['id']);
      },

      // RED DELETE BACKGROUND HEX
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Color(0xFFFFFFFF), size: 30),
      ),

      movementDuration: const Duration(milliseconds: 200),
      resizeDuration: const Duration(milliseconds: 200),

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // PET PHOTO
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: pet['profile_picture_url'] != null
                  ? Image.network(
                      pet['profile_picture_url'],
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: const Color(0xFF6E4B3A),
                      child: const Icon(Icons.pets,
                          color: Color(0xFFDDC7A9), size: 32),
                    ),
            ),

            const SizedBox(width: 14),

            // PET INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  styledText(
                    pet['name'] ?? '',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                  const SizedBox(height: 2),
                  styledText(
                    "${pet['type'] ?? ''} • $breed",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                  const SizedBox(height: 2),
                  styledText(
                    "$age • ${pet['gender'] ?? ''}",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ],
              ),
            ),

            // EDIT BUTTON
            SizedBox(
              width: 100,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FurrentEditPetScreen(petData: pet),
                    ),
                  );
                  _loadPets();
                },
                child: styledText(
                  "Edit",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDDC7A9),
                ),
              ),
            ),
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
        title: styledText("My Pets",
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A)),
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFDCB58)))
          : pets.isEmpty
              ? Center(
                  child: styledText(
                    "No pet yet",
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E4B3A),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: pets.length,
                  itemBuilder: (_, i) => _petCard(pets[i]),
                ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6E4B3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FurrentAddPetScreen(),
                ),
              );
              _loadPets();
            },
            child: Text(
              'Add Pet',
              style: GoogleFonts.dosis(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDDC7A9),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
