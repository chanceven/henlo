import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'terms_and_conditions_screen.dart';
import 'privacy_policy_screen.dart';
import 'signin_screen.dart';
import 'otp_screen.dart';

class PawtnerSignUpScreen extends StatefulWidget {
  const PawtnerSignUpScreen({super.key});

  @override
  State<PawtnerSignUpScreen> createState() => _PawtnerSignUpScreenState();
}

class _PawtnerSignUpScreenState extends State<PawtnerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final Dio dio = Dio();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  List<String> selectedServices = [];
  List<String> selectedBusinessTypes = [];
  List<String> selectedAreas = [];
  bool dropdownOpenServiceType = false;
  bool dropdownOpenBusinessType = false;
  bool dropdownOpenAvailableAreas = false;
  final LayerLink _serviceTypeLink = LayerLink();
  final LayerLink _businessTypeLink = LayerLink();
  final LayerLink _areasLink = LayerLink();
  OverlayEntry? _activeDropdownOverlay;
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

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  int _currentStep = 1;
  bool isLoading = false;
  bool agreeTerms = false;

  bool _isValidContactNumber(String value) {
    final trimmed = value.trim();
    return RegExp(
      r'^(09[0-9]{9}|(\+63|63)9[0-9]{9})$',
    ).hasMatch(trimmed);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    businessNameController.dispose();
    locationController.dispose();
    _activeDropdownOverlay?.remove();
    super.dispose();
  }

  void _closeDropdownOverlay() {
    _activeDropdownOverlay?.remove();
    _activeDropdownOverlay = null;
    setState(() {
      dropdownOpenServiceType = false;
      dropdownOpenBusinessType = false;
      dropdownOpenAvailableAreas = false;
    });
  }

  void _openDropdownOverlay({
    required LayerLink link,
    required List<String> options,
    required List<String> selected,
    required void Function(String option) onToggle,
    required VoidCallback markOpen,
  }) {
    _closeDropdownOverlay();
    markOpen();

    _activeDropdownOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 48,
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 62),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6E4B3A)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((s) {
                    final isSelected = selected.contains(s);
                    return InkWell(
                      onTap: () {
                        onToggle(s);
                        _activeDropdownOverlay?.markNeedsBuild();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        color: isSelected
                            ? const Color(0xFF6E4B3A).withValues(alpha: 0.15)
                            : Colors.transparent,
                        child: Center(
                          child: Text(
                            s,
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_activeDropdownOverlay!);
  }

  InputDecoration buildInputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      prefixIcon:
          icon == null ? null : Icon(icon, color: const Color(0xFF6E4B3A)),
      hintText: hint,
      hintStyle: GoogleFonts.dosis(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: Colors.grey[400],
      ),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: const Color(0xFF6E4B3A).withValues(alpha: 0.3), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim().toLowerCase();

    try {
      final exists = await supabase
          .rpc('check_email_exists', params: {'check_email': email});

      if (!mounted) return;

      if (exists == true) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "This email is already registered. Please sign in instead.",
              style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
            ),
            backgroundColor: const Color(0xFF6E4B3A),
          ),
        );

        return;
      }

      setState(() => _isLoading = false);

      _goToBusinessStep();
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong. Try again."),
          backgroundColor: Color(0xFF6E4B3A),
        ),
      );
    }
  }

  bool isServiceSelected(String service) {
    return selectedServices.contains(service);
  }

  bool isBusinessTypeSelected(String type) {
    return selectedBusinessTypes.contains(type);
  }

  bool isAreaSelected(String area) {
    return selectedAreas.contains(area);
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
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom +
                24,
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

                            if (context.mounted) Navigator.pop(context);
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

  void _goToBusinessStep() {
    setState(() {
      _currentStep = 2;
    });
  }

  void _goToReviewStep() {
    setState(() {
      _currentStep = 3;
    });
  }

  void _goToAccountStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(45, 32, 45, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepWithLabel(1, "Account"),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(top: 14),
              color: _currentStep >= 2
                  ? const Color(0xFF6E4B3A)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          _buildStepWithLabel(2, "Business"),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(top: 14),
              color: _currentStep >= 3
                  ? const Color(0xFF6E4B3A)
                  : const Color(0xFFE0E0E0),
            ),
          ),
          _buildStepWithLabel(3, "Review"),
        ],
      ),
    );
  }

  Widget _buildStepWithLabel(int step, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStepCircle(step),
        const SizedBox(height: 4),
        _buildStepLabel(label),
      ],
    );
  }

  Widget _buildStepCircle(int step) {
    final active = _currentStep >= step;

    return CircleAvatar(
      radius: 18,
      backgroundColor:
          active ? const Color(0xFF6E4B3A) : const Color(0xFFE0E0E0),
      child: Text(
        "$step",
        style: GoogleFonts.dosis(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: active ? const Color(0xFFDDC7A9) : const Color(0xFF888888),
        ),
      ),
    );
  }

  Widget _buildStepLabel(String label) {
    return SizedBox(
      width: 50,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: GoogleFonts.dosis(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF6E4B3A),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildAccountStep();
      case 2:
        return _buildBusinessStep();
      case 3:
        return _buildReviewStep();
      default:
        return _buildAccountStep();
    }
  }

  Widget _buildAccountStep() {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 60),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: buildInputDecoration(
                                  'Full Name', Icons.person),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }

                                final emailRegex =
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email';
                                }

                                return null;
                              },
                              decoration: buildInputDecoration(
                                'Email',
                                Icons.email,
                              ),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contactCtrl,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d+]'),
                                ),
                                LengthLimitingTextInputFormatter(13),
                              ],
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your contact number';
                                }

                                if (!_isValidContactNumber(value.trim())) {
                                  return 'Please enter a valid contact number';
                                }

                                return null;
                              },
                              decoration: buildInputDecoration(
                                'Contact Number',
                                Icons.phone,
                              ),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: !_showPassword,
                              maxLength: 32,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your password';
                                }

                                if (value.trim().length < 8) {
                                  return 'Password must be at least 8 characters';
                                }

                                if (value.trim().length > 32) {
                                  return 'Password must not exceed 32 characters';
                                }

                                if (!value.trim().contains(RegExp(r'[0-9]'))) {
                                  return 'Password must contain at least one number';
                                }

                                if (!value
                                    .trim()
                                    .contains(RegExp(r'[a-zA-Z]'))) {
                                  return 'Password must contain at least one letter';
                                }

                                return null;
                              },
                              decoration: buildInputDecoration(
                                'Password',
                                Icons.lock,
                              ).copyWith(
                                counterText: '',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF6E4B3A),
                                  ),
                                  onPressed: () => setState(
                                      () => _showPassword = !_showPassword),
                                ),
                              ),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: !_showConfirm,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please confirm your password';
                                }

                                if (value != _passwordCtrl.text) {
                                  return 'Passwords do not match';
                                }

                                return null;
                              },
                              decoration: buildInputDecoration(
                                'Confirm Password',
                                Icons.lock,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirm
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF6E4B3A),
                                  ),
                                  onPressed: () => setState(
                                      () => _showConfirm = !_showConfirm),
                                ),
                              ),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessStep() {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8F8F8),
      body: GestureDetector(
        onTap: () {
          _closeDropdownOverlay();
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
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
                      decoration: buildInputDecoration(
                        "Business Name",
                        null,
                      ),
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 16),

// Service Type dropdown
                    CompositedTransformTarget(
                      link: _serviceTypeLink,
                      child: GestureDetector(
                        onTap: () {
                          if (dropdownOpenServiceType) {
                            _closeDropdownOverlay();
                          } else {
                            _openDropdownOverlay(
                              link: _serviceTypeLink,
                              options: serviceOptions,
                              selected: selectedServices,
                              onToggle: (s) => setState(() {
                                selectedServices.contains(s)
                                    ? selectedServices.remove(s)
                                    : selectedServices.add(s);
                              }),
                              markOpen: () => setState(
                                  () => dropdownOpenServiceType = true),
                            );
                          }
                        },
                        child: InputDecorator(
                          isEmpty: selectedServices.isEmpty,
                          decoration: buildInputDecoration(
                            "Service Type",
                            null,
                          ).copyWith(
                            suffixIcon: Icon(
                              dropdownOpenServiceType
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                          child: Text(
                            selectedServices.isEmpty
                                ? ""
                                : selectedServices.join(", "),
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
// Business Type dropdown
                    CompositedTransformTarget(
                      link: _businessTypeLink,
                      child: GestureDetector(
                        onTap: () {
                          if (dropdownOpenBusinessType) {
                            _closeDropdownOverlay();
                          } else {
                            _openDropdownOverlay(
                              link: _businessTypeLink,
                              options: businessTypeOptions,
                              selected: selectedBusinessTypes,
                              onToggle: (s) => setState(() {
                                selectedBusinessTypes.contains(s)
                                    ? selectedBusinessTypes.remove(s)
                                    : selectedBusinessTypes.add(s);
                              }),
                              markOpen: () => setState(
                                  () => dropdownOpenBusinessType = true),
                            );
                          }
                        },
                        child: InputDecorator(
                          isEmpty: selectedBusinessTypes.isEmpty,
                          decoration: buildInputDecoration(
                            "Business Type",
                            null,
                          ).copyWith(
                            suffixIcon: Icon(
                              dropdownOpenBusinessType
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                          child: Text(
                            selectedBusinessTypes.isEmpty
                                ? ""
                                : selectedBusinessTypes.join(", "),
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Available Areas (only if Home is selected)
                    if (selectedBusinessTypes.contains("Home")) ...[
                      CompositedTransformTarget(
                        link: _areasLink,
                        child: GestureDetector(
                          onTap: () {
                            if (dropdownOpenAvailableAreas) {
                              _closeDropdownOverlay();
                            } else {
                              _openDropdownOverlay(
                                link: _areasLink,
                                options: metroManilaCities,
                                selected: selectedAreas,
                                onToggle: (a) => setState(() {
                                  selectedAreas.contains(a)
                                      ? selectedAreas.remove(a)
                                      : selectedAreas.add(a);
                                }),
                                markOpen: () => setState(
                                    () => dropdownOpenAvailableAreas = true),
                              );
                            }
                          },
                          child: InputDecorator(
                            isEmpty: selectedAreas.isEmpty,
                            decoration: buildInputDecoration(
                              "Available Areas",
                              null,
                            ).copyWith(
                              suffixIcon: Icon(
                                dropdownOpenAvailableAreas
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_drop_down,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            child: Text(
                              selectedAreas.isEmpty
                                  ? ""
                                  : selectedAreas.join(", "),
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextField(
                      controller: locationController,
                      readOnly: true,
                      decoration: buildInputDecoration(
                        "Business Location",
                        null,
                      ),
                      style: GoogleFonts.dosis(
                        fontSize: 16,
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _goToReviewStep,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.dosis(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "—" : value,
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Please agree to the Terms & Conditions and Privacy Policy"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    late final AuthResponse res;
    try {
      res = await Supabase.instance.client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please wait a moment before trying again.",
            style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
      return;
    }

    final user = res.user;

    if (!mounted) return;

    if (user == null) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Oops! Something went wrong. Please try again."),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            email: _emailCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            contact: _contactCtrl.text.trim(),
            businessName: businessNameController.text.trim(),
            location: locationController.text.trim(),
            typeOfService: selectedServices.join(", "),
            businessType: selectedBusinessTypes.join(", "),
            availableAreas: selectedAreas.join(", "),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildReviewStep() {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        border: Border.all(
                            color: const Color(0xFF6E4B3A), width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Account Details",
                            style: GoogleFonts.dosis(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRow("Full Name", _nameCtrl.text),
                          _buildRow("Email", _emailCtrl.text),
                          _buildRow("Contact Number", _contactCtrl.text),
                          const Divider(
                              color: Color(0xFF6E4B3A),
                              thickness: 1,
                              height: 24),
                          Text(
                            "Business Details",
                            style: GoogleFonts.dosis(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRow(
                              "Business Name", businessNameController.text),
                          _buildRow(
                              "Service Type", selectedServices.join(", ")),
                          _buildRow("Business Type",
                              selectedBusinessTypes.join(", ")),
                          if (selectedBusinessTypes.contains("Home"))
                            _buildRow(
                                "Available Areas", selectedAreas.join(", ")),
                          _buildRow(
                              "Business Location", locationController.text),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.translate(
                          offset: const Offset(-10, -4),
                          child: Checkbox(
                            value: agreeTerms,
                            onChanged: (val) =>
                                setState(() => agreeTerms = val ?? false),
                            activeColor: const Color(0xFF6E4B3A),
                            checkColor: const Color(0xFFDDC7A9),
                            side: const BorderSide(
                              color: Color(0xFF6E4B3A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Transform.translate(
                            offset: const Offset(-8, 0),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                children: [
                                  Text(
                                    'By creating an account, you agree to our ',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const TermsAndConditionsScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Terms & Conditions',
                                      style: GoogleFonts.dosis(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6E4B3A),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' and ',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PrivacyPolicyScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Privacy Policy.',
                                      style: GoogleFonts.dosis(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6E4B3A),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: agreeTerms && !isLoading ? _createAccount : null,
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
                            "Create Account",
                            style: GoogleFonts.dosis(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFDDC7A9),
                            ),
                          ),
                  ),
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
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (_currentStep == 3) {
          _goToBusinessStep();
        } else if (_currentStep == 2) {
          _goToAccountStep();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F8F8),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Color(0xFF6E4B3A),
              ),
              onPressed: () {
                if (_currentStep == 3) {
                  _goToBusinessStep();
                } else if (_currentStep == 2) {
                  _goToAccountStep();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            title: Text(
              'Sign Up',
              style: GoogleFonts.dosis(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              _buildStepIndicator(),
              Expanded(
                child: _buildCurrentStep(),
              ),
            ],
          ),
          bottomNavigationBar: _currentStep == 1
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6E4B3A),
                              foregroundColor: const Color(0xFFDDC7A9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFFDDC7A9),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: GoogleFonts.dosis(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.dosis(
                                fontSize: 18,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignInScreen(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "Sign In",
                                  style: GoogleFonts.dosis(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6E4B3A),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
