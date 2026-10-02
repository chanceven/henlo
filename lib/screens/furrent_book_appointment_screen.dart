import 'dart:async';
import 'package:flutter/material.dart';
import '../places_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FurrentBookAppointmentScreen extends StatefulWidget {
  final String pawtnerId;
  final String serviceId;
  final String petId;
  final String pawtnerName;

  const FurrentBookAppointmentScreen({
    super.key,
    required this.pawtnerId,
    required this.serviceId,
    required this.petId,
    required this.pawtnerName,
  });

  @override
  State<FurrentBookAppointmentScreen> createState() =>
      _FurrentBookAppointmentScreenState();
}

class _FurrentBookAppointmentScreenState
    extends State<FurrentBookAppointmentScreen> {
  final supabase = Supabase.instance.client;

  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  DateTime calendarMonth = DateTime.now();
  bool _boardingStartPicked = false;
  DateTime? selectedEndDate;
  bool isBoardingService = false;
  double servicePrice = 0;
  int serviceDurationMinutes = 60;
  int boardingDays = 0;
  double totalPrice = 0;
  String serviceName = '';
  String petName = '';
  List<TimeOfDay> availableTimes = [];
  TimeOfDay? selectedTime;

  List<String> subtypeTabs = [];
  String selectedSubtype = '';
  String furrentAddress = '';
  String pawtnerAddress = '';

  final TextEditingController notesController = TextEditingController();

  int maxBookingsPerSlot = 1;
  bool isSaving = false;
  int _timesSeq = 0;
  bool isLoadingTimes = false;
  bool pawtnerAddressLoaded = false;

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dosis(
            color: const Color(0xFFDDC7A9),
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPawtnerAddress();
    _loadPetName();
    // Load the service first: slot capacity depends on its duration and max bookings.
    _loadServiceSubtypes().then((_) {
      if (mounted) _loadAvailableTimes(selectedDate);
    });
  }

  Future<void> _loadServiceSubtypes() async {
    try {
      final response = await supabase
          .from('services')
          .select(
              'service_type, service_subtype, price, service_name, duration_minutes, max_bookings_per_slot')
          .eq('id', widget.serviceId)
          .maybeSingle();

      if (response != null) {
        final serviceType = response['service_type'] as String;
        if (serviceType.toLowerCase() == 'boarding') {
          isBoardingService = true;
        }
        final subtype = response['service_subtype'] as String;
        servicePrice = (response['price'] ?? 0).toDouble();
        serviceName = response['service_name'] ?? '';
        serviceDurationMinutes = (response['duration_minutes'] ?? 60) as int;

        maxBookingsPerSlot = (response['max_bookings_per_slot'] ?? 1) as int;

        final subtypeList =
            subtype.split(',').map((s) => s.trim().toLowerCase()).toList();
        _cachedSubtypeList = subtypeList;

        if (serviceType.toLowerCase() == 'grooming') {
          subtypeTabs = ['Pet Shop', 'Home Service'];
        } else if (serviceType.toLowerCase() == 'boarding') {
          subtypeTabs = ['Pet Hotel', 'Home Boarding'];
        } else if (serviceType.toLowerCase() == 'training') {
          subtypeTabs = ['Training Center', 'Home Training'];
        } else {
          subtypeTabs = [subtype];
        }

        selectedSubtype = subtypeTabs.firstWhere(
            (s) => subtypeList.contains(s.toLowerCase()),
            orElse: () => subtypeTabs.first);

        if (!mounted) return;
        setState(() {});
      } else {
        _showToast('Service is no longer available.');
      }
    } catch (e) {
      debugPrint('Error loading subtypes: $e');
      _showToast('Failed to load service details.');
    }
  }

  Future<void> _loadPawtnerAddress() async {
    try {
      final response = await supabase
          .from('pawtners')
          .select('business_address, city')
          .eq('id', widget.pawtnerId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        pawtnerAddress = response?['business_address'] as String? ?? '';
        pawtnerAddressLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading pawtner address: $e');
      if (mounted) setState(() => pawtnerAddressLoaded = true);
    }
  }

  Future<void> _loadPetName() async {
    try {
      final response = await supabase
          .from('pets')
          .select('name')
          .eq('id', widget.petId)
          .maybeSingle();

      if (!mounted) return;
      if (response != null) {
        setState(() => petName = response['name'] ?? '');
      }
    } catch (e) {
      debugPrint('Error loading pet name: $e');
    }
  }

  Future<void> _loadAvailableTimes(DateTime date) async {
    final seq = ++_timesSeq;
    if (mounted) setState(() => isLoadingTimes = true);
    try {
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final dayOfWeek = dayNames[date.weekday % 7];

      final response = await supabase
          .from('service_availability')
          .select('start_time, end_time')
          .eq('service_id', widget.serviceId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      final availList =
          (response as List).map((e) => e as Map<String, dynamic>).toList();

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
              currentMinutes + serviceDurationMinutes <= endMinutes) {
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

        final slotEnd = isBoardingService && selectedEndDate != null
            ? DateTime(
                selectedEndDate!.year,
                selectedEndDate!.month,
                selectedEndDate!.day,
                time.hour,
                time.minute,
              )
            : slotStart.add(Duration(minutes: serviceDurationMinutes));

        final existing = await supabase
            .from('bookings')
            .select('id')
            .eq('pawtner_id', widget.pawtnerId)
            .eq('service_id', widget.serviceId)
            .neq('status', 'Cancelled')
            .lt(
              'scheduled_start',
              slotEnd.toUtc().toIso8601String(),
            )
            .gt(
              'scheduled_end',
              slotStart.toUtc().toIso8601String(),
            );

        if (existing.length < maxBookingsPerSlot) {
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
      _showToast('Failed to load available times.');
    }
  }

  double _timeToDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

  TimeOfDay _addMinutes(TimeOfDay t, int m) {
    final totalMins = t.hour * 60 + t.minute + m;
    return TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60);
  }

  void _onSelectDate(DateTime date) {
    if (date.isBefore(DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day))) {
      return;
    }

    if (!isBoardingService) {
      setState(() => selectedDate = date);
      _loadAvailableTimes(date);
      return;
    }

    if (_boardingStartPicked &&
        selectedEndDate == null &&
        date.isAfter(selectedDate)) {
      setState(() {
        selectedEndDate = date;
        boardingDays = selectedEndDate!.difference(selectedDate).inDays;
        totalPrice = servicePrice * boardingDays;
      });
    } else {
      _boardingStartPicked = true;
      setState(() {
        selectedDate = date;
        selectedEndDate = null;
        boardingDays = 0;
        totalPrice = 0;
      });
    }

    _loadAvailableTimes(selectedDate);
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
                'Enter your address',
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

                            if (!context.mounted || !mounted) return;
                            setState(() {
                              furrentAddress = shortAddress;
                            });

                            Navigator.pop(context);
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

  List<String> _getAvailableSubtypes() {
    return _cachedSubtypeList;
  }

  List<String> _cachedSubtypeList = [];

  Widget _buildServiceSubtypeTabs() {
    if (subtypeTabs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: subtypeTabs.map((tab) {
            final isSelected = selectedSubtype == tab;
            final availableSubtypes = _getAvailableSubtypes();
            final isDisabled = !availableSubtypes.contains(tab.toLowerCase());
            return Expanded(
              child: GestureDetector(
                onTap: isDisabled
                    ? null
                    : () => setState(() => selectedSubtype = tab),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? Colors.grey[200]
                        : isSelected
                            ? const Color(0xFF6E4B3A)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDisabled ? Colors.grey : const Color(0xFF6E4B3A),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab,
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? Colors.grey
                          : isSelected
                              ? const Color(0xFFDDC7A9)
                              : const Color(0xFF6E4B3A),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (selectedSubtype == 'Pet Shop' ||
            selectedSubtype == 'Pet Hotel' ||
            selectedSubtype == 'Home Boarding' ||
            selectedSubtype == 'Training Center')
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              //color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              //border: Border.all(color: const Color(0xFF6E4B3A)),
            ),
            child: Text(
              pawtnerAddress.isNotEmpty
                  ? 'Location: $pawtnerAddress'
                  : (pawtnerAddressLoaded
                      ? 'Location not provided'
                      : 'Loading address...'),
              style: GoogleFonts.dosis(
                color: const Color(0xFF6E4B3A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (selectedSubtype == 'Home Service' ||
            selectedSubtype == 'Home Training')
          GestureDetector(
            onTap: _pickFurrentAddress,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6E4B3A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFF6E4B3A), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      furrentAddress.isNotEmpty
                          ? furrentAddress
                          : 'Enter your address',
                      style: GoogleFonts.dosis(
                        color: furrentAddress.isNotEmpty
                            ? const Color(0xFF6E4B3A)
                            : const Color(0xFFBDBDBD),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF6E4B3A), size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendar() {
    DateTime firstOfMonth =
        DateTime(calendarMonth.year, calendarMonth.month, 1);
    int startingWeekday = firstOfMonth.weekday % 7;
    int daysInMonth =
        DateTime(calendarMonth.year, calendarMonth.month + 1, 0).day;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      DateTime current = DateTime(calendarMonth.year, calendarMonth.month, day);
      bool isPast = current.isBefore(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));
      bool isStart = selectedDate.day == day &&
          selectedDate.month == current.month &&
          selectedDate.year == current.year;

      bool isEnd = selectedEndDate != null &&
          selectedEndDate!.day == day &&
          selectedEndDate!.month == current.month &&
          selectedEndDate!.year == current.year;

      bool isInRange = selectedEndDate != null &&
          current.isAfter(selectedDate) &&
          current.isBefore(selectedEndDate!);

      dayWidgets.add(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isPast ? null : () => _onSelectDate(current),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: isStart || isEnd
                  ? const BoxDecoration(
                      color: Color(0xFF6E4B3A),
                      shape: BoxShape.circle,
                    )
                  : isInRange
                      ? BoxDecoration(
                          color: const Color(0xFF6E4B3A).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        )
                      : null,
              child: Text(
                '$day',
                style: GoogleFonts.dosis(
                  fontSize: 17,
                  color: isPast
                      ? Colors.grey
                      : (isStart || isEnd
                          ? Colors.white
                          : const Color(0xFF6E4B3A)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    while (dayWidgets.length % 7 != 0) {
      dayWidgets.add(Container());
    }

    List<TableRow> rows = [];

    rows.add(TableRow(
      children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
          .map((d) => Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  d,
                  style: GoogleFonts.dosis(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
              ))
          .toList(),
    ));

    for (int i = 0; i < dayWidgets.length; i += 7) {
      rows.add(TableRow(
        children: dayWidgets.sublist(i, i + 7).map((w) {
          return Container(
            height: 40,
            alignment: Alignment.center,
            child: w,
          );
        }).toList(),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF6E4B3A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    final now = DateTime.now();
                    final currentMonth = DateTime(now.year, now.month, 1);
                    final prevMonth = DateTime(
                        calendarMonth.year, calendarMonth.month - 1, 1);
                    if (prevMonth.isBefore(currentMonth)) return;
                    setState(() => calendarMonth = prevMonth);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      "<",
                      style: GoogleFonts.dosis(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "${_monthName(calendarMonth.month)} ${calendarMonth.year}",
                      style: GoogleFonts.dosis(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      calendarMonth = DateTime(
                          calendarMonth.year, calendarMonth.month + 1, 1);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      ">",
                      style: GoogleFonts.dosis(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Table(
            defaultColumnWidth: const FlexColumnWidth(),
            children: rows,
          ),
        ],
      ),
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
      'December'
    ];
    return names[month];
  }

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
                      fontSize: 16,
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

  Future<bool?> _showConfirmBookingModal({
    required String serviceName,
    required String petName,
    required String pawtnerName,
    required String location,
    required String schedule,
    required String time,
    required double total,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Review Booking',
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  serviceName,
                  style: GoogleFonts.dosis(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pawtnerName,
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Pet: $petName",
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Schedule: $schedule",
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Time: $time",
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Total: ₱${total.toStringAsFixed(0)}",
                  style: GoogleFonts.dosis(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6E4B3A),
                  ).copyWith(fontFamilyFallback: const ['Roboto', 'Arial']),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.dosis(
                            color: const Color(0xFFF8F8F8),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E4B3A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          "Confirm",
                          style: GoogleFonts.dosis(
                            color: const Color(0xFFDDC7A9),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Book Appointment',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
              onPressed: selectedTime != null &&
                      !isLoadingTimes &&
                      selectedSubtype.isNotEmpty &&
                      (!isBoardingService || selectedEndDate != null) &&
                      (!(selectedSubtype == 'Home Service' ||
                              selectedSubtype == 'Home Training') ||
                          furrentAddress.isNotEmpty) &&
                      !isSaving
                  ? () async {
                      if (isSaving) return;
                      setState(() => isSaving = true);
                      bool booked = false;
                      try {
                        final currentUser = supabase.auth.currentUser;
                        if (currentUser == null) {
                          _showToast(
                              'Your session expired. Please log in again.');
                          return;
                        }
                        final furrentId = currentUser.id;

                        final furrentResponse = await supabase
                            .from('furrents')
                            .select('full_name')
                            .eq('id', furrentId)
                            .maybeSingle();
                        final furrentName =
                            furrentResponse?['full_name'] as String? ?? '';

                        final scheduledStart = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime!.hour,
                          selectedTime!.minute,
                        );

                        String location;

                        if (selectedSubtype == 'Pet Shop' ||
                            selectedSubtype == 'Pet Hotel' ||
                            selectedSubtype == 'Home Boarding' ||
                            selectedSubtype == 'Training Center') {
                          location = pawtnerAddress;
                        } else {
                          location = furrentAddress;
                        }

                        if (!context.mounted) return;

                        final confirm = await _showConfirmBookingModal(
                          serviceName: serviceName,
                          pawtnerName: widget.pawtnerName,
                          location: location,
                          schedule: isBoardingService && selectedEndDate != null
                              ? (selectedDate.month == selectedEndDate!.month
                                  ? "${DateFormat('MMM d').format(selectedDate)}–${selectedEndDate!.day}, $boardingDays Days"
                                  : "${DateFormat('MMM d').format(selectedDate)}–${DateFormat('MMM d').format(selectedEndDate!)}, $boardingDays Days")
                              : DateFormat('MMM d').format(selectedDate),
                          time: selectedTime!.format(context),
                          petName: petName,
                          total: isBoardingService ? totalPrice : servicePrice,
                        );

                        if (confirm != true || !mounted) return;

                        if (!scheduledStart.isAfter(DateTime.now())) {
                          _showToast(
                              'Selected time has already passed. Please choose a later time.');
                          return;
                        }

                        DateTime? scheduledEnd;

                        if (isBoardingService && selectedEndDate != null) {
                          scheduledEnd = DateTime(
                            selectedEndDate!.year,
                            selectedEndDate!.month,
                            selectedEndDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );
                        } else {
                          scheduledEnd = scheduledStart.add(
                            Duration(minutes: serviceDurationMinutes),
                          );
                        }

                        final conflictCheck = await supabase
                            .from('bookings')
                            .select('id')
                            .eq('pawtner_id', widget.pawtnerId)
                            .eq('service_id', widget.serviceId)
                            .neq('status', 'Cancelled')
                            .lt('scheduled_start',
                                scheduledEnd.toUtc().toIso8601String())
                            .gt('scheduled_end',
                                scheduledStart.toUtc().toIso8601String());

                        if (!mounted) return;
                        if (conflictCheck.length >= maxBookingsPerSlot) {
                          _showToast(
                              'Selected date/time is no longer available.');
                          _loadAvailableTimes(selectedDate);
                          return;
                        }

                        await supabase.from('bookings').insert({
                          'furrent_id': furrentId,
                          'pawtner_id': widget.pawtnerId,
                          'service_id': widget.serviceId,
                          'pet_id': widget.petId,
                          'furrent_name': furrentName,
                          'pawtner_name': widget.pawtnerName,
                          'service_name': serviceName,
                          'pet_name': petName,
                          'price': servicePrice,
                          'scheduled_start':
                              scheduledStart.toUtc().toIso8601String(),
                          'scheduled_end':
                              scheduledEnd.toUtc().toIso8601String(),
                          'furrent_address':
                              (selectedSubtype == 'Home Service' ||
                                      selectedSubtype == 'Home Training')
                                  ? furrentAddress
                                  : null,
                          'status': 'Upcoming',
                          'booking_source': 'App',
                          'notes': notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim(),
                          'chosen_service_subtype': selectedSubtype,
                        });

                        booked = true;
                        _showToast('Booking successful.');

                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        debugPrint('Error creating booking: $e');
                        _showToast(
                            'Failed to create booking. Please try again.');
                      } finally {
                        if (mounted && !booked) {
                          setState(() => isSaving = false);
                        }
                      }
                    }
                  : null,
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFDDC7A9)),
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
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceSubtypeTabs(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Select Date',
                    style: GoogleFonts.dosis(
                      color: const Color(0xFF6E4B3A),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCalendar(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Select Time',
                    style: GoogleFonts.dosis(
                      color: const Color(0xFF6E4B3A),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildTimeSlots(),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
                  decoration: InputDecoration(
                    hintText: 'Notes to Pawtner',
                    hintStyle: GoogleFonts.dosis(
                      color: const Color(0xFFBDBDBD),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF6E4B3A), width: 1.5),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
