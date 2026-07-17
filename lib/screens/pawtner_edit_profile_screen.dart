import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for input formatters
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PawtnerEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> pawtnerData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const PawtnerEditProfileScreen({
    super.key,
    required this.pawtnerData,
    required this.onProfileUpdated,
  });

  @override
  State<PawtnerEditProfileScreen> createState() =>
      _PawtnerEditProfileScreenState();
}

class _PawtnerEditProfileScreenState extends State<PawtnerEditProfileScreen> {
  final supabase = Supabase.instance.client;
  final dio = Dio();

  late Map<String, dynamic> pawtner;
  bool isLoading = true;

  String? _emailError;
  String? _contactNumberError;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController serviceTypeController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController availableAreasController =
      TextEditingController();

  String? businessPermitName;
  String? governmentIdName;

  bool dropdownOpenServiceType = false;
  bool dropdownOpenBusinessType = false;
  bool dropdownOpenAvailableAreas = false;

  final List<String> serviceOptions = ["Grooming", "Boarding", "Training"];
  final List<String> businessTypeOptions = ["Home", "Shop"];
  List<String> selectedServices = [];
  List<String> selectedBusinessTypes = [];
  List<String> selectedAreas = [];

  final List<String> metroManilaCities = [
    'Caloocan',
    'Las Piñas',
    'Makati',
    'Malabon',
    'Mandaluyong',
    'Manila',
    'Marikina',
    'Muntinlupa',
    'Navotas',
    'Parañaque',
    'Pasay',
    'Pasig',
    'Quezon City',
    'San Juan',
    'Taguig',
    'Valenzuela'
  ];

  @override
  void initState() {
    super.initState();
    pawtner = widget.pawtnerData;
    loadData();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    businessNameController.dispose();
    serviceTypeController.dispose();
    businessTypeController.dispose();
    locationController.dispose();
    availableAreasController.dispose();
    super.dispose();
  }

  void loadData() {
    fullNameController.text = pawtner['full_name']?.toString() ?? '';
    emailController.text = pawtner['email']?.toString() ?? '';
    contactNumberController.text = pawtner['contact_number']?.toString() ?? '';
    businessNameController.text = pawtner['business_name']?.toString() ?? '';
    locationController.text = pawtner['business_address']?.toString() ?? '';

    // Service Type
    final dbServices = pawtner['service_type']?.toString() ?? '';
    selectedServices =
        dbServices.split(", ").where((s) => s.isNotEmpty).toList();
    serviceTypeController.text = selectedServices.join(", ");

    // Business Type
    final dbBusinessType = pawtner['business_type']?.toString() ?? '';
    selectedBusinessTypes =
        dbBusinessType.split(", ").where((s) => s.isNotEmpty).toList();
    businessTypeController.text = selectedBusinessTypes.join(", ");

    // Available Areas
    final dbAreas = pawtner['available_areas']?.toString() ?? '';
    selectedAreas = dbAreas.split(", ").where((s) => s.isNotEmpty).toList();
    availableAreasController.text = selectedAreas.join(", ");

    businessPermitName =
        pawtner['business_permit_url']?.toString().split('/').last;
    governmentIdName = pawtner['govt_id_url']?.toString().split('/').last;

    setState(() => isLoading = false);
  }

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$').hasMatch(trimmed);
  }

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: Text(
          message,
          style: GoogleFonts.dosis(
            color: const Color(0xFF6E4B3A),
          ),
        ),
        backgroundColor: const Color(0xFFDDC7A9),
      ),
    );
  }

  Future<String?> _uploadBytesToStorage({
    required String bucket,
    required String remotePath,
    required Uint8List bytes,
  }) async {
    try {
      await supabase.storage.from(bucket).uploadBinary(remotePath, bytes);
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(remotePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Supabase upload error: $e');
      return null;
    }
  }

  Future<void> _chooseAndUploadFile(String type) async {
    final result = await showModalBottomSheet<FilePickerResult?>(
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
              leading: const Icon(Icons.folder, color: Color(0xFF6E4B3A)),
              title: Text('Select a file',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A))),
              onTap: () async {
                final picked = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                  withData: true,
                );
                if (mounted) Navigator.pop(context, picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
              title: Text('Take a photo',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A))),
              onTap: () async {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 80,
                );
                if (image == null) {
                  if (mounted) Navigator.pop(context, null);
                  return;
                }
                final bytes = await image.readAsBytes();
                final result = FilePickerResult([
                  PlatformFile(
                      name: image.name, bytes: bytes, size: bytes.length),
                ]);
                if (mounted) Navigator.pop(context, result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Color(0xFF8B0000)),
              title: Text('Cancel',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B0000))),
              onTap: () => Navigator.pop(context, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return;

    final picked = result.files.first;
    final bytes = picked.bytes;
    final name = picked.name;
    if (bytes == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final ext = name.split('.').last;
    final remoteFileName = type == "permit"
        ? '${user.id}/business_permit.$ext'
        : '${user.id}/govt_id.$ext';
    final bucketName = type == "permit" ? 'business_permits' : 'govt_ids';

    final publicUrl = await _uploadBytesToStorage(
      bucket: bucketName,
      remotePath: remoteFileName,
      bytes: bytes,
    );

    if (publicUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed.',
              style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A))),
          backgroundColor: const Color(0xFFDDC7A9),
        ));
      }
      return;
    }

    try {
      if (type == "permit") {
        await supabase
            .from('pawtners')
            .update({'business_permit_url': publicUrl}).eq('id', user.id);
        setState(() => businessPermitName = name);
      } else {
        await supabase
            .from('pawtners')
            .update({'govt_id_url': publicUrl}).eq('id', user.id);
        setState(() => governmentIdName = name);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload successful.',
              style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A))),
          backgroundColor: const Color(0xFFDDC7A9),
        ));
      }
    } catch (e) {
      debugPrint('DB update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save file info.',
              style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A))),
          backgroundColor: const Color(0xFFDDC7A9),
        ));
      }
    }
  }

  Future<void> _deletePermitName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('pawtners')
        .update({'business_permit_url': null}).eq('id', user.id);
    setState(() => businessPermitName = null);
  }

  Future<void> _deleteGovtIdName() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    await supabase
        .from('pawtners')
        .update({'govt_id_url': null}).eq('id', user.id);
    setState(() => governmentIdName = null);
  }

  Future<void> _pickLocation() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    const apiKey = 'AIzaSyBOKb6toq6ItcFdi94IekJNj5WX0p8tkt4';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your location',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                autofocus: true,
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  color: const Color(0xFF6E4B3A),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 123 Rizal St, Makati',
                  hintStyle: GoogleFonts.dosis(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                  suffixIcon: isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        )
                      : null,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
                  ),
                ),
                onChanged: (value) async {
                  if (value.trim().length < 3) {
                    setModalState(() => searchResults = []);
                    return;
                  }

                  setModalState(() => isSearching = true);

                  try {
                    final response = await dio.post(
                      'https://places.googleapis.com/v1/places:autocomplete',
                      options: Options(
                        headers: {
                          'Content-Type': 'application/json',
                          'X-Goog-Api-Key': apiKey,
                        },
                      ),
                      data: {
                        'input': value,
                        'locationBias': {
                          'circle': {
                            'center': {
                              'latitude': 12.8797,
                              'longitude': 121.7740,
                            },
                            'radius': 50000.0,
                          },
                        },
                        'includedRegionCodes': ['ph'],
                      },
                    );

                    if (!mounted) return;
                    final suggestions =
                        response.data['suggestions'] as List? ?? [];

                    setModalState(() {
                      searchResults = suggestions
                          .map((e) =>
                              e['placePrediction'] as Map<String, dynamic>)
                          .toList();
                      isSearching = false;
                    });
                  } catch (e) {
                    if (!mounted) return;
                    debugPrint('Autocomplete error: $e');
                    setModalState(() => isSearching = false);
                  }
                },
              ),
              const SizedBox(height: 8),
              if (searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      final mainText = result['structuredFormat']?['mainText']
                              ?['text'] ??
                          '';
                      final secondaryText = result['structuredFormat']
                              ?['secondaryText']?['text'] ??
                          '';
                      final placeId = result['placeId'] ?? '';

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on,
                            color: Color(0xFF6E4B3A), size: 20),
                        title: Text(
                          mainText,
                          style: GoogleFonts.dosis(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E4B3A),
                          ),
                        ),
                        subtitle: Text(
                          secondaryText,
                          style: GoogleFonts.dosis(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          try {
                            final detailResponse = await dio.get(
                              'https://places.googleapis.com/v1/places/$placeId',
                              options: Options(
                                headers: {
                                  'X-Goog-Api-Key': apiKey,
                                  'X-Goog-FieldMask':
                                      'location,displayName,formattedAddress',
                                },
                              ),
                            );

                            final formattedAddress =
                                detailResponse.data['formattedAddress'] ??
                                    mainText;
                            final addressParts = formattedAddress.split(',');
                            final shortAddress = addressParts.length > 2
                                ? addressParts.take(2).join(',').trim()
                                : formattedAddress;

                            setState(() {
                              locationController.text = shortAddress;
                            });

                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Place detail error: $e');
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.dosis(
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6E4B3A),
        ),
      ),
    );
  }

  Widget infoLine(
    String label,
    TextEditingController controller, {
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$label:",
              style: GoogleFonts.dosis(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6E4B3A),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: label == "Service Type" ||
                  label == "Business Type" ||
                  label == "Available Areas",
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              onTap: () {
                setState(() {
                  if (label == "Service Type") {
                    dropdownOpenServiceType = !dropdownOpenServiceType;
                  } else if (label == "Business Type") {
                    dropdownOpenBusinessType = !dropdownOpenBusinessType;
                  } else if (label == "Available Areas") {
                    dropdownOpenAvailableAreas = !dropdownOpenAvailableAreas;
                  }
                });
              },
              style: GoogleFonts.dosis(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6E4B3A),
                ),
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                errorText: errorText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget uploadBox({
    required String? fileName,
    required VoidCallback onUpload,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF6E4B3A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fileName ?? "No file uploaded",
              style: GoogleFonts.dosis(
                textStyle: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6E4B3A),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            width: 100,
            child: TextButton(
              onPressed: onUpload,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFDDC7A9),
              ),
              child: const Text(
                "Upload",
                style: TextStyle(color: Color(0xFF6E4B3A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E4B3A)),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.dosis(
                        color: const Color(0xFFDDC7A9),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDDC7A9)),
                  onPressed: () async {
                    setState(() {
                      _emailError = null;
                      _contactNumberError = null;
                    });
                    final user = supabase.auth.currentUser;
                    if (user == null) return;

                    bool hasError = false;

                    if (!_isValidContactNumber(contactNumberController.text)) {
                      _contactNumberError =
                          'Please enter a valid contact number';
                      hasError = true;
                    }

                    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                    if (!emailRegex.hasMatch(emailController.text.trim())) {
                      _emailError = 'Please enter a valid email';
                      hasError = true;
                    }

                    if (hasError) {
                      setState(() {});
                      return;
                    }

                    try {
                      await supabase.from('pawtners').update({
                        'full_name': fullNameController.text,
                        'email': emailController.text,
                        'contact_number': contactNumberController.text,
                        'business_name': businessNameController.text,
                        'service_type': serviceTypeController.text,
                        'business_type': businessTypeController.text,
                        'business_address': locationController.text,
                        'available_areas': availableAreasController.text,
                      }).eq('id', user.id);
                    } catch (e) {
                      debugPrint('Profile update error: $e');
                      if (mounted) {
                        _showToast('Could not save changes. Please try again.');
                      }
                      return;
                    }

                    final updatedData = {
                      ...pawtner,
                      'full_name': fullNameController.text,
                      'email': emailController.text,
                      'contact_number': contactNumberController.text,
                      'business_name': businessNameController.text,
                      'service_type': serviceTypeController.text,
                      'business_type': businessTypeController.text,
                      'business_address': locationController.text,
                      'available_areas': availableAreasController.text,
                    };

                    widget.onProfileUpdated(updatedData);

                    if (mounted) {
                      _showToast('Profile updated successfully.',
                          isError: false);
                    }

                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save Changes',
                    style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                        fontWeight: FontWeight.w600,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Personal Details"),
            const SizedBox(height: 8),
            infoLine("Full Name", fullNameController),
            infoLine(
              "Email",
              emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
            ),
            infoLine(
              "Contact Number",
              contactNumberController,
              errorText: _contactNumberError,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // Allow digits and a leading "+" (for +63 format).
                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                LengthLimitingTextInputFormatter(13),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade400),
            const SizedBox(height: 12),
            sectionTitle("Business Details"),
            const SizedBox(height: 8),
            infoLine("Business Name", businessNameController),
            infoLine("Business Type", businessTypeController),
            if (dropdownOpenBusinessType)
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: businessTypeOptions.map((s) {
                    final selected = selectedBusinessTypes.contains(s);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!selected) {
                            selectedBusinessTypes.add(s);
                          } else {
                            selectedBusinessTypes.remove(s);
                          }
                          businessTypeController.text =
                              selectedBusinessTypes.join(", ");
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: selected
                            ? const Color(0xFF6E4B3A).withOpacity(0.2)
                            : Colors.transparent,
                        child: Text(
                          s,
                          style: GoogleFonts.dosis(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            infoLine("Service Type", serviceTypeController),
            if (dropdownOpenServiceType)
              Padding(
                padding: const EdgeInsets.only(left: 140, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: serviceOptions.map((s) {
                    final selected = selectedServices.contains(s);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!selected) {
                            selectedServices.add(s);
                          } else {
                            selectedServices.remove(s);
                          }
                          serviceTypeController.text =
                              selectedServices.join(", ");
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        color: selected
                            ? const Color(0xFF6E4B3A).withOpacity(0.2)
                            : Colors.transparent,
                        child: Text(
                          s,
                          style: GoogleFonts.dosis(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            GestureDetector(
              onTap: () async {
                await _pickLocation();
              },
              child: AbsorbPointer(
                child: infoLine("Location", locationController),
              ),
            ),
            if (selectedBusinessTypes.contains("Home"))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoLine("Available Areas", availableAreasController),
                  if (dropdownOpenAvailableAreas)
                    Padding(
                      padding: const EdgeInsets.only(left: 140, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: metroManilaCities.map((area) {
                          final selected = selectedAreas.contains(area);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (!selected) {
                                  selectedAreas.add(area);
                                } else {
                                  selectedAreas.remove(area);
                                }
                                availableAreasController.text =
                                    selectedAreas.join(", ");
                              });
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              color: selected
                                  ? const Color(0xFF6E4B3A).withOpacity(0.2)
                                  : Colors.transparent,
                              child: Text(
                                area,
                                style: GoogleFonts.dosis(
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E4B3A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade400),
            const SizedBox(height: 12),
            sectionTitle("Uploads"),
            const SizedBox(height: 8),
            Text("Business Permit",
                style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A))),
            const SizedBox(height: 6),
            uploadBox(
              fileName: businessPermitName,
              onUpload: () => _chooseAndUploadFile("permit"),
              onDelete: _deletePermitName,
            ),
            const SizedBox(height: 6),
            Text("Government ID",
                style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A))),
            const SizedBox(height: 6),
            uploadBox(
              fileName: governmentIdName,
              onUpload: () => _chooseAndUploadFile("govt"),
              onDelete: _deleteGovtIdName,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
