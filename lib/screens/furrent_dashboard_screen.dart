import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'furrent_bookings_screen.dart';
import 'furrent_messages_screen.dart';
import 'furrent_profile_screen.dart';
import 'furrent_grooming_screen.dart';
import 'furrent_boarding_screen.dart';
import 'furrent_training_screen.dart';
import 'furrent_reschedule_screen.dart';
import 'furrent_booking_detail_screen.dart';

class FurrentDashboardScreen extends StatefulWidget {
  const FurrentDashboardScreen({super.key});

  @override
  State<FurrentDashboardScreen> createState() => _FurrentDashboardScreenState();
}

class _FurrentDashboardScreenState extends State<FurrentDashboardScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? furrentData;
  List<Map<String, dynamic>> bookingsUpcoming = [];
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> mainServices = [
    {'service_name': 'Grooming', 'service_type': 'grooming'},
    {'service_name': 'Boarding', 'service_type': 'boarding'},
    {'service_name': 'Training', 'service_type': 'training'},
  ];

  late RealtimeChannel _bookingsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtimeBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    supabase.removeChannel(_bookingsChannel);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final furrent = await supabase
          .from('furrents')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      final now = DateTime.now();

      final bookingsQuery = await supabase
          .from('bookings')
          .select(
              '*, pets(name), services(service_name, service_type), pawtners(full_name, business_name, profile_picture_url)')
          .eq('furrent_id', user.id)
          .eq('status', 'Upcoming')
          .gt('scheduled_start', now.toIso8601String())
          .order('scheduled_start', ascending: true);

      final bookingsList = (bookingsQuery as List)
          .map((b) => b as Map<String, dynamic>)
          .toList();

      setState(() {
        furrentData = furrent;
        bookingsUpcoming = bookingsList;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading furrent dashboard: $e');
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

void _setupRealtimeBookings() {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  _bookingsChannel = supabase
      .channel('bookings-${user.id}')
      .onPostgresChanges(
        schema: 'public',
        table: 'bookings',
        event: PostgresChangeEvent.all,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'furrent_id',
          value: user.id,
        ),
        callback: (payload) async {
          debugPrint('Realtime booking change detected');

          // VERY IMPORTANT — wait for DB commit + joins
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            _loadData();
          }
        },
      )
      .subscribe();
}

  void _onNavTapped(int index) {
    setState(() => _selectedNavIndex = index);
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF000000),
      TextAlign textAlign = TextAlign.center}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle: TextStyle(
            fontSize: fontSize, fontWeight: fontWeight, color: color),
      ),
      textAlign: textAlign,
    );
  }

  IconData _iconForService(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'grooming':
        return Icons.content_cut;
      case 'boarding':
        return Icons.home;
      case 'training':
        return Icons.fitness_center;
      default:
        return Icons.pets;
    }
  }

  Widget _buildServiceButton(String service, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (service.toLowerCase() == 'grooming') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FurrentGroomingScreen()));
        } else if (service.toLowerCase() == 'boarding') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FurrentBoardingScreen()));
        } else if (service.toLowerCase() == 'training') {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const FurrentTrainingScreen()));
        }
      },
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6E4B3A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFFDDC7A9), size: 40),
            ),
          ),
          const SizedBox(height: 8),
          customText(service,
              fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE6E6E6)),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 4,
                            offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/search');
                            },
                            child: const AbsorbPointer(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search for services or pawtners',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFAAAAAA),
                                    fontSize: 16,
                                  ),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  customText('Services Offered',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: mainServices.map((s) {
                      final name = s['service_name'] ?? '';
                      final type = s['service_type'] ?? '';
                      return _buildServiceButton(name, _iconForService(type));
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  customText('Upcoming Bookings',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A)),
                  const SizedBox(height: 12),
                  bookingsUpcoming.isEmpty
                      ? customText('No upcoming bookings.',
                          fontSize: 16, color: const Color(0xFFAAAAAA))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: bookingsUpcoming.length,
                          itemBuilder: (context, index) {
                            final booking = bookingsUpcoming[index];
                            final pet =
                                booking['pets'] as Map<String, dynamic>?;
                            final service =
                                booking['services'] as Map<String, dynamic>?;
                            final pawtner =
                                booking['pawtners'] as Map<String, dynamic>?;

                            final scheduledStart = DateTime.tryParse(
                                booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a')
                                    .format(scheduledStart)
                                : '';

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
                                          offset: Offset(0, 2))
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
                                          image: pawtner?['profile_picture_url'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(pawtner!['profile_picture_url']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: pawtner?['profile_picture_url'] == null
                                            ? const Icon(Icons.person, color: Color(0xFFDDC7A9), size: 40)
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
                                            const SizedBox(height: 2),
                                            customText(
                                              pawtner?['business_name'] ?? '',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                            const SizedBox(height: 2),
                                            customText(
                                              'Pet: ${pet?['name'] ?? ''}',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                            const SizedBox(height: 2),
                                            customText(
                                              formattedDate,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                                                borderSide: const BorderSide(
                                                                    color: Color(0xFF6E4B3A), width: 1.5),
                                                              ),
                                                              enabledBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: const BorderSide(
                                                                    color: Color(0xFF6E4B3A), width: 1.5),
                                                              ),
                                                              focusedBorder: OutlineInputBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                                borderSide: const BorderSide(
                                                                    color: Color(0xFF6E4B3A), width: 2),
                                                              ),
                                                              contentPadding: const EdgeInsets.symmetric(
                                                                  horizontal: 12, vertical: 8),
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
                                                  bookingsUpcoming.removeWhere((b) => b['id'] == bookingId);
                                                  booking['status'] = 'Cancelled';
                                                  booking['cancelled_reason'] = reasonController.text.trim();
                                                  booking['cancelled_at'] = DateTime.now().toIso8601String();
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
                                ),
                              );
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    Widget getBody() {
      switch (_selectedNavIndex) {
        case 0:
          return _buildHome();
        case 1:
          return const FurrentBookingsScreen();
        case 2:
          return const FurrentMessagesScreen();
        case 3:
          return const FurrentProfileScreen();
        default:
          return _buildHome();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTapped,
        selectedItemColor: const Color(0xFF6E4B3A),
        unselectedItemColor: const Color(0xFFBBBBBB),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
