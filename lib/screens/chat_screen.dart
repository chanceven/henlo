import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;       // required for receiver_id
  final String otherUserName;
  final String otherUserAvatar;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final supabase = Supabase.instance.client;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late RealtimeChannel _channel;

  List<Map<String, dynamic>> messages = [];

  String get userId => supabase.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _setupRealtime();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    supabase.removeChannel(_channel);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom();
  }

  // ---------------- LOAD MESSAGES ----------------

  Future<void> _loadMessages() async {
    final res = await supabase
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true); // oldest first

    setState(() {
      messages = List<Map<String, dynamic>>.from(res);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ---------------- REALTIME ----------------

  void _setupRealtime() {
    _channel = supabase
        .channel('messages-${widget.conversationId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;

            setState(() {
              messages.add(newMessage);
            });

            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
          },
        )
        .subscribe();
  }

  // ---------------- SEND MESSAGE ----------------

  Future<void> _sendMessage({String? text, String? fileUrl}) async {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) return;

    final now = DateTime.now().toIso8601String();

    // 1️⃣ Insert message
    await supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': userId,
      'sender_type': 'user',
      'receiver_id': widget.otherUserId,
      'receiver_type': 'user',
      'message': text ?? '',
      'is_read': false,
      'last_message_at': now,
      'created_at': now,
      'file_url': fileUrl,
    });

    // 2️⃣ Update conversation table so it shows in FurrentMessagesScreen
    await supabase.from('conversations').update({
      'last_message': text ?? (fileUrl != null ? 'Attachment' : ''),
      'last_message_at': now,
    }).eq('id', widget.conversationId);

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // ---------------- UPLOAD FILE ----------------

  Future<void> _uploadFile(File file) async {
    final fileName =
        '${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage.from('chat_files').upload(fileName, file);

    final url = supabase.storage.from('chat_files').getPublicUrl(fileName);

    _sendMessage(fileUrl: url);
  }

  // ---------------- UI HELPERS ----------------

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  bool _showDateHeader(int index) {
    if (index == 0) return true;

    final prev = DateTime.parse(messages[index - 1]['created_at']);
    final curr = DateTime.parse(messages[index]['created_at']);

    return prev.day != curr.day ||
        prev.month != curr.month ||
        prev.year != curr.year;
  }

  // ---------------- BUILD ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6E4B3A)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserAvatar.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar)
                  : null,
              backgroundColor: const Color(0xFFDDC7A9),
              child: widget.otherUserAvatar.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF6E4B3A))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: const TextStyle(
                color: Color(0xFF6E4B3A),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE0E0E0)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg['sender_id'] == userId;
                  final time = DateFormat('hh:mm a')
                      .format(DateTime.parse(msg['created_at']));

                  return Column(
                    children: [
                      if (_showDateHeader(index))
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat('MMMM d, y').format(
                                  DateTime.parse(msg['created_at'])),
                              style: const TextStyle(
                                  color: Color(0xFF6E4B3A), fontSize: 12),
                            ),
                          ),
                        ),
                      Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          padding: const EdgeInsets.all(10),
                          constraints:
                              const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF6E4B3A) : Colors.white,
                            border: Border.all(color: const Color(0xFF6E4B3A)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg['file_url'] != null)
                                Image.network(msg['file_url'], width: 200),
                              if (msg['message'] != null)
                                Text(
                                  msg['message'],
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white
                                        : const Color(0xFF6E4B3A),
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // INPUT ROW WITH PAPERCLIP INTEGRATED
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF6E4B3A)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              const BorderSide(color: Color(0xFF6E4B3A)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        prefixIcon: PopupMenuButton<String>(
                          icon:
                              const Icon(Icons.attach_file, color: Color(0xFF6E4B3A)),
                          onSelected: (value) async {
                            if (value == 'Choose File') {
                              final result = await FilePicker.platform.pickFiles();
                              if (result != null &&
                                  result.files.single.path != null) {
                                _uploadFile(File(result.files.single.path!));
                              }
                            } else if (value == 'Choose Image') {
                              final image = await ImagePicker()
                                  .pickImage(source: ImageSource.gallery);
                              if (image != null) _uploadFile(File(image.path));
                            } else if (value == 'Take Photo') {
                              final photo = await ImagePicker()
                                  .pickImage(source: ImageSource.camera);
                              if (photo != null) _uploadFile(File(photo.path));
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'Choose File',
                              child: Text('Choose File'),
                            ),
                            const PopupMenuItem(
                              value: 'Choose Image',
                              child: Text('Choose Image'),
                            ),
                            const PopupMenuItem(
                              value: 'Take Photo',
                              child: Text('Take Photo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF6E4B3A),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () =>
                          _sendMessage(text: _messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
