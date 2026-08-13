import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactUsScreen extends StatefulWidget {
  final String userType;

  const ContactUsScreen({
    super.key,
    required this.userType,
  });

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? selectedSubject;
  final TextEditingController _messageController = TextEditingController();

  bool isSubmitting = false;
  bool emailValid = true;
  bool isSubjectDropdownOpen = false;
  final GlobalKey _subjectKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateForm);
    _emailController.addListener(_validateForm);
    _messageController.addListener(_validateForm);
  }

  bool get isFormValid {
    final nameValid = _nameController.text.trim().isNotEmpty;
    final emailFieldValid = _emailController.text.trim().isNotEmpty &&
        _isEmailValid(_emailController.text.trim());
    final subjectValid = selectedSubject != null;
    final messageValid = _messageController.text.trim().isNotEmpty;
    return nameValid && emailFieldValid && subjectValid && messageValid;
  }

  void _validateForm() {
    setState(() {
      emailValid = _emailController.text.isEmpty ||
          _isEmailValid(_emailController.text.trim());
    });
  }

  bool _isEmailValid(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _hideSubjectDropdown() {
    if (isSubjectDropdownOpen) {
      setState(() {
        isSubjectDropdownOpen = false;
      });
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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
          'Contact Us',
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
      body: GestureDetector(
        onTap: () {
          _hideSubjectDropdown();
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              IgnorePointer(
                ignoring: isSubjectDropdownOpen,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_nameController, 'Full Name'),
                      _buildEmailField(_emailController, 'Email'),
                      _buildSubjectDropdown(),
                      _buildMessageField(
                          _messageController, 'Enter your message'),
                    ],
                  ),
                ),
              ),
              if (isSubjectDropdownOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _hideSubjectDropdown,
                    behavior: HitTestBehavior.opaque,
                    child: Container(color: Colors.transparent),
                  ),
                ),
              _buildSubjectOverlay(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6E4B3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isFormValid && !isSubmitting ? _submitForm : null,
              child: isSubmitting
                  ? const CircularProgressIndicator(
                      color: Color(0xFFDDC7A9),
                    )
                  : Text(
                      'Submit',
                      style: GoogleFonts.dosis(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFDDC7A9),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFFFF),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: _hideSubjectDropdown,
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
        },
        style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.dosis(
            color: const Color(0xFFBDBDBD),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField(
      TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!emailValid)
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 4),
            child: Text(
              'Please enter a valid email',
              style: GoogleFonts.dosis(
                color: const Color(0xFF8B0000),
                fontSize: 12,
              ),
            ),
          ),
        _buildTextField(controller, placeholder,
            keyboardType: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    final isExpanded = isSubjectDropdownOpen;

    return Column(
      key: _subjectKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();

            setState(() {
              isSubjectDropdownOpen = !isSubjectDropdownOpen;
            });
          },
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: const Color(0xFF6E4B3A),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedSubject ?? 'Subject',
                    style: GoogleFonts.dosis(
                      color: selectedSubject != null
                          ? const Color(0xFF6E4B3A)
                          : const Color(0xFFBDBDBD),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
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
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSubjectOverlay() {
    if (!isSubjectDropdownOpen) {
      return const SizedBox.shrink();
    }

    final renderBox =
        _subjectKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return const SizedBox.shrink();
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    const subjects = [
      'General Inquiry',
      'Account & Profile',
      'Booking',
      'Technical Issue',
      'Report a Problem',
      'Feedback & Suggestions',
      'Other',
    ];

    final screenSize = MediaQuery.of(context).size;
    final calculatedHeight = subjects.length * 45.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 74;

    final spaceBelow =
        screenSize.height - position.dy - size.height - bottomPadding;

    final openUpward = spaceBelow < calculatedHeight;

    final topOffset = openUpward
        ? (position.dy -
            calculatedHeight -
            kToolbarHeight -
            MediaQuery.of(context).padding.top -
            8)
        : (position.dy +
            size.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.top -
            12);

    return Positioned(
      top: topOffset,
      left: position.dx,
      width: size.width,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFF6E4B3A),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: subjects.map(
              (subject) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedSubject = subject;
                      isSubjectDropdownOpen = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    color: subject == selectedSubject
                        ? const Color(0xFF6E4B3A).withValues(alpha: 0.2)
                        : Colors.transparent,
                    child: Text(
                      subject,
                      style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageField(
      TextEditingController controller, String placeholder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFFFFFFFF),
      child: TextField(
        controller: controller,
        maxLines: 6,
        onTap: _hideSubjectDropdown,
        onTapOutside: (_) {
          FocusScope.of(context).unfocus();
        },
        style: GoogleFonts.dosis(color: const Color(0xFF6E4B3A)),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: GoogleFonts.dosis(
            color: const Color(0xFFBDBDBD),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6E4B3A), width: 2),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() => isSubmitting = true);

    try {
      await Supabase.instance.client.functions.invoke(
        'contact-us',
        body: {
          'name':
              '[${_capitalize(widget.userType)}] ${_nameController.text.trim()}',
          'email': _emailController.text.trim(),
          'subject': selectedSubject,
          'message': _messageController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(
            'Message submitted successfully',
            style: GoogleFonts.dosis(
              color: const Color(0xFFDDC7A9),
            ),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );

      _nameController.clear();
      _emailController.clear();
      selectedSubject = null;
      _messageController.clear();

      setState(() {
        emailValid = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          content: Text(
            'Failed to submit message',
            style: GoogleFonts.dosis(
              color: const Color(0xFFDDC7A9),
            ),
          ),
          backgroundColor: const Color(0xFF6E4B3A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }
}
