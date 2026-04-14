import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'furrent_pawtner_detail_screen.dart';

class FurrentTrainingScreen extends StatefulWidget {
  const FurrentTrainingScreen({super.key});

  @override
  State<FurrentTrainingScreen> createState() => _FurrentTrainingScreenState();
}

class _FurrentTrainingScreenState extends State<FurrentTrainingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> services = [];
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  double furrentLocationLat = 14.5547;
  double furrentLocationLong = 121.0244;

  final List<String> tabs = ['All', 'Training Center', 'Home Training', 'Top Rated'];
  final List<bool> _selectedTabFlags = [true, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * pi / 180;

  Future<void> _loadServices() async {
    setState(() => isLoading = true);
    try {
      var query = supabase
          .from('services')
          .select(
              '*, pawtners:pawtner_id(id, full_name, business_name, profile_picture_url, business_address, location_lat, location_long)')
          .ilike('service_type', 'training')
          .eq('is_public', true);

      if (selectedTab == 'Training Center') {
        query = query.ilike('service_subtype', '%training center%');
      } else if (selectedTab == 'Home Training') {
        query = query.ilike('service_subtype', '%home training%');
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        query = query.or(
          'service_name.ilike.%$search%,pawtners.full_name.ilike.%$search%,pawtners.business_name.ilike.%$search%',
        );
      }

      final response = await query;
      final data =
          (response as List).map((e) => e as Map<String, dynamic>).toList();

      setState(() {
        services = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading training services: $e');
      setState(() => isLoading = false);
    }
  }

  Future<double> _getAverageRating(String pawtnerId) async {
    try {
      final reviewResponse = await supabase
          .from('reviews')
          .select('rating')
          .eq('pawtner_id', pawtnerId);

      final ratings =
          (reviewResponse as List).map((e) => e['rating'] as int).toList();

      return ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0.0;
    } catch (e) {
      debugPrint('Error fetching rating: $e');
      return 0.0;
    }
  }

  Widget _buildServiceMiniCard(Map<String, dynamic> service, String pawtnerId) {
    final serviceName = service['service_name'] ?? 'Service';
    final price = service['price']?.toStringAsFixed(0) ?? '0';
    final search = _searchController.text.trim().toLowerCase();

    List<TextSpan> spans = [];
    if (search.isNotEmpty) {
      String lowerName = serviceName.toLowerCase();
      int start = 0;
      int index;
      while ((index = lowerName.indexOf(search, start)) != -1) {
        if (index > start) {
          spans.add(TextSpan(
              text: serviceName.substring(start, index),
              style: GoogleFonts.dosis(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E4B3A))));
        }
        spans.add(TextSpan(
            text: serviceName.substring(index, index + search.length),
            style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFFDCB58))));
        start = index + search.length;
      }
      if (start < serviceName.length) {
        spans.add(TextSpan(
            text: serviceName.substring(start),
            style: GoogleFonts.dosis(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6E4B3A))));
      }
    } else {
      spans.add(TextSpan(
          text: serviceName,
          style: GoogleFonts.dosis(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6E4B3A))));
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FurrentPawtnerDetailScreen(
              pawtnerId: pawtnerId,
              initialServiceId: service['id'].toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF5EB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(children: spans),
            ),
            Text(
              '₱$price',
              style: GoogleFonts.dosis(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E4B3A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final pawtner = service['pawtners'] as Map<String, dynamic>?;

    final pawtnerId = pawtner?['id'] ?? '';
    final businessName = pawtner?['business_name'] ?? pawtner?['full_name'] ?? 'Pawtner';
    final profileUrl = pawtner?['profile_picture_url'];
    final businessAddress = pawtner?['business_address'] ?? '';

    final subtypeRaw = (service['service_subtype'] ?? '').toString();
    final subtypesList = subtypeRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final subtype = subtypesList.join(' + ');

    bool hasTrainingCenter = subtypesList
        .map((s) => s.toLowerCase())
        .any((s) => s.contains('training center'));

    final lat = pawtner?['location_lat'] != null
        ? (pawtner!['location_lat'] as num).toDouble()
        : 0.0;
    final long = pawtner?['location_long'] != null
        ? (pawtner!['location_long'] as num).toDouble()
        : 0.0;

    String locationText = '';
    double distanceKm = 0;

    if (selectedTab == 'Home Training') {
      locationText = 'See All Locations';
    } else if (subtypesList.length == 1 &&
        subtypesList.first.toLowerCase() == 'home training') {
      locationText = 'See All Locations';
    } else if (hasTrainingCenter) {
      if (lat != 0 && long != 0) {
        distanceKm = calculateDistance(furrentLocationLat, furrentLocationLong, lat, long);
      }
      locationText = '$businessAddress • ${distanceKm.toInt()} km';
    }

    final search = _searchController.text.trim().toLowerCase();

    List<TextSpan> businessNameSpans = [];
    if (search.isNotEmpty && businessName.toLowerCase().contains(search)) {
      String lowerName = businessName.toLowerCase();
      int start = 0;
      int index;
      while ((index = lowerName.indexOf(search, start)) != -1) {
        if (index > start) {
          businessNameSpans.add(TextSpan(
            text: businessName.substring(start, index),
            style: GoogleFonts.dosis(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A),
            ),
          ));
        }
        businessNameSpans.add(TextSpan(
          text: businessName.substring(index, index + search.length),
          style: GoogleFonts.dosis(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFDCB58),
          ),
        ));
        start = index + search.length;
      }
      if (start < businessName.length) {
        businessNameSpans.add(TextSpan(
          text: businessName.substring(start),
          style: GoogleFonts.dosis(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ));
      }
    } else {
      businessNameSpans.add(TextSpan(
        text: businessName,
        style: GoogleFonts.dosis(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6E4B3A),
        ),
      ));
    }

    final matchingServices = services
        .where((s) {
          final sName = (s['service_name'] ?? '').toString().toLowerCase();
          final pName = (s['pawtners']?['business_name'] ?? s['pawtners']?['full_name'] ?? '').toString().toLowerCase();
          return s['pawtners']?['id'] == pawtnerId &&
              (search.isEmpty || sName.contains(search) || pName.contains(search));
        })
        .toList();

    final showMiniCards = search.isNotEmpty &&
        matchingServices.any((s) => (s['service_name'] ?? '').toString().toLowerCase().contains(search));

    if (search.isNotEmpty && matchingServices.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Center(
          child: Text(
            'No results found',
            style: GoogleFonts.dosis(
                fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
          ),
        ),
      );
    }

    return FutureBuilder<double>(
        future: _getAverageRating(pawtnerId),
        builder: (context, snapshot) {
          final rating = snapshot.data ?? 0.0;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FurrentPawtnerDetailScreen(
                    pawtnerId: pawtnerId,
                    initialServiceId: service['id'].toString(),
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        margin: search.isNotEmpty ? const EdgeInsets.only(top: 4) : EdgeInsets.zero,
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
                            ? const Icon(Icons.person, color: Color(0xFFDDC7A9), size: 32)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(children: businessNameSpans),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Color(0xFF6E4B3A), size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: GoogleFonts.dosis(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E4B3A)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              locationText,
                              style: GoogleFonts.dosis(fontSize: 14, color: const Color(0xFF6E4B3A)),
                            ),
                            const SizedBox(height: 4),
                            if (selectedTab == 'All' || selectedTab == 'Top Rated')
                              Text(
                                subtype,
                                style: GoogleFonts.dosis(fontSize: 14, color: const Color(0xFF6E4B3A)),
                              ),
                            const SizedBox(height: 4),
                            if (showMiniCards)
                              ...matchingServices
                                  .where((s) => (s['service_name'] ?? '').toString().toLowerCase().contains(search))
                                  .map((s) => _buildServiceMiniCard(s, pawtnerId))
                                  .toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildPillTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTabFlags[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  for (int i = 0; i < _selectedTabFlags.length; i++) {
                    _selectedTabFlags[i] = i == index;
                  }
                  selectedTab = tabs[index];
                });
                _loadServices();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6E4B3A)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6E4B3A)),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dosis(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFFDDC7A9)
                          : const Color(0xFF6E4B3A),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uniquePawtnerIds = services
        .map((s) => s['pawtners']?['id'])
        .toSet()
        .toList();

    final pawtnerList = uniquePawtnerIds
        .map((id) => services.firstWhere((s) => s['pawtners']?['id'] == id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Training',
          style: GoogleFonts.dosis(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6E4B3A)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E6E6))),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF6E4B3A)),
                  SizedBox(width: 8),
                  Text('Select Location',
                      style: TextStyle(color: Color(0xFFAAAAAA))),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFDDC7A9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('Image Placeholder',
                      style: TextStyle(color: Colors.white))),
            ),
            const SizedBox(height: 16),
            _buildPillTabs(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E6E6)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Search for pawtners or services',
                          hintStyle: TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) => _loadServices(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                          itemCount: pawtnerList.length,
                          itemBuilder: (context, index) {
                            return _buildServiceCard(pawtnerList[index]);
                          }),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
