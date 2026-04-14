import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'furrent_review_screen.dart';
import 'furrent_reschedule_screen.dart';

class FurrentBookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const FurrentBookingDetailsScreen({super.key, required this.booking});

  @override
  State<FurrentBookingDetailsScreen> createState() =>
      _FurrentBookingDetailsScreenState();
}

class _FurrentBookingDetailsScreenState extends State<FurrentBookingDetailsScreen> {
  final supabase = Supabase.instance.client;
  late RealtimeChannel _bookingsChannel;

  @override
  void initState() {
    super.initState();
    _setupRealtimeBooking();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    supabase.removeChannel(_bookingsChannel);
    super.dispose();
  }

  void _setupRealtimeBooking() {
    final bookingId = widget.booking['id'];
    _bookingsChannel = supabase
        .channel('bookings-$bookingId')
        .onPostgresChanges(
          schema: 'public',
          table: 'bookings',
          event: PostgresChangeEvent.all,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: bookingId,
          ),
          callback: (payload) async {
            debugPrint('Realtime booking change detected');
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              await _fetchBookingDetails();
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchBookingDetails() async {
    final bookingId = widget.booking['id'];
    final response = await supabase
        .from('bookings')
        .select('*, pets(*), furrents(*), services(*), pawtners(*)')
        .eq('id', bookingId)
        .maybeSingle();

    if (response != null) {
      setState(() {
        widget.booking.clear();
        widget.booking.addAll(response);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final pet = booking['pets'] as Map<String, dynamic>?;
    final service = booking['services'] as Map<String, dynamic>?;
    final pawtner = booking['pawtners'] as Map<String, dynamic>?;
    final subtype = (booking['chosen_service_subtype'] ?? '').toString();
    final location =
        (subtype.contains('Home Service') || subtype.contains('Home Training'))
            ? booking['furrent_address']
            : "${pawtner?['business_address']}, ${pawtner?['city'] ?? ''}";

    final scheduledStart = DateTime.tryParse(booking['scheduled_start'] ?? '');
    final scheduledEnd = DateTime.tryParse(booking['scheduled_end'] ?? '');

    String formattedSchedule = '-';

    if (scheduledStart != null &&
        scheduledEnd != null &&
        scheduledStart.day != scheduledEnd.day) {

      final time = DateFormat('h:mm a').format(scheduledStart);

      if (scheduledStart.month == scheduledEnd.month) {
        final start = DateFormat('MMM d').format(scheduledStart);
        final end = DateFormat('d').format(scheduledEnd);
        formattedSchedule = "$start-$end, $time";
      } else {
        final start = DateFormat('MMM d').format(scheduledStart);
        final end = DateFormat('MMM d').format(scheduledEnd);
        formattedSchedule = "$start-$end, $time";
      }

    } else if (scheduledStart != null) {

      formattedSchedule = DateFormat('MMM d, h:mm a').format(scheduledStart);

    }

    final cancelledAt = DateTime.tryParse(booking['cancelled_at'] ?? '');
    final formattedCancelledAt = cancelledAt != null
        ? DateFormat('MMM d, h:mm a').format(cancelledAt)
        : '-';

    final completedAt = DateTime.tryParse(booking['completed_at'] ?? '');
    final formattedCompletedAt = completedAt != null
        ? DateFormat('MMM d, h:mm a').format(completedAt)
        : '-';

    final bookingRating = booking['rating'] ?? 0;
    final bookingComment = booking['review_comment'] ?? '-';

    final missedAt = DateTime.tryParse(booking['missed_at'] ?? '');
    final formattedMissedAt = missedAt != null
        ? DateFormat('MMM d, h:mm a').format(missedAt)
        : '-';

    final double price = (service?['price'] ?? 0).toDouble();

    double total = price;

    if (scheduledStart != null && scheduledEnd != null) {
      final days = scheduledEnd.difference(scheduledStart).inDays;
      if (days > 0) {
        total = price * days;
      }
    }

    final status = (booking['status'] ?? 'Upcoming').toString();

    String summaryTitle = '';
    if (status.toLowerCase() == 'completed') summaryTitle = 'Completion Summary';
    if (status.toLowerCase() == 'cancelled') summaryTitle = 'Cancellation Summary';
    if (status.toLowerCase() == 'missed') summaryTitle = 'Missed Summary';

    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'completed':
          return const Color(0xFF2E7D32);
        case 'cancelled':
          return const Color(0xFF8B0000);
        case 'missed':
          return const Color(0xFFFFB300);
        case 'upcoming':
        default:
          return const Color(0xFF5C5C5C);
      }
    }

    String capitalize(String text) {
      if (text.isEmpty) return '';
      return text[0].toUpperCase() + text.substring(1).toLowerCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F8F8),
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDC7A9), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(service?['service_name'] ?? '',
                          style: GoogleFonts.dosis(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6E4B3A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getStatusColor(booking['status'] ?? 'upcoming'),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          capitalize(booking['status'] ?? 'Upcoming'),
                          style: GoogleFonts.dosis(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(pawtner?['business_name'] ?? pawtner?['full_name'] ?? '',
                    style: GoogleFonts.dosis(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(booking['chosen_service_subtype'] ??
                      service?['service_subtype'] ??
                      '',
                      style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A))),
                  const SizedBox(height: 4),
                  Text(location ?? '',
                    style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    thickness: 1,
                    color: Color(0xFFDDC7A9),
                  ),
                  const SizedBox(height: 8),
                  Text('Schedule: $formattedSchedule',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      )),
                  const SizedBox(height: 4),
                  Text('Pet: ${pet?['name'] ?? ''}',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      )),
                  const SizedBox(height: 4),
                  
                  if (status.toLowerCase() != 'cancelled' &&
                      status.toLowerCase() != 'missed') ...[
                    Text('Notes: ${booking['notes'] ?? '-'}',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const SizedBox(height: 8),
                    ],
                    

                    if (status.toLowerCase() != 'cancelled' &&
                        status.toLowerCase() != 'missed')
                      const Divider(
                        thickness: 1,
                        color: Color(0xFFDDC7A9),
                      ),
                    
                    const SizedBox(height: 8),

                  if (status.toLowerCase() == 'upcoming') ...[
                    Text('Price: ₱${price.toStringAsFixed(0)}',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        )),
                  ],
                      const SizedBox(height: 4),
                    if (status.toLowerCase() != 'cancelled' &&
                        status.toLowerCase() != 'missed') ...[
                      if (status.toLowerCase() == 'upcoming')
                        const SizedBox(height: 4),
                      Text('Total: ₱${total.toStringAsFixed(0)}',
                          style: GoogleFonts.dosis(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6E4B3A),
                          )),
                        ],
                  const SizedBox(height: 8),
                  ],
                ),
              ),

                      if (status.toLowerCase() != 'upcoming')
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFDDC7A9), width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              if (summaryTitle.isNotEmpty)
                                Text(summaryTitle,
                                    style: GoogleFonts.dosis(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6E4B3A),
                                    )),

                              const SizedBox(height: 8),

                              if (status.toLowerCase() == 'cancelled') ...[
                                Text('Cancelled At: $formattedCancelledAt',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                                const SizedBox(height: 4),
                                Text(
                                  'Cancelled By: ${booking['cancelled_by'] ?? '-'}',
                                  style: GoogleFonts.dosis(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF6E4B3A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Reason: ${booking['cancelled_reason'] ?? '-'}',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                              ]

                              else if (status.toLowerCase() == 'completed') ...[
                                Text('Date Completed: $formattedCompletedAt',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Rating: ',
                                      style: GoogleFonts.dosis(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6E4B3A),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          Icons.star,
                                          color: index < bookingRating
                                              ? const Color(0xFF6E4B3A)
                                              : const Color(0xFFCCCCCC),
                                          size: 20,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Review: $bookingComment',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                              ]

                              else if (status.toLowerCase() == 'missed') ...[
                                Text('Date Marked as Missed: $formattedMissedAt',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                                const SizedBox(height: 4),
                                Text('Reason: ${booking['missed_reason'] ?? '-'}',
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF6E4B3A),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        
                  const SizedBox(height: 80),
                  if (status.toLowerCase() == 'completed' && (booking['reviewed'] ?? false) == false) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FurrentReviewScreen(
                                bookingId: booking['id'],
                                pawtnerId: pawtner?['id'] ?? '',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6E4B3A),
                          alignment: Alignment.center,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Add Review',
                          style: GoogleFonts.dosis(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDDC7A9),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (status.toLowerCase() == 'upcoming') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final currentUserId = supabase.auth.currentUser!.id;
                          final pawtner = booking['pawtners'] as Map<String, dynamic>?;
                          if (pawtner == null) return;
                          final pawtnerId = pawtner['id'];
                          if (pawtnerId == null) return;

                          final existing = await supabase
                              .from('conversations')
                              .select()
                              .eq('pawtner_id', pawtnerId)
                              .eq('furrent_id', currentUserId)
                              .maybeSingle();

                          String conversationId;
                          if (existing != null) {
                            conversationId = existing['id'];
                          } else {
                            final inserted = await supabase
                                .from('conversations')
                                .insert({
                                  'pawtner_id': pawtnerId,
                                  'furrent_id': currentUserId,
                                  'last_message': '',
                                  'last_message_at': DateTime.now().toIso8601String(),
                                })
                                .select()
                                .single();
                            conversationId = inserted['id'];
                          }

                          if (!context.mounted) return;

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversationId,
                                otherUserId: pawtnerId,
                                otherUserName: pawtner['business_name'] ?? pawtner['full_name'] ?? '',
                                otherUserAvatar: pawtner['profile_picture_url'] ?? '',
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDDC7A9),
                          alignment: Alignment.center,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Chat with Pawtner',
                          style: GoogleFonts.dosis(
                              fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
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
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF8B0000),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
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
                                              fontSize: 16,
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

                          try {
                            await supabase.from('bookings').update({
                              'status': 'Cancelled',
                              'cancelled_reason': reasonController.text.trim(),
                              'cancelled_at': DateTime.now().toIso8601String(),
                            }).eq('id', booking['id']);

                            setState(() {
                              booking['status'] = 'Cancelled';
                              booking['cancelled_reason'] = reasonController.text.trim();
                              booking['cancelled_at'] = DateTime.now().toIso8601String();
                            });

                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Booking cancelled.')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to cancel booking.')),
                            );
                          }
                        },
                          style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          alignment: Alignment.center,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel Booking',
                          style: GoogleFonts.dosis(
                              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FurrentRescheduleScreen(
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
                          alignment: Alignment.center,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Reschedule',
                          style: GoogleFonts.dosis(
                              fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFFDDC7A9)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
      }
