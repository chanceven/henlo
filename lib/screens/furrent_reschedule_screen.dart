import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FurrentRescheduleScreen extends StatefulWidget {
  final String bookingId;
  final String pawtnerId;
  final String serviceId;
  final String petId;

  const FurrentRescheduleScreen({
    super.key,
    required this.bookingId,
    required this.pawtnerId,
    required this.serviceId,
    required this.petId,
  });

  @override
  State<FurrentRescheduleScreen> createState() =>
      _FurrentRescheduleScreenState();
}

class _FurrentRescheduleScreenState extends State<FurrentRescheduleScreen> {
  final supabase = Supabase.instance.client;

  DateTime selectedDate = DateTime.now();
  DateTime? selectedEndDate;
  bool isBoardingService = false;
  double servicePrice = 0;
  int boardingDays = 0;
  double totalPrice = 0;
  String serviceName = '';
  String petName = '';
  String pawtnerName = '';
  List<TimeOfDay> availableTimes = [];
  TimeOfDay? selectedTime;

  List<String> subtypeTabs = [];
  String selectedSubtype = '';
  String furrentAddress = '';
  String pawtnerAddress = '';
  String pawtnerCity = '';
  String notes = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _loadBookingDates() async {

  final booking = await supabase
      .from('bookings')
      .select('scheduled_start, scheduled_end')
      .eq('id', widget.bookingId)
      .maybeSingle();

  if (booking != null) {
    final start =
        DateTime.parse(booking['scheduled_start']);
    selectedDate = start;
    if (booking['scheduled_end'] != null) {
      selectedEndDate =
          DateTime.parse(booking['scheduled_end']);
    }
  }
}

  Future<void> _initData() async {
    try {
      await _loadBookingDates();
      await _loadServiceSubtypes();
      await _loadPawtnerAddress();
      await _loadPawtnerName();
      await _loadPetName();
      await _loadAvailableTimes(selectedDate);
    } catch (e) {
      debugPrint('Error initializing reschedule screen: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadServiceSubtypes() async {
    try {
      final response = await supabase
          .from('services')
          .select('service_type, service_subtype, price, service_name')
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
            (s) => s.toLowerCase() == subtype.toLowerCase(),
            orElse: () => subtypeTabs.first);
      }
    } catch (e) {
      debugPrint('Error loading subtypes: $e');
    }
  }

  Future<void> _loadPawtnerAddress() async {
    try {
      final response = await supabase
          .from('pawtners')
          .select('business_address, city')
          .eq('id', widget.pawtnerId)
          .maybeSingle();
      if (response != null) {
        pawtnerAddress = response['business_address'] as String? ?? '';
        pawtnerCity = response['city'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading pawtner address: $e');
    }
  }

  Future<void> _loadPawtnerName() async {
    try {
      final response = await supabase
          .from('pawtners')
          .select('business_name, full_name')
          .eq('id', widget.pawtnerId)
          .maybeSingle();
      if (response != null) {
        pawtnerName =
            response['business_name'] ??
            response['full_name'] ??
            '';
      }
    } catch (e) {
      debugPrint('Error loading pawtner name: $e');
    }
  }

  Future<void> _loadPetName() async {
    try {
      final response = await supabase
          .from('pets')
          .select('name')
          .eq('id', widget.petId)
          .maybeSingle();
      if (response != null) {
        petName = response['name'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading pet name: $e');
    }
  }

  Future<void> _loadAvailableTimes(DateTime date) async {
    try {
      const dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
      final dayOfWeek = dayNames[date.weekday % 7];

      final response = await supabase
          .from('service_availability')
          .select('start_time, end_time')
          .eq('service_id', widget.serviceId)
          .eq('day_of_week', dayOfWeek);

      final availList = (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      List<TimeOfDay> slots = [];

      for (var row in availList) {
        final startParts = (row['start_time'] as String).split(':');
        final endParts = (row['end_time'] as String).split(':');

        TimeOfDay current = TimeOfDay(
            hour: int.parse(startParts[0]),
            minute: int.parse(startParts[1]));
        final end = TimeOfDay(
            hour: int.parse(endParts[0]),
            minute: int.parse(endParts[1]));

        while (_timeToDouble(current) < _timeToDouble(end)) {
          slots.add(current);
          current = _addMinutes(current, 30);
        }
      }

      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        slots = slots.where((t) {
          final slotDt = DateTime(date.year, date.month, date.day, t.hour, t.minute);
          return slotDt.isAfter(now);
        }).toList();
      }

      setState(() => availableTimes = slots);
    } catch (e) {
      debugPrint('Error loading available times: $e');
      setState(() => availableTimes = []);
    }
  }

  double _timeToDouble(TimeOfDay t) => t.hour + t.minute / 60.0;

  TimeOfDay _addMinutes(TimeOfDay t, int m) {
    final totalMins = t.hour * 60 + t.minute + m;
    return TimeOfDay(hour: totalMins ~/ 60, minute: totalMins % 60);
  }

  void _onSelectDate(DateTime date) {

    if (date.isBefore(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day))) return;

    if (!isBoardingService) {
      setState(() => selectedDate = date);
      _loadAvailableTimes(date);
      return;
    }

    if (selectedEndDate == null && date.isAfter(selectedDate)) {

      setState(() {
        selectedEndDate = date;

        boardingDays =
            selectedEndDate!.difference(selectedDate).inDays;

        totalPrice = servicePrice * boardingDays;
      });

    } else {

      setState(() {
        selectedDate = date;
        selectedEndDate = null;

        boardingDays = 0;
        totalPrice = 0;
      });

    }

    _loadAvailableTimes(date);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)), onPressed: () => Navigator.pop(context)),
        title: Text('Reschedule Appointment', style: GoogleFonts.dosis(fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceSubtypeTabs(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Select Date', style: TextStyle(color: Color(0xFF6E4B3A), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              _buildCalendar(),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('Select Time', style: TextStyle(color: Color(0xFF6E4B3A), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              _buildTimeSlots(),
              const SizedBox(height: 16),
              TextField(
                style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
                decoration: InputDecoration(
                  hintText: 'Notes to Pawtner',
                  hintStyle: GoogleFonts.dosis(
                    color: const Color(0xFF6E4B3A),
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
                      color: Color(0xFF6E4B3A),
                      width: 1.5,
                    ),
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                onChanged: (value) => notes = value,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6E4B3A), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
onPressed: selectedTime != null &&
(!isBoardingService || selectedEndDate != null) &&
(!(selectedSubtype == 'Home Service' ||
   selectedSubtype == 'Home Training') ||
 furrentAddress.isNotEmpty)
? () async {

    try {

      final scheduledStart = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      DateTime? scheduledEnd;

      if (isBoardingService && selectedEndDate != null) {

        scheduledEnd = DateTime(
          selectedEndDate!.year,
          selectedEndDate!.month,
          selectedEndDate!.day,
          selectedTime!.hour,
          selectedTime!.minute,
        );

      }

      String location;

      if (selectedSubtype == 'Pet Shop' ||
          selectedSubtype == 'Pet Hotel' ||
          selectedSubtype == 'Home Boarding' ||
          selectedSubtype == 'Training Center') {

        location = "$pawtnerAddress, $pawtnerCity";

      } else {
        location = furrentAddress;
      }

      final confirm = await _showConfirmBookingModal(
        serviceName: serviceName,
        pawtnerName: pawtnerName,
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

      if (confirm != true) return;

      await supabase
          .from('bookings')
          .update({

        'scheduled_start':
            scheduledStart.toIso8601String(),

        'scheduled_end':
            scheduledEnd?.toIso8601String(),

        'furrent_address':
            (selectedSubtype == 'Home Service' ||
             selectedSubtype == 'Home Training')
                ? furrentAddress
                : null,

        'notes': notes,

        'chosen_service_subtype': selectedSubtype,

      })
      .eq('id', widget.bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking rescheduled 🐾'),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reschedule failed: $e'),
        ),
      );

    }

}
: null,
                  child: Text('Reschedule', style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9), fontWeight: FontWeight.w600, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS COPIED FROM BOOK APPOINTMENT ---

  Widget _buildServiceSubtypeTabs() {
    if (subtypeTabs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: subtypeTabs.map((tab) {
            final isSelected = selectedSubtype == tab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => selectedSubtype = tab),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6E4B3A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF6E4B3A)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    tab,
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFFDDC7A9) : const Color(0xFF6E4B3A),
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
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
            child: Text(
              pawtnerAddress.isNotEmpty
                  ? 'Location: $pawtnerAddress, $pawtnerCity'
                  : 'Loading address...',
              style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        if (selectedSubtype == 'Home Service' || selectedSubtype == 'Home Training')
          TextField(
            style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Enter your address',
              hintStyle: GoogleFonts.dosis(
                color: const Color(0xFF6E4B3A),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6E4B3A)),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF6E4B3A),
                  width: 1.5,
                ),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 1,
            onChanged: (value) => furrentAddress = value,
          ),
      ],
    );
  }

  Widget _buildCalendar() {

    DateTime firstOfMonth =
        DateTime(selectedDate.year, selectedDate.month, 1);

    int startingWeekday = firstOfMonth.weekday % 7;

    int daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < startingWeekday; i++) {
      dayWidgets.add(Container());
    }

    for (int day = 1; day <= daysInMonth; day++) {

      DateTime current =
          DateTime(selectedDate.year, selectedDate.month, day);

      bool isPast = current.isBefore(
          DateTime(DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day));

      bool isStart =
          selectedDate.day == day &&
          selectedDate.month == current.month &&
          selectedDate.year == current.year;

      bool isEnd =
          selectedEndDate != null &&
          selectedEndDate!.day == day &&
          selectedEndDate!.month == current.month &&
          selectedEndDate!.year == current.year;

      bool isInRange =
          selectedEndDate != null &&
          current.isAfter(selectedDate) &&
          current.isBefore(selectedEndDate!);

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _onSelectDate(current),
          child: Container(
            alignment: Alignment.center,
            decoration: isStart || isEnd
                ? const BoxDecoration(
                    color: Color(0xFF6E4B3A),
                    shape: BoxShape.circle,
                  )
                : isInRange
                    ? BoxDecoration(
                        color: const Color(0xFF6E4B3A)
                            .withOpacity(0.2),
                        shape: BoxShape.circle,
                      )
                    : null,
            child: Text(
              '$day',
              style: GoogleFonts.dosis(
                fontSize: 16,
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
      );
    }

    while (dayWidgets.length % 7 != 0) {
      dayWidgets.add(Container());
    }

    List<TableRow> rows = [];

    rows.add(
      TableRow(
        children: ['Su','Mo','Tu','We','Th','Fr','Sa']
            .map(
              (d) => Container(
                height: 40,
                alignment: Alignment.center,
                child: Text(
                  d,
                  style: GoogleFonts.dosis(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
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
          children: dayWidgets
              .sublist(i, i + 7)
              .map(
                (w) => Container(
                  height: 40,
                  alignment: Alignment.center,
                  child: w,
                ),
              )
              .toList(),
        ),
      );
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
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [

                Text(
                  "${_monthName(selectedDate.month)} ${selectedDate.year}",
                  style: GoogleFonts.dosis(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),

                Row(
                  children: [

                    GestureDetector(
                      onTap: () {
                        final now = DateTime.now();

                        final prevMonth = DateTime(
                            selectedDate.year,
                            selectedDate.month - 1,
                            1);

                        setState(() {

                          if (prevMonth.year == now.year &&
                              prevMonth.month == now.month) {

                            selectedDate = DateTime(
                                now.year,
                                now.month,
                                now.day);

                          } else {

                            selectedDate = prevMonth;

                          }

                        });

                        _loadAvailableTimes(selectedDate);
                      },
                      child: const Text(
                        "<",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6E4B3A),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    GestureDetector(
                      onTap: () {
                        setState(() {

                          selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month + 1,
                              1);

                        });

                        _loadAvailableTimes(selectedDate);
                      },
                      child: const Text(
                        ">",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6E4B3A),
                        ),
                      ),
                    ),

                  ],
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

  Widget _buildTimeSlots() {
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
      height: 200,
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
                onTap: () => setState(() => selectedTime = time),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6E4B3A) : null,
                    border: Border.all(color: const Color(0xFF6E4B3A)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(time.format(context), style: GoogleFonts.dosis(color: isSelected ? Colors.white : const Color(0xFF6E4B3A), fontWeight: FontWeight.w600)),
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
                  ),
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
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white),
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

  String _monthName(int month) {
    const names = ['', 'January','February','March','April','May','June','July','August','September','October','November','December'];
    return names[month];
  }
}
