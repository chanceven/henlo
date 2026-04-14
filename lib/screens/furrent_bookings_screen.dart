import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'furrent_reschedule_screen.dart';
import 'furrent_booking_detail_screen.dart';

class FurrentBookingsScreen extends StatefulWidget {
  const FurrentBookingsScreen({super.key});

  @override
  State<FurrentBookingsScreen> createState() => _FurrentBookingsScreenState();
}

class _FurrentBookingsScreenState extends State<FurrentBookingsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> upcomingBookings = [];
  List<Map<String, dynamic>> pastBookings = [];

  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final bookingsQuery = await supabase
          .from('bookings')
          .select(
              '*, pets(name), services(service_name, service_type), pawtners(full_name, business_name, profile_picture_url)')
          .eq('furrent_id', user.id)
          .order('scheduled_start', ascending: true);

      final upcoming = <Map<String, dynamic>>[];
      final past = <Map<String, dynamic>>[];

      for (var booking in bookingsQuery as List) {
        final b = booking as Map<String, dynamic>;

        var status = b['status'] as String? ?? 'Upcoming';
        b['status'] = status;

        if (status == 'Upcoming') {
          upcoming.add(b);
        } else {
          past.add(b);
        }
      }

      past.sort((a, b) {
        final aTime = DateTime.tryParse(a['scheduled_start'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['scheduled_start'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime); // descending
      });

      setState(() {
        upcomingBookings = upcoming;
        pastBookings = past;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Oops! Something went wrong. Please try again."),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF000000),
      TextAlign textAlign = TextAlign.center}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle:
            TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Upcoming', 'Past'];
    final bookingsToShow =
        selectedTabIndex == 0 ? upcomingBookings : pastBookings;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Bookings',
          style: GoogleFonts.dosis(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E4B3A),
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedTabIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6E4B3A)
                                : const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              tabs[index],
                              style: GoogleFonts.dosis(
                                fontSize: 18,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? const Color(0xFFDDC7A9)
                                    : const Color(0xFF6E4B3A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: bookingsToShow.isEmpty
                      ? Center(
                          child: Text(
                            'No bookings',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookingsToShow.length,
                          itemBuilder: (context, index) {
                            final booking = bookingsToShow[index];
                            final pet = booking['pets'] as Map<String, dynamic>?;
                            final service = booking['services'] as Map<String, dynamic>?;
                            final pawtner = booking['pawtners'] as Map<String, dynamic>?;

                            final scheduledStart =
                                DateTime.tryParse(booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a').format(scheduledStart)
                                : '';

                            final serviceType = service?['service_type'] ?? '';
                            final businessName = pawtner?['business_name'] ?? '';
                            final profileUrl = pawtner?['profile_picture_url'];

                            final status = booking['status'];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FurrentBookingDetailsScreen(
                                    booking: booking,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFF6E4B3A),
                                      image: profileUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(profileUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profileUrl == null
                                        ? const Icon(Icons.person, color: Color(0xFFDDC7A9), size: 40)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            serviceType,
                                            style: GoogleFonts.dosis(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF6E4B3A)),
                                          ),

                                          if (selectedTabIndex == 1)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: (() {
                                                  if (status == 'Completed') return const Color(0xFF2E7D32);
                                                  if (status == 'Cancelled') return const Color(0xFF8B0000);
                                                  if (status == 'Missed') return const Color(0xFFFFB300);
                                                  return const Color(0xFF6E4B3A);
                                                })(),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                status,
                                                style: GoogleFonts.dosis(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        businessName,
                                        style: GoogleFonts.dosis(
                                            fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6E4B3A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pet: ${pet?['name'] ?? ''}',
                                        style: GoogleFonts.dosis(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6E4B3A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        formattedDate,
                                        style: GoogleFonts.dosis(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF6E4B3A)),
                                      ),
                                      const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      if (selectedTabIndex == 0)
                                        Column(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: const Color(0xFFF8F8F8),
                                                    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
                                                    contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                                                    content: SizedBox(
                                                      height: 140,
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Are you sure you want to cancel this booking?',
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.dosis(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 15,
                                                                color: const Color(0xFF6E4B3A)),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            'This action cannot be undone.',
                                                            textAlign: TextAlign.center,
                                                            style: GoogleFonts.dosis(
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 15,
                                                                color: const Color(0xFF6E4B3A)),
                                                          ),
                                                          const SizedBox(height: 20),
                                                          Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
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
                                                                  onPressed: () => Navigator.pop(context, false),
                                                                  child: Text(
                                                                    'Keep Booking',
                                                                    style: GoogleFonts.dosis(
                                                                      fontWeight: FontWeight.w600,
                                                                      fontSize: 15,
                                                                      color: const Color(0xFFDDC7A9),
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
                                                                    backgroundColor: const Color(0xFF8B0000),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(8),
                                                                    ),
                                                                  ),
                                                                  onPressed: () => Navigator.pop(context, true),
                                                                  child: Text(
                                                                    'Confirm',
                                                                    style: GoogleFonts.dosis(
                                                                      fontWeight: FontWeight.w600,
                                                                      fontSize: 15,
                                                                      color: Colors.white,
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
                                                );

                                                if (confirmed != true) return;

                                                final reasonController = TextEditingController();
                                                final reasonSubmitted = await showDialog<bool>(
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
                                                          children: [
                                                            Text(
                                                              'Why are you cancelling this booking?',
                                                              textAlign: TextAlign.center,
                                                              style: GoogleFonts.dosis(
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 16,
                                                                color: const Color(0xFF6E4B3A),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 12),
                                                            TextField(
                                                              controller: reasonController,
                                                              maxLines: 3,
                                                              decoration: InputDecoration(
                                                                hintText: 'Enter your reason for cancellation',
                                                                hintStyle: GoogleFonts.dosis(
                                                                  fontSize: 14,
                                                                  color: const Color(0xFFAAAAAA),
                                                                ),
                                                                border: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1.5),
                                                                ),
                                                                enabledBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1.5),
                                                                ),
                                                                focusedBorder: OutlineInputBorder(
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
                                                                ),
                                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                              ),
                                                              style: GoogleFonts.dosis(
                                                                fontSize: 14,
                                                                color: const Color(0xFF6E4B3A),
                                                              ),
                                                            ),
                                                            const SizedBox(height: 16),
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
                                                                onPressed: () {
                                                                  if (reasonController.text.trim().isEmpty) return;
                                                                  Navigator.pop(context, true);
                                                                },
                                                                child: Text(
                                                                  'Submit',
                                                                  style: GoogleFonts.dosis(
                                                                    fontWeight: FontWeight.w600,
                                                                    fontSize: 15,
                                                                    color: Colors.white,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );

                                                if (reasonSubmitted != true) return;

                                                final bookingId = booking['id'];
                                                try {
                                                  await supabase.from('bookings').update({
                                                    'status': 'Cancelled',
                                                    'cancelled_reason': reasonController.text.trim(),
                                                    'cancelled_at': DateTime.now().toIso8601String(),
                                                  }).eq('id', bookingId);

                                                  setState(() {
                                                    upcomingBookings.removeWhere((b) => b['id'] == bookingId);
                                                    booking['status'] = 'Cancelled';
                                                    booking['cancelled_reason'] = reasonController.text.trim();
                                                    booking['cancelled_at'] = DateTime.now().toIso8601String();
                                                    pastBookings.insert(0, booking);
                                                  });

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Booking cancelled.')),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Failed to cancel booking.')),
                                                  );
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF8B0000),
                                                minimumSize: const Size(100, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  softWrap: false,
                                                  overflow: TextOverflow.visible,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => FurrentRescheduleScreen(
                                                      bookingId: booking['id'],
                                                      pawtnerId: booking['pawtner_id'],
                                                      serviceId: booking['service_id'],
                                                      petId: booking['pet_id'],
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF6E4B3A),
                                                minimumSize: const Size(100, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                              ),
                                              child: const Align(
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Reschedule',
                                                  style: TextStyle(
                                                    color: Color(0xFFDDC7A9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  softWrap: false,
                                                  overflow: TextOverflow.visible,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
    );
  }
}
