import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class FurrentReviewScreen extends StatefulWidget {
  final String bookingId;
  final String pawtnerId;

  const FurrentReviewScreen({
    super.key,
    required this.bookingId,
    required this.pawtnerId,
  });

  @override
  State<FurrentReviewScreen> createState() => _FurrentReviewScreenState();
}

class _FurrentReviewScreenState extends State<FurrentReviewScreen> {
  final supabase = Supabase.instance.client;

  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  Map<String, dynamic>? bookingData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingData() async {
    try {
      final response = await supabase
          .from('bookings')
          .select('*, pawtners(*), services(*)')
          .eq('id', widget.bookingId)
          .single();

      bookingData = Map<String, dynamic>.from(response as Map);
      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading booking data: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load booking data."),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

Future<void> submitReview() async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User not logged in')),
    );
    return;
  }

  if (rating == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a rating before submitting.')),
    );
    return;
  }

  try {
    await supabase
        .from('bookings')
        .update({
          'rating': rating.toInt(),
          'review_comment': reviewController.text.trim(),
          'reviewed': true,
        })
        .eq('id', widget.bookingId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted successfully!')),
    );

    Navigator.pop(context,true);
  } catch (e) {
    debugPrint('Error submitting review: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to submit review. Please try again.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final pawtnerName = bookingData?['pawtners']?['business_name']?.toString().isNotEmpty == true
        ? bookingData!['pawtners']!['business_name']
        : bookingData?['pawtners']?['full_name'] ?? '';
    final serviceName = bookingData?['services']?['service_name'] ?? '';
    final scheduledStart = bookingData?['scheduled_start'] != null
        ? DateFormat('MMM d, h:mm a').format(DateTime.parse(bookingData!['scheduled_start']))
        : '';
    final profileUrl = bookingData?['pawtners']?['profile_picture_url'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Review',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFF6E4B3A),
                            image: profileUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(profileUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: profileUrl == null
                              ? const Icon(Icons.person, color: Color(0xFFDDC7A9), size: 28)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pawtnerName,
                                style: GoogleFonts.dosis(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                serviceName,
                                style: GoogleFonts.dosis(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scheduledStart,
                                style: GoogleFonts.dosis(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6E4B3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                  Text(
                    'How was your experience?',
                    style: GoogleFonts.dosis(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: const Color(0xFF6E4B3A),
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: reviewController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: Color(0xFF6E4B3A),
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Share your experience',
                      hintStyle: const TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 120),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6E4B3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Submit Review',
                        style: GoogleFonts.dosis(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDC7A9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
