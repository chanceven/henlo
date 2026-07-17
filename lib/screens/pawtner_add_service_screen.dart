// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // for input formatters
import 'package:supabase_flutter/supabase_flutter.dart';

class PawtnerAddServiceScreen extends StatefulWidget {
  final String? preselectedServiceType;
  const PawtnerAddServiceScreen({super.key, this.preselectedServiceType});

  @override
  State<PawtnerAddServiceScreen> createState() =>
      _PawtnerAddServiceScreenState();
}

class _PawtnerAddServiceScreenState extends State<PawtnerAddServiceScreen> {
  final supabase = Supabase.instance.client;

  final _serviceNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _durationHoursController = TextEditingController();
  final _durationMinutesController = TextEditingController();
  final _priceController = TextEditingController();

  String? serviceType;
  List<String> serviceSubType = [];
  bool serviceTypeLocked = false;

  Map<String, Map<String, dynamic>> availability = {
    'Mon': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Tue': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Wed': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Thu': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Fri': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Sat': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
    'Sun': {'start': '9:00 AM', 'end': '7:00 PM', 'enabled': true},
  };

  List<String> serviceTypeOptions = ['Grooming', 'Boarding', 'Training'];

  Map<String, List<String>> subTypeOptions = {
    'Grooming': ['Pet Shop', 'Home Service'],
    'Boarding': ['Pet Hotel', 'Home Boarding'],
    'Training': ['Training Center', 'Home Training'],
  };

  bool serviceTypeDropdownOpen = false;
  bool businessTypeDropdownOpen = false;

  void _openOnly(String which) {
    setState(() {
      serviceTypeDropdownOpen = which == 'serviceType';
      businessTypeDropdownOpen = which == 'businessType';
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.preselectedServiceType != null) {
      serviceType = widget.preselectedServiceType;
      serviceTypeLocked = true;
    }
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveService() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final hours = int.tryParse(_durationHoursController.text) ?? 0;

    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;

    final duration = (hours * 60) + minutes;

    final price = double.tryParse(_priceController.text) ?? 0;

    final serviceResponse = await supabase
        .from('services')
        .insert({
          'pawtner_id': currentUser.id,
          'service_type': serviceType,
          'service_subtype': serviceSubType.join(', '),
          'service_name': _serviceNameController.text,
          'description': _descriptionController.text,
          'duration_minutes': duration,
          'price': price,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final serviceId = serviceResponse['id'];

    for (var day in availability.entries) {
      final dayData = day.value;
      if (!dayData['enabled']) continue;
      await supabase.from('service_availability').insert({
        'service_id': serviceId,
        'day_of_week': day.key,
        'start_time': dayData['start'],
        'end_time': dayData['end'],
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Service added successfully.',
          style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A))),
      backgroundColor: const Color(0xFFDDC7A9),
    ));
    Navigator.pop(context);
  }

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
                    value.isEmpty
                        ? ''
                        : (multiSelect ? value.join(', ') : value[0]),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                if (enabled)
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
                  decoration: BoxDecoration(
                    color:
                        selected ? const Color(0xFF6E4B3A) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dosis(
                        color: selected
                            ? const Color(0xFFDDC7A9)
                            : const Color(0xFF6E4B3A),
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

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
      inputFormatters
          .add(FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Only change is below ----
        label.contains('Duration')
            ? RichText(
                text: TextSpan(
                  text: 'Duration ',
                  style: GoogleFonts.dosis(
                      color: const Color(0xFF6E4B3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: '(minutes)',
                      style: GoogleFonts.dosis(
                          color: const Color(0xFFA0A0A0),
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
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
          onTap: () {
            setState(() {
              serviceTypeDropdownOpen = false;
              businessTypeDropdownOpen = false;
            });
          },
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.dosis(
            color: const Color(0xFF6E4B3A),
          ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _openOnly('none');
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF8F8F8),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
          title: Text(
            'Add Service',
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
              _buildDropdown(
                label: 'Service Type',
                value: serviceType != null ? [serviceType!] : [],
                items: serviceTypeOptions,
                dropdownOpen: serviceTypeDropdownOpen,
                toggleDropdown: () {
                  if (!serviceTypeLocked) {
                    _openOnly(
                      serviceTypeDropdownOpen ? 'none' : 'serviceType',
                    );
                  }
                },
                onChanged: (val) {
                  setState(() {
                    serviceType = val[0];
                    serviceSubType.clear();
                  });
                },
                enabled: !serviceTypeLocked,
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
                    _openOnly(
                      businessTypeDropdownOpen ? 'none' : 'businessType',
                    );
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duration',
                    style: GoogleFonts.dosis(
                      color: const Color(0xFF6E4B3A),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onTap: () => _openOnly('none'),
                          controller: _durationHoursController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: GoogleFonts.dosis(
                            color: const Color(0xFF6E4B3A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Hours',
                            hintStyle: GoogleFonts.dosis(
                              color: const Color(0xFFBDBDBD),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          onTap: () => _openOnly('none'),
                          controller: _durationMinutesController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: GoogleFonts.dosis(
                            color: const Color(0xFF6E4B3A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Minutes',
                            hintStyle: GoogleFonts.dosis(
                              color: const Color(0xFFBDBDBD),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Color(0xFF6E4B3A)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    fontSize: 16,
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
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: _TimeSegmentInput(
                            key: ValueKey('$day-start'),
                            initialTime: dayData['start'],
                            onClosingDropdowns: () => _openOnly('none'),
                            onChanged: (newTime) {
                              setState(() {
                                dayData['start'] = newTime;
                              });
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _TimeSegmentInput(
                            key: ValueKey('$day-end'),
                            initialTime: dayData['end'],
                            onClosingDropdowns: () => _openOnly('none'),
                            onChanged: (newTime) {
                              setState(() {
                                dayData['end'] = newTime;
                              });
                            },
                          ),
                        ),
                      ),
                      Switch(
                        value: dayData['enabled'],
                        activeThumbColor: const Color(0xFF6E4B3A),
                        onChanged: (val) {
                          _openOnly('none');

                          setState(() {
                            dayData['enabled'] = val;
                          });
                        },
                      ),
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
                      onPressed: _saveService,
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

/// Inline segmented time input.
///
/// Collapsed state shows e.g. "9:00 AM" inside a bordered box.
/// Tapping it expands into three editable segments: [hour] [minute] [AM/PM].
/// - Typing a 2-digit hour (or a single digit that can't extend, e.g. 2-9)
///   auto-advances focus to the minute segment.
/// - Typing a 2-digit minute (or a first digit 6-9) auto-advances focus to
///   the AM/PM segment.
/// - Typing "A" or "P" in the period segment sets AM/PM directly.
/// - Tapping anywhere outside the three segments commits the value and
///   collapses back to display mode. No popup, sheet, or dropdown is used.
class _TimeSegmentInput extends StatefulWidget {
  final String initialTime;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClosingDropdowns;

  const _TimeSegmentInput({
    super.key,
    required this.initialTime,
    required this.onChanged,
    this.onClosingDropdowns,
  });

  @override
  State<_TimeSegmentInput> createState() => _TimeSegmentInputState();
}

class _TimeSegmentInputState extends State<_TimeSegmentInput> {
  bool _editing = false;
  String _displayTime = '';

  late final TextEditingController _hourCtrl;
  late final TextEditingController _minuteCtrl;
  late final TextEditingController _periodCtrl;

  final FocusNode _hourFocus = FocusNode(debugLabel: 'time-hour');
  final FocusNode _minuteFocus = FocusNode(debugLabel: 'time-minute');
  final FocusNode _periodFocus = FocusNode(debugLabel: 'time-period');
  final FocusScopeNode _scopeNode = FocusScopeNode(debugLabel: 'time-scope');

  @override
  void initState() {
    super.initState();
    _displayTime = widget.initialTime;
    final parsed = _parse(_displayTime);
    _hourCtrl = TextEditingController(text: parsed.hour);
    _minuteCtrl = TextEditingController(text: parsed.minute);
    _periodCtrl = TextEditingController(text: parsed.period);
    _scopeNode.addListener(_handleScopeFocusChange);
  }

  ({String hour, String minute, String period}) _parse(String time) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false)
        .firstMatch(time.trim());
    if (match != null) {
      return (
        hour: match.group(1)!,
        minute: match.group(2)!,
        period: match.group(3)!.toUpperCase(),
      );
    }
    return (hour: '9', minute: '00', period: 'AM');
  }

  void _handleScopeFocusChange() {
    if (!_scopeNode.hasFocus && _editing) {
      _commit();
    }
  }

  void _commit() {
    int hour = int.tryParse(_hourCtrl.text) ?? 9;
    if (hour < 1) hour = 1;
    if (hour > 12) hour = 12;

    int minute = int.tryParse(_minuteCtrl.text) ?? 0;
    if (minute < 0) minute = 0;
    if (minute > 59) minute = 59;

    String period = _periodCtrl.text.toUpperCase();
    if (period != 'AM' && period != 'PM') period = 'AM';

    final formatted = '$hour:${minute.toString().padLeft(2, '0')} $period';

    _hourCtrl.text = hour.toString();
    _minuteCtrl.text = minute.toString().padLeft(2, '0');
    _periodCtrl.text = period;

    if (!mounted) {
      _displayTime = formatted;
      _editing = false;
      widget.onChanged(formatted);
      return;
    }

    setState(() {
      _displayTime = formatted;
      _editing = false;
    });

    widget.onChanged(formatted);
  }

  void _startEditing() {
    widget.onClosingDropdowns?.call();

    final parsed = _parse(_displayTime);
    _hourCtrl.text = parsed.hour;
    _minuteCtrl.text = parsed.minute;
    _periodCtrl.text = parsed.period;

    setState(() {
      _editing = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _hourFocus.requestFocus();
      _hourCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _hourCtrl.text.length);
    });
  }

  @override
  void dispose() {
    _scopeNode.removeListener(_handleScopeFocusChange);
    _hourFocus.dispose();
    _minuteFocus.dispose();
    _periodFocus.dispose();
    _scopeNode.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  void _onHourChanged(String val) {
    if (val.isEmpty) return;
    final n = int.tryParse(val) ?? 0;
    final shouldAdvance = val.length == 2 || n >= 2;
    if (shouldAdvance) {
      if (val.length == 2 && n > 12) {
        _hourCtrl.text = '12';
      }
      if (val.length == 1 && n == 0) {
        // "0" alone isn't a valid hour; let them keep typing.
        return;
      }
      _minuteFocus.requestFocus();
      _minuteCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _minuteCtrl.text.length);
    }
  }

  void _onMinuteChanged(String val) {
    if (val.isEmpty) return;
    final n = int.tryParse(val) ?? 0;
    final shouldAdvance = val.length == 2 || n >= 6;
    if (shouldAdvance) {
      if (val.length == 2 && n > 59) {
        _minuteCtrl.text = '59';
      }
      _periodFocus.requestFocus();
      _periodCtrl.selection =
          TextSelection(baseOffset: 0, extentOffset: _periodCtrl.text.length);
    }
  }

  Widget _segment({
    required TextEditingController controller,
    required FocusNode focusNode,
    required int maxLength,
    required List<TextInputFormatter> formatters,
    required ValueChanged<String> onTextChanged,
    double width = 22,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLength,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        inputFormatters: formatters,
        style: GoogleFonts.dosis(
          color: const Color(0xFF6E4B3A),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          counterText: '',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: InputBorder.none,
        ),
        onChanged: onTextChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_editing) {
      return GestureDetector(
        onTap: _startEditing,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF6E4B3A)),
            color: Colors.white,
          ),
          child: Text(
            _displayTime,
            textAlign: TextAlign.center,
            style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return FocusScope(
      node: _scopeNode,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF6E4B3A), width: 1.4),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _segment(
              controller: _hourCtrl,
              focusNode: _hourFocus,
              maxLength: 2,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onTextChanged: _onHourChanged,
            ),
            Text(
              ':',
              style: GoogleFonts.dosis(
                  color: const Color(0xFF6E4B3A),
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            _segment(
              controller: _minuteCtrl,
              focusNode: _minuteFocus,
              maxLength: 2,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onTextChanged: _onMinuteChanged,
            ),
            const SizedBox(width: 4),
            _segment(
              controller: _periodCtrl,
              focusNode: _periodFocus,
              maxLength: 2,
              width: 30,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[AaPp]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  final letter =
                      newValue.text[newValue.text.length - 1].toUpperCase();
                  final period = letter == 'P' ? 'PM' : 'AM';
                  return TextEditingValue(
                    text: period,
                    selection: TextSelection.collapsed(offset: period.length),
                  );
                }),
              ],
              onTextChanged: (_) {},
            ),
          ],
        ),
      ),
    );
  }
}
