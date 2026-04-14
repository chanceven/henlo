import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pawtner_add_service_screen.dart';
import 'pawtner_edit_service_screen.dart';

class PawtnerServicesTrainingScreen extends StatefulWidget {
  const PawtnerServicesTrainingScreen({super.key});

  @override
  State<PawtnerServicesTrainingScreen> createState() =>
      _PawtnerServicesTrainingScreenState();
}

class _PawtnerServicesTrainingScreenState
    extends State<PawtnerServicesTrainingScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> trainingServices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrainingServices();
  }

  Future<void> fetchTrainingServices() async {
    setState(() {
      isLoading = true;
    });

    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final response = await supabase
        .from('services')
        .select()
        .eq('pawtner_id', currentUser.id)
        .eq('service_type', 'Training')
        .order('created_at', ascending: false);

    setState(() {
      trainingServices = List<Map<String, dynamic>>.from(response);
      isLoading = false;
    });
  }

  Future<void> deleteService(String serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure you want to delete this service?',
              textAlign: TextAlign.center,
              style: GoogleFonts.dosis(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
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
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 120,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E4B3A)),
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFFDDC7A9)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.dosis(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await supabase.from('services').delete().eq('id', serviceId);
      await supabase
          .from('service_availability')
          .delete()
          .eq('service_id', serviceId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted successfully'),
          duration: Duration(seconds: 2),
        ),
      );

      fetchTrainingServices();
    }
  }

  String formatPrice(dynamic price) {
    if (price == null) return '₱ 0';
    if (price is num && price % 1 == 0) {
      return '₱ ${price.toInt()}';
    } else {
      return '₱ $price';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
        title: Text(
          'Training Service',
          style: GoogleFonts.dosis(
              color: const Color(0xFF6E4B3A),
              fontSize: 24,
              fontWeight: FontWeight.w600),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: trainingServices.isEmpty
                      ? Center(
                          child: Text(
                            'No Training Services yet',
                            style: GoogleFonts.dosis(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6E4B3A)),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: trainingServices.length,
                          itemBuilder: (context, index) {
                            final service = trainingServices[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x1F000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          service['service_name'] ?? '',
                                          style: GoogleFonts.dosis(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF6E4B3A)),
                                        ),
                                      ),
                                      Text(
                                        formatPrice(service['price']),
                                        style: GoogleFonts.dosis(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6E4B3A)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    service['description'] ?? '',
                                    style: GoogleFonts.dosis(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF6E4B3A)),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF6E4B3A)),
                                          onPressed: () {
                                            deleteService(service['id']);
                                          },
                                          child: Text(
                                            'Delete Service',
                                            style: GoogleFonts.dosis(
                                                color: const Color(0xFFDDC7A9),
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFDDC7A9)),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PawtnerEditServiceScreen(
                                                        serviceId:
                                                            service['id']),
                                              ),
                                            );
                                            fetchTrainingServices();
                                          },
                                          child: Text(
                                            'Edit Service',
                                            style: GoogleFonts.dosis(
                                                color: const Color(0xFF6E4B3A),
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDDC7A9)),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PawtnerAddServiceScreen()),
                        );
                        fetchTrainingServices();
                      },
                      child: Text(
                        'Add Service',
                        style: GoogleFonts.dosis(
                            color: const Color(0xFF6E4B3A),
                            fontWeight: FontWeight.w600,
                            fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
