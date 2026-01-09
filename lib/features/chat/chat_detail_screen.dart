import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String partnerName;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.partnerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// ================= FORMAT TIME =================
  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      return DateFormat('HH:mm').format(ts.toDate());
    }
    return '';
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// ================= SEND MESSAGE =================
  Future<void> _sendMessage() async {
    if (_sending) return;

    final text = _messageController.text.trim();
    final user = _auth.currentUser;
    if (text.isEmpty || user == null) return;

    setState(() => _sending = true);
    _messageController.clear();

    try {
      final chatRef = _db.collection('chats').doc(widget.chatId);
      final msgRef = chatRef.collection('messages').doc();

      final batch = _db.batch();

      batch.set(msgRef, {
        'text': text,
        'sender_id': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      batch.set(
        chatRef,
        {
          'last_message': text,
          'updated_at': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim pesan')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// ================= BACK HANDLER =================
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _handleBack,
          icon: Image.asset(
            'assets/image/icon/arrow-back.png',
            width: 22,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            /// PROFILE IMAGE (ASSET PNG)
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: Image.asset(
                  'assets/image/profile_default.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),

            /// PARTNER NAME
            Expanded(
              child: Text(
                widget.partnerName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),

      /// ================= BODY =================
      body: Column(
        children: [
          /// ================= CHAT LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('created_at')
                  .snapshots(),
              builder: (_, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Gagal memuat pesan'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isNotEmpty) _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final data = messages[i].data();
                    final isMe = data['sender_id'] == currentUserId;

                    return _ChatBubble(
                      message: (data['text'] ?? '').toString(),
                      time: _formatTime(data['created_at']),
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          /// ================= INPUT =================
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  /// TEXT FIELD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis Pesan...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  /// SEND BUTTON (ASSET PNG)
                  GestureDetector(
                    onTap: _sending ? null : _sendMessage,
                    child: Opacity(
                      opacity: _sending ? 0.5 : 1,
                      child: Image.asset(
                        'assets/image/icon/Send.png',
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================
/// CHAT BUBBLE
/// ============================================================
class _ChatBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  const _ChatBubble({
    required this.message,
    required this.time,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? Warna.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 13,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
