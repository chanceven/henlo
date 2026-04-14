import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'furrent_pawtner_detail_screen.dart';

class FurrentSearchScreen extends StatefulWidget {
  const FurrentSearchScreen({super.key});

  @override
  State<FurrentSearchScreen> createState() => _FurrentSearchScreenState();
}

class _FurrentSearchScreenState extends State<FurrentSearchScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;
  bool isLoading = false;

  List<Map<String, dynamic>> results = [];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => isLoading = true);

    try {
      // Search services
      final services = await supabase
          .from('services')
          .select('id, service_name, service_type, pawtner_id, pawtners!inner(business_name)')
          .ilike('service_name', '%$query%')
          .limit(10);

      // Search pawtners
      final pawtners = await supabase
          .from('pawtners')
          .select('id, full_name, business_name')
          .or('full_name.ilike.%$query%,business_name.ilike.%$query%')
          .limit(10);

      // Merge results
      final merged = [
        ...(services as List).map((e) => {
              'title': e['service_name'],
              'subtitle':
                  "${e['service_type']} • ${e['pawtners']['business_name'] ?? ''}",
              'icon': Icons.pets,
              'pawtnerId': e['pawtner_id'],
              'serviceId': e['id'],
            }),
        ...(pawtners as List).map((e) => {
              'title': e['business_name']?.isNotEmpty == true
                  ? e['business_name']
                  : e['full_name'],
              'subtitle': '',
              'icon': Icons.store,
              'pawtnerId': e['id'],
            }),
      ];

      setState(() {
        results = merged.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6E4B3A);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8F8F8),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: primaryColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: primaryColor),
          decoration: const InputDecoration(
            hintText: 'Search for services or pawtners',
            hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
            border: InputBorder.none,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : results.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];

                    final isService = item['subtitle'] != ''; // service vs pawtner

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FurrentPawtnerDetailScreen(
                              pawtnerId: item['pawtnerId'],
                              initialServiceId:
                                  isService ? item['serviceId'] : null,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.brown.shade100,
                          child: Icon(item['icon'], color: primaryColor),
                        ),
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item['title'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6E4B3A)),
                          ),
                        ),
                        subtitle: isService
                            ? Text(
                                item['subtitle'] ?? '',
                                style: const TextStyle(color: Color(0xFF6E4B3A)),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
