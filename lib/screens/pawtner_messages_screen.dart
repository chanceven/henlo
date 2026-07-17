// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'new_chat_screen.dart';
import 'pawtner_booking_detail_screen.dart';

class PawtnerMessagesScreen extends StatefulWidget {
  const PawtnerMessagesScreen({super.key});

  @override
  State<PawtnerMessagesScreen> createState() => _PawtnerMessagesScreenState();
}

class _PawtnerMessagesScreenState extends State<PawtnerMessagesScreen> {
  final supabase = Supabase.instance.client;

  int selectedTabIndex = 0; // 0: Chats, 1: Notifications
  String searchQuery = '';

  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;

  int unreadChatsCount = 0;
  int unreadNotificationsCount = 0;

  late RealtimeChannel _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupRealtime();
  }

  @override
  void dispose() {
    supabase.removeChannel(_realtimeChannel);
    super.dispose();
  }

  Future<void> _loadData() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      setState(() {
        chats = [];
        notifications = [];
        isLoading = false;
      });
      return;
    }

    try {
      // Fetch conversations where pawtner is current user and include furrent info
      final chatData = await supabase
          .from('conversations')
          .select('*, furrents(id, full_name, profile_picture_url)')
          .eq('pawtner_id', currentUser.id)
          .or('hidden_for_pawtner.is.null,hidden_for_pawtner.eq.false')
          .not('last_message', 'is', null)
          .neq('last_message', '')
          .order('last_message_at', ascending: false);

      final notificationData = await supabase
          .from('notifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      int getCount(dynamic value) {
        if (value == null) return 0;
        return (value as num).toInt();
      }

      final unreadChats = chatData.fold<int>(0, (sum, chat) {
        return sum + getCount(chat['unread_count_pawtner']);
      });

      final unreadNotifications = notificationData.where((notif) {
        return notif['is_read'] == false;
      }).length;

      setState(() {
        chats = List<Map<String, dynamic>>.from(chatData);
        notifications = List<Map<String, dynamic>>.from(notificationData);
        unreadChatsCount = unreadChats;
        unreadNotificationsCount = unreadNotifications;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _setupRealtime() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    _realtimeChannel = supabase
        .channel('public:conversations:pawtner_id=${currentUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pawtner_id',
            value: currentUser.id,
          ),
          callback: (payload) async {
            final convo = await supabase
                .from('conversations')
                .select('*, furrents(id, full_name, profile_picture_url)')
                .eq('id', payload.newRecord['id'])
                .single();

            if (convo['hidden_for_pawtner'] == true) {
              setState(() => chats.removeWhere((c) => c['id'] == convo['id']));
              return;
            }

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
            column: 'pawtner_id',
            value: currentUser.id,
          ),
          callback: (payload) async {
            final convo = await supabase
                .from('conversations')
                .select('*, furrents(id, full_name, profile_picture_url)')
                .eq('id', payload.newRecord['id'])
                .single();

            if (convo['hidden_for_pawtner'] == true) {
              setState(() => chats.removeWhere((c) => c['id'] == convo['id']));
              return;
            }

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
      textAlign: TextAlign.start,
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
            .where((chat) => ((chat['furrents'] ?? {})['full_name'] ?? '')
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      } else {
        itemsToShow = itemsToShow
            .where((notif) => (notif['title'] as String)
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
            .toList();
      }
    }

    final currentUser = supabase.auth.currentUser;

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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                      ),
                      onChanged: (value) => setState(() => searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.dosis(
                          color: const Color(0xFFBDBDBD),
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
                                ? const Color(0xFFDDC7A9)
                                : const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                customText(
                                  tabs[index],
                                  fontSize: 18,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? const Color(0xFF6E4B3A)
                                      : const Color(0xFF6E4B3A),
                                ),
                                if ((index == 0 && unreadChatsCount > 0) ||
                                    (index == 1 &&
                                        unreadNotificationsCount > 0))
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      index == 0
                                          ? unreadChatsCount.toString()
                                          : unreadNotificationsCount.toString(),
                                      style: GoogleFonts.dosis(
                                        color: const Color(0xFFFFFFFF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
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
                              final furrent =
                                  item['furrents'] as Map<String, dynamic>? ??
                                      {};
                              final profilePic =
                                  furrent['profile_picture_url'] ?? '';
                              final lastMessageDate =
                                  item['last_message_at'] != null
                                      ? DateTime.parse(item['last_message_at'])
                                          .toLocal()
                                      : null;

                              String formattedDate = '';
                              if (lastMessageDate != null) {
                                final now = DateTime.now();
                                if (lastMessageDate.year == now.year &&
                                    lastMessageDate.month == now.month &&
                                    lastMessageDate.day == now.day) {
                                  formattedDate =
                                      formatTime12Hour(lastMessageDate);
                                } else {
                                  formattedDate =
                                      "${lastMessageDate.month}/${lastMessageDate.day}/${lastMessageDate.year}";
                                }
                              }

                              String lastMessageText =
                                  item['last_message'] ?? '';
                              final lastMessageSender =
                                  item['last_message_sender_id'];
                              if (lastMessageSender == currentUser?.id) {
                                lastMessageText = "You: $lastMessageText";
                              }

                              final unreadCount =
                                  (item['unread_count_pawtner'] ?? 0) as num;
                              final isUnread = unreadCount > 0;

                              return Dismissible(
                                key: Key(item['id']),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      title: customText(
                                          'Delete this entire conversation?',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6E4B3A)),
                                      content: customText(
                                          'This action cannot be undone.',
                                          fontSize: 16,
                                          color: const Color(0xFF6E4B3A)),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: customText('Cancel',
                                              fontSize: 16,
                                              color: const Color(0xFF6E4B3A)),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: customText('Delete',
                                              fontSize: 16,
                                              color: const Color(0xFFFF3B30)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) async {
                                  await supabase
                                      .from('messages')
                                      .update({'deleted_for_pawtner': true}).eq(
                                          'conversation_id', item['id']);
                                  await supabase.from('conversations').update({
                                    'hidden_for_pawtner': true,
                                    'pawtner_cleared_at':
                                        DateTime.now().toIso8601String(),
                                  }).eq('id', item['id']);
                                  setState(() => chats.removeWhere(
                                      (c) => c['id'] == item['id']));

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: customText(
                                          'Chat has been deleted',
                                          color: const Color(0xFF6E4B3A),
                                        ),
                                        backgroundColor:
                                            const Color(0xFFDDC7A9),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: const Icon(Icons.delete,
                                      color: const Color(0xFFFFFFFF), size: 30),
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    await supabase
                                        .from('conversations')
                                        .update({
                                      'unread_count_pawtner': 0,
                                    }).eq('id', item['id']);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          conversationId: item['id'],
                                          otherUserId: furrent['id'],
                                          otherUserName:
                                              furrent['full_name'] ?? '',
                                          otherUserAvatar:
                                              furrent['profile_picture_url'] ??
                                                  '',
                                          currentUserType: 'pawtner',
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              const Color(0xFFDDC7A9),
                                          backgroundImage: profilePic.isNotEmpty
                                              ? NetworkImage(profilePic)
                                              : null,
                                          child: profilePic.isEmpty
                                              ? const Icon(Icons.person,
                                                  size: 24,
                                                  color: Color(0xFF6E4B3A))
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  customText(
                                                    furrent['full_name'] ?? '',
                                                    fontWeight: isUnread
                                                        ? FontWeight.w800
                                                        : FontWeight.w600,
                                                    color:
                                                        const Color(0xFF6E4B3A),
                                                  ),
                                                  customText(
                                                    formattedDate,
                                                    fontSize: 12,
                                                    color:
                                                        const Color(0xFF6E4B3A),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      lastMessageText,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: GoogleFonts.dosis(
                                                        fontSize: 14,
                                                        fontWeight: isUnread
                                                            ? FontWeight.w700
                                                            : FontWeight.normal,
                                                        color: const Color(
                                                            0xFF6E4B3A),
                                                      ),
                                                    ),
                                                  ),
                                                  if (unreadCount > 0)
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 4),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        unreadCount
                                                            .toInt()
                                                            .toString(),
                                                        style:
                                                            GoogleFonts.dosis(
                                                          color: const Color(
                                                              0xFFFFFFFF),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.bold,
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
                                  ),
                                ),
                              );
                            } else {
                              final type = item['type'] ?? '';
                              final isReadNotif = item['is_read'] == true;

                              IconData notifIcon;
                              Color notifColor;

                              if (type == 'booking') {
                                notifIcon = Icons.calendar_today;
                                notifColor = const Color(0xFF6E4B3A);
                              } else if (type == 'reminder') {
                                notifIcon = Icons.alarm;
                                notifColor = const Color(0xFFFF9500);
                              } else if (type == 'review') {
                                notifIcon = Icons.star;
                                notifColor = const Color(0xFFFFCC00);
                              } else {
                                notifIcon = Icons.campaign;
                                notifColor = const Color(0xFF007AFF);
                              }

                              return GestureDetector(
                                onTap: () async {
                                  if (!isReadNotif) {
                                    await supabase.from('notifications').update(
                                        {'is_read': true}).eq('id', item['id']);
                                    setState(() {
                                      item['is_read'] = true;
                                      unreadNotificationsCount =
                                          (unreadNotificationsCount - 1)
                                              .clamp(0, 999);
                                    });
                                  }

                                  final bookingId = item['booking_id'];
                                  if (bookingId == null) return;

                                  final booking = await supabase
                                      .from('bookings')
                                      .select(
                                          '*, pets(*), furrents(*), services(*)')
                                      .eq('id', bookingId)
                                      .maybeSingle();

                                  if (booking == null || !context.mounted) {
                                    return;
                                  }

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PawtnerBookingDetailsScreen(
                                        booking:
                                            Map<String, dynamic>.from(booking),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isReadNotif
                                        ? const Color(0xFFFFFFFF)
                                        : notifColor.withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x1F000000),
                                          blurRadius: 4,
                                          offset: Offset(0, 2))
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: notifColor.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(notifIcon,
                                            color: notifColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: customText(
                                                    item['title'] ?? '',
                                                    fontWeight: isReadNotif
                                                        ? FontWeight.w600
                                                        : FontWeight.w800,
                                                    color:
                                                        const Color(0xFF6E4B3A),
                                                  ),
                                                ),
                                                if (!isReadNotif)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: notifColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            customText(
                                              item['message'] ?? '',
                                              fontSize: 14,
                                              color: const Color(0xFF6E4B3A),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
          color: const Color(0xFFDDC7A9),
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
          icon: const Icon(Icons.add, color: Color(0xFF6E4B3A)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const NewChatScreen(currentUserType: "pawtner"),
              ),
            ).then((_) => _loadData());
          },
        ),
      ),
    );
  }
}
