import 'dart:async';
import '../places_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class PawtnerAddBookingScreen extends StatefulWidget {
  const PawtnerAddBookingScreen({super.key});

  @override
  State<PawtnerAddBookingScreen> createState() =>
      _PawtnerAddBookingScreenState();
}

class _PawtnerAddBookingScreenState extends State<PawtnerAddBookingScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController petNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  // Matched existing furrent (real app customer), if any.
  String? matchedFurrentId;
  String? matchedFurrentName;
  String? matchedFurrentContactNumber;
  List<Map<String, dynamic>> matchedFurrentPets = [];
  String? selectedExistingPetId;
  bool isAddingNewPet = false;

  List<Map<String, dynamic>> furrentSearchResults = [];
  bool isSearchingFurrent = false;
  int _furrentSearchSeq = 0;

  String bookingSource = 'Phone';
  String? selectedServiceType;
  String? selectedServiceId;
  String? selectedPetType;

  String selectedSubtype = '';
  String furrentAddress = '';

  DateTime? selectedDate;
  DateTime? selectedEndDate;
  TimeOfDay? selectedTime;
  int boardingDays = 0;

  // ---- ADDED: available time slots ----
  List<TimeOfDay> availableTimes = [];
  int _timesSeq = 0;
  bool isLoadingTimes = false;

  List<Map<String, dynamic>> services = [];

  bool isLoading = true;
  bool isSaving = false;

  bool serviceTypeDropdownOpen = false;
  bool serviceDropdownOpen = false;
  bool petTypeDropdownOpen = false;
  bool petDropdownOpen = false;

  final LayerLink _serviceTypeLink = LayerLink();
  final LayerLink _serviceLink = LayerLink();
  final LayerLink _petTypeLink = LayerLink();
  final LayerLink _petLink = LayerLink();

  OverlayEntry? _dropdownOverlay;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _dropdownOverlay?.remove();
    customerNameController.dispose();
    contactNumberController.dispose();
    petNameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _openOnly(String which) {
    setState(() {
      serviceTypeDropdownOpen = which == 'serviceType';
      serviceDropdownOpen = which == 'service';
      petTypeDropdownOpen = which == 'petType';
      petDropdownOpen = which == 'pet';
    });

    if (which == 'none') {
      _closeDropdownOverlay();
    }
  }

  void _closeDropdownOverlay() {
    _dropdownOverlay?.remove();
    _dropdownOverlay = null;
  }

  void _showDropdownOverlay({
    required LayerLink link,
    required double width,
    required List<String> items,
    required String? selectedValue,
    required ValueChanged<String> onChanged,
    required VoidCallback onCloseAfterSelect,
  }) {
    _closeDropdownOverlay();

    _dropdownOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: width,
        child: CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          offset: const Offset(0, 54),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) {
                final selected = selectedValue == item;

                return InkWell(
                  onTap: () {
                    onChanged(item);
                    onCloseAfterSelect();
                  },
                  child: Container(
                    height: 50,
                    alignment: Alignment.center,
                    color: selected ? const Color(0xFF6E4B3A) : Colors.white,
                    child: Text(
                      item,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dosis(
                        color: selected
                            ? const Color(0xFFDDC7A9)
                            : const Color(0xFF6E4B3A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_dropdownOverlay!);
  }

  Future<void> _loadServices() async {
    try {
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw 'User not logged in';
      }

      final response = await supabase
          .from('services')
          .select(
            'id, service_type, service_subtype, service_name, price, duration_minutes, max_bookings_per_slot',
          )
          .eq('pawtner_id', user.id)
          .order('service_type')
          .order('service_name');

      if (!mounted) return;

      setState(() {
        services =
            (response as List).map((e) => e as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading services: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load services.',
            style: GoogleFonts.dosis(
              color: const Color(0xFFDDC7A9),
            ),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        ),
      );
    }
  }

  // ---- ADDED: copied/adapted from FurrentBookAppointmentScreen ----
  double _timeToDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

  TimeOfDay _addMinutes(TimeOfDay t, int m) {
    final totalMins = t.hour * 60 + t.minute + m;
    return TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60);
  }

  // ---- ADDED: copied/adapted from FurrentBookAppointmentScreen ----
  Future<void> _loadAvailableTimes(DateTime date) async {
    final seq = ++_timesSeq;
    if (selectedServiceId == null) {
      if (!mounted) return;
      setState(() {
        availableTimes = [];
        selectedTime = null;
        isLoadingTimes = false;
      });
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (mounted) setState(() => isLoadingTimes = true);

    try {
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayOfWeek = dayNames[date.weekday % 7];

      final response = await supabase
          .from('service_availability')
          .select('start_time, end_time')
          .eq('service_id', selectedServiceId!)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      final availList =
          (response as List).map((e) => e as Map<String, dynamic>).toList();

      final selectedService = services.firstWhere(
        (s) => s['id'].toString() == selectedServiceId,
        orElse: () => <String, dynamic>{},
      );
      final durationMinutes =
          (selectedService['duration_minutes'] as int?) ?? 60;
      final isBoardingService =
          selectedServiceType?.toLowerCase() == 'boarding';

      List<TimeOfDay> slots = [];

      for (var row in availList) {
        final startParts = (row['start_time'] as String).split(':');
        final endParts = (row['end_time'] as String).split(':');

        TimeOfDay current = TimeOfDay(
          hour: int.parse(startParts[0]),
          minute: int.parse(startParts[1]),
        );

        final end = TimeOfDay(
          hour: int.parse(endParts[0]),
          minute: int.parse(endParts[1]),
        );

        final endMinutes = end.hour * 60 + end.minute;
        while (_timeToDouble(current) < _timeToDouble(end)) {
          final currentMinutes = current.hour * 60 + current.minute;
          if (isBoardingService ||
              currentMinutes + durationMinutes <= endMinutes) {
            slots.add(current);
          }
          current = _addMinutes(current, 30);
        }
      }

      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        slots = slots.where((t) {
          final slotDt = DateTime(
            date.year,
            date.month,
            date.day,
            t.hour,
            t.minute,
          );
          return slotDt.isAfter(now);
        }).toList();
      }

      final maxPerSlot =
          (selectedService['max_bookings_per_slot'] as int?) ?? 1;

      // Check booking capacity for each time slot.
      final availableSlots = <TimeOfDay>[];

      for (final time in slots) {
        if (!mounted || seq != _timesSeq) return;
        final slotStart = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final isBoardingSlot = selectedServiceType?.toLowerCase() == 'boarding';
        final slotEnd = isBoardingSlot && selectedEndDate != null
            ? DateTime(
                selectedEndDate!.year,
                selectedEndDate!.month,
                selectedEndDate!.day,
                time.hour,
                time.minute,
              )
            : slotStart.add(Duration(minutes: durationMinutes));

        final existing = await supabase
            .from('bookings')
            .select('id')
            .eq('pawtner_id', user.id)
            .eq('service_id', selectedServiceId!)
            .neq('status', 'Cancelled')
            .lt(
              'scheduled_start',
              slotEnd.toUtc().toIso8601String(),
            )
            .gt(
              'scheduled_end',
              slotStart.toUtc().toIso8601String(),
            );

        if (existing.length < maxPerSlot) {
          availableSlots.add(time);
        }
      }

      if (!mounted || seq != _timesSeq) return;

      setState(() {
        availableTimes = availableSlots;
        isLoadingTimes = false;

        if (selectedTime != null && !availableSlots.contains(selectedTime)) {
          selectedTime = null;
        }
      });
    } catch (e) {
      debugPrint('Error loading available times: $e');

      if (!mounted || seq != _timesSeq) return;

      setState(() {
        availableTimes = [];
        selectedTime = null;
        isLoadingTimes = false;
      });
    }
  }

  Future<void> _searchFurrents(String query) async {
    final seq = ++_furrentSearchSeq;
    // Remove characters that break the PostgREST filter syntax.
    final q = query.replaceAll(RegExp(r'[,()%*]'), ' ').trim();

    if (q.length < 2) {
      setState(() {
        furrentSearchResults = [];
        isSearchingFurrent = false;
      });
      return;
    }

    setState(() => isSearchingFurrent = true);

    try {
      final results = await supabase
          .from('furrents')
          .select('id, full_name, contact_number')
          .ilike('full_name', '%$q%')
          .limit(5);

      if (!mounted || seq != _furrentSearchSeq) return;

      setState(() {
        furrentSearchResults =
            (results as List).map((e) => e as Map<String, dynamic>).toList();
        isSearchingFurrent = false;
      });
    } catch (e) {
      debugPrint('Furrent search error: $e');
      if (!mounted || seq != _furrentSearchSeq) return;
      setState(() => isSearchingFurrent = false);
    }
  }

  Future<void> _selectFurrent(Map<String, dynamic> furrent) async {
    final furrentId = furrent['id'].toString();
    _furrentSearchSeq++;

    setState(() {
      isSearchingFurrent = false;
      matchedFurrentId = furrentId;
      matchedFurrentName = furrent['full_name'].toString();
      customerNameController.text = furrent['full_name'].toString();
      matchedFurrentContactNumber = furrent['contact_number']?.toString() ?? '';
      contactNumberController.clear();
      furrentSearchResults = [];
      selectedExistingPetId = null;
      isAddingNewPet = false;
      petNameController.clear();
      selectedPetType = null;
    });

    try {
      final pets = await supabase
          .from('pets')
          .select('id, name, type')
          .eq('furrent_id', furrentId);

      if (!mounted || matchedFurrentId != furrentId) return;

      setState(() {
        matchedFurrentPets =
            (pets as List).map((e) => e as Map<String, dynamic>).toList();
      });
    } catch (e) {
      debugPrint('Error loading pets for furrent: $e');
      if (!mounted || matchedFurrentId != furrentId) return;
      _showMessage('Failed to load customer pets. Please try again.');
      _clearMatchedFurrent();
    }
  }

  void _clearMatchedFurrent() {
    _furrentSearchSeq++;
    setState(() {
      isSearchingFurrent = false;
      matchedFurrentId = null;
      matchedFurrentName = null;
      matchedFurrentContactNumber = null;
      contactNumberController.clear();
      matchedFurrentPets = [];
      selectedExistingPetId = null;
      isAddingNewPet = false;
      petNameController.clear();
      selectedPetType = null;
      furrentSearchResults = [];
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      ),
    );
  }

  Future<void> _saveBooking() async {
    if (isSaving) return;
    // ---- Validation ----
    if (customerNameController.text.trim().isEmpty) {
      _showMessage('Please enter customer name.');
      return;
    }
    final contactNumber = matchedFurrentId != null
        ? (matchedFurrentContactNumber ?? '')
        : contactNumberController.text.trim();
    if (contactNumber.isEmpty) {
      _showMessage('Please enter contact number.');
      return;
    }
    if (matchedFurrentId == null &&
        !RegExp(r'^09\d{9}$').hasMatch(contactNumber)) {
      _showMessage(
          'Please enter a valid 11-digit mobile number (09XXXXXXXXX).');
      return;
    }
    final usingExistingPet =
        matchedFurrentId != null && selectedExistingPetId != null;
    if (matchedFurrentId != null &&
        matchedFurrentPets.isNotEmpty &&
        !isAddingNewPet &&
        selectedExistingPetId == null) {
      _showMessage('Please select a pet.');
      return;
    }
    if (!usingExistingPet && petNameController.text.trim().isEmpty) {
      _showMessage('Please enter pet name.');
      return;
    }
    if (!usingExistingPet && selectedPetType == null) {
      _showMessage('Please select a pet type.');
      return;
    }
    if (selectedServiceType == null || selectedServiceId == null) {
      _showMessage('Please select a service.');
      return;
    }
    if (selectedSubtype.isEmpty) {
      _showMessage('Please select a service mode.');
      return;
    }
    final needsAddress =
        selectedSubtype == 'Home Service' || selectedSubtype == 'Home Training';
    if (needsAddress && furrentAddress.isEmpty) {
      _showMessage('Please enter the customer address.');
      return;
    }
    final isBoarding = selectedServiceType?.toLowerCase() == 'boarding';

    if (selectedDate == null) {
      _showMessage('Please select a date.');
      return;
    }

    if (isBoarding && selectedEndDate == null) {
      _showMessage('Please select an end date.');
      return;
    }

    if (selectedTime == null) {
      _showMessage('Please select a time.');
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      _showMessage('You are not logged in.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final selectedService = services.firstWhere(
        (s) => s['id'].toString() == selectedServiceId,
        orElse: () => <String, dynamic>{},
      );

      final maxPerSlot =
          (selectedService['max_bookings_per_slot'] as int?) ?? 1;

      final pawtnerResponse = await supabase
          .from('pawtners')
          .select('business_name')
          .eq('id', user.id)
          .maybeSingle();
      final pawtnerBusinessName =
          pawtnerResponse?['business_name'] as String? ?? '';

      final scheduledStart = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      final durationMinutes =
          (selectedService['duration_minutes'] as int?) ?? 60;

      final scheduledEnd = isBoarding && selectedEndDate != null
          ? DateTime(
              selectedEndDate!.year,
              selectedEndDate!.month,
              selectedEndDate!.day,
              selectedTime!.hour,
              selectedTime!.minute,
            )
          : scheduledStart.add(
              Duration(minutes: durationMinutes),
            );

      final existing = await supabase
          .from('bookings')
          .select('id')
          .eq('pawtner_id', user.id)
          .eq('service_id', selectedServiceId!)
          .neq('status', 'Cancelled')
          .lt('scheduled_start', scheduledEnd.toUtc().toIso8601String())
          .gt('scheduled_end', scheduledStart.toUtc().toIso8601String());

      if (existing.length >= maxPerSlot) {
        _showMessage('This slot is already fully booked.');
        return;
      }

      String? petId = selectedExistingPetId;

      if (matchedFurrentId != null && selectedExistingPetId == null) {
        final newPet = await supabase
            .from('pets')
            .insert({
              'furrent_id': matchedFurrentId,
              'name': petNameController.text.trim(),
              'type': selectedPetType,
            })
            .select('id')
            .single();

        petId = newPet['id'].toString();

        // Keep the new pet selected so a retry reuses it instead of
        // creating a duplicate if the booking insert fails.
        if (mounted) {
          setState(() {
            matchedFurrentPets = [
              ...matchedFurrentPets,
              {
                'id': petId,
                'name': petNameController.text.trim(),
                'type': selectedPetType,
              },
            ];
            selectedExistingPetId = petId;
            isAddingNewPet = false;
          });
        }
      }

      // ---- Insert booking ----
      await supabase.from('bookings').insert({
        'pawtner_id': user.id,
        'service_id': selectedServiceId,
        'furrent_id': matchedFurrentId,
        'pet_id': petId,
        'guest_name': customerNameController.text.trim(),
        'guest_contact_number': contactNumber,
        'guest_pet_name': petNameController.text.trim(),
        'guest_pet_type': matchedFurrentId == null ? selectedPetType : null,
        'pawtner_name': pawtnerBusinessName,
        'furrent_name': matchedFurrentId != null
            ? matchedFurrentName
            : customerNameController.text.trim(),
        'pet_name': petNameController.text.trim(),
        'service_name': selectedService['service_name']?.toString() ?? '',
        'price': selectedService['price'],
        'chosen_service_subtype': selectedSubtype,
        'furrent_address': needsAddress ? furrentAddress : null,
        'notes': notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        'booking_source': bookingSource,
        'scheduled_start': scheduledStart.toUtc().toIso8601String(),
        'scheduled_end': scheduledEnd.toUtc().toIso8601String(),
        'status': 'Upcoming',
      });

      if (!mounted) return;

      _showMessage('Booking added.');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Error saving booking: $e');
      _showMessage('Could not save booking. Please try again.');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    _openOnly('none');

    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month, today.day);
    final lastDay = DateTime(today.year, today.month, today.day + 365);

    final isBoarding = selectedServiceType?.toLowerCase() == 'boarding';

    DateTime? dialogStartDate = selectedDate;
    DateTime? dialogEndDate = selectedEndDate;

    DateTime calendarMonth =
        selectedDate ?? DateTime(today.year, today.month, today.day);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final firstOfMonth =
                DateTime(calendarMonth.year, calendarMonth.month, 1);

            final startingWeekday = firstOfMonth.weekday % 7;

            final daysInMonth =
                DateTime(calendarMonth.year, calendarMonth.month + 1, 0).day;

            final dayWidgets = <Widget>[];

            for (int i = 0; i < startingWeekday; i++) {
              dayWidgets.add(const SizedBox());
            }

            for (int day = 1; day <= daysInMonth; day++) {
              final currentDate =
                  DateTime(calendarMonth.year, calendarMonth.month, day);

              final isPast = currentDate.isBefore(firstDay);
              final isAfterLimit = currentDate.isAfter(lastDay);

              final isStart = dialogStartDate != null &&
                  dialogStartDate!.year == currentDate.year &&
                  dialogStartDate!.month == currentDate.month &&
                  dialogStartDate!.day == currentDate.day;

              final isEnd = dialogEndDate != null &&
                  dialogEndDate!.year == currentDate.year &&
                  dialogEndDate!.month == currentDate.month &&
                  dialogEndDate!.day == currentDate.day;

              final isInRange = isBoarding &&
                  dialogStartDate != null &&
                  dialogEndDate != null &&
                  currentDate.isAfter(dialogStartDate!) &&
                  currentDate.isBefore(dialogEndDate!);

              dayWidgets.add(
                GestureDetector(
                  onTap: (isPast || isAfterLimit)
                      ? null
                      : () {
                          if (!isBoarding) {
                            setState(() {
                              selectedDate = currentDate;
                              selectedEndDate = null;
                              boardingDays = 0;
                              selectedTime = null;
                            });

                            // ---- ADDED ----
                            _loadAvailableTimes(currentDate);

                            Navigator.pop(context);
                            return;
                          }

                          if (dialogStartDate == null ||
                              dialogEndDate != null ||
                              !currentDate.isAfter(dialogStartDate!)) {
                            setDialogState(() {
                              dialogStartDate = currentDate;
                              dialogEndDate = null;
                              boardingDays = 0;
                            });
                            return;
                          }

                          if (dialogEndDate == null &&
                              currentDate.isAfter(dialogStartDate!)) {
                            setDialogState(() {
                              dialogEndDate = currentDate;
                              boardingDays = currentDate
                                  .difference(dialogStartDate!)
                                  .inDays;
                            });

                            setState(() {
                              selectedDate = dialogStartDate;
                              selectedEndDate = dialogEndDate;
                              boardingDays = dialogEndDate!
                                  .difference(dialogStartDate!)
                                  .inDays;
                              selectedTime = null;
                            });

                            // ---- ADDED ----
                            _loadAvailableTimes(dialogStartDate!);

                            Navigator.pop(context);
                          }
                        },
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: (isStart || isEnd)
                        ? const BoxDecoration(
                            color: Color(0xFF6E4B3A),
                            shape: BoxShape.circle,
                          )
                        : isInRange
                            ? BoxDecoration(
                                color: const Color(0xFF6E4B3A)
                                    .withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              )
                            : null,
                    child: Text(
                      '$day',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (isPast || isAfterLimit)
                            ? Colors.grey
                            : (isStart || isEnd)
                                ? Colors.white
                                : const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                ),
              );
            }

            while (dayWidgets.length % 7 != 0) {
              dayWidgets.add(const SizedBox());
            }

            final rows = <TableRow>[];

            rows.add(
              TableRow(
                children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                    .map(
                      (day) => SizedBox(
                        height: 40,
                        child: Center(
                          child: Text(
                            day,
                            style: GoogleFonts.dosis(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            );

            for (int i = 0; i < dayWidgets.length; i += 7) {
              rows.add(
                TableRow(
                  children: dayWidgets.sublist(i, i + 7),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            final previousMonth = DateTime(
                              calendarMonth.year,
                              calendarMonth.month - 1,
                              1,
                            );

                            final currentMonth = DateTime(
                              today.year,
                              today.month,
                              1,
                            );

                            if (previousMonth.isBefore(currentMonth)) {
                              return;
                            }

                            setDialogState(() {
                              calendarMonth = previousMonth;
                            });
                          },
                          child: const Text(
                            "<",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              "${_monthName(calendarMonth.month)} ${calendarMonth.year}",
                              style: GoogleFonts.dosis(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final nextMonth = DateTime(
                              calendarMonth.year,
                              calendarMonth.month + 1,
                              1,
                            );

                            final lastAllowedMonth = DateTime(
                              lastDay.year,
                              lastDay.month,
                              1,
                            );

                            if (nextMonth.isAfter(lastAllowedMonth)) {
                              return;
                            }

                            setDialogState(() {
                              calendarMonth = nextMonth;
                            });
                          },
                          child: const Text(
                            ">",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF6E4B3A),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Table(
                        defaultColumnWidth: const FlexColumnWidth(),
                        children: rows,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _monthName(int month) {
    const names = [
      '',
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
      'December',
    ];

    return names[month];
  }

  Future<void> _pickFurrentAddress() async {
    final TextEditingController searchController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    Timer? debounce;
    int searchSeq = 0;
    bool picking = false;
    String? addressError;

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
                'Enter customer address',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 20),
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
                    color: const Color(0xFFBDBDBD),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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
                onChanged: (value) {
                  debounce?.cancel();
                  if (value.trim().length < 3) {
                    searchSeq++;
                    setModalState(() {
                      searchResults = [];
                      isSearching = false;
                    });
                    return;
                  }
                  debounce = Timer(const Duration(milliseconds: 400), () async {
                    if (!context.mounted) return;
                    final seq = ++searchSeq;
                    setModalState(() => isSearching = true);
                    try {
                      final response = await PlacesService.autocomplete(value);
                      if (!context.mounted || seq != searchSeq) return;
                      final suggestions =
                          response['suggestions'] as List? ?? [];
                      setModalState(() {
                        searchResults = suggestions
                            .map((e) =>
                                e['placePrediction'] as Map<String, dynamic>)
                            .toList();
                        isSearching = false;
                      });
                    } catch (e) {
                      debugPrint('Autocomplete error: $e');
                      if (!context.mounted || seq != searchSeq) return;
                      setModalState(() => isSearching = false);
                    }
                  });
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
                          if (picking) return;
                          picking = true;
                          setModalState(() => addressError = null);
                          try {
                            final detailResponse =
                                await PlacesService.details(placeId);
                            final formattedAddress =
                                detailResponse['formattedAddress'] ?? mainText;
                            final addressParts = formattedAddress.split(',');
                            final shortAddress = addressParts.length > 2
                                ? addressParts.take(2).join(',').trim()
                                : formattedAddress;

                            if (!mounted) return;
                            setState(() {
                              furrentAddress = shortAddress;
                            });

                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Place detail error: $e');
                            picking = false;
                            if (!context.mounted) return;
                            setModalState(() => addressError =
                                'Failed to load address. Please try again.');
                          }
                        },
                      );
                    },
                  ),
                ),
              if (addressError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    addressError!,
                    style: GoogleFonts.dosis(
                      fontSize: 14,
                      color: const Color(0xFF8B0000),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get serviceModeTabs {
    if (selectedServiceType == null) {
      return ['Shop', 'Home'];
    }

    switch (selectedServiceType!.toLowerCase()) {
      case 'grooming':
        return ['Pet Shop', 'Home Service'];
      case 'boarding':
        return ['Pet Hotel', 'Home Boarding'];
      case 'training':
        return ['Training Center', 'Home Training'];
      default:
        return ['Pet Shop', 'Home Service'];
    }
  }

  List<String> get availableServiceModes {
    if (selectedServiceId == null) return [];

    final selected = services.firstWhere(
      (service) => service['id'].toString() == selectedServiceId,
      orElse: () => <String, dynamic>{},
    );

    final subtype = selected['service_subtype']?.toString() ?? '';

    return subtype
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> get filteredServices {
    if (selectedServiceType == null) {
      return [];
    }

    return services
        .where(
          (service) =>
              service['service_type'].toString().toLowerCase() ==
              selectedServiceType!.toLowerCase(),
        )
        .toList();
  }

  Widget _buildTextField({
    required TextEditingController controller,
  }) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        onTap: () => _openOnly('none'),
        textCapitalization: TextCapitalization.words,
        style: GoogleFonts.dosis(
          fontSize: 16,
          color: const Color(0xFF6E4B3A),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6E4B3A),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6E4B3A),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required LayerLink layerLink,
    required String? value,
    required String hint,
    required List<String> items,
    required bool dropdownOpen,
    required VoidCallback toggleDropdown,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    void handleToggle() {
      final willOpen = !dropdownOpen;

      toggleDropdown();

      if (willOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          _showDropdownOverlay(
            link: layerLink,
            width: MediaQuery.of(context).size.width - 32,
            items: items,
            selectedValue: value,
            onChanged: (selected) {
              onChanged(selected);
            },
            onCloseAfterSelect: toggleDropdown,
          );
        });
      } else {
        _closeDropdownOverlay();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dosis(
            color: const Color(0xFF6E4B3A),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        CompositedTransformTarget(
          link: layerLink,
          child: GestureDetector(
            onTap: enabled ? handleToggle : null,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6E4B3A),
                ),
                color: enabled ? Colors.white : Colors.grey[200],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      value ?? '',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (enabled)
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
        ),
      ],
    );
  }

  Widget _buildServiceDropdown() {
    return _buildDropdown(
      label: 'Service Name',
      layerLink: _serviceLink,
      value: selectedServiceId == null
          ? null
          : filteredServices
              .where(
                (service) => service['id'].toString() == selectedServiceId,
              )
              .map(
                (service) => service['service_name'].toString(),
              )
              .firstOrNull,
      hint: selectedServiceType == null
          ? 'Select service type first'
          : 'Select service',
      items: filteredServices
          .map(
            (service) => service['service_name'].toString(),
          )
          .toList(),
      dropdownOpen: serviceDropdownOpen,
      toggleDropdown: () {
        if (selectedServiceType != null) {
          _openOnly(
            serviceDropdownOpen ? 'none' : 'service',
          );
        }
      },
      onChanged: (serviceName) {
        if (serviceName == null) return;

        final selected = filteredServices.firstWhere(
          (service) => service['service_name'].toString() == serviceName,
        );

        final subtype = selected['service_subtype']?.toString() ?? '';

        final available = subtype
            .split(',')
            .map((s) => s.trim().toLowerCase())
            .where((s) => s.isNotEmpty)
            .toList();

        final tabs = serviceModeTabs;

        String newSubtype = '';

        for (final tab in tabs) {
          if (available.contains(tab.toLowerCase())) {
            newSubtype = tab;
            break;
          }
        }

        setState(() {
          selectedServiceId = selected['id'].toString();
          selectedSubtype = newSubtype;
          furrentAddress = '';
        });

        // ---- ADDED: refresh time slots for the newly picked service ----
        if (selectedDate != null) {
          _loadAvailableTimes(selectedDate!);
        }
      },
      enabled: selectedServiceType != null,
    );
  }

  // ---- ADDED: copied/adapted from FurrentBookAppointmentScreen ----
  Widget _buildTimeSlots() {
    if (isLoadingTimes) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF6E4B3A)),
        ),
      );
    }
    if (availableTimes.isEmpty) {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'No available slots',
            style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 275,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3,
            ),
            itemCount: availableTimes.length,
            itemBuilder: (context, index) {
              TimeOfDay time = availableTimes[index];
              final isSelected = selectedTime == time;
              return GestureDetector(
                onTap: () {
                  _openOnly('none');
                  setState(() {
                    selectedTime = time;
                  });
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6E4B3A) : null,
                    border: Border.all(color: const Color(0xFF6E4B3A)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    time.format(context),
                    style: GoogleFonts.dosis(
                      color:
                          isSelected ? Colors.white : const Color(0xFF6E4B3A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
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
          iconTheme: const IconThemeData(
            color: Color(0xFF6E4B3A),
          ),
          title: Text(
            'Add Booking',
            style: GoogleFonts.dosis(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6E4B3A),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Source',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _sourceButton('Phone'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _sourceButton('Walk-in'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _sourceButton('Off-platform'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Customer Name',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextField(
                        controller: customerNameController,
                        onTap: () => _openOnly('none'),
                        readOnly: matchedFurrentId != null,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          color: const Color(0xFF6E4B3A),
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: matchedFurrentId == null
                              ? Colors.white
                              : Colors.grey[200],
                          suffixIcon: isSearchingFurrent
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF6E4B3A),
                                    ),
                                  ),
                                )
                              : matchedFurrentId != null
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Color(0xFF6E4B3A)),
                                      onPressed: _clearMatchedFurrent,
                                    )
                                  : null,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E4B3A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: _searchFurrents,
                      ),
                    ),
                    if (furrentSearchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE6E6E6)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: furrentSearchResults.map((f) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.person,
                                  color: Color(0xFF6E4B3A), size: 20),
                              title: Text(
                                f['full_name'].toString(),
                                style: GoogleFonts.dosis(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              onTap: () => _selectFurrent(f),
                            );
                          }).toList(),
                        ),
                      ),
                    if (matchedFurrentId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Linked to existing customer: $matchedFurrentName',
                          style: GoogleFonts.dosis(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Contact Number',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 52,
                      child: TextField(
                        controller: contactNumberController,
                        onTap: () => _openOnly('none'),
                        enabled: matchedFurrentId == null,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          color: const Color(0xFF6E4B3A),
                        ),
                        decoration: InputDecoration(
                          hintText: '09XXXXXXXXX',
                          hintStyle: GoogleFonts.dosis(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: matchedFurrentId == null
                              ? Colors.white
                              : Colors.grey[200],
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6E4B3A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged:
                            matchedFurrentId == null ? _searchFurrents : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (matchedFurrentId != null &&
                        matchedFurrentPets.isNotEmpty &&
                        !isAddingNewPet)
                      _buildDropdown(
                        label: 'Pet Name',
                        layerLink: _petLink,
                        value: selectedExistingPetId == null
                            ? null
                            : matchedFurrentPets
                                .where((pet) =>
                                    pet['id'].toString() ==
                                    selectedExistingPetId)
                                .map((pet) => pet['name'].toString())
                                .firstOrNull,
                        hint: 'Select pet',
                        items: [
                          ...matchedFurrentPets
                              .map((pet) => pet['name'].toString()),
                          '+ New pet',
                        ],
                        dropdownOpen: petDropdownOpen,
                        toggleDropdown: () {
                          _openOnly(petDropdownOpen ? 'none' : 'pet');
                        },
                        onChanged: (petName) {
                          if (petName == null) return;

                          if (petName == '+ New pet') {
                            setState(() {
                              selectedExistingPetId = null;
                              isAddingNewPet = true;
                              petNameController.clear();
                              selectedPetType = null;
                            });
                            return;
                          }

                          final pet = matchedFurrentPets.firstWhere(
                            (p) => p['name'].toString() == petName,
                          );

                          setState(() {
                            selectedExistingPetId = pet['id'].toString();
                            isAddingNewPet = false;
                            petNameController.text = petName;
                            selectedPetType = pet['type']?.toString();
                          });
                        },
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pet Name',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: petNameController,
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Pet Type',
                      layerLink: _petTypeLink,
                      value: selectedPetType,
                      hint: '',
                      items: ['Dog', 'Cat'],
                      enabled: matchedFurrentId == null ||
                          isAddingNewPet ||
                          matchedFurrentPets.isEmpty,
                      dropdownOpen: petTypeDropdownOpen,
                      toggleDropdown: () {
                        _openOnly(petTypeDropdownOpen ? 'none' : 'petType');
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedPetType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdown(
                      label: 'Service Type',
                      layerLink: _serviceTypeLink,
                      value: selectedServiceType,
                      hint: 'Select service type',
                      items: ['Grooming', 'Boarding', 'Training'],
                      dropdownOpen: serviceTypeDropdownOpen,
                      toggleDropdown: () {
                        _openOnly(
                          serviceTypeDropdownOpen ? 'none' : 'serviceType',
                        );
                      },
                      onChanged: (value) {
                        setState(() {
                          selectedServiceType = value;
                          selectedServiceId = null;
                          selectedSubtype = '';
                          furrentAddress = '';
                          selectedDate = null;
                          selectedEndDate = null;
                          boardingDays = 0;
                          selectedTime = null;
                          availableTimes = []; // ---- ADDED ----
                          _timesSeq++; // cancel any in-flight slot load
                          isLoadingTimes = false;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildServiceDropdown(),
                    const SizedBox(height: 20),
                    ...[
                      Text(
                        'Service Mode',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: selectedServiceId == null
                              ? const Color(0xFFBDBDBD)
                              : const Color(0xFF6E4B3A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: serviceModeTabs.map((tab) {
                          final isSelected = selectedSubtype == tab;
                          final isAvailable = selectedServiceId != null &&
                              availableServiceModes.contains(tab.toLowerCase());

                          return Expanded(
                            child: GestureDetector(
                              onTap: !isAvailable
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedSubtype = tab;

                                        if (tab != 'Home Service' &&
                                            tab != 'Home Training') {
                                          furrentAddress = '';
                                        }
                                      });
                                    },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isAvailable
                                      ? Colors.grey[200]
                                      : isSelected
                                          ? const Color(0xFF6E4B3A)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: !isAvailable
                                        ? Colors.grey
                                        : const Color(0xFF6E4B3A),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  tab,
                                  style: GoogleFonts.dosis(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: !isAvailable
                                        ? Colors.grey
                                        : isSelected
                                            ? const Color(0xFFDDC7A9)
                                            : const Color(0xFF6E4B3A),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      if (selectedSubtype == 'Home Service' ||
                          selectedSubtype == 'Home Training')
                        GestureDetector(
                          onTap: _pickFurrentAddress,
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF6E4B3A),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF6E4B3A),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    furrentAddress.isNotEmpty
                                        ? furrentAddress
                                        : 'Enter customer address',
                                    style: GoogleFonts.dosis(
                                      color: furrentAddress.isNotEmpty
                                          ? const Color(0xFF6E4B3A)
                                          : const Color(0xFFBDBDBD),
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFF6E4B3A),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Date',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6E4B3A),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedDate == null
                                  ? ''
                                  : selectedEndDate == null
                                      ? '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}'
                                      : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year} - ${selectedEndDate!.month}/${selectedEndDate!.day}/${selectedEndDate!.year}',
                              style: GoogleFonts.dosis(
                                fontSize: 16,
                                color: selectedDate == null
                                    ? const Color(0xFFBDBDBD)
                                    : const Color(0xFF6E4B3A),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6E4B3A),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Time',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ---- CHANGED: was _TimeSegmentInput, now a slot grid ----
                    _buildTimeSlots(),
                    const SizedBox(height: 20),
                    Text(
                      'Notes',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      onTap: () => _openOnly('none'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        color: const Color(0xFF6E4B3A),
                      ),
                      decoration: InputDecoration(
                        hintStyle: GoogleFonts.dosis(
                          color: const Color(0xFFBDBDBD),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6E4B3A),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6E4B3A),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : _saveBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6E4B3A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFDDC7A9),
                                  ),
                                )
                              : Text(
                                  'Book Now',
                                  style: GoogleFonts.dosis(
                                    color: const Color(0xFFDDC7A9),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sourceButton(String source) {
    final selected = bookingSource == source;

    return GestureDetector(
      onTap: () {
        _openOnly('none');

        setState(() {
          bookingSource = source;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF6E4B3A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6E4B3A),
          ),
        ),
        child: Center(
          child: Text(
            source,
            style: GoogleFonts.dosis(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  selected ? const Color(0xFFDDC7A9) : const Color(0xFF6E4B3A),
            ),
          ),
        ),
      ),
    );
  }
}
