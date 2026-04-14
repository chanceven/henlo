import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FurrentAddPetScreen extends StatefulWidget {
  const FurrentAddPetScreen({super.key});

  @override
  State<FurrentAddPetScreen> createState() => _FurrentAddPetScreenState();
}

class _FurrentAddPetScreenState extends State<FurrentAddPetScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  String? _petType;
  String? _gender;
  String? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;
  File? _petImage;
  bool isSaving = false;

  bool showPetTypeOptions = false;
  bool showGenderOptions = false;
  bool showMonthOptions = false;
  bool showDayOptions = false;
  bool showYearOptions = false;

  final List<String> petTypes = ['Dog', 'Cat'];
  final List<String> genders = ['Boy', 'Girl'];
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<int> years = List.generate(20, (index) => DateTime.now().year - index);

  List<int> getDaysInMonth(int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _petImage = File(picked.path);
      });
    }
  }

  void _showImageOptions() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upload Pet Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF6E4B3A)),
              title: const Text('Choose Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
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

  Future<void> _savePet() async {
    if (_nameController.text.isEmpty ||
        _selectedMonth == null ||
        _selectedDay == null ||
        _selectedYear == null ||
        _petType == null ||
        _gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'No user logged in';

      int monthIndex = months.indexOf(_selectedMonth!) + 1;
      final birthDate = DateTime(_selectedYear!, monthIndex, _selectedDay!);

      // Format as YYYY-MM-DD for date column
      final birthDateStr =
          "${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}";

      Map<String, dynamic> petData = {
        'furrent_id': user.id,
        'name': _nameController.text,
        'type': _petType,
        'breed': _breedController.text.isNotEmpty ? _breedController.text : null,
        'birth_date': birthDateStr,
        'gender': _gender,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_petImage != null) {
        final bytes = await _petImage!.readAsBytes();
        final fileName = 'pet_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';

        await supabase.storage.from('profile_pictures').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        final publicUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        petData['profile_picture_url'] = publicUrl;
      }

      await supabase.from('pets').insert(petData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Pet added successfully!"),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding pet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add pet: $e"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget customTextField({
    required TextEditingController controller,
    required Widget? labelWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelWidget != null) labelWidget,
        if (labelWidget != null) const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF6E4B3A), fontWeight: FontWeight.w400),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
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

  Widget customDropdownField<T>({
    required String label,
    required T? value,
    required List<T> options,
    required bool isExpanded,
    required VoidCallback toggleDropdown,
    required Function(T) onSelect,
    double maxHeight = 200,
    String? placeholder,
    bool truncateValue = false, // NEW
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: GoogleFonts.dosis(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        GestureDetector(
          onTap: toggleDropdown,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF6E4B3A), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? (truncateValue && value is String ? value.substring(0, 3) : value.toString())
                        : (placeholder ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: value == null ? TextAlign.center : TextAlign.left,
                    style: TextStyle(
                      color: value != null ? const Color(0xFF6E4B3A) : Colors.grey[500],
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6E4B3A),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF6E4B3A), width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: options
                    .map(
                      (e) => GestureDetector(
                        onTap: () {
                          onSelect(e);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          color: e == value ? const Color(0xFF6E4B3A).withOpacity(0.2) : Colors.transparent,
                          child: Center(
                            child: Text(
                              e.toString(),
                              style: const TextStyle(
                                color: Color(0xFF6E4B3A),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget birthdateDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Birthdate",
          style: GoogleFonts.dosis(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: customDropdownField<String>(
                label: "",
                value: _selectedMonth,
                options: months,
                placeholder: "Month",
                isExpanded: showMonthOptions,
                toggleDropdown: () {
                  setState(() {
                    showMonthOptions = !showMonthOptions;
                    showDayOptions = false;
                    showYearOptions = false;
                  });
                },
                onSelect: (val) {
                  setState(() {
                    _selectedMonth = val;

                    if (_selectedYear != null && _selectedDay != null) {
                      final m = months.indexOf(val) + 1;
                      final maxDay = getDaysInMonth(m, _selectedYear!).length;

                      if (_selectedDay! > maxDay) {
                        _selectedDay = maxDay;
                      }
                    }

                    showMonthOptions = false;
                  });
                },
                maxHeight: 150,
                truncateValue: true, // only truncate months
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: customDropdownField<int>(
                label: "",
                value: _selectedDay,
                options: (_selectedMonth != null && _selectedYear != null)
                    ? getDaysInMonth(months.indexOf(_selectedMonth!) + 1, _selectedYear!)
                    : List.generate(31, (index) => index + 1),
                placeholder: "Day",
                isExpanded: showDayOptions,
                toggleDropdown: () {
                  setState(() {
                    showDayOptions = !showDayOptions;
                    showMonthOptions = false;
                    showYearOptions = false;
                  });
                },
                onSelect: (val) {
                  setState(() {
                    _selectedDay = val;
                    showDayOptions = false;
                  });
                },
                maxHeight: 150,
                truncateValue: false,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: customDropdownField<int>(
                label: "",
                value: _selectedYear,
                options: years,
                placeholder: "Year",
                isExpanded: showYearOptions,
                toggleDropdown: () {
                  setState(() {
                    showYearOptions = !showYearOptions;
                    showMonthOptions = false;
                    showDayOptions = false;
                  });
                },
                onSelect: (val) {
                  setState(() {
                    _selectedYear = val;

                    if (_selectedMonth != null && _selectedDay != null) {
                      final m = months.indexOf(_selectedMonth!) + 1;
                      final maxDay = getDaysInMonth(m, val).length;

                      if (_selectedDay! > maxDay) {
                        _selectedDay = maxDay;
                      }
                    }

                    showYearOptions = false;
                  });
                },
                maxHeight: 150,
                truncateValue: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget uploadPhotoField() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF6E4B3A), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.photo_camera, color: Color(0xFF6E4B3A)),
            const SizedBox(width: 8),
            Expanded(
              child: _petImage == null
                  ? RichText(
                      text: TextSpan(
                        text: 'Upload Pet Photo ',
                        style: const TextStyle(
                          color: Color(0xFF6E4B3A),
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: '(Optional)',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      "Photo Selected",
                      style: TextStyle(
                        color: Color(0xFF6E4B3A),
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _hideDropdowns() {
    if (showPetTypeOptions || showGenderOptions || showMonthOptions || showDayOptions || showYearOptions) {
      setState(() {
        showPetTypeOptions = false;
        showGenderOptions = false;
        showMonthOptions = false;
        showDayOptions = false;
        showYearOptions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideDropdowns,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Add Pet',
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
              customTextField(
                controller: _nameController,
                labelWidget: Text(
                  'Pet Name',
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
              ),
              customDropdownField(
                label: "Pet Type",
                value: _petType,
                options: petTypes,
                isExpanded: showPetTypeOptions,
                toggleDropdown: () {
                  setState(() {
                    showPetTypeOptions = !showPetTypeOptions;
                    showGenderOptions = false;
                  });
                },
                onSelect: (val) {
                  setState(() {
                    _petType = val;
                    showPetTypeOptions = false;
                  });
                },
                truncateValue: false, // show full text
              ),
              customTextField(
                controller: _breedController,
                labelWidget: RichText(
                  text: TextSpan(
                    text: 'Breed ',
                    style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                    children: [
                      TextSpan(
                        text: '(Optional)',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              birthdateDropdowns(),
              customDropdownField(
                label: "Gender",
                value: _gender,
                options: genders,
                isExpanded: showGenderOptions,
                toggleDropdown: () {
                  setState(() {
                    showGenderOptions = !showGenderOptions;
                    showPetTypeOptions = false;
                  });
                },
                onSelect: (val) {
                  setState(() {
                    _gender = val;
                    showGenderOptions = false;
                  });
                },
                truncateValue: false, // show full text
              ),
              uploadPhotoField(),
              const SizedBox(height: 50),
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
                  onPressed: isSaving ? null : _savePet,
                  child: isSaving
                      ? const CircularProgressIndicator(color: Color(0xFFDDC7A9))
                      : Text(
                          'Add Pet',
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
      ),
    );
  }
}
