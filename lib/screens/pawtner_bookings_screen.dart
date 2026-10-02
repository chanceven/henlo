import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pawtner_booking_detail_screen.dart';
import 'pawtner_add_booking_screen.dart';

class PawtnerBookingsScreen extends StatefulWidget {
  const PawtnerBookingsScreen({super.key});

  @override
  State<PawtnerBookingsScreen> createState() => _PawtnerBookingsScreenState();
}

class _PawtnerBookingsScreenState extends State<PawtnerBookingsScreen> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _bookingsChannel;

  bool isLoading = true;
  List<Map<String, dynamic>> upcomingBookings = [];
  List<Map<String, dynamic>> completedBookings = [];
  List<Map<String, dynamic>> cancelledBookings = [];
  List<Map<String, dynamic>> missedBookings = [];

  int selectedTabIndex = 0;
  int selectedPastFilter = 0;

  final TextEditingController searchController = TextEditingController();

  String searchQuery = '';
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _setupRealtimeBookings();
  }

  void _setupRealtimeBookings() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _bookingsChannel = supabase
        .channel('pawtner-bookings-${user.id}')
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
            debugPrint('Booking change detected — refreshing bookings');

            await _loadBookings();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_bookingsChannel != null) {
      supabase.removeChannel(_bookingsChannel!);
    }
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final seq = ++_loadSeq;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw 'User not logged in';

      final now = DateTime.now();

      final bookingsQuery = await supabase
          .from('bookings')
          .select('''
            *,
pets(type, name, profile_picture_url),
services(service_type, service_name),
furrents(full_name)
            ''')
          .eq('pawtner_id', user.id)
          .order('scheduled_start', ascending: true);

      final upcoming = <Map<String, dynamic>>[];
      final completed = <Map<String, dynamic>>[];
      final cancelled = <Map<String, dynamic>>[];
      final missed = <Map<String, dynamic>>[];

      for (var b in bookingsQuery as List) {
        final booking = b as Map<String, dynamic>;
        final status = (booking['status'] ?? '').toString().toLowerCase();

        if (status == 'completed') {
          completed.add(booking);
        } else if (status == 'cancelled') {
          cancelled.add(booking);
        } else if (status == 'missed') {
          missed.add(booking);
        } else {
          upcoming.add(booking);
        }
      }

      // Sort upcoming by ascending (earliest first) — optional, already sorted
      upcoming.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['scheduled_start'] ?? '')?.toLocal() ?? now;
        final dateB =
            DateTime.tryParse(b['scheduled_start'] ?? '')?.toLocal() ?? now;
        return dateA.compareTo(dateB);
      });

      // Sort Completed, Cancelled, Missed by descending (latest first)
      completed.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['scheduled_start'] ?? '')?.toLocal() ?? now;
        final dateB =
            DateTime.tryParse(b['scheduled_start'] ?? '')?.toLocal() ?? now;
        return dateB.compareTo(dateA); // latest first
      });

      cancelled.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['scheduled_start'] ?? '')?.toLocal() ?? now;
        final dateB =
            DateTime.tryParse(b['scheduled_start'] ?? '')?.toLocal() ?? now;
        return dateB.compareTo(dateA);
      });

      missed.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['scheduled_start'] ?? '')?.toLocal() ?? now;
        final dateB =
            DateTime.tryParse(b['scheduled_start'] ?? '')?.toLocal() ?? now;
        return dateB.compareTo(dateA);
      });

      if (!mounted || seq != _loadSeq) return;
      setState(() {
        upcomingBookings = upcoming;
        completedBookings = completed;
        cancelledBookings = cancelled;
        missedBookings = missed;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading bookings: $e');
      if (!mounted || seq != _loadSeq) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oops! Something went wrong. Please try again.',
            style: GoogleFonts.dosis(color: const Color(0xFFDDC7A9)),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'Cancelled':
        return const Color(0xFF8B0000);
      case 'Missed':
        return const Color(0xFFFFB300);
      default:
        return const Color(0xFF5C5C5C);
    }
  }

  String _statusLabel(dynamic raw) {
    switch ((raw ?? '').toString().toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'missed':
        return 'Missed';
      default:
        return 'Upcoming';
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

    List<Map<String, dynamic>> bookingsToShow;

    if (selectedTabIndex == 0) {
      bookingsToShow = upcomingBookings;
    } else {
      switch (selectedPastFilter) {
        case 1:
          bookingsToShow = cancelledBookings;
          break;
        case 2:
          bookingsToShow = missedBookings;
          break;
        default:
          bookingsToShow = completedBookings;
      }
    }

    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      final allBookings = [
        ...upcomingBookings,
        ...completedBookings,
        ...cancelledBookings,
        ...missedBookings,
      ];

      bookingsToShow = allBookings.where((booking) {
        final pet = booking['pets'] as Map<String, dynamic>?;

        final service = booking['services'] as Map<String, dynamic>?;

        final furrent = booking['furrents'] as Map<String, dynamic>?;

        final petName = (pet?['name'] ?? '').toString().toLowerCase();

        final serviceName =
            (service?['service_name'] ?? '').toString().toLowerCase();

        final furrentName =
            (furrent?['full_name'] ?? '').toString().toLowerCase();
        final guestName =
            (booking['guest_name'] ?? '').toString().toLowerCase();
        final guestPetName =
            (booking['guest_pet_name'] ?? '').toString().toLowerCase();

        return petName.contains(query) ||
            serviceName.contains(query) ||
            furrentName.contains(query) ||
            guestName.contains(query) ||
            guestPetName.contains(query);
      }).toList();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Column(
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
                  if (selectedTabIndex == 1) ...[
                    Row(
                      children: List.generate(3, (index) {
                        final pastTabs = ['Completed', 'Cancelled', 'Missed'];
                        final isSelected = selectedPastFilter == index;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => selectedPastFilter = index),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF6E4B3A)
                                    : const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  pastTabs[index],
                                  style: GoogleFonts.dosis(
                                    fontSize: 16,
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
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search bookings',
                          hintStyle: GoogleFonts.dosis(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF6E4B3A),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFFFFFF),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: bookingsToShow.isEmpty
                        ? Center(
                            child: customText('No bookings',
                                fontSize: 16, color: const Color(0xFF6E4B3A)),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: bookingsToShow.length,
                            itemBuilder: (context, index) {
                              final booking = bookingsToShow[index];
                              final pet =
                                  booking['pets'] as Map<String, dynamic>?;
                              final service =
                                  booking['services'] as Map<String, dynamic>?;

                              final scheduledStart = DateTime.tryParse(
                                      booking['scheduled_start'] ?? '')
                                  ?.toLocal();
                              final formattedDate = scheduledStart != null
                                  ? DateFormat('MMM d, h:mm a')
                                      .format(scheduledStart)
                                  : '';

                              final petPhotoUrl =
                                  pet?['profile_picture_url']?.toString() ?? '';
                              final statusLabel =
                                  _statusLabel(booking['status']);

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(14),
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
                                        image: petPhotoUrl.isNotEmpty
                                            ? DecorationImage(
                                                image:
                                                    NetworkImage(petPhotoUrl),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: petPhotoUrl.isEmpty
                                          ? const Icon(Icons.pets,
                                              color: Color(0xFF6E4B3A),
                                              size: 40)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: customText(
                                                  service?['service_type'] ??
                                                      '',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFF6E4B3A),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                              if (query.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(
                                                        statusLabel),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    statusLabel,
                                                    style: GoogleFonts.dosis(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 5),
                                          customText(
                                            service?['service_name'] ?? '',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6E4B3A),
                                          ),
                                          const SizedBox(height: 5),
                                          customText(
                                            booking['furrent_id'] == null
                                                ? '${booking['guest_pet_type'] ?? ''} • ${booking['guest_pet_name'] ?? ''}'
                                                : '${pet?['type'] ?? ''} • ${pet?['name'] ?? ''}',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6E4B3A),
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              customText(
                                                formattedDate,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: const Color(0xFF6E4B3A),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  final result =
                                                      await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          PawtnerBookingDetailsScreen(
                                                        booking: booking,
                                                        fromPawtnerBookingsScreen:
                                                            true,
                                                      ),
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
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                                child: Text(
                                                  'View Details',
                                                  style: GoogleFonts.dosis(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        const Color(0xFF6E4B3A),
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
            ),
      bottomNavigationBar: selectedTabIndex == 0
          ? SafeArea(
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
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PawtnerAddBookingScreen(),
                        ),
                      );
                      if (!mounted) return;
                      _loadBookings();
                    },
                    child: Text(
                      'Add Booking',
                      style: GoogleFonts.dosis(
                        color: const Color(0xFFDDC7A9),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
