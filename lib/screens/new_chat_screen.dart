import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  final String currentUserType; // "furrent" or "pawtner"

  const NewChatScreen({super.key, required this.currentUserType});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final supabase = Supabase.instance.client;

  String searchQuery = '';
  List<Map<String, dynamic>> users = [];
  bool isSearching = false;
  bool noResults = false;

  Future<void> _searchUsers(String query) async {
    setState(() {
      isSearching = true;
      noResults = false;
      users = [];
    });

    final tableName =
        widget.currentUserType == "furrent" ? "pawtners" : "furrents";

    try {
      List<Map<String, dynamic>> results;

      if (widget.currentUserType == "pawtner") {
        // Pawtner searching furrents by full_name (start-of-word)
        results = List<Map<String, dynamic>>.from(await supabase
            .from(tableName)
            .select('id, full_name, profile_picture_url')
            .ilike('full_name', '$query%')
            .limit(20));
      } else {
        // Furrent searching pawtners by business_name (start-of-word), fallback to full_name
        final data = await supabase
            .from(tableName)
            .select('id, full_name, business_name, profile_picture_url')
            .limit(20);

        results = List<Map<String, dynamic>>.from(data).where((user) {
          final nameToSearch = (user['business_name'] != null &&
                  user['business_name'].toString().trim().isNotEmpty)
              ? user['business_name']
              : (user['full_name'] ?? '');
          return nameToSearch.toLowerCase().startsWith(query.toLowerCase());
        }).toList();
      }

      setState(() {
        users = results;
        noResults = results.isEmpty;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() {
        users = [];
        noResults = true;
      });
    }
  }

  Future<void> _startChat(Map<String, dynamic> otherUser) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    final String furrentId =
        widget.currentUserType == "furrent"
            ? currentUser.id
            : otherUser['id'];

    final String pawtnerId =
        widget.currentUserType == "pawtner"
            ? currentUser.id
            : otherUser['id'];

    final existingConversation = await supabase
        .from('conversations')
        .select('*')
        .eq('furrent_id', furrentId)
        .eq('pawtner_id', pawtnerId)
        .maybeSingle();

    Map<String, dynamic> conversation;

    if (existingConversation != null) {
      conversation = existingConversation;
    } else {
      final newConversation = await supabase
          .from('conversations')
          .insert({
            'furrent_id': furrentId,
            'pawtner_id': pawtnerId,
            'last_message': '',
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      conversation = newConversation;
    }

    final displayName =
        (widget.currentUserType == "furrent" &&
                otherUser['business_name'] != null &&
                otherUser['business_name'].toString().trim().isNotEmpty)
            ? otherUser['business_name']
            : (otherUser['full_name'] ?? 'Unknown User');

    final convoReturned = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation['id'],
          otherUserId: otherUser['id'],
          otherUserName: displayName,
          otherUserAvatar: otherUser['profile_picture_url'] ?? '',
        ),
      ),
    );

    if (convoReturned != null) {
      Navigator.pop(context, convoReturned);
    }
  }

  Widget customText(String text,
      {double fontSize = 14, FontWeight fontWeight = FontWeight.normal}) {
    return Text(
      text,
      style: GoogleFonts.dosis(
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: const Color(0xFF6E4B3A),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hintText = widget.currentUserType == "furrent"
        ? 'Search pawtners'
        : 'Search furrents';

    return Scaffold(
      appBar: AppBar(
        title: customText('New Chat',
            fontSize: 24, fontWeight: FontWeight.w600),
        backgroundColor: const Color(0xFFF8F8F8),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SizedBox(
              height: 44,
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  searchQuery = value;
                  if (value.isNotEmpty) {
                    _searchUsers(value);
                  } else {
                    setState(() {
                      users = [];
                      isSearching = false;
                      noResults = false;
                    });
                  }
                },
                style: const TextStyle(color: Color(0xFF6E4B3A)),
                decoration: InputDecoration(
                  hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFFAAAAAA),
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: isSearching
                ? users.isNotEmpty
                    ? ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];

                          final displayName =
                              (widget.currentUserType == "furrent" &&
                                      user['business_name'] != null &&
                                      user['business_name']
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                  ? user['business_name']
                                  : user['full_name'];

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  user['profile_picture_url'] != null
                                      ? NetworkImage(user['profile_picture_url'])
                                      : null,
                              backgroundColor: const Color(0xFFDDC7A9),
                              child: user['profile_picture_url'] == null
                                  ? const Icon(Icons.person,
                                      color: Color(0xFF6E4B3A))
                                  : null,
                            ),
                            title: customText(displayName,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                            onTap: () => _startChat(user),
                          );
                        },
                      )
                    : noResults
                        ? Center(
                            child: customText('No users found',
                                fontSize: 16))
                        : const SizedBox.shrink()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
