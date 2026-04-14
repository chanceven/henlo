import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

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

  late Map<String, dynamic> pawtner;
  bool isLoading = true;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController =
      TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController serviceTypeController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController availableAreasController = TextEditingController();

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
  'Caloocan', 'Las Piñas', 'Makati', 'Malabon', 'Mandaluyong', 'Manila',
  'Marikina', 'Muntinlupa', 'Navotas', 'Parañaque', 'Pasay',
  'Pasig', 'Quezon City', 'San Juan', 'Taguig', 'Valenzuela'
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
    governmentIdName =
        pawtner['govt_id_url']?.toString().split('/').last;

    setState(() => isLoading = false);
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
    final result = await showDialog<FilePickerResult?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload File"),
          content: const Text("Choose an option:"),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(
                  context,
                  await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                    withData: true,
                  ),
                );
              },
              child: const Text("Choose File"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final picked = result.files.first;
    final bytes = picked.bytes;
    final name = picked.name;
    if (bytes == null) return;

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final remoteFileName =
        "${user.id}_${DateTime.now().millisecondsSinceEpoch}_$name";
    final bucketName = type == "permit" ? 'business_permits' : 'govt_ids';

    final publicUrl = await _uploadBytesToStorage(
      bucket: bucketName,
      remotePath: remoteFileName,
      bytes: bytes,
    );

    if (publicUrl == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload failed.')));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Upload successful.')));
      }
    } catch (e) {
      debugPrint('DB update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save file info.')));
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

  Widget infoLine(String label, TextEditingController controller) {
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 6),
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
          if (fileName != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, color: Color(0xFF8B0000)),
            ),
          if (fileName != null) const SizedBox(width: 10),
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
            infoLine("Email", emailController),
            infoLine("Contact Number", contactNumberController),
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
            infoLine("Location", locationController),
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
                                availableAreasController.text = selectedAreas.join(", ");
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
                    fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A))),
            const SizedBox(height: 6),
            uploadBox(
              fileName: businessPermitName,
              onUpload: () => _chooseAndUploadFile("permit"),
              onDelete: _deletePermitName,
            ),
            const SizedBox(height: 6),
            Text("Government ID",
                style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A))),
            const SizedBox(height: 6),
            uploadBox(
              fileName: governmentIdName,
              onUpload: () => _chooseAndUploadFile("govt"),
              onDelete: _deleteGovtIdName,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6E4B3A),
                      foregroundColor: const Color(0xFFDDC7A9),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDDC7A9),
                      foregroundColor: const Color(0xFF6E4B3A),
                    ),
                    onPressed: () async {
                      final user = supabase.auth.currentUser;
                      if (user == null) return;

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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile updated successfully')),
                        );
                      }

                      Navigator.pop(context);
                    },
                    child: const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}