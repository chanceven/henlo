// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FurrentFAQScreen extends StatefulWidget {
  const FurrentFAQScreen({super.key});

  @override
  State<FurrentFAQScreen> createState() => _FurrentFAQScreenState();
}

class _FurrentFAQScreenState extends State<FurrentFAQScreen> {
  final supabase = Supabase.instance.client;

  Map<String, List<Map<String, dynamic>>> faqsByCategory = {};
  Map<String, bool> expandedCategories = {};
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    setState(() => isLoading = true);

    try {
      final List<dynamic> response =
          await supabase.from('furrent_faqs').select('*').order('created_at');

      final faqList = response
          .where((item) => item != null)
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final faq in faqList) {
        final category = faq['category']?.toString() ?? 'General';
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(faq);
      }

      setState(() {
        faqsByCategory = grouped;
        expandedCategories = {for (var k in grouped.keys) k: true};
      });
    } catch (e) {
      debugPrint('Error fetching FAQs: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(
            'Failed to load FAQs',
            style: GoogleFonts.dosis(
              color: const Color(0xFFDDC7A9),
            ),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter FAQs based on search query
    final Map<String, List<Map<String, dynamic>>> filteredFaqs = {};
    faqsByCategory.forEach((category, faqs) {
      final matchingFaqs = faqs.where((faq) {
        final question = faq['question']?.toString().toLowerCase() ?? '';
        final answer = faq['answer']?.toString().toLowerCase() ?? '';
        return question.contains(searchQuery.toLowerCase()) ||
            answer.contains(searchQuery.toLowerCase());
      }).toList();
      if (matchingFaqs.isNotEmpty) {
        filteredFaqs[category] = matchingFaqs;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'FAQ',
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
      body: isLoading
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
                    child: SizedBox(
                      height: 40, // smaller height
                      child: TextField(
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                        ),
                        onChanged: (value) =>
                            setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: GoogleFonts.dosis(
                            color: const Color(0xFFBDBDBD),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          fillColor: const Color(0xFFFFFFFF),
                          filled: true,
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF6E4B3A)),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredFaqs.isEmpty
                      ? Center(
                          child: Text(
                            'No FAQs found',
                            style: GoogleFonts.dosis(
                                fontSize: 16, color: const Color(0xFF6E4B3A)),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: filteredFaqs.entries
                              .map((entry) =>
                                  _buildCategorySection(entry.key, entry.value))
                              .toList(),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategorySection(
      String category, List<Map<String, dynamic>> faqs) {
    final isExpanded = expandedCategories[category] ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              expandedCategories[category] =
                  !(expandedCategories[category] ?? true);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: GoogleFonts.dosis(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E4B3A),
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: const Color(0xFF6E4B3A),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...faqs.map((faq) => _buildFAQTile(faq)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFAQTile(Map<String, dynamic> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: const Color(0xFF6E4B3A),
        ),
        child: ExpansionTile(
          iconColor: const Color(0xFF6E4B3A),
          collapsedIconColor: const Color(0xFF6E4B3A),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: _highlightText(faq['question'] ?? 'No question'),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF8F8F8),
              child: _highlightText(faq['answer'] ?? 'No answer'),
            ),
          ],
        ),
      ),
    );
  }

  // Highlight search terms in text
  Widget _highlightText(String text) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.dosis(fontSize: 16, color: const Color(0xFF6E4B3A)),
      );
    }

    final query = searchQuery.toLowerCase();
    final lowerText = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(query, start);
      if (index < 0) {
        spans.add(TextSpan(
            text: text.substring(start),
            style: GoogleFonts.dosis(
                fontSize: 16, color: const Color(0xFF6E4B3A))));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: GoogleFonts.dosis(
                fontSize: 16, color: const Color(0xFF6E4B3A))));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: GoogleFonts.dosis(
              fontSize: 16,
              color: const Color(0xFF6E4B3A),
              backgroundColor: const Color(0xFFFFF59D))));
      start = index + query.length;
    }

    return RichText(text: TextSpan(children: spans));
  }
}
