import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'furrent_pawtner_ratings_screen.dart';
import 'chat_screen.dart';
import 'furrent_book_appointment_screen.dart';

class FurrentPawtnerDetailScreen extends StatefulWidget {
  final String pawtnerId;
  final String? initialServiceId;

  const FurrentPawtnerDetailScreen({super.key, required this.pawtnerId, this.initialServiceId});

  @override
  State<FurrentPawtnerDetailScreen> createState() =>
      _FurrentPawtnerDetailScreenState();
}

class _FurrentPawtnerDetailScreenState
    extends State<FurrentPawtnerDetailScreen> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? pawtner;
  Map<String, List<Map<String, dynamic>>> servicesByType = {};
  late TabController _tabController;
  List<String> serviceTypes = ['Grooming', 'Boarding', 'Training'];
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _serviceKeys = {};
  String? _serviceIdToScroll;
  List<Map<String, dynamic>> furrentPets = [];

  final Map<String, AnimationController> _wiggleControllers = {};
  final ScrollController _areasScrollController = ScrollController();
  Timer? _areasTimer;

  @override
  void initState() {
    super.initState();
    _loadPawtnerDetails();
    _loadFurrentPets();
  }

  void _startAvailableAreasMarquee() {
    _areasTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_areasScrollController.hasClients) return;

      _areasTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        if (!_areasScrollController.hasClients) return;

        final maxScroll = _areasScrollController.position.maxScrollExtent;
        final current = _areasScrollController.offset;

        if (maxScroll <= 0) return;

        if (current >= maxScroll) {
          _areasScrollController.jumpTo(0);
        } else {
          _areasScrollController.jumpTo(current + 1);
        }
      });
    });
  }

  Future<void> _loadPawtnerDetails() async {
    setState(() => isLoading = true);

    try {
      final pawtnerResponse = await supabase
          .from('pawtners')
          .select()
          .eq('id', widget.pawtnerId)
          .single();

      pawtner = pawtnerResponse as Map<String, dynamic>?;

      final servicesResponse = await supabase
          .from('services')
          .select()
          .eq('pawtner_id', widget.pawtnerId)
          .eq('is_public', true);

      final services = (servicesResponse as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      servicesByType.clear();
      for (var s in services) {
        final type = s['service_type'] ?? 'Other';
        if (!servicesByType.containsKey(type)) {
          servicesByType[type] = [];
        }
        servicesByType[type]!.add(s);
      }

      _tabController = TabController(length: serviceTypes.length, vsync: this);

      for (var list in servicesByType.values) {
        for (var service in list) {
          final serviceId = service['id'].toString();
          _wiggleControllers[serviceId] = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
            lowerBound: -0.05,
            upperBound: 0.05,
          );
        }
      }

      if (widget.initialServiceId != null) {
        _serviceIdToScroll = widget.initialServiceId;

        for (int i = 0; i < serviceTypes.length; i++) {
          final type = serviceTypes[i];
          final list = servicesByType[type] ?? [];
          if (list.any((s) => s['id'].toString() == widget.initialServiceId)) {
            _tabController.index = i;
            break;
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            final key = _serviceKeys[_serviceIdToScroll!];
            if (key != null && key.currentContext != null) {
              Scrollable.ensureVisible(
                key.currentContext!,
                duration: const Duration(milliseconds: 300),
                alignment: 0.1,
              );

              final controller = _wiggleControllers[_serviceIdToScroll!];
              if (controller != null) {
                controller.repeat(reverse: true);
                Future.delayed(const Duration(seconds: 1), () {
                  controller.stop();
                  controller.value = 0;
                });
              }
            }
          });
        });
      }

      setState(() => isLoading = false);
      _startAvailableAreasMarquee();
    } catch (e) {
      debugPrint('Error loading pawtner details: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadFurrentPets() async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('pets')
          .select()
          .eq('furrent_id', currentUserId);

      setState(() {
        furrentPets = (response as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading furrent pets: $e');
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

  void _showSelectPetModal(String serviceId) {
    int selectedIndex = 0;

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 150,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Select Pet',
                  style: GoogleFonts.dosis(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E4B3A),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: furrentPets.isEmpty
                      ? const Center(child: Text('No pets found'))
                      : StatefulBuilder(
                          builder: (context, setStateSB) {
                            return ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              perspective: 0.003,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setStateSB(() {
                                  selectedIndex = index;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                builder: (context, index) {
                                  if (index >= furrentPets.length) return null;
                                  final pet = furrentPets[index];
                                  final isSelected = index == selectedIndex;

                                  return Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                FurrentBookAppointmentScreen(
                                              pawtnerId: pawtner!['id'],
                                              serviceId: serviceId,
                                              petId: pet['id'],
                                              pawtnerName: pawtner!['business_name'] ?? pawtner!['full_name'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 64, vertical: 6),
                                        decoration: isSelected
                                            ? BoxDecoration(
                                                color: const Color(0xFF6E4B3A),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              )
                                            : null,
                                        child: Text(
                                          '${pet['name'] ?? 'Unnamed'} (${pet['type'] ?? ''})',
                                          style: GoogleFonts.dosis(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFFDDC7A9)
                                                : const Color(0xFF6E4B3A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                childCount: furrentPets.length,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final serviceId = service['id'].toString();
    _serviceKeys[serviceId] = GlobalKey();
    final wiggle = _wiggleControllers[serviceId];

    final serviceName = service['service_name'] ?? 'Service';
    final description = service['description'] ?? '';
    final price = service['price']?.toStringAsFixed(0) ?? '0';
    final durationMinutes = service['duration_minutes'] ?? 0;
    final serviceType = service['service_type'] ?? 'Grooming';

    String durationText;
    if (durationMinutes < 60) {
      durationText = '$durationMinutes minutes';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      durationText = minutes == 0
          ? '$hours ${hours == 1 ? 'hour' : 'hours'}'
          : '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes minutes';
    }

    return AnimatedBuilder(
      animation: wiggle ?? const AlwaysStoppedAnimation(0),
      builder: (context, child) {
        final offset = wiggle != null ? wiggle.value * 10 : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          final currentIndex = serviceTypes.indexOf(serviceType);
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < 0) {
              if (currentIndex < serviceTypes.length - 1) {
                _tabController.animateTo(currentIndex + 1);
                setState(() {});
              }
            } else if (details.primaryVelocity! > 0) {
              if (currentIndex > 0) {
                _tabController.animateTo(currentIndex - 1);
                setState(() {});
              }
            }
          }
        },
        child: Container(
          key: _serviceKeys[serviceId],
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
                children: [
                  Expanded(
                    child: Text(
                      serviceName,
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                  IntrinsicWidth(
                    child: Text(
                      '₱$price',
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.dosis(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Duration: $durationText',
                      style: GoogleFonts.dosis(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showSelectPetModal(serviceId);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6E4B3A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Book Now',
                        style: GoogleFonts.dosis(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDC7A9),
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
  }

  Widget _buildHeader() {
    if (pawtner == null) return const SizedBox();

    final businessName = pawtner?['business_name'] ?? '';
    final pawtnerFullName = pawtner?['full_name'] ?? 'Pawtner';
    final displayName = businessName.isNotEmpty ? businessName : pawtnerFullName;

    final ratingFuture = _getAverageRating(widget.pawtnerId);
    final businessAddress = pawtner?['business_address'] ?? '';
    final city = pawtner?['city'] ?? '';
    final availableAreas = pawtner?['available_areas'] ?? '';

    final fullAddress = [businessAddress, city]
        .where((e) => e.toString().trim().isNotEmpty)
        .join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          displayName,
          style: GoogleFonts.dosis(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6E4B3A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        FutureBuilder<double>(
          future: ratingFuture,
          builder: (context, snapshot) {
            final rating = snapshot.data ?? 0.0;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        FurrentPawtnerRatingsScreen(pawtnerId: widget.pawtnerId),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFF6E4B3A), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'See all reviews',
                    style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6E4B3A),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (fullAddress.isNotEmpty)
          Text(
            'Shop Location: $fullAddress',
            style: GoogleFonts.dosis(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6E4B3A),
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 4),
        if (availableAreas.toString().trim().isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Home Service Areas:',
                style: GoogleFonts.dosis(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E4B3A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: ListView(
                    controller: _areasScrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Center(
                        child: Text(
                          '$availableAreas   •   $availableAreas   ',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          style: GoogleFonts.dosis(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6E4B3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPillTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(serviceTypes.length, (index) {
          final isSelected = _tabController.index == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
                setState(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6E4B3A)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6E4B3A),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  serviceTypes[index],
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
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            image: pawtner?['profile_picture_url'] != null
                                ? DecorationImage(
                                    image: NetworkImage(
                                        pawtner!['profile_picture_url']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: const Color(0xFFDDC7A9),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back,
                                  color: Color(0xFF6E4B3A)),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 80),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        children: [
                          _buildPillTabs(),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 500,
                            child: TabBarView(
                              controller: _tabController,
                              children: serviceTypes.map((type) {
                                final services = servicesByType[type] ?? [];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: services.isEmpty
                                      ? Center(
                                          child: Text(
                                            'No services available',
                                            style: GoogleFonts.dosis(
                                                fontSize: 16,
                                                color: const Color(
                                                    0xFF6E4B3A)),
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _scrollController,
                                          itemCount: services.length,
                                          padding: EdgeInsets.zero,
                                          itemBuilder: (context, index) =>
                                              _buildServiceCard(
                                                  services[index]),
                                        ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 120,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildHeader(),
                    ),
                  ),
                ),
                if (pawtner != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () async {
                        final currentUserId = supabase.auth.currentUser!.id;
                        final pawtnerId = pawtner!['id'];

                        final existing = await supabase
                            .from('conversations')
                            .select()
                            .eq('furrent_id', currentUserId)
                            .eq('pawtner_id', pawtnerId)
                            .maybeSingle();

                        String conversationId;

                        if (existing != null) {
                          conversationId = existing['id'];
                        } else {
                          final inserted = await supabase.from('conversations').insert({
                            'furrent_id': currentUserId,
                            'pawtner_id': pawtnerId,
                            'last_message': '',
                            'last_message_at': DateTime.now().toIso8601String(),
                          }).select().single();

                          conversationId = inserted['id'];
                        }

                        if (!mounted) return;

                        final displayName = (pawtner!['business_name'] ?? '').isNotEmpty
                            ? pawtner!['business_name']
                            : pawtner!['full_name'];

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conversationId,
                              otherUserId: pawtnerId,
                              otherUserName: displayName,
                              otherUserAvatar: pawtner!['profile_picture_url'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6E4B3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Chat with Pawtner',
                          style: GoogleFonts.dosis(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDDC7A9),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _areasTimer?.cancel();
    _areasScrollController.dispose();

    for (var c in _wiggleControllers.values) {
      c.dispose();
    }
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}