import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'pawtner_bookings_screen.dart';
import 'pawtner_messages_screen.dart';
import 'pawtner_profile_screen.dart';
import 'pawtner_booking_detail_screen.dart';

class PawtnerDashboardScreen extends StatefulWidget {
  const PawtnerDashboardScreen({super.key});

  @override
  State<PawtnerDashboardScreen> createState() =>
      _PawtnerDashboardScreenState();
}

class _PawtnerDashboardScreenState extends State<PawtnerDashboardScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? pawtnerData;
  List<Map<String, dynamic>> bookingsToday = [];
  List<Map<String, dynamic>> bookingsUpcoming = [];
  double? pawtnerRating;

  int _selectedNavIndex = 0;

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
    supabase.removeChannel(_bookingsChannel);
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final pawtner = await supabase
          .from('pawtners')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toUtc();
      final todayEnd = todayStart.add(const Duration(days: 1)).toUtc();

      final todayBookingsQuery = await supabase
        .from('bookings')
        .select('*, pets(type, name, profile_picture_url), services(service_name, service_type), furrents(*)')
        .eq('pawtner_id', user.id)
        .eq('status', 'Upcoming')
        .gte('scheduled_start', todayStart.toIso8601String())
        .lt('scheduled_start', todayEnd.toIso8601String())
        .order('scheduled_start', ascending: true);

      final todayBookings = (todayBookingsQuery as List)
          .map((b) => b as Map<String, dynamic>)
          .toList();

      final upcomingBookingsQuery = await supabase
        .from('bookings')
        .select('*, pets(type, name, profile_picture_url), services(service_name, service_type), furrents(*)')
        .eq('pawtner_id', user.id)
        .eq('status', 'Upcoming')
        .gte('scheduled_start', todayEnd.toIso8601String())
        .order('scheduled_start', ascending: true);

      final upcomingBookings = (upcomingBookingsQuery as List)
          .map((b) => b as Map<String, dynamic>)
          .toList();

      setState(() {
        pawtnerData = pawtner;
        bookingsToday = todayBookings;
        bookingsUpcoming = upcomingBookings;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
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
            column: 'pawtner_id',
            value: user.id,
          ),
          callback: (payload) async {
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

  Widget _getBody() {
    switch (_selectedNavIndex) {
      case 0:
        return _buildHome();
      case 1:
        return const PawtnerBookingsScreen();
      case 2:
        return const PawtnerMessagesScreen();
      case 3:
        return PawtnerProfileScreen(
          onProfileUpdated: () {
            _loadData();
          },
        );
      default:
        return _buildHome();
    }
  }

  bool isServiceActive(String serviceType) {
    final typeOfServiceRaw = pawtnerData?['type_of_service'];
    if (typeOfServiceRaw == null) return false;

    List<String> services = [];

    if (typeOfServiceRaw is List) {
      services = typeOfServiceRaw.map((s) => s.toString()).toList();
    } else if (typeOfServiceRaw is String) {
      services = typeOfServiceRaw.split(',').map((s) => s.trim()).toList();
    }

    return services.contains(serviceType);
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = Colors.black}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
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
                  customText(
                    'Hi, ${pawtnerData?['full_name']?.split(' ').first ?? ''}',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6E4B3A),
                  ),
                  const SizedBox(height: 16),
                  customText('Today\'s Bookings',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A)),
                  const SizedBox(height: 12),
                  bookingsToday.isEmpty
                      ? customText('No bookings for today.', 
                      fontSize: 16, color: const Color(0xFFAAAAAA))
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: bookingsToday.length,
                          itemBuilder: (context, index) {
                            final booking = bookingsToday[index];
                            final pet = booking['pets'] as Map<String, dynamic>?;
                            final service = booking['services'] as Map<String, dynamic>?;

                            final scheduledStart =
                                DateTime.tryParse(booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a').format(scheduledStart)
                                : '';

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
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
                                      color: const Color(0xFFDDC7A9),
                                      image: pet?['profile_picture_url'] != null
                                          ? DecorationImage(
                                              image: NetworkImage(pet?['profile_picture_url']),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: pet?['profile_picture_url'] == null
                                        ? const Icon(Icons.pets,
                                            color: Color(0xFF6E4B3A), size: 40)
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
                                                    builder: (_) => PawtnerBookingDetailsScreen(
                                                      booking: booking,
                                                    ),
                                                  ),
                                                );

                                                if (result == true) {
                                                  _loadData();
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(0, 0),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                "View Details",
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
                  const SizedBox(height: 24),
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
                              final pet = booking['pets'] as Map<String, dynamic>?;
                              final service = booking['services'] as Map<String, dynamic>?;

                              final scheduledStart =
                                  DateTime.tryParse(booking['scheduled_start'] ?? '');
                              final formattedDate = scheduledStart != null
                                  ? DateFormat('MMM d, h:mm a').format(scheduledStart)
                                  : '';

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                        color: const Color(0xFFDDC7A9),
                                        image: pet?['profile_picture_url'] != null
                                            ? DecorationImage(
                                                image: NetworkImage(pet!['profile_picture_url']),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: pet?['profile_picture_url'] == null
                                          ? const Icon(Icons.pets,
                                              color: Color(0xFF6E4B3A), size: 40)
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
                                                      builder: (_) => PawtnerBookingDetailsScreen(
                                                        booking: booking,
                                                      ),
                                                    ),
                                                  );

                                                  if (result == true) {
                                                    _loadData();
                                                  }
                                                },
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(0, 0),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  "View Details",
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
                ],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _getBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTapped,
        selectedItemColor: const Color(0xFF6E4B3A),
        unselectedItemColor: const Color(0xFFBBBBBB),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
