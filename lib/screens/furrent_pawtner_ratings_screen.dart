import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FurrentPawtnerRatingsScreen extends StatefulWidget {
  final String pawtnerId;

  const FurrentPawtnerRatingsScreen({super.key, required this.pawtnerId});

  @override
  State<FurrentPawtnerRatingsScreen> createState() =>
      _FurrentPawtnerRatingsScreenState();
}

class _FurrentPawtnerRatingsScreenState
    extends State<FurrentPawtnerRatingsScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> reviews = [];
  Map<String, dynamic>? pawtner;
  double averageRating = 0.0;
  int selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);

    try {
      final pawtnerResponse = await supabase
          .from('pawtners')
          .select()
          .eq('id', widget.pawtnerId)
          .single();
      pawtner = pawtnerResponse as Map<String, dynamic>?;

      final reviewResponse = await supabase
        .from('bookings')
        .select('''
          rating,
          review_comment,
          updated_at,
          services:service_id (
            service_type
          ),
          furrents:furrent_id (
            full_name,
            profile_picture_url
          )
        ''')
        .eq('pawtner_id', widget.pawtnerId)
        .not('rating', 'is', null)
        .order('updated_at', ascending: false);

      reviews = (reviewResponse as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      if (reviews.isNotEmpty) {
        final ratings =
            reviews.map((e) => e['rating'] as int).toList();
        averageRating =
            ratings.reduce((a, b) => a + b) / ratings.length;
      } else {
        averageRating = 0.0;
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      setState(() => isLoading = false);
    }
  }

  Widget _buildHeader() {
    final businessName = pawtner?['business_name'] ?? 'Pawtner';
    final totalReviews = reviews.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          businessName,
          style: GoogleFonts.dosis(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6E4B3A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Color(0xFF6E4B3A), size: 18),
            const SizedBox(width: 6),
            Text(
              '${averageRating.toStringAsFixed(1)} • $totalReviews Reviews',
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterBar() {
    final filters = [0, 5, 4, 3, 2, 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((rating) {

          final isSelected = selectedFilter == rating;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = rating;
                });
              },
              child: Container(
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6E4B3A)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                child: rating == 0
                    ? Text(
                        'All',
                        style: GoogleFonts.dosis(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFDDC7A9)
                              : const Color(0xFF6E4B3A),
                        ),
                      )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFFDDC7A9)
                          : const Color(0xFF6E4B3A),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '$rating',
                      style: GoogleFonts.dosis(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6E4B3A),
                      ),
                    ),
                  ],
                )
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> get filteredReviews {
    if (selectedFilter == 0) {
      return reviews;
    }

    return reviews.where((review) {
      return review['rating'] == selectedFilter;
    }).toList();
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final reviewer = review['furrents'] as Map<String, dynamic>?;
    final reviewerName = reviewer?['full_name'] ?? 'Furrent';
    final rating = review['rating'] ?? 0;
    final comment = review['review_comment'] ?? '';
    final service = review['services'] as Map<String, dynamic>?;
    final serviceType = service?['service_type'] ?? '';
    final createdAt = review['updated_at'] != null
    ? DateFormat('d MMM yyyy')
        .format(DateTime.parse(review['updated_at']))
    : '';

    final gallery = review['gallery'] as List?;
    final images = gallery != null && gallery.isNotEmpty
        ? (gallery.take(6).toList() as List<String>)
        : [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [

            Text(
              reviewerName,
              style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6E4B3A),
              ),
            ),

            Row(
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  size: 16,
                  color: index < rating
                      ? const Color(0xFF6E4B3A)
                      : const Color(0xFFCCCCCC),
                );
              }),
            ),

          ],
        ),
          const SizedBox(height: 4),
          Text(
          comment,
            style: GoogleFonts.dosis(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E4B3A),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                serviceType,
                style: GoogleFonts.dosis(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              Text(
                createdAt,
                style: GoogleFonts.dosis(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
            ],
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
            if ((gallery?.length ?? 0) > 6)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'See All',
                  style: GoogleFonts.dosis(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
              ),
          ],
        ],
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
        title: Text(
          'Ratings & Reviews',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: _buildHeader(),
                  ),
                  _buildFilterBar(),

                  const SizedBox(height: 8),

                  Expanded(
                    child: reviews.isEmpty
                        ? Center(
                            child: Text(
                              'No reviews yet',
                              style: GoogleFonts.dosis(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF6E4B3A)),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredReviews.length,
                            itemBuilder: (context, index) =>
                                _buildReviewCard(filteredReviews[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
