import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pawtner_review_details_screen.dart';

class PawtnerBusinessDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String contact;

  const PawtnerBusinessDetailsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.contact,
  });

  @override
  State<PawtnerBusinessDetailsScreen> createState() =>
      _PawtnerBusinessDetailsScreenState();
}

class _PawtnerBusinessDetailsScreenState
    extends State<PawtnerBusinessDetailsScreen> {
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  List<String> selectedServices = [];
  bool dropdownOpen = false;

  PlatformFile? profilePhoto;
  PlatformFile? businessPermit;
  PlatformFile? govtID;

  final List<String> serviceOptions = ["Grooming", "Boarding", "Training"];
  bool isLoading = false;

  @override
  void dispose() {
    businessNameController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      final file = result.files.first;
      const maxSize = 50 * 1024 * 1024; // 50 MB
      if (file.size > maxSize) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("File too large. Max size is 50MB."),
          ),
        );
        return;
      }

      setState(() {
        switch (type) {
          case 'profile':
            profilePhoto = file;
            break;
          case 'permit':
            businessPermit = file;
            break;
          case 'govt':
            govtID = file;
            break;
        }
      });
    }
  }

  // Error-free Supabase upload
  Future<String?> _uploadFile(String bucket, PlatformFile file) async {
    if (file.path == null) return null;
    final bytes = await File(file.path!).readAsBytes();
    final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.name}";

    try {
      await Supabase.instance.client.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
          );
      final publicUrl =
          Supabase.instance.client.storage.from(bucket).getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Supabase storage upload error: $e");
      return null;
    }
  }

  Future<void> _continue() async {
    if (businessNameController.text.isEmpty || selectedServices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    setState(() => isLoading = true);

    // Upload files and get URLs
    String? profileUrl;
    String? permitUrl;
    String? govtIdUrl;

    if (profilePhoto != null) {
      profileUrl = await _uploadFile('profile_pictures', profilePhoto!);
    }
    if (businessPermit != null) {
      permitUrl = await _uploadFile('business_permits', businessPermit!);
    }
    if (govtID != null) {
      govtIdUrl = await _uploadFile('govt_ids', govtID!);
    }

    if (!mounted) return;
    setState(() => isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PawtnerReviewDetailsScreen(
          name: widget.name,
          email: widget.email,
          contact: widget.contact,
          businessName: businessNameController.text,
          typeOfService: selectedServices.join(", "),
          location: locationController.text,
          uploadedProfilePhotoUrl: profileUrl,
          uploadedBusinessPermitUrl: permitUrl,
          uploadedGovernmentIDUrl: govtIdUrl,
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6E4B3A)),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget buildUploadButton(String label, PlatformFile? file, String type) {
    return OutlinedButton.icon(
      onPressed: () => _pickFile(type),
      icon: const Icon(Icons.upload_file, color: Color(0xFF6E4B3A)),
      label: Text(
        file != null ? "$label Selected" : label,
        style: TextStyle(
          color: Colors.grey[400],
          fontWeight: FontWeight.w400,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFF6E4B3A)),
        backgroundColor: Colors.transparent,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Business Details",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6E4B3A),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Name
            TextField(
              controller: businessNameController,
              decoration: buildInputDecoration("Business Name"),
              style: const TextStyle(
                color: Color(0xFF6E4B3A),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // Type of Service
            GestureDetector(
              onTap: () => setState(() => dropdownOpen = !dropdownOpen),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF6E4B3A)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedServices.isEmpty
                            ? "Type of Service"
                            : selectedServices.join(", "),
                        style: TextStyle(
                          color: selectedServices.isEmpty
                              ? Colors.grey[400]
                              : const Color(0xFF6E4B3A),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      dropdownOpen
                          ? Icons.arrow_drop_up
                          : Icons.arrow_drop_down,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ],
                ),
              ),
            ),

            if (dropdownOpen)
              Column(
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
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        s,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? const Color(0xFF6E4B3A)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 16),
            // Business Location
            TextField(
              controller: locationController,
              readOnly: true,
              decoration:
                  buildInputDecoration("Business Location (Select on map)"),
              onTap: () {
                // TODO: integrate map picker
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Container(
                color: Colors.grey[300],
                child: const Center(child: Text("Map will appear here")),
              ),
            ),
            const SizedBox(height: 16),

            // Uploads
            buildUploadButton("Upload Business Permit", businessPermit, 'permit'),
            const SizedBox(height: 8),
            buildUploadButton("Upload Government ID", govtID, 'govt'),
            const SizedBox(height: 8),
            buildUploadButton("Upload Profile Picture", profilePhoto, 'profile'),
            const SizedBox(height: 24),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _continue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A),
                  foregroundColor: const Color(0xFFDDC7A9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Color(0xFFDDC7A9),
                      )
                    : const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
