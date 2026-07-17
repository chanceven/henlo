// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
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
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          24,
        ),
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

  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  String? _petType;
  String? _gender;
  String? _selectedMonth;
  int? _selectedDay;
  int? _selectedYear;
  Uint8List? _petImageBytes; // ← was File? _petImage
  bool isSaving = false;

  bool showPetTypeOptions = false;
  bool showGenderOptions = false;
  bool showMonthOptions = false;
  bool showDayOptions = false;
  bool showYearOptions = false;

  final List<String> petTypes = ['Dog', 'Cat'];
  final List<String> genders = ['Boy', 'Girl'];
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  final List<int> years =
      List.generate(20, (index) => DateTime.now().year - index);

  void _openOnly(String which) {
    setState(() {
      showPetTypeOptions = which == 'type';
      showGenderOptions = which == 'gender';
      showMonthOptions = which == 'month';
      showDayOptions = which == 'day';
      showYearOptions = which == 'year';
    });
  }

  List<int> getDaysInMonth(int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  Future<void> _pickPetImage() async {
    _openOnly('none'); // close any open dropdown before showing the sheet
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
                  'Select photo',
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
                  'Remove photo',
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
        setState(() => _petImageBytes = null);
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
        setState(() => _petImageBytes = bytes);
      }
    } catch (e) {
      debugPrint('Error picking pet image: $e');
    }
  }

  Future<void> _savePet() async {
    if (_nameController.text.isEmpty ||
        _selectedMonth == null ||
        _selectedDay == null ||
        _selectedYear == null ||
        _petType == null ||
        _gender == null) {
      _showToast('Please fill all required fields');
      return;
    }

    setState(() => isSaving = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'No user logged in';

      int monthIndex = months.indexOf(_selectedMonth!) + 1;
      final birthDate = DateTime(_selectedYear!, monthIndex, _selectedDay!);
      final birthDateStr =
          '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

      Map<String, dynamic> petData = {
        'furrent_id': user.id,
        'name': _nameController.text,
        'type': _petType,
        'breed':
            _breedController.text.isNotEmpty ? _breedController.text : null,
        'birth_date': birthDateStr,
        'gender': _gender,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_petImageBytes != null) {
        final fileName =
            '${user.id}/pet_${_nameController.text.trim().toLowerCase().replaceAll(' ', '_')}.png';

        await supabase.storage.from('profile_pictures').uploadBinary(
              fileName,
              _petImageBytes!,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: true),
            );

        final publicUrl =
            supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        petData['profile_picture_url'] = publicUrl;
      }

      await supabase.from('pets').insert(petData);

      if (mounted) {
        _showToast('Pet added successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding pet: $e');
      if (mounted) {
        _showToast('Failed to add pet');
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
          onTap: () => _openOnly('none'),
          style: GoogleFonts.dosis(
            color: const Color(0xFF6E4B3A),
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
    bool truncateValue = false,
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
                        ? (truncateValue && value is String
                            ? value.substring(0, 3)
                            : value.toString())
                        : (placeholder ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign:
                        value == null ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.dosis(
                      color: value != null
                          ? const Color(0xFF6E4B3A)
                          : Colors.grey[500],
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
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
                        onTap: () => onSelect(e),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          color: e == value
                              ? const Color(0xFF6E4B3A).withOpacity(0.2)
                              : Colors.transparent,
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
          'Birthdate',
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
                label: '',
                value: _selectedMonth,
                options: months,
                placeholder: 'Month',
                isExpanded: showMonthOptions,
                toggleDropdown: () =>
                    _openOnly(showMonthOptions ? 'none' : 'month'),
                onSelect: (val) {
                  setState(() {
                    _selectedMonth = val;
                    if (_selectedYear != null && _selectedDay != null) {
                      final m = months.indexOf(val) + 1;
                      final maxDay = getDaysInMonth(m, _selectedYear!).length;
                      if (_selectedDay! > maxDay) _selectedDay = maxDay;
                    }
                    showMonthOptions = false;
                  });
                },
                maxHeight: 150,
                truncateValue: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: customDropdownField<int>(
                label: '',
                value: _selectedDay,
                options: (_selectedMonth != null && _selectedYear != null)
                    ? getDaysInMonth(
                        months.indexOf(_selectedMonth!) + 1, _selectedYear!)
                    : List.generate(31, (index) => index + 1),
                placeholder: 'Day',
                isExpanded: showDayOptions,
                toggleDropdown: () =>
                    _openOnly(showDayOptions ? 'none' : 'day'),
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
                label: '',
                value: _selectedYear,
                options: years,
                placeholder: 'Year',
                isExpanded: showYearOptions,
                toggleDropdown: () =>
                    _openOnly(showYearOptions ? 'none' : 'year'),
                onSelect: (val) {
                  setState(() {
                    _selectedYear = val;
                    if (_selectedMonth != null && _selectedDay != null) {
                      final m = months.indexOf(_selectedMonth!) + 1;
                      final maxDay = getDaysInMonth(m, val).length;
                      if (_selectedDay! > maxDay) _selectedDay = maxDay;
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

  // ← Replaced AlertDialog-based uploadPhotoField with bottom-sheet tap
  Widget uploadPhotoField() {
    return GestureDetector(
      onTap: _pickPetImage,
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
              child: _petImageBytes == null
                  ? RichText(
                      text: TextSpan(
                        text: 'Upload Pet Photo ',
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                        ),
                        children: [
                          TextSpan(
                            text: '(Optional)',
                            style: GoogleFonts.dosis(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'Photo Selected',
                      style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
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
    if (showPetTypeOptions ||
        showGenderOptions ||
        showMonthOptions ||
        showDayOptions ||
        showYearOptions) {
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
      behavior: HitTestBehavior.opaque,
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
              onPressed: isSaving ? null : _savePet,
              child: isSaving
                  ? const CircularProgressIndicator(
                      color: Color(0xFFDDC7A9),
                    )
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
                label: 'Pet Type',
                value: _petType,
                options: petTypes,
                isExpanded: showPetTypeOptions,
                toggleDropdown: () =>
                    _openOnly(showPetTypeOptions ? 'none' : 'type'),
                onSelect: (val) {
                  setState(() {
                    _petType = val;
                    showPetTypeOptions = false;
                  });
                },
                truncateValue: false,
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
                label: 'Gender',
                value: _gender,
                options: genders,
                isExpanded: showGenderOptions,
                toggleDropdown: () =>
                    _openOnly(showGenderOptions ? 'none' : 'gender'),
                onSelect: (val) {
                  setState(() {
                    _gender = val;
                    showGenderOptions = false;
                  });
                },
                truncateValue: false,
              ),
              uploadPhotoField(),
            ],
          ),
        ),
      ),
    );
  }
}
