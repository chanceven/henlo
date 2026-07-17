import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pawtner_review_details_screen.dart';

class PawtnerBusinessDetailsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String contact;
  final String password;

  const PawtnerBusinessDetailsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.contact,
    required this.password,
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
  List<String> selectedBusinessTypes = [];
  List<String> selectedAreas = [];

  bool dropdownOpenServiceType = false;
  bool dropdownOpenBusinessType = false;
  bool dropdownOpenAvailableAreas = false;

  final List<String> serviceOptions = ["Grooming", "Boarding", "Training"];
  final List<String> businessTypeOptions = ["Shop", "Home"];

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
  final dio = Dio();
  bool isLoading = false;

  @override
  void dispose() {
    businessNameController.dispose();
    locationController.dispose();
    super.dispose();
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
                'Enter your business location',
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

  Future<void> _continue() async {
    if (businessNameController.text.isEmpty || selectedServices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PawtnerReviewDetailsScreen(
          name: widget.name,
          email: widget.email,
          contact: widget.contact,
          password: widget.password,
          businessName: businessNameController.text,
          typeOfService: selectedServices.join(", "),
          businessType: selectedBusinessTypes.join(", "),
          availableAreas: selectedAreas.join(", "),
          location: locationController.text,
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dosis(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.grey[400],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text(
          "Business Details",
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
      ),
      body: GestureDetector(
        onTap: () => setState(() {
          dropdownOpenServiceType = false;
          dropdownOpenBusinessType = false;
          dropdownOpenAvailableAreas = false;
        }),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Business Name
                    TextField(
                      controller: businessNameController,
                      onTap: () {
                        setState(() {
                          dropdownOpenServiceType = false;
                          dropdownOpenBusinessType = false;
                          dropdownOpenAvailableAreas = false;
                        });
                      },
                      decoration: buildInputDecoration("Business Name"),
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Service Type dropdown
                    GestureDetector(
                      onTap: () => setState(() {
                        dropdownOpenServiceType = !dropdownOpenServiceType;
                        dropdownOpenBusinessType = false;
                        dropdownOpenAvailableAreas = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFF6E4B3A))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedServices.isEmpty
                                    ? "Service Type"
                                    : selectedServices.join(", "),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: selectedServices.isEmpty
                                      ? Colors.grey[400]
                                      : const Color(0xFF6E4B3A),
                                ),
                              ),
                            ),
                            Icon(
                              dropdownOpenServiceType
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (dropdownOpenServiceType)
                      Column(
                        children: serviceOptions.map((s) {
                          final selected = selectedServices.contains(s);
                          return GestureDetector(
                            onTap: () => setState(() {
                              selected
                                  ? selectedServices.remove(s)
                                  : selectedServices.add(s);

                              dropdownOpenServiceType = false;
                            }),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: selected
                                  ? const Color(0xFF6E4B3A).withOpacity(0.2)
                                  : Colors.transparent,
                              child: Center(
                                child: Text(s,
                                    style: GoogleFonts.dosis(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6E4B3A))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Business Type dropdown
                    GestureDetector(
                      onTap: () => setState(() {
                        dropdownOpenBusinessType = !dropdownOpenBusinessType;
                        dropdownOpenServiceType = false;
                        dropdownOpenAvailableAreas = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: Color(0xFF6E4B3A))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                selectedBusinessTypes.isEmpty
                                    ? "Business Type"
                                    : selectedBusinessTypes.join(", "),
                                style: GoogleFonts.dosis(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: selectedBusinessTypes.isEmpty
                                      ? Colors.grey[400]
                                      : const Color(0xFF6E4B3A),
                                ),
                              ),
                            ),
                            Icon(
                              dropdownOpenBusinessType
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (dropdownOpenBusinessType)
                      Column(
                        children: businessTypeOptions.map((s) {
                          final selected = selectedBusinessTypes.contains(s);
                          return GestureDetector(
                            onTap: () => setState(() {
                              selected
                                  ? selectedBusinessTypes.remove(s)
                                  : selectedBusinessTypes.add(s);

                              dropdownOpenBusinessType = false;
                            }),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              color: selected
                                  ? const Color(0xFF6E4B3A).withOpacity(0.2)
                                  : Colors.transparent,
                              child: Center(
                                child: Text(s,
                                    style: GoogleFonts.dosis(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6E4B3A))),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 16),

                    // Available Areas (only if Home is selected)
                    if (selectedBusinessTypes.contains("Home")) ...[
                      GestureDetector(
                        onTap: () => setState(() {
                          dropdownOpenAvailableAreas =
                              !dropdownOpenAvailableAreas;
                          dropdownOpenServiceType = false;
                          dropdownOpenBusinessType = false;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Color(0xFF6E4B3A))),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedAreas.isEmpty
                                      ? "Available Areas"
                                      : selectedAreas.join(", "),
                                  style: GoogleFonts.dosis(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: selectedAreas.isEmpty
                                        ? Colors.grey[400]
                                        : const Color(0xFF6E4B3A),
                                  ),
                                ),
                              ),
                              Icon(
                                dropdownOpenAvailableAreas
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (dropdownOpenAvailableAreas)
                        Column(
                          children: metroManilaCities.map((area) {
                            final selected = selectedAreas.contains(area);
                            return GestureDetector(
                              onTap: () => setState(() {
                                selected
                                    ? selectedAreas.remove(area)
                                    : selectedAreas.add(area);

                                dropdownOpenAvailableAreas = false;
                              }),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                color: selected
                                    ? const Color(0xFF6E4B3A).withOpacity(0.2)
                                    : Colors.transparent,
                                child: Center(
                                  child: Text(area,
                                      style: GoogleFonts.dosis(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6E4B3A))),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: locationController,
                      readOnly: true,
                      decoration: buildInputDecoration("Business Location"),
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                      onTap: () {
                        setState(() {
                          dropdownOpenServiceType = false;
                          dropdownOpenBusinessType = false;
                          dropdownOpenAvailableAreas = false;
                        });

                        _pickLocation();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Continue button pinned to bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E4B3A),
                    foregroundColor: const Color(0xFFDDC7A9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Color(0xFFDDC7A9))
                      : Text(
                          "Continue",
                          style: GoogleFonts.dosis(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDDC7A9)),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
