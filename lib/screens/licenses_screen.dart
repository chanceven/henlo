import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

class LicensesScreen extends StatefulWidget {
  const LicensesScreen({super.key});

  @override
  State<LicensesScreen> createState() => _LicensesScreenState();
}

class _PackageLicense {
  final String name;
  final String text;
  _PackageLicense(this.name, this.text);
}

class _LicensesScreenState extends State<LicensesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<_PackageLicense> _all = [];
  List<_PackageLicense> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final Map<String, StringBuffer> grouped = {};

    await for (final license in LicenseRegistry.licenses) {
      final text = license.paragraphs.map((e) => e.text).join('\n');
      for (final pkg in license.packages) {
        grouped.putIfAbsent(pkg, () => StringBuffer());
        grouped[pkg]!.writeln(text);
        grouped[pkg]!.writeln();
      }
    }

    final items = grouped.entries
        .map((e) => _PackageLicense(e.key, e.value.toString().trim()))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _all = items;
      _filtered = items;
      _loading = false;
    });
  }

  void _filter(String value) {
    final q = value.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all
            .where((e) =>
                e.name.toLowerCase().contains(q) ||
                e.text.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Open Source Licenses',
          style: GoogleFonts.dosis(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6E4B3A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filter,
                      style: GoogleFonts.dosis(
                        fontSize: 16,
                        color: const Color(0xFF6E4B3A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search packages',
                        hintStyle: GoogleFonts.dosis(
                          fontSize: 16,
                          color: const Color(0xFFBDBDBD),
                        ),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No licenses found.',
                            style: GoogleFonts.dosis(
                              fontSize: 16,
                              color: const Color(0xFF6E4B3A),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final item = _filtered[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: const Color(0xFF6E4B3A),
                                ),
                                child: ExpansionTile(
                                  iconColor: const Color(0xFF6E4B3A),
                                  collapsedIconColor: const Color(0xFF6E4B3A),
                                  title: Text(
                                    item.name,
                                    style: GoogleFonts.dosis(
                                      fontSize: 16,
                                      color: const Color(0xFF6E4B3A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: const Color(0xFFF8F8F8),
                                      padding: const EdgeInsets.all(16),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 300,
                                        ),
                                        child: Scrollbar(
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              item.text,
                                              style: GoogleFonts.dosis(
                                                fontSize: 14,
                                                color: const Color(0xFF6E4B3A),
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
