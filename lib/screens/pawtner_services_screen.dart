import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pawtner_services_grooming_screen.dart';
import 'pawtner_services_boarding_screen.dart';
import 'pawtner_services_training_screen.dart';

class PawtnerServicesScreen extends StatefulWidget {
  const PawtnerServicesScreen({super.key});

  @override
  State<PawtnerServicesScreen> createState() => _PawtnerServicesScreenState();
}

class _PawtnerServicesScreenState extends State<PawtnerServicesScreen> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? pawtnerData;
  bool isLoading = true;

  final List<Map<String, String>> mainServices = [
    {'service_name': 'Grooming', 'service_type': 'grooming'},
    {'service_name': 'Boarding', 'service_type': 'boarding'},
    {'service_name': 'Training', 'service_type': 'training'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchPawtnerData();
  }

  Future<void> _fetchPawtnerData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final pawtner = await supabase
          .from('pawtners')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        pawtnerData = pawtner;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to load services. Try again."),
        ),
      );
    }
  }

  bool isServiceActive(String serviceType) {
    final typeOfServiceRaw = pawtnerData?['service_type'];
    if (typeOfServiceRaw == null || typeOfServiceRaw.trim().isEmpty) return false;

    final services = typeOfServiceRaw
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();

    return services.contains(serviceType.toLowerCase());
  }

  Color _serviceButtonColor(bool active) =>
      active ? const Color(0xFFDDC7A9) : const Color(0xFFCCCCCC);

  IconData _iconForService(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'grooming':
        return Icons.content_cut;
      case 'boarding':
        return Icons.home;
      case 'training':
        return Icons.fitness_center;
      default:
        return Icons.pets;
    }
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

  Widget _buildServiceButton(String service, IconData icon, bool active) {
    return Column(
      children: [
        GestureDetector(
          onTap: active
              ? () {
                  if (service.toLowerCase() == 'grooming') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PawtnerServicesGroomingScreen()));
                  } else if (service.toLowerCase() == 'boarding') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PawtnerServicesBoardingScreen()));
                  } else if (service.toLowerCase() == 'training') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PawtnerServicesTrainingScreen()));
                  }
                }
              : null,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _serviceButtonColor(active),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(icon,
                  color: active ? const Color(0xFF6E4B3A) : Colors.white,
                  size: 40),
            ),
          ),
        ),
        const SizedBox(height: 8),
        customText(
          service,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6E4B3A),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
        title: customText('My Services',
            fontSize: 24, fontWeight: FontWeight.w600, color: const Color(0xFF6E4B3A)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16), // <- EXACT PADDING YOU WANTED
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: mainServices.map((service) {
                        final name = service['service_name']!;
                        final type = service['service_type']!;
                        final active = isServiceActive(type);
                        return _buildServiceButton(name, _iconForService(type), active);
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }