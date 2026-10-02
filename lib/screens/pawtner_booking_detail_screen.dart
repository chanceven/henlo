// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';

class PawtnerBookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;
  final bool fromPawtnerBookingsScreen;

  const PawtnerBookingDetailsScreen({
    super.key,
    required this.booking,
    this.fromPawtnerBookingsScreen = false,
  });

  @override
  State<PawtnerBookingDetailsScreen> createState() =>
      _PawtnerBookingDetailsScreenState();
}

class _PawtnerBookingDetailsScreenState
    extends State<PawtnerBookingDetailsScreen> {
  final supabase = Supabase.instance.client;
  RealtimeChannel? _bookingsChannel;
  String? _selectedAction;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupRealtimeBooking();
    _fetchBookingDetails();
  }

  @override
  void dispose() {
    final channel = _bookingsChannel;
    if (channel != null) supabase.removeChannel(channel);
    super.dispose();
  }

  void _showToast(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.dosis(
            color: const Color(0xFFDDC7A9),
          ),
        ),
        backgroundColor: const Color(0xFF6E4B3A),
        behavior: widget.fromPawtnerBookingsScreen
            ? SnackBarBehavior.floating
            : SnackBarBehavior.fixed,
        margin: widget.fromPawtnerBookingsScreen
            ? const EdgeInsets.fromLTRB(16, 0, 16, 80)
            : null,
      ),
    );
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
            if (!mounted) return;
            await _fetchBookingDetails();
          },
        )
        .subscribe();
  }

  Future<void> _fetchBookingDetails() async {
    final bookingId = widget.booking['id'];

    try {
      final response = await supabase
          .from('bookings')
          .select('*, pets(*), furrents(*), services(*)')
          .eq('id', bookingId)
          .maybeSingle();

      if (!mounted) return;
      if (response != null) {
        setState(() {
          widget.booking.clear();
          widget.booking.addAll(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching booking details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final pet = booking['pets'] as Map<String, dynamic>?;
    final service = booking['services'] as Map<String, dynamic>?;
    final furrent = booking['furrents'] as Map<String, dynamic>?;

    final wasRealFurrentAccount = booking['guest_name'] == null;
    final furrentAccountDeleted =
        wasRealFurrentAccount && booking['furrent_id'] == null;
    final displayFurrentName = (booking['furrent_name'] ??
            furrent?['full_name'] ??
            booking['guest_name'] ??
            '-') +
        (furrentAccountDeleted ? ' (Deleted User)' : '');
    final displayFurrentPetName =
        booking['pet_name'] ?? pet?['name'] ?? booking['guest_pet_name'] ?? '-';
    final displayServiceName =
        (booking['service_name'] ?? service?['service_name'] ?? '') +
            (booking['service_id'] == null ? ' (Deleted Service)' : '');

    final scheduledStart =
        DateTime.tryParse(booking['scheduled_start'] ?? '')?.toLocal();

    final scheduledEnd =
        DateTime.tryParse(booking['scheduled_end'] ?? '')?.toLocal();

    final now = DateTime.now();
    bool canMarkDone = false;

    if (scheduledEnd != null) {
      final autoCompleteTime = scheduledEnd.add(const Duration(minutes: 30));

      canMarkDone =
          !now.isBefore(scheduledEnd) && now.isBefore(autoCompleteTime);
    }

    String formattedSchedule = '-';

    if (scheduledStart != null &&
        scheduledEnd != null &&
        !DateUtils.isSameDay(scheduledStart, scheduledEnd)) {
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

    final cancelledAt =
        DateTime.tryParse(booking['cancelled_at'] ?? '')?.toLocal();
    final formattedCancelledAt = cancelledAt != null
        ? DateFormat('MMM d, h:mm a').format(cancelledAt)
        : '-';

    final completedAt =
        DateTime.tryParse(booking['completed_at'] ?? '')?.toLocal();
    final formattedCompletedAt = completedAt != null
        ? DateFormat('MMM d, h:mm a').format(completedAt)
        : '';

    final bookingRating = booking['rating'] ?? 0;
    final bookingComment = booking['review_comment'] ?? '-';

    final missedAt = DateTime.tryParse(booking['missed_at'] ?? '')?.toLocal();
    final formattedMissedAt =
        missedAt != null ? DateFormat('MMM d, h:mm a').format(missedAt) : '-';

    final price = booking['price'] ?? service?['price'] ?? 0;

    int days = 1;

    if (scheduledStart != null && scheduledEnd != null) {
      final diff = scheduledEnd.difference(scheduledStart).inDays;
      if (diff > 0) {
        days = diff;
      }
    }

    final total = price * days;

    final status = (booking['status'] ?? 'Upcoming').toString();

    String summaryTitle = 'Service Details';
    if (status.toLowerCase() == 'completed') {
      summaryTitle = 'Completion Summary';
    }
    if (status.toLowerCase() == 'cancelled') {
      summaryTitle = 'Cancellation Summary';
    }
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
      bottomNavigationBar: status.toLowerCase() == 'upcoming'
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (booking['furrent_id'] != null) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  final currentUser = supabase.auth.currentUser;
                                  if (currentUser == null) {
                                    _showToast(
                                        'Your session expired. Please log in again.');
                                    return;
                                  }
                                  final currentUserId = currentUser.id;
                                  final furrent = booking['furrents']
                                      as Map<String, dynamic>?;
                                  if (furrent == null) return;

                                  final furrentId = furrent['id'];
                                  if (furrentId == null) return;

                                  setState(() => _isSaving = true);
                                  String? conversationId;
                                  try {
                                    final existing = await supabase
                                        .from('conversations')
                                        .select('id')
                                        .eq('furrent_id', furrentId)
                                        .eq('pawtner_id', currentUserId)
                                        .maybeSingle();
                                    conversationId =
                                        existing?['id']?.toString();
                                  } catch (e) {
                                    debugPrint('Error opening chat: $e');
                                    _showToast('Failed to open chat.');
                                    return;
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                  }

                                  if (!context.mounted) return;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: conversationId,
                                        otherUserId: furrentId,
                                        otherUserName:
                                            furrent['full_name'] ?? '',
                                        otherUserAvatar:
                                            furrent['profile_picture_url'] ??
                                                '',
                                        currentUserType: 'pawtner',
                                        isDeletedAccount: false,
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDDC7A9),
                            alignment: Alignment.center,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            'Chat with Furrent',
                            style: GoogleFonts.dosis(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6E4B3A)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFF8F8F8),
                              insetPadding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(24, 20, 24, 0),
                              content: SizedBox(
                                height: 130,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Are you sure you want to cancel this booking?',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dosis(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 140,
                                          height: 40,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF6E4B3A),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: Text(
                                              'Keep Booking',
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      const Color(0xFFDDC7A9)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        SizedBox(
                                          width: 140,
                                          height: 40,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF8B0000),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: Text(
                                              'Confirm',
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.white),
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

                          if (confirmed != true || !mounted) return;

                          String reasonText = '';
                          final reasonSubmitted = await showDialog<bool>(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setDialogState) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: EdgeInsets.zero,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(
                                        24, 20, 24, 24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F8F8),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 4,
                                            offset: Offset(0, 2))
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Why are you cancelling this booking?',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.dosis(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: const Color(0xFF6E4B3A)),
                                        ),
                                        const SizedBox(height: 12),
                                        TextField(
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          maxLines: 3,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              reasonText = value;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            hintText:
                                                'Enter your reason for cancellation',
                                            hintStyle: GoogleFonts.dosis(
                                                fontSize: 14,
                                                color: const Color(0xFFAAAAAA)),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF6E4B3A),
                                                  width: 1.5),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF6E4B3A),
                                                  width: 1.5),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: const BorderSide(
                                                  color: Color(0xFF6E4B3A),
                                                  width: 2),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8),
                                          ),
                                          style: GoogleFonts.dosis(
                                              fontSize: 14,
                                              color: const Color(0xFF6E4B3A)),
                                        ),
                                        const SizedBox(height: 16),
                                        SizedBox(
                                          width: 140,
                                          height: 40,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  reasonText.trim().isEmpty
                                                      ? const Color(0xFFD9D9D9)
                                                      : const Color(0xFF8B0000),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8)),
                                            ),
                                            onPressed: reasonText.trim().isEmpty
                                                ? null
                                                : () {
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                            child: Text(
                                              'Submit',
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );

                          if (reasonSubmitted != true || !mounted) return;
                          if (_isSaving) return;

                          reasonText = reasonText.trim();

                          final bookingId = booking['id'];
                          setState(() => _isSaving = true);
                          try {
                            await supabase.from('bookings').update({
                              'status': 'Cancelled',
                              'cancelled_reason': reasonText,
                              'cancelled_at':
                                  DateTime.now().toUtc().toIso8601String(),
                              'cancelled_by': 'Pawtner',
                            }).eq('id', bookingId);

                            _showToast('Booking cancelled.');

                            if (mounted) Navigator.pop(context, true);
                          } catch (e) {
                            debugPrint('Error cancelling booking: $e');
                            _showToast('Failed to cancel booking.');
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B0000),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Cancel Booking',
                          style: GoogleFonts.dosis(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFFDDC7A9), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(displayServiceName,
                              style: GoogleFonts.dosis(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E4B3A))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                  booking['status'] ?? 'upcoming'),
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
                      Text(
                        booking['chosen_service_subtype'] ??
                            service?['service_subtype'] ??
                            '',
                        style: GoogleFonts.dosis(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6E4B3A)),
                      ),
                      if (booking['furrent_address'] != null &&
                          booking['furrent_address'].toString().isNotEmpty)
                        const SizedBox(height: 6),
                      if (booking['furrent_address'] != null &&
                          booking['furrent_address'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                              'Furrent Address: ${booking['furrent_address']}',
                              style: GoogleFonts.dosis(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A))),
                        ),
                      const SizedBox(height: 4),
                      Text('Schedule: $formattedSchedule',
                          style: GoogleFonts.dosis(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6E4B3A),
                          )),
                      const SizedBox(height: 8),
                      const Divider(
                        thickness: 1,
                        color: Color(0xFFDDC7A9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Booking Source: ${booking['booking_source'] ?? '-'}',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pet Name: $displayFurrentPetName',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        ),
                      ),
                      if (pet?['breed'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Breed: ${pet?['breed']}',
                          style: GoogleFonts.dosis(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6E4B3A),
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'Furrent Name: $displayFurrentName',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Furrent Contact Number: ${furrent?['contact_number'] ?? booking['guest_contact_number'] ?? '-'}',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6E4B3A),
                        ),
                      ),
                      if (status.toLowerCase() != 'cancelled') ...[
                        const SizedBox(height: 8),
                        const Divider(
                          thickness: 1,
                          color: Color(0xFFDDC7A9),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (status.toLowerCase() != 'cancelled' &&
                          status.toLowerCase() != 'missed') ...[
                        Text('Notes from Furrent: ${booking['notes'] ?? '-'}',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            )),
                        const SizedBox(height: 8),
                        const Divider(
                          thickness: 1,
                          color: Color(0xFFDDC7A9),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (status.toLowerCase() != 'cancelled' &&
                          status.toLowerCase() != 'missed') ...[
                        Text(
                            'Total: ₱${total % 1 == 0 ? total.toInt() : total}',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF6E4B3A),
                            ).copyWith(
                                fontFamilyFallback: const ['Roboto', 'Arial'])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (status.toLowerCase() == 'upcoming') ...[
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: 'done',
                          groupValue: _selectedAction,
                          activeColor: const Color(0xFF6E4B3A),
                          fillColor:
                              WidgetStateProperty.all(const Color(0xFF6E4B3A)),
                          onChanged: (canMarkDone && !_isSaving)
                              ? (value) async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFFF8F8F8),
                                      insetPadding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          24, 20, 24, 0),
                                      content: SizedBox(
                                        height: 130,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Are you sure you want to mark this booking as done?',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      const Color(0xFF6E4B3A)),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'This action cannot be undone.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color:
                                                      const Color(0xFF6E4B3A)),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 140,
                                                  height: 40,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF6E4B3A),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts.dosis(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: const Color(
                                                              0xFFDDC7A9)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                SizedBox(
                                                  width: 140,
                                                  height: 40,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF2E7D32),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: Text(
                                                      'Confirm',
                                                      style: GoogleFonts.dosis(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: Colors.white),
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

                                  if (confirmed != true || !mounted) return;

                                  final bookingId = booking['id'];
                                  setState(() => _isSaving = true);

                                  try {
                                    await supabase.from('bookings').update({
                                      'status': 'Completed',
                                      'completed_at': DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                    }).eq('id', bookingId);

                                    _showToast('Booking marked as completed.');

                                    if (mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    debugPrint('Error completing booking: $e');
                                    _showToast('Failed to complete booking.');
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                  }
                                }
                              : null,
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Text(
                            'Mark as Done',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(width: 8),

                    /// MARK AS MISSED
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Radio<String>(
                          value: 'missed',
                          groupValue: _selectedAction,
                          activeColor: const Color(0xFF6E4B3A),
                          fillColor:
                              WidgetStateProperty.all(const Color(0xFF6E4B3A)),
                          onChanged: (canMarkDone && !_isSaving)
                              ? (value) async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xFFF8F8F8),
                                      insetPadding: const EdgeInsets.symmetric(
                                          horizontal: 20),
                                      contentPadding: const EdgeInsets.fromLTRB(
                                          24, 20, 24, 0),
                                      content: SizedBox(
                                        height: 130,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Are you sure you want to mark this booking as missed?',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color:
                                                      const Color(0xFF6E4B3A)),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'This action cannot be undone.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.dosis(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color:
                                                      const Color(0xFF6E4B3A)),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 140,
                                                  height: 40,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF6E4B3A),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: Text(
                                                      'Cancel',
                                                      style: GoogleFonts.dosis(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: const Color(
                                                              0xFFDDC7A9)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                SizedBox(
                                                  width: 140,
                                                  height: 40,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF8B0000),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8)),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: Text(
                                                      'Confirm',
                                                      style: GoogleFonts.dosis(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                          color: Colors.white),
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

                                  if (confirmed != true || !mounted) return;

                                  final reasonController =
                                      TextEditingController();

                                  final reasonSubmitted =
                                      await showDialog<bool>(
                                    context: context,
                                    builder: (context) => Dialog(
                                      backgroundColor: Colors.transparent,
                                      insetPadding: EdgeInsets.zero,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Container(
                                          padding: const EdgeInsets.fromLTRB(
                                              24, 20, 24, 24),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F8F8),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Why are you marking this booking as missed?',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.dosis(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                    color: const Color(
                                                        0xFF6E4B3A)),
                                              ),
                                              const SizedBox(height: 12),
                                              TextField(
                                                controller: reasonController,
                                                maxLines: 3,
                                                decoration: InputDecoration(
                                                  hintText: 'Enter your reason',
                                                  hintStyle: GoogleFonts.dosis(
                                                      fontSize: 14,
                                                      color: const Color(
                                                          0xFFAAAAAA)),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Color(
                                                                0xFF6E4B3A),
                                                            width: 1.5),
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Color(
                                                                0xFF6E4B3A),
                                                            width: 1.5),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    borderSide:
                                                        const BorderSide(
                                                            color: Color(
                                                                0xFF6E4B3A),
                                                            width: 2),
                                                  ),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                ),
                                                style: GoogleFonts.dosis(
                                                    fontSize: 14,
                                                    color: const Color(
                                                        0xFF6E4B3A)),
                                              ),
                                              const SizedBox(height: 16),
                                              SizedBox(
                                                width: 140,
                                                height: 40,
                                                child: ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF8B0000),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                  ),
                                                  onPressed: () {
                                                    if (reasonController.text
                                                        .trim()
                                                        .isEmpty) {
                                                      return;
                                                    }
                                                    Navigator.pop(
                                                        context, true);
                                                  },
                                                  child: Text(
                                                    'Submit',
                                                    style: GoogleFonts.dosis(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  if (reasonSubmitted != true || !mounted) {
                                    return;
                                  }

                                  final bookingId = booking['id'];
                                  setState(() => _isSaving = true);

                                  try {
                                    await supabase.from('bookings').update({
                                      'status': 'Missed',
                                      'missed_reason':
                                          reasonController.text.trim(),
                                      'missed_at': DateTime.now()
                                          .toUtc()
                                          .toIso8601String(),
                                    }).eq('id', bookingId);

                                    _showToast('Booking marked as missed.');

                                    if (mounted) {
                                      Navigator.pop(context, true);
                                    }
                                  } catch (e) {
                                    debugPrint(
                                        'Error marking booking missed: $e');
                                    _showToast(
                                        'Failed to mark booking as missed.');
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSaving = false);
                                    }
                                  }
                                }
                              : null,
                        ),
                        Transform.translate(
                          offset: const Offset(-8, 0),
                          child: Text(
                            'Mark as Missed',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (status.toLowerCase() != 'upcoming')
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: const Color(0xFFDDC7A9), width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    ] else if (status.toLowerCase() == 'completed') ...[
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
                    ] else if (status.toLowerCase() == 'missed') ...[
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
