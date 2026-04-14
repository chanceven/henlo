import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pawtner_booking_detail_screen.dart';

class PawtnerBookingsScreen extends StatefulWidget {
  const PawtnerBookingsScreen({super.key});

  @override
  State<PawtnerBookingsScreen> createState() => _PawtnerBookingsScreenState();
}

class _PawtnerBookingsScreenState extends State<PawtnerBookingsScreen> {
  final supabase = Supabase.instance.client;

  bool isLoading = true;
  List<Map<String, dynamic>> upcomingBookings = [];
  List<Map<String, dynamic>> completedBookings = [];
  List<Map<String, dynamic>> cancelledBookings = [];
  List<Map<String, dynamic>> missedBookings = [];

  int selectedTabIndex = 0; // 0: Upcoming, 1: Completed, 2: Cancelled, 3: Missed

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final now = DateTime.now();

      final bookingsQuery = await supabase
          .from('bookings')
          .select(
            '''
            *,
            pets(type, name, profile_picture_url),
            services(service_type, service_name)
            '''
          )
          .eq('pawtner_id', user.id)
          .order('scheduled_start', ascending: true);

      final upcoming = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];
      final cancelled = <Map<String, dynamic>>[];
      final missed = <Map<String, dynamic>>[];

      for (var b in bookingsQuery as List) {
        final booking = b as Map<String, dynamic>;
        final scheduledStart = DateTime.tryParse(booking['scheduled_start'] ?? '') ?? now;
        final status = (booking['status'] ?? '').toString().toLowerCase();

        if (status == 'cancelled') {
          cancelled.add(booking);
        } else if (status == 'missed') {
          missed.add(booking);
        } else {
          final today = DateTime(now.year, now.month, now.day);
          final bookingDate = DateTime(scheduledStart.year, scheduledStart.month, scheduledStart.day);

          if (bookingDate.isAtSameMomentAs(today) || bookingDate.isAfter(today)) {
            booking['status'] = 'Upcoming';
            upcoming.add(booking);
          } else {
            booking['status'] = 'Completed';
            completed.add(booking);
          }
        }
      }

      // Sort upcoming by ascending (earliest first) — optional, already sorted
      upcoming.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduled_start'] ?? '') ?? now;
        final dateB = DateTime.tryParse(b['scheduled_start'] ?? '') ?? now;
        return dateA.compareTo(dateB);
      });

      // Sort Completed, Cancelled, Missed by descending (latest first)
      completed.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduled_start'] ?? '') ?? now;
        final dateB = DateTime.tryParse(b['scheduled_start'] ?? '') ?? now;
        return dateB.compareTo(dateA); // latest first
      });

      cancelled.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduled_start'] ?? '') ?? now;
        final dateB = DateTime.tryParse(b['scheduled_start'] ?? '') ?? now;
        return dateB.compareTo(dateA);
      });

      missed.sort((a, b) {
        final dateA = DateTime.tryParse(a['scheduled_start'] ?? '') ?? now;
        final dateB = DateTime.tryParse(b['scheduled_start'] ?? '') ?? now;
        return dateB.compareTo(dateA);
      });

      setState(() {
        upcomingBookings = upcoming;
        completedBookings = completed;
        cancelledBookings = cancelled;
        missedBookings = missed;
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
        textStyle: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
      textAlign: textAlign,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Upcoming', 'Completed', 'Cancelled', 'Missed'];

    List<Map<String, dynamic>> bookingsToShow;
    switch (selectedTabIndex) {
      case 1:
        bookingsToShow = completedBookings;
        break;
      case 2:
        bookingsToShow = cancelledBookings;
        break;
      case 3:
        bookingsToShow = missedBookings;
        break;
      default:
        bookingsToShow = upcomingBookings;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
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
        automaticallyImplyLeading: false,
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
                        onTap: () => setState(() => selectedTabIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFDDC7A9)
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
                                color: const Color(0xFF6E4B3A),
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
                          child: customText('No bookings', fontSize: 16, color: const Color(0xFF6E4B3A)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bookingsToShow.length,
                          itemBuilder: (context, index) {
                            final booking = bookingsToShow[index];
                            final pet = booking['pets'] as Map<String, dynamic>?;
                            final service = booking['services'] as Map<String, dynamic>?;

                            final scheduledStart = DateTime.tryParse(booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a').format(scheduledStart)
                                : '';

                            return Container(
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
                                      color: const Color(0xFFDDC7A9),
                                      image: pet?['profile_picture_url'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(pet!['profile_picture_url']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: pet?['profile_picture_url'] == null
                                        ? const Icon(Icons.pets, color: Color(0xFF6E4B3A), size: 40)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        customText(
                                          service?['service_type'] ?? '',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E4B3A),
                                        ),
                                        const SizedBox(height: 4),
                                        customText(
                                          service?['service_name'] ?? '',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6E4B3A),
                                        ),
                                        const SizedBox(height: 4),
                                        customText(
                                          '${pet?['type'] ?? ''} • ${pet?['name'] ?? ''}',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6E4B3A),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            customText(
                                              formattedDate,
                                              fontSize: 14, 
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        PawtnerBookingDetailsScreen(
                                                            booking: booking),
                                                  ),
                                                );

                                                if (result == true) {
                                                  _loadBookings();
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize:
                                                    MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'View Details',
                                                style: GoogleFonts.dosis(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF6E4B3A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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