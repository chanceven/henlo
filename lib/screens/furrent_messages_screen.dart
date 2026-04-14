import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';

class FurrentMessagesScreen extends StatefulWidget {
  const FurrentMessagesScreen({super.key});

  @override
  State<FurrentMessagesScreen> createState() => _FurrentMessagesScreenState();
}

class _FurrentMessagesScreenState extends State<FurrentMessagesScreen> {
  final supabase = Supabase.instance.client;

  int selectedTabIndex = 0; // 0: Chats, 1: Notifications
  String searchQuery = '';

  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;

  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime(); // automatic update
  }

  @override
  void dispose() {
    supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        chats = [];
        notifications = [];
        isLoading = false;
      });
      return;
    }

    try {
      final chatData = await supabase
          .from('conversations')
          .select('*, pawtners(id, full_name, business_name, profile_picture_url)')
          .eq('furrent_id', user.id)
          .order('last_message_at', ascending: false);

      final notificationData = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        chats = List<Map<String, dynamic>>.from(chatData);
        notifications = List<Map<String, dynamic>>.from(notificationData);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _setupRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _realtimeChannel = supabase
        .channel('public:conversations:furrent_id=${user.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'furrent_id',
            value: user.id,
          ),
          callback: (payload) async {
            final convo = await supabase
                .from('conversations')
                .select('*, pawtners(id, full_name, business_name, profile_picture_url)')
                .eq('id', payload.newRecord['id'])
                .single();

            final index = chats.indexWhere((c) => c['id'] == convo['id']);
            if (index != -1) {
              setState(() {
                chats[index] = convo;
              });
            } else {
              setState(() {
                chats.insert(0, convo);
              });
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'furrent_id',
            value: user.id,
          ),
          callback: (payload) async {
            final convo = await supabase
                .from('conversations')
                .select('*, pawtners(id, full_name, business_name, profile_picture_url)')
                .eq('id', payload.newRecord['id'])
                .single();

            final index = chats.indexWhere((c) => c['id'] == convo['id']);
            if (index != -1) {
              setState(() {
                chats[index] = convo;
              });
            } else {
              setState(() {
                chats.insert(0, convo);
              });
            }
          },
        )
        .subscribe();
  }

  Widget customText(String text,
      {double fontSize = 14,
      FontWeight fontWeight = FontWeight.normal,
      Color color = const Color(0xFF000000)}) {
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

  String formatTime12Hour(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $ampm";
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Chats', 'Notifications'];

    List<Map<String, dynamic>> itemsToShow =
        selectedTabIndex == 0 ? chats : notifications;

    if (searchQuery.isNotEmpty) {
      if (selectedTabIndex == 0) {
        itemsToShow = itemsToShow
            .where((chat) {
              final pawtner = chat['pawtners'] ?? {};

              final nameToSearch =
                  (pawtner['business_name'] != null &&
                          pawtner['business_name'].toString().trim().isNotEmpty)
                      ? pawtner['business_name']
                      : (pawtner['full_name'] ?? '');

              return nameToSearch
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
            })
            .toList();
      } else {
        itemsToShow = itemsToShow
            .where((notif) => (notif['title'] as String)
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      }
    }

    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF6E4B3A)),
        title: customText(
          'Messages',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6E4B3A),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 16),
                Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedTabIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedTabIndex = index);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6E4B3A)
                                : const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: customText(
                              tabs[index],
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFFDDC7A9)
                                  : const Color(0xFF6E4B3A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                          color: Color(0xFFBDBDBD),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        fillColor: const Color(0xFFFFFFFF),
                        filled: true,
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF6E4B3A)),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: itemsToShow.isEmpty
                      ? Center(
                          child: customText(
                            selectedTabIndex == 0
                                ? 'No chats'
                                : 'No notifications',
                            fontSize: 16,
                            color: const Color(0xFF6E4B3A),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: itemsToShow.length,
                          itemBuilder: (context, index) {
                            final item = itemsToShow[index];
                            if (selectedTabIndex == 0) {
                              final pawtner =
                                  item['pawtners'] as Map<String, dynamic>? ?? {};

                              final String displayName =
                                  (pawtner['business_name'] != null &&
                                          pawtner['business_name']
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                      ? pawtner['business_name']
                                      : (pawtner['full_name'] ?? '');

                              final profilePic =
                                  pawtner['profile_picture_url'] ?? '';
                              final lastMessageDate = item['last_message_at'] !=
                                      null
                                  ? DateTime.parse(item['last_message_at'])
                                      .toLocal()
                                  : null;

                              String formattedDate = '';
                              if (lastMessageDate != null) {
                                final now = DateTime.now();
                                if (lastMessageDate.year == now.year &&
                                    lastMessageDate.month == now.month &&
                                    lastMessageDate.day == now.day) {
                                  formattedDate = formatTime12Hour(lastMessageDate);
                                } else {
                                  formattedDate =
                                      "${lastMessageDate.month}/${lastMessageDate.day}/${lastMessageDate.year}";
                                }
                              }

                              String lastMessageText = item['last_message'] ?? '';
                              final lastMessageSender =
                                  item['last_message_sender_id'];
                              if (lastMessageSender == user?.id) {
                                lastMessageText = "You: $lastMessageText";
                              }

                              final isUnread =
                                  item['last_message_read'] == false &&
                                      lastMessageSender != user?.id;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        conversationId: item['id'],
                                        otherUserId: pawtner['id'],
                                        otherUserName: displayName,
                                        otherUserAvatar:
                                            pawtner['profile_picture_url'] ?? '',
                                      ),
                                    ),
                                  ).then((_) => _loadData());
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
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
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor:
                                            const Color(0xFF6E4B3A),
                                        backgroundImage: profilePic.isNotEmpty
                                            ? NetworkImage(profilePic)
                                            : null,
                                        child: profilePic.isEmpty
                                            ? const Icon(Icons.person,
                                                size: 24, color: Color(0xFFDDC7A9))
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                customText(
                                                  displayName,
                                                  fontWeight: isUnread
                                                      ? FontWeight.w800
                                                      : FontWeight.w600,
                                                  color: const Color(0xFF6E4B3A),
                                                ),
                                                customText(
                                                  formattedDate,
                                                  fontSize: 12,
                                                  color: const Color(0xFF6E4B3A),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            customText(
                                              lastMessageText,
                                              fontSize: 14,
                                              fontWeight: isUnread
                                                  ? FontWeight.w700
                                                  : FontWeight.normal,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
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
                                    customText(
                                      item['title'] ?? '',
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                    const SizedBox(height: 4),
                                    customText(
                                      item['messages'] ?? '',
                                      fontSize: 14,
                                      color: const Color(0xFF6E4B3A),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF6E4B3A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.add, color: Color(0xFFDDC7A9)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NewChatScreen(currentUserType: "furrent"),
              ),
            ).then((_) => _loadData());
          },
        ),
      ),
    );
  }
}
