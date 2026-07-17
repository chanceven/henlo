import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import 'pawtner_bookings_screen.dart';
import 'pawtner_messages_screen.dart';
import 'pawtner_profile_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'pawtner_booking_detail_screen.dart';

class PawtnerDashboardScreen extends StatefulWidget {
  const PawtnerDashboardScreen({super.key});

  @override
  State<PawtnerDashboardScreen> createState() => _PawtnerDashboardScreenState();
}

class _PawtnerDashboardScreenState extends State<PawtnerDashboardScreen> {
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? pawtnerData;
  List<Map<String, dynamic>> bookingsToday = [];
  List<Map<String, dynamic>> bookingsUpcoming = [];
  double? pawtnerRating;

  int _selectedNavIndex = 0;

  int _unreadMessagesCount = 0;
  int _unreadNotificationsCount = 0;

  final List<Map<String, String>> mainServices = [
    {'service_name': 'Grooming', 'service_type': 'grooming'},
    {'service_name': 'Boarding', 'service_type': 'boarding'},
    {'service_name': 'Training', 'service_type': 'training'},
  ];

  late RealtimeChannel _bookingsChannel;

  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
    _setupRealtimeBookings();
    _loadUnreadNotificationsCount();
    _setupRealtimeNotifications();
  }

  @override
  void dispose() {
    supabase.removeChannel(_bookingsChannel);
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _showDocumentUploadModal(
      Map<String, dynamic> pawtnerData) async {
    String? businessPermitName =
        pawtnerData['business_permit_url']?.toString().split('/').last;
    String? governmentIdName =
        pawtnerData['govt_id_url']?.toString().split('/').last;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Complete Your Profile',
                      style: GoogleFonts.dosis(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Please upload your documents to start using the app.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dosis(
                        fontSize: 14,
                        color: const Color(0xFF6E4B3A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Business Permit',
                      style: GoogleFonts.dosis(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6E4B3A))),
                  const SizedBox(height: 6),
                  _uploadBoxModal(
                    fileName: businessPermitName,
                    onUpload: () async {
                      final name = await _uploadDocumentFromModal('permit');
                      if (name != null) {
                        setModalState(() => businessPermitName = name);
                      }
                    },
                    onDelete: () async {
                      final user = supabase.auth.currentUser;
                      if (user == null) return;
                      await supabase.from('pawtners').update(
                          {'business_permit_url': null}).eq('id', user.id);
                      setModalState(() => businessPermitName = null);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Government ID',
                      style: GoogleFonts.dosis(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6E4B3A))),
                  const SizedBox(height: 6),
                  _uploadBoxModal(
                    fileName: governmentIdName,
                    onUpload: () async {
                      final name = await _uploadDocumentFromModal('govt');
                      if (name != null) {
                        setModalState(() => governmentIdName = name);
                      }
                    },
                    onDelete: () async {
                      final user = supabase.auth.currentUser;
                      if (user == null) return;
                      await supabase
                          .from('pawtners')
                          .update({'govt_id_url': null}).eq('id', user.id);
                      setModalState(() => governmentIdName = null);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: businessPermitName != null &&
                                governmentIdName != null
                            ? const Color(0xFF6E4B3A)
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                          businessPermitName != null && governmentIdName != null
                              ? () => Navigator.pop(context)
                              : null,
                      child: Text(
                        'Done',
                        style: GoogleFonts.dosis(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFDDC7A9),
                        ),
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
  }

  Widget _uploadBoxModal({
    required String? fileName,
    required VoidCallback onUpload,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF6E4B3A)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (fileName != null)
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close, color: Color(0xFF8B0000)),
            ),
          if (fileName != null) const SizedBox(width: 10),
          Expanded(
            child: Text(
              fileName ?? 'No file uploaded',
              style: GoogleFonts.dosis(
                fontSize: 14,
                color: const Color(0xFF6E4B3A),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            height: 42,
            width: 100,
            child: TextButton(
              onPressed: onUpload,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFDDC7A9),
              ),
              child: Text(
                'Upload',
                style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadDocumentFromModal(String type) async {
    final result = await showModalBottomSheet<FilePickerResult?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFF6E4B3A)),
              title: Text('Select a file',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A))),
              onTap: () async {
                final picked = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
                  withData: true,
                );
                if (mounted) Navigator.pop(context, picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF6E4B3A)),
              title: Text('Take a photo',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A))),
              onTap: () async {
                final picker = ImagePicker();
                final XFile? image = await picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 80,
                );
                if (image == null) {
                  if (mounted) Navigator.pop(context, null);
                  return;
                }
                final bytes = await image.readAsBytes();
                final result = FilePickerResult([
                  PlatformFile(
                      name: image.name, bytes: bytes, size: bytes.length),
                ]);
                if (mounted) Navigator.pop(context, result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: Color(0xFF8B0000)),
              title: Text('Cancel',
                  style: GoogleFonts.dosis(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B0000))),
              onTap: () => Navigator.pop(context, null),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (result == null) return null;

    final picked = result.files.first;
    final bytes = picked.bytes;
    final name = picked.name;
    if (bytes == null) return null;

    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final ext = name.split('.').last;
    final remoteFileName = type == 'permit'
        ? '${user.id}/business_permit.$ext'
        : '${user.id}/govt_id.$ext';
    final bucketName = type == 'permit' ? 'business_permits' : 'govt_ids';

    try {
      await supabase.storage
          .from(bucketName)
          .uploadBinary(remoteFileName, bytes);
      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(remoteFileName);

      if (type == 'permit') {
        await supabase
            .from('pawtners')
            .update({'business_permit_url': publicUrl}).eq('id', user.id);
      } else {
        await supabase
            .from('pawtners')
            .update({'govt_id_url': publicUrl}).eq('id', user.id);
      }

      return name;
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
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
          .select(
              '*, pets(type, name, profile_picture_url), services(service_name, service_type), furrents(*)')
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
          .select(
              '*, pets(type, name, profile_picture_url), services(service_name, service_type), furrents(*)')
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

      if (pawtner != null) {
        final hasPermit = pawtner['business_permit_url'] != null;
        final hasGovtId = pawtner['govt_id_url'] != null;
        if (!hasPermit || !hasGovtId) {
          if (mounted) await _showDocumentUploadModal(pawtner);
        }
      }
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

  void _setupRealtimeNotifications() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _notificationsChannel = supabase
        .channel('notifications-${user.id}')
        .onPostgresChanges(
          schema: 'public',
          table: 'notifications',
          event: PostgresChangeEvent.all,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (mounted) _loadUnreadNotificationsCount();
          },
        )
        .subscribe();
  }

  Future<void> _loadUnreadCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('conversations')
        .select('unread_count_pawtner')
        .eq('pawtner_id', user.id);

    final count = (data as List).fold<int>(0, (sum, row) {
      return sum + ((row['unread_count_pawtner'] ?? 0) as num).toInt();
    });

    setState(() => _unreadMessagesCount = count);
  }

  Future<void> _loadUnreadNotificationsCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    setState(() => _unreadNotificationsCount = (data as List).length);
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
                            final pet =
                                booking['pets'] as Map<String, dynamic>?;
                            final service =
                                booking['services'] as Map<String, dynamic>?;

                            final scheduledStart = DateTime.tryParse(
                                booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a')
                                    .format(scheduledStart)
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
                                              image: NetworkImage(
                                                  pet?['profile_picture_url']),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                "View Details",
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
                            final pet =
                                booking['pets'] as Map<String, dynamic>?;
                            final service =
                                booking['services'] as Map<String, dynamic>?;

                            final scheduledStart = DateTime.tryParse(
                                booking['scheduled_start'] ?? '');
                            final formattedDate = scheduledStart != null
                                ? DateFormat('MMM d, h:mm a')
                                    .format(scheduledStart)
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
                                              image: NetworkImage(
                                                  pet!['profile_picture_url']),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                              child: Text(
                                                "View Details",
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
        onTap: (index) {
          _onNavTapped(index);
          if (index == 2) {
            _loadUnreadCount();
            _loadUnreadNotificationsCount();
          }
        },
        selectedItemColor: const Color(0xFF6E4B3A),
        unselectedItemColor: const Color(0xFFBBBBBB),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.book_online), label: 'Bookings'),
          BottomNavigationBarItem(
            label: 'Messages',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.message),
                if (_unreadMessagesCount > 0 || _unreadNotificationsCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
