import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'furrent_pawtner_detail_screen.dart';

class FurrentBoardingScreen extends StatefulWidget {
  const FurrentBoardingScreen({super.key});

  @override
  State<FurrentBoardingScreen> createState() => _FurrentBoardingScreenState();
}

class _FurrentBoardingScreenState extends State<FurrentBoardingScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  List<Map<String, dynamic>> services = [];
  String selectedTab = 'All';
  final TextEditingController _searchController = TextEditingController();

  final dio = Dio();
  double furrentLocationLat = 0.0;
  double furrentLocationLong = 0.0;
  String _locationLabel = 'Detecting location...';

  final List<String> tabs = ['All', 'Pet Hotel', 'Home Boarding'];
  final List<bool> _selectedTabFlags = [true, false, false];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationLabel = 'Location permission denied');
        _loadServices();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        furrentLocationLat = position.latitude;
        furrentLocationLong = position.longitude;
        _locationLabel = 'Detecting address...';
      });

      try {
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse?lat=${position.latitude}&lon=${position.longitude}&format=json',
          options: Options(
            headers: {'User-Agent': 'io.supabase.petapp'},
          ),
        );
        final displayName = response.data['display_name'] as String;
        final shortAddress = displayName.split(',').take(3).join(',').trim();
        if (!mounted) return;
        setState(() => _locationLabel = shortAddress);
      } catch (e) {
        debugPrint('Reverse geocode error: $e');
        if (!mounted) return;
        setState(() => _locationLabel = 'Current Location');
      }

      _loadServices();
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (!mounted) return;
      setState(() => _locationLabel = 'Could not detect location');
      _loadServices();
    }
  }

  Future<void> _pickLocationManually() async {
    final TextEditingController locationController = TextEditingController();
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;
    const apiKey = 'AIzaSyBOKb6toq6ItcFdi94IekJNj5WX0p8tkt4';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your location',
                style: GoogleFonts.dosis(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                autofocus: true,
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  color: const Color(0xFF6E4B3A),
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 123 Rizal St, Makati',
                  hintStyle: GoogleFonts.dosis(
                    color: const Color(0xFFBDBDBD),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  suffixIcon: isSearching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6E4B3A),
                            ),
                          ),
                        )
                      : null,
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF6E4B3A), width: 1),
                  ),
                ),
                onChanged: (value) async {
                  if (value.trim().length < 3) {
                    setModalState(() => searchResults = []);
                    return;
                  }

                  setModalState(() => isSearching = true);

                  try {
                    final response = await dio.post(
                      'https://places.googleapis.com/v1/places:autocomplete',
                      options: Options(
                        headers: {
                          'Content-Type': 'application/json',
                          'X-Goog-Api-Key': apiKey,
                        },
                      ),
                      data: {
                        'input': value,
                        'locationBias': {
                          'circle': {
                            'center': {
                              'latitude': 12.8797,
                              'longitude': 121.7740,
                            },
                            'radius': 50000.0,
                          },
                        },
                        'includedRegionCodes': ['ph'],
                      },
                    );

                    if (!mounted) return;
                    final suggestions =
                        response.data['suggestions'] as List? ?? [];

                    setModalState(() {
                      searchResults = suggestions
                          .map((e) =>
                              e['placePrediction'] as Map<String, dynamic>)
                          .toList();
                      isSearching = false;
                    });
                  } catch (e) {
                    if (!mounted) return;
                    debugPrint('Autocomplete error: $e');
                    setModalState(() => isSearching = false);
                  }
                },
              ),
              const SizedBox(height: 8),
              if (searchResults.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E6E6)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: searchResults.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE6E6E6)),
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      final mainText = result['structuredFormat']?['mainText']
                              ?['text'] ??
                          '';
                      final secondaryText = result['structuredFormat']
                              ?['secondaryText']?['text'] ??
                          '';
                      final placeId = result['placeId'] ?? '';

                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on,
                            color: Color(0xFF6E4B3A), size: 20),
                        title: Text(
                          mainText,
                          style: GoogleFonts.dosis(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6E4B3A),
                          ),
                        ),
                        subtitle: Text(
                          secondaryText,
                          style: GoogleFonts.dosis(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          try {
                            final detailResponse = await dio.get(
                              'https://places.googleapis.com/v1/places/$placeId',
                              options: Options(
                                headers: {
                                  'X-Goog-Api-Key': apiKey,
                                  'X-Goog-FieldMask':
                                      'location,displayName,formattedAddress',
                                },
                              ),
                            );

                            final lat = detailResponse.data['location']
                                ['latitude'] as double;
                            final lng = detailResponse.data['location']
                                ['longitude'] as double;
                            final formattedAddress =
                                detailResponse.data['formattedAddress'] ??
                                    mainText;
                            final addressParts = formattedAddress.split(',');
                            final shortAddress = addressParts.length > 2
                                ? addressParts.take(2).join(',').trim()
                                : formattedAddress;

                            setState(() {
                              furrentLocationLat = lat;
                              furrentLocationLong = lng;
                              _locationLabel = shortAddress;
                            });

                            _loadServices();
                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint('Place detail error: $e');
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6E4B3A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.my_location, color: Color(0xFF6E4B3A)),
                  label: Text(
                    'Use Current Location',
                    style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _getCurrentLocation();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
          .ilike('service_type', 'boarding')
          .eq('is_public', true);

      if (selectedTab == 'Pet Hotel') {
        query = query.ilike('service_subtype', '%pet hotel%');
      } else if (selectedTab == 'Home Boarding') {
        query = query.ilike('service_subtype', '%home boarding%');
      }

      final search = _searchController.text.trim();
      if (search.isNotEmpty) {
        final pattern = '%$search%';
        query = query.or(
            '(service_name.ilike.$pattern,pawtners.full_name.ilike.$pattern,pawtners.business_name.ilike.$pattern)');
      }

      final response = await query;
      var data =
          (response as List).map((e) => e as Map<String, dynamic>).toList();

      data.sort((a, b) {
        final latA = (a['pawtners']?['location_lat'] as num?)?.toDouble() ?? 0;
        final lonA = (a['pawtners']?['location_long'] as num?)?.toDouble() ?? 0;
        final latB = (b['pawtners']?['location_lat'] as num?)?.toDouble() ?? 0;
        final lonB = (b['pawtners']?['location_long'] as num?)?.toDouble() ?? 0;
        final distA = calculateDistance(
            furrentLocationLat, furrentLocationLong, latA, lonA);
        final distB = calculateDistance(
            furrentLocationLat, furrentLocationLong, latB, lonB);
        return distA.compareTo(distB);
      });

      if (!mounted) return;

      setState(() {
        services = data;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading boarding services: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<double> _getAverageRating(String pawtnerId) async {
    try {
      final reviewResponse = await supabase
          .from('bookings')
          .select('rating')
          .eq('pawtner_id', pawtnerId)
          .not('rating', 'is', null);
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
            RichText(text: TextSpan(children: spans)),
            Text('₱$price',
                style: GoogleFonts.dosis(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A))),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final pawtner = service['pawtners'] as Map<String, dynamic>?;
    final pawtnerId = pawtner?['id'] ?? '';
    final businessName =
        pawtner?['business_name'] ?? pawtner?['full_name'] ?? 'Pawtner';
    final profileUrl = pawtner?['profile_picture_url'];
    final businessAddress = pawtner?['business_address'] ?? '';
    final lat = pawtner?['location_lat'] != null
        ? (pawtner!['location_lat'] as num).toDouble()
        : 0.0;
    final long = pawtner?['location_long'] != null
        ? (pawtner!['location_long'] as num).toDouble()
        : 0.0;

    final subtypeRaw = (service['service_subtype'] ?? '').toString();
    final subtypesList = subtypeRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final subtype = subtypesList.join(' + ');

    double distanceKm = 0;
    if (lat != 0 && long != 0) {
      distanceKm =
          calculateDistance(furrentLocationLat, furrentLocationLong, lat, long);
    }

    final search = _searchController.text.trim().toLowerCase();

    final matchingServices = services.where((s) {
      final sName = (s['service_name'] ?? '').toString().toLowerCase();
      final pName =
          (s['pawtners']?['business_name'] ?? s['pawtners']?['full_name'] ?? '')
              .toString()
              .toLowerCase();
      return s['pawtners']?['id'] == pawtnerId &&
          (search.isEmpty || sName.contains(search) || pName.contains(search));
    }).toList();

    final showMiniCards = search.isNotEmpty &&
        matchingServices.any((s) => (s['service_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(search));

    if (search.isNotEmpty && matchingServices.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<double>(
      future: _getAverageRating(pawtnerId),
      builder: (context, snapshot) {
        final rating = snapshot.data ?? 0.0;

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
                    color: const Color(0xFF6E4B3A)),
              ));
            }
            businessNameSpans.add(TextSpan(
              text: businessName.substring(index, index + search.length),
              style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFDCB58)),
            ));
            start = index + search.length;
          }
          if (start < businessName.length) {
            businessNameSpans.add(TextSpan(
              text: businessName.substring(start),
              style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6E4B3A)),
            ));
          }
        } else {
          businessNameSpans.add(TextSpan(
            text: businessName,
            style: GoogleFonts.dosis(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6E4B3A)),
          ));
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
            margin: const EdgeInsets.symmetric(vertical: 8),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      margin: search.isNotEmpty
                          ? const EdgeInsets.only(top: 4)
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF6E4B3A),
                        image: profileUrl != null
                            ? DecorationImage(
                                image: NetworkImage(profileUrl),
                                fit: BoxFit.cover)
                            : null,
                      ),
                      child: profileUrl == null
                          ? const Icon(Icons.person,
                              color: Color(0xFFDDC7A9), size: 32)
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
                                      text: TextSpan(
                                          children: businessNameSpans))),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Color(0xFF6E4B3A), size: 16),
                                  const SizedBox(width: 2),
                                  Text(rating.toStringAsFixed(1),
                                      style: GoogleFonts.dosis(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E4B3A))),
                                  if (rating >= 4.7)
                                    Container(
                                      margin: const EdgeInsets.only(
                                          left: 6, top: 2),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFDCB58),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Top Rated',
                                        style: GoogleFonts.dosis(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6E4B3A),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('$businessAddress • ${distanceKm.toInt()} km',
                              style: GoogleFonts.dosis(
                                  fontSize: 14,
                                  color: const Color(0xFF6E4B3A))),
                          const SizedBox(height: 4),
                          if (selectedTab == 'All')
                            Text(subtype,
                                style: GoogleFonts.dosis(
                                    fontSize: 14,
                                    color: const Color(0xFF6E4B3A))),
                          const SizedBox(height: 4),
                          if (showMiniCards)
                            ...matchingServices
                                .where((s) => (s['service_name'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains(search))
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
      },
    );
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
    final uniquePawtnerIds =
        services.map((s) => s['pawtners']?['id']).toSet().toList();
    final pawtnerList = uniquePawtnerIds
        .map((id) => services.firstWhere((s) => s['pawtners']?['id'] == id))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6E4B3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFDDC7A9)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Boarding',
          style: GoogleFonts.dosis(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDDC7A9)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF6E4B3A),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickLocationManually,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFFDDC7A9), size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationLabel,
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              color: const Color(0xFFDDC7A9),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFFDDC7A9), size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            textAlignVertical: TextAlignVertical.center,
                            style: GoogleFonts.dosis(
                                fontSize: 16, color: const Color(0xFF6E4B3A)),
                            decoration: InputDecoration(
                              hintText: 'Search for pawtners or services',
                              hintStyle: GoogleFonts.dosis(
                                color: const Color(0xFFBDBDBD),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                            ),
                            onChanged: (value) => _loadServices(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildPillTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        itemCount: pawtnerList.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(pawtnerList[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
