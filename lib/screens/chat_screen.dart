import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final String currentUserType;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    required this.currentUserType,
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
  bool _showAttachmentOptions = false;

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
    // no longer needed with reverse: true
  }

  Future<void> _loadMessages() async {
    final convo = await supabase
        .from('conversations')
        .select()
        .eq('id', widget.conversationId)
        .single();

    final clearedAt = convo['pawtner_cleared_at'];

    var query = supabase
        .from('messages')
        .select()
        .eq('conversation_id', widget.conversationId);

    if (clearedAt != null) {
      query = query.gt('created_at', clearedAt);
    }

    final res = await query.order('created_at', ascending: true);

    setState(() {
      messages = List<Map<String, dynamic>>.from(res);
    });

    await supabase
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', widget.conversationId)
        .neq('sender_id', userId);
  }

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
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.conversationId,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            final index = messages.indexWhere((m) => m['id'] == updated['id']);
            if (index != -1) {
              setState(() {
                messages[index] = updated;
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _sendMessage({String? text, String? fileUrl}) async {
    if ((text == null || text.trim().isEmpty) && fileUrl == null) return;

    debugPrint('currentUserType: ${widget.currentUserType}');

    final now = DateTime.now().toUtc().toIso8601String();

    final convo = await supabase
        .from('conversations')
        .select()
        .eq('id', widget.conversationId)
        .single();

    final isFurrent = convo['furrent_id'] == userId;

    await supabase.from('messages').insert({
      'conversation_id': widget.conversationId,
      'sender_id': userId,
      'sender_type': widget.currentUserType,
      'receiver_id': widget.otherUserId,
      'receiver_type':
          widget.currentUserType == 'pawtner' ? 'furrent' : 'pawtner',
      'message': (text == null || text.trim().isEmpty) ? null : text.trim(),
      'is_read': false,
      'last_message_at': now,
      'created_at': now,
      'file_url': fileUrl,
      'deleted_for_pawtner': isFurrent && convo['pawtner_cleared_at'] != null
          ? DateTime.parse(now)
              .isBefore(DateTime.parse(convo['pawtner_cleared_at']))
          : false,
    });

    await supabase.from('conversations').update({
      'last_message': text ?? (fileUrl != null ? 'Attachment' : ''),
      'last_message_sender_id': userId,
      'last_message_at': now,
      'hidden_for_pawtner': false,
      'hidden_for_furrent': false,
      if (isFurrent)
        'unread_count_pawtner':
            ((convo['unread_count_pawtner'] ?? 0) as num).toInt() + 1
      else
        'unread_count_furrent':
            ((convo['unread_count_furrent'] ?? 0) as num).toInt() + 1,
    }).eq('id', widget.conversationId);

    _messageController.clear();
  }

  Future<void> _uploadFile(File file) async {
    final ext = file.path.split('.').last;
    final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await supabase.storage.from('chat_files').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final signedUrl = await supabase.storage
          .from('chat_files')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

      await _sendMessage(fileUrl: signedUrl);
    } on StorageException catch (e) {
      debugPrint("Storage error: ${e.message}");
    } catch (e) {
      debugPrint("Upload error: $e");
    }
  }

  bool _showDateHeader(int reversedIndex) {
    final index = messages.length - 1 - reversedIndex;
    if (index == 0) return true;

    final curr = DateTime.parse(messages[index]['created_at']).toLocal();
    final prev = DateTime.parse(messages[index - 1]['created_at']).toLocal();

    return curr.day != prev.day ||
        curr.month != prev.month ||
        curr.year != prev.year;
  }

  @override
  Widget build(BuildContext context) {
    String? lastReadMessageId;
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['sender_id'] == userId && msg['is_read'] == true) {
        lastReadMessageId = msg['id'];
        break;
      }
    }

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
              style: GoogleFonts.dosis(
                color: const Color(0xFF6E4B3A),
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
                reverse: true,
                itemBuilder: (context, index) {
                  final msg = messages[messages.length - 1 - index];
                  final isMe = msg['sender_id'] == userId;
                  final time = DateFormat('hh:mm a')
                      .format(DateTime.parse(msg['created_at']).toLocal());

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
                                  DateTime.parse(msg['created_at']).toLocal()),
                              style: GoogleFonts.dosis(
                                color: const Color(0xFF6E4B3A),
                                fontSize: 12,
                              ),
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
                          constraints: const BoxConstraints(maxWidth: 280),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xFF6E4B3A)
                                : const Color(0xFFF8F8F8),
                            border: Border.all(color: const Color(0xFF6E4B3A)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IntrinsicWidth(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (msg['file_url'] != null)
                                  GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(msg['file_url']);
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    },
                                    child: Image.network(
                                      msg['file_url'],
                                      width: 200,
                                      errorBuilder: (_, __, ___) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.attach_file,
                                              size: 16,
                                              color: isMe
                                                  ? const Color(0xFFF8F8F8)
                                                  : const Color(0xFF6E4B3A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Attachment',
                                            style: GoogleFonts.dosis(
                                                color: isMe
                                                    ? const Color(0xFFF8F8F8)
                                                    : const Color(0xFF6E4B3A)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (msg['message'] != null &&
                                    msg['message'].toString().isNotEmpty)
                                  Text(
                                    msg['message'],
                                    style: GoogleFonts.dosis(
                                        color: isMe
                                            ? const Color(0xFFF8F8F8)
                                            : const Color(0xFF6E4B3A)),
                                  ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    time,
                                    style: GoogleFonts.dosis(
                                        fontSize: 10,
                                        color: isMe
                                            ? const Color(0xFFF8F8F8)
                                            : const Color(0xFFBDBDBD)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (msg['id'] == lastReadMessageId)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 12, bottom: 4),
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: const Color(0xFFDDC7A9),
                              backgroundImage: widget.otherUserAvatar.isNotEmpty
                                  ? NetworkImage(widget.otherUserAvatar)
                                  : null,
                              child: widget.otherUserAvatar.isEmpty
                                  ? const Icon(Icons.person,
                                      size: 10, color: Color(0xFF6E4B3A))
                                  : null,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            if (_showAttachmentOptions)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F8F8),
                  border: Border(
                    top: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        vertical: -3,
                      ),
                      leading: const Icon(Icons.insert_drive_file,
                          color: Color(0xFF6E4B3A)),
                      title: Text(
                        'Choose File',
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () async {
                        setState(() => _showAttachmentOptions = false);
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null &&
                            result.files.single.path != null) {
                          _uploadFile(File(result.files.single.path!));
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        vertical: -3,
                      ),
                      leading:
                          const Icon(Icons.image, color: Color(0xFF6E4B3A)),
                      title: Text(
                        'Choose Image',
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () async {
                        setState(() => _showAttachmentOptions = false);
                        final image = await ImagePicker()
                            .pickImage(source: ImageSource.gallery);
                        if (image != null) _uploadFile(File(image.path));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(
                        vertical: -3,
                      ),
                      leading: const Icon(Icons.camera_alt,
                          color: Color(0xFF6E4B3A)),
                      title: Text(
                        'Take Photo',
                        style: GoogleFonts.dosis(
                          color: const Color(0xFF6E4B3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () async {
                        setState(() => _showAttachmentOptions = false);
                        final photo = await ImagePicker()
                            .pickImage(source: ImageSource.camera);
                        if (photo != null) _uploadFile(File(photo.path));
                      },
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _showAttachmentOptions ? Icons.close : Icons.add,
                      color: const Color(0xFF6E4B3A),
                    ),
                    onPressed: () {
                      setState(() =>
                          _showAttachmentOptions = !_showAttachmentOptions);
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      style: GoogleFonts.dosis(
                        color: const Color(0xFF6E4B3A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle:
                            GoogleFonts.dosis(color: const Color(0xFFBDBDBD)),
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
                      icon: const Icon(Icons.send, color: Color(0xFFDDC7A9)),
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
