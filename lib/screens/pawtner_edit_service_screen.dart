import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // for input formatters
import 'package:supabase_flutter/supabase_flutter.dart';

class PawtnerEditServiceScreen extends StatefulWidget {
  final String serviceId;

  const PawtnerEditServiceScreen({
    super.key,
    required this.serviceId,
  });

  @override
  State<PawtnerEditServiceScreen> createState() =>
      _PawtnerEditServiceScreenState();
}

class _PawtnerEditServiceScreenState extends State<PawtnerEditServiceScreen> {
  final supabase = Supabase.instance.client;

  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _priceController = TextEditingController();

  String? serviceType;
  List<String> serviceSubType = [];

  Map<String, Map<String, dynamic>> availability = {
    'Mon': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Tue': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Wed': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Thu': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Fri': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Sat': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
    'Sun': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': false},
  };

  List<String> serviceTypeOptions = ['Grooming', 'Boarding', 'Training'];

  Map<String, List<String>> subTypeOptions = {
    'Grooming': ['Pet Shop', 'Home Service'],
    'Boarding': ['Pet Hotel', 'Home Boarding'],
    'Training': ['Training Center', 'Home Training'],
  };

  bool serviceTypeDropdownOpen = false;
  bool businessTypeDropdownOpen = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // ---------------- LOAD EXISTING SERVICE ----------------
  Future<void> _loadService() async {
    final service = await supabase
        .from('services')
        .select()
        .eq('id', widget.serviceId)
        .single();

    final availabilityRows = await supabase
        .from('service_availability')
        .select()
        .eq('service_id', widget.serviceId);

    setState(() {
      serviceType = service['service_type'];
      serviceSubType =
          service['service_subtype'].toString().split(', ');
      _serviceNameController.text = service['service_name'] ?? '';
      _descriptionController.text = service['description'] ?? '';
      _durationController.text =
          service['duration_minutes'].toString();
      _priceController.text = service['price'].toString();

      for (final row in availabilityRows) {
        final day = row['day_of_week'];
        availability[day]!['start'] = row['start_time'];
        availability[day]!['end'] = row['end_time'];
        availability[day]!['enabled'] = true;
      }

      loading = false;
    });
  }

  // ---------------- TIME PICKER ----------------
  Future<void> _pickTime(String day, bool isStart) async {
    final current = availability[day]!;
    TimeOfDay initialTime =
        _stringToTimeOfDay(isStart ? current['start'] : current['end']);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        current[isStart ? 'start' : 'end'] = picked.format(context);
      });
    }
  }

  TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(RegExp(r'[: ]'));
    if (parts.length != 3) return const TimeOfDay(hour: 9, minute: 0);

    int hour = int.tryParse(parts[0]) ?? 9;
    int minute = int.tryParse(parts[1]) ?? 0;
    String period = parts[2];

    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  // ---------------- UPDATE SERVICE ----------------
  Future<void> _updateService() async {
    await supabase.from('services').update({
      'service_type': serviceType,
      'service_subtype': serviceSubType.join(', '),
      'service_name': _serviceNameController.text,
      'description': _descriptionController.text,
      'duration_minutes': int.tryParse(_durationController.text) ?? 0,
      'price': double.tryParse(_priceController.text) ?? 0,
    }).eq('id', widget.serviceId);

    await supabase
        .from('service_availability')
        .delete()
        .eq('service_id', widget.serviceId);

    for (var day in availability.entries) {
      if (!day.value['enabled']) continue;
      await supabase.from('service_availability').insert({
        'service_id': widget.serviceId,
        'day_of_week': day.key,
        'start_time': day.value['start'],
        'end_time': day.value['end'],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Service updated successfully')),
    );
    Navigator.pop(context);
  }

  // ---------------- DROPDOWN BUILDER ----------------
  Widget _buildDropdown({
    required String label,
    required List<String> value,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
    required bool dropdownOpen,
    required VoidCallback toggleDropdown,
    bool multiSelect = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: enabled ? toggleDropdown : null,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF6E4B3A)),
              color: enabled ? Colors.white : Colors.grey[200],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? '' : (multiSelect ? value.join(', ') : value[0]),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(
                  dropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: const Color(0xFF6E4B3A),
                ),
              ],
            ),
          ),
        ),
        if (dropdownOpen && enabled)
          Column(
            children: items.map((e) {
              final selected = value.contains(e);
              return GestureDetector(
                onTap: () {
                  if (multiSelect) {
                    List<String> newValue = List.from(value);
                    if (selected) {
                      newValue.remove(e);
                    } else {
                      newValue.add(e);
                    }
                    onChanged(newValue);
                  } else {
                    onChanged([e]);
                    toggleDropdown();
                  }
                },
                child: Container(
                  height: 50,
                  alignment: Alignment.center,
                  color: selected ? const Color(0xFF6E4B3A) : Colors.transparent,
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dosis(
                        color: selected ? const Color(0xFFDDC7A9) : const Color(0xFF6E4B3A),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // ---------------- TEXTFIELD BUILDER ----------------
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    List<TextInputFormatter> inputFormatters = [];

    if (label.contains('Duration')) {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
    } else if (label.contains('Price')) {
      inputFormatters.add(
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label.contains('Duration')
            ? RichText(
                text: TextSpan(
                  style: GoogleFonts.dosis(
                      color: const Color(0xFF6E4B3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  children: const [
                    TextSpan(text: 'Duration '),
                    TextSpan(
                        text: '(minutes)',
                        style: TextStyle(color: Color(0xFFA0A0A0))),
                  ],
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dosis(
                    color: const Color(0xFF6E4B3A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: Color(0xFF6E4B3A)),
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle:
                GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontSize: 16),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- BUILD UI ----------------
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          serviceTypeDropdownOpen = false;
          businessTypeDropdownOpen = false;
        });
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
          title: Text(
            'Edit Service',
            style: GoogleFonts.dosis(
                color: const Color(0xFF6E4B3A),
                fontSize: 24,
                fontWeight: FontWeight.w600),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Details',
                style: GoogleFonts.dosis(
                    color: const Color(0xFF6E4B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Service Type',
                value: serviceType != null ? [serviceType!] : [],
                items: serviceTypeOptions,
                dropdownOpen: serviceTypeDropdownOpen,
                toggleDropdown: () {
                  setState(() {
                    serviceTypeDropdownOpen = !serviceTypeDropdownOpen;
                    businessTypeDropdownOpen = false;
                  });
                },
                onChanged: (val) {
                  setState(() {
                    serviceType = val[0];
                    serviceSubType.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                label: 'Business Type',
                value: serviceSubType,
                items: serviceType != null
                    ? subTypeOptions[serviceType!]!
                    : ['Select service type first'],
                dropdownOpen: businessTypeDropdownOpen,
                toggleDropdown: () {
                  if (serviceType != null) {
                    setState(() {
                      businessTypeDropdownOpen = !businessTypeDropdownOpen;
                    });
                  }
                },
                onChanged: (val) {
                  setState(() {
                    serviceSubType = val;
                  });
                },
                multiSelect: true,
                enabled: serviceType != null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Service Name', controller: _serviceNameController),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Inclusion', controller: _descriptionController),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Duration (minutes)',
                  controller: _durationController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(
                  label: 'Price',
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  prefixText: '₱ '),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Service Availability',
                style: GoogleFonts.dosis(
                    color: const Color(0xFF6E4B3A),
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...availability.entries.map((entry) {
                final day = entry.key;
                final dayData = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          day,
                          style: GoogleFonts.dosis(
                              color: const Color(0xFF6E4B3A),
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(day, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            margin: const EdgeInsets.only(right: 24),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF6E4B3A)),
                              color: const Color(0xFFFFFFFF),
                            ),
                            child: Text(dayData['start'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dosis(
                                    color: const Color(0xFF6E4B3A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _pickTime(day, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 8),
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF6E4B3A)),
                              color: const Color(0xFFFFFFFF),
                            ),
                            child: Text(dayData['end'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dosis(
                                    color: const Color(0xFF6E4B3A),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400)),
                          ),
                        ),
                      ),
                      Switch(
                          value: dayData['enabled'],
                          activeThumbColor: const Color(0xFF6E4B3A),
                          onChanged: (val) {
                            setState(() {
                              dayData['enabled'] = val;
                            });
                          }),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E4B3A),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.dosis(
                            color: const Color(0xFFDDC7A9),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDDC7A9),
                      ),
                      onPressed: _updateService,
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.dosis(
                            color: const Color(0xFF6E4B3A),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
