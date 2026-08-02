// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DropdownType { petType, gender, month, day, year, none }

class FurrentAddPetScreen extends StatefulWidget {
  final bool isBookingFlow;

  const FurrentAddPetScreen({
    super.key,
    this.isBookingFlow = false,
  });

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
  Uint8List? _petImageBytes;
  bool isSaving = false;

  DropdownType _activeDropdown = DropdownType.none;

  final GlobalKey _petTypeKey = GlobalKey();
  final GlobalKey _genderKey = GlobalKey();
  final GlobalKey _monthKey = GlobalKey();
  final GlobalKey _dayKey = GlobalKey();
  final GlobalKey _yearKey = GlobalKey();

  final List<String> petTypes = ['Dog', 'Cat'];
  final List<String> genders = ['Boy', 'Girl'];
  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  final List<int> years = List.generate(20, (index) => DateTime.now().year - index);

  // Reusable label style for 100% consistency
  final TextStyle _labelStyle = GoogleFonts.dosis(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF6E4B3A),
  );

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Text(
          message,
          style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
      ),
    );
  }

  void _toggleDropdown(DropdownType type) {
    setState(() {
      _activeDropdown = _activeDropdown == type ? DropdownType.none : type;
    });
  }

  void _hideDropdowns() {
    if (_activeDropdown != DropdownType.none) {
      setState(() {
        _activeDropdown = DropdownType.none;
      });
    }
  }

  List<int> getDaysInMonth(int month, int year) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return List.generate(lastDay, (index) => index + 1);
  }

  Future<void> _pickPetImage() async {
    _hideDropdowns();
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
                leading: const Icon(Icons.photo_library, color: Color(0xFF6E4B3A)),
                title: Text(
                  'Select photo',
                  style: GoogleFonts.dosis(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
                ),
                onTap: () => Navigator.pop(_, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
                title: Text(
                  'Take a photo',
                  style: GoogleFonts.dosis(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
                ),
                onTap: () => Navigator.pop(_, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Color(0xFF8B0000)),
                title: Text(
                  'Remove photo',
                  style: GoogleFonts.dosis(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF8B0000)),
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

      final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 80);

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
      final birthDateStr = '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}';

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

      if (_petImageBytes != null) {
        final fileName = '${user.id}/pet_${_nameController.text.trim().toLowerCase().replaceAll(' ', '_')}.png';
        await supabase.storage.from('profile_pictures').uploadBinary(
              fileName,
              _petImageBytes!,
              fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
            );

        final publicUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
        petData['profile_picture_url'] = publicUrl;
      }

      final insertedPet = await supabase.from('pets').insert(petData).select().single();

      if (mounted) {
        _showToast('Pet added successfully!');
        Navigator.pop(context, widget.isBookingFlow ? insertedPet['id'] : null);
      }
    } catch (e) {
      debugPrint('Error adding pet: $e');
      if (mounted) _showToast('Failed to add pet');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Widget customTextField({
    required TextEditingController controller,
    required Widget labelWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget,
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onTap: _hideDropdowns,
          style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontWeight: FontWeight.w400),
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

  Widget customDropdownTrigger<T>({
    required GlobalKey key,
    required String label,
    required T? value,
    required DropdownType dropdownType,
    String? placeholder,
    bool truncateValue = false,
  }) {
    final bool isExpanded = _activeDropdown == dropdownType;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: _labelStyle),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _toggleDropdown(dropdownType),
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
                    style: GoogleFonts.dosis(
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOverlayMenu() {
    if (_activeDropdown == DropdownType.none) return const SizedBox.shrink();

    GlobalKey? activeKey;
    List options = [];
    dynamic currentValue;
    Function(dynamic) onSelect;
    double maxHeight = 200;

    switch (_activeDropdown) {
      case DropdownType.petType:
        activeKey = _petTypeKey;
        options = petTypes;
        currentValue = _petType;
        onSelect = (val) {
          setState(() {
            _petType = val as String;
            _activeDropdown = DropdownType.none;
          });
        };
        break;
      case DropdownType.gender:
        activeKey = _genderKey;
        options = genders;
        currentValue = _gender;
        onSelect = (val) {
          setState(() {
            _gender = val as String;
            _activeDropdown = DropdownType.none;
          });
        };
        break;
      case DropdownType.month:
        activeKey = _monthKey;
        options = months;
        currentValue = _selectedMonth;
        maxHeight = 150;
        onSelect = (val) {
          setState(() {
            _selectedMonth = val as String;
            if (_selectedYear != null && _selectedDay != null) {
              final m = months.indexOf(_selectedMonth!) + 1;
              final maxDay = getDaysInMonth(m, _selectedYear!).length;
              if (_selectedDay! > maxDay) _selectedDay = maxDay;
            }
            _activeDropdown = DropdownType.none;
          });
        };
        break;
      case DropdownType.day:
        activeKey = _dayKey;
        options = (_selectedMonth != null && _selectedYear != null)
            ? getDaysInMonth(months.indexOf(_selectedMonth!) + 1, _selectedYear!)
            : List.generate(31, (index) => index + 1);
        currentValue = _selectedDay;
        maxHeight = 150;
        onSelect = (val) {
          setState(() {
            _selectedDay = val as int;
            _activeDropdown = DropdownType.none;
          });
        };
        break;
      case DropdownType.year:
        activeKey = _yearKey;
        options = years;
        currentValue = _selectedYear;
        maxHeight = 150;
        onSelect = (val) {
          setState(() {
            _selectedYear = val as int;
            if (_selectedMonth != null && _selectedDay != null) {
              final m = months.indexOf(_selectedMonth!) + 1;
              final maxDay = getDaysInMonth(m, val).length;
              if (_selectedDay! > maxDay) _selectedDay = maxDay;
            }
            _activeDropdown = DropdownType.none;
          });
        };
        break;
      case DropdownType.none:
        return const SizedBox.shrink();
    }

    final renderBox = activeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const SizedBox.shrink();

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    final bottomBarPadding = MediaQuery.of(context).padding.bottom + 74;

    final calculatedContentHeight = (options.length * 45.0).clamp(0.0, maxHeight);
    final spaceBelow = screenSize.height - position.dy - size.height - bottomBarPadding;
    final bool openUpward = spaceBelow < calculatedContentHeight;

    final topOffset = openUpward
        ? (position.dy - calculatedContentHeight - kToolbarHeight - MediaQuery.of(context).padding.top - 8)
        : (position.dy + size.height - kToolbarHeight - MediaQuery.of(context).padding.top - 12);

    return Positioned(
      top: topOffset,
      left: position.dx,
      width: size.width,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF6E4B3A), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (e) => GestureDetector(
                      onTap: () => onSelect(e),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        color: e == currentValue ? const Color(0xFF6E4B3A).withOpacity(0.2) : Colors.transparent,
                        child: Text(
                          e.toString(),
                          style: const TextStyle(color: Color(0xFF6E4B3A), fontWeight: FontWeight.w400),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget birthdateDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Birthdate', style: _labelStyle),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: customDropdownTrigger<String>(
                key: _monthKey,
                label: '',
                value: _selectedMonth,
                placeholder: 'Month',
                dropdownType: DropdownType.month,
                truncateValue: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: customDropdownTrigger<int>(
                key: _dayKey,
                label: '',
                value: _selectedDay,
                placeholder: 'Day',
                dropdownType: DropdownType.day,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: customDropdownTrigger<int>(
                key: _yearKey,
                label: '',
                value: _selectedYear,
                placeholder: 'Year',
                dropdownType: DropdownType.year,
              ),
            ),
          ],
        ),
      ],
    );
  }

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
                  ? Text.rich(
                      TextSpan(
                        text: 'Upload Pet Photo ',
                        style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontWeight: FontWeight.w400, fontSize: 16),
                        children: [
                          TextSpan(
                            text: '(Optional)',
                            style: GoogleFonts.dosis(color: Colors.grey[500], fontWeight: FontWeight.w400, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      'Photo Selected',
                      style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontWeight: FontWeight.w400, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
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
            style: GoogleFonts.dosis(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + MediaQuery.of(context).padding.bottom),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E4B3A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSaving ? null : _savePet,
              child: isSaving
                  ? const CircularProgressIndicator(color: Color(0xFFDDC7A9))
                  : Text(
                      'Add Pet',
                      style: GoogleFonts.dosis(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFDDC7A9)),
                    ),
            ),
          ),
        ),
        body: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollNotification) {
                if (_activeDropdown != DropdownType.none) {
                  _hideDropdowns();
                }
                return false;
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    customTextField(
                      controller: _nameController,
                      labelWidget: Text('Pet Name', style: _labelStyle),
                    ),
                    customDropdownTrigger(
                      key: _petTypeKey,
                      label: 'Pet Type',
                      value: _petType,
                      dropdownType: DropdownType.petType,
                    ),
                    customTextField(
                      controller: _breedController,
                      labelWidget: Text.rich(
                        TextSpan(
                          text: 'Breed ',
                          style: _labelStyle,
                          children: [
                            TextSpan(
                              text: '(Optional)',
                              style: GoogleFonts.dosis(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    birthdateDropdowns(),
                    customDropdownTrigger(
                      key: _genderKey,
                      label: 'Gender',
                      value: _gender,
                      dropdownType: DropdownType.gender,
                    ),
                    uploadPhotoField(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildOverlayMenu(),
          ],
        ),
      ),
    );
  }
}