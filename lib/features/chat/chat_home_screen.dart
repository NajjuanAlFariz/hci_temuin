import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';

class ChatHomeScreen extends StatefulWidget {
  const ChatHomeScreen({super.key});

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen> {
  final _searchController = TextEditingController();
  String _keyword = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      return DateFormat('HH:mm').format(ts.toDate());
    }
    return '';
  }

  String _getPartnerNameFromChatDoc({
    required Map<String, dynamic> data,
    required String myUid,
    required String partnerUid,
  }) {
    // 1) participant_names[partnerUid]
    final namesRaw = data['participant_names'];
    if (namesRaw is Map) {
      final names = Map<String, dynamic>.from(namesRaw);
      final v = names[partnerUid];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }

    // 2) fallback: chat_partner_name (kalau kamu simpan saat create chat)
    final fallback = (data['chat_partner_name'] ?? '').toString().trim();
    if (fallback.isNotEmpty) return fallback;

    // 3) fallback terakhir
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: Image.asset(
            'assets/image/icon/arrow-back.png',
            width: 22,
          ),
        ),
        title: const Text(
          'Chat',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    setState(() => _keyword = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  isDense: true,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/image/icon/search.png',
                      width: 18,
                      height: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// CHAT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: user.uid)
                  .orderBy('updated_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Gagal memuat chat, cek koneksi internet'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Belum ada chat'));
                }

                final items = <_ChatItem>[];

                for (final d in docs) {
                  final data = d.data();

                  final participants =
                      List<String>.from(data['participants'] ?? []);

                  final partnerUid = participants.firstWhere(
                    (id) => id != user.uid,
                    orElse: () => '',
                  );

                  final partnerName = _getPartnerNameFromChatDoc(
                    data: data,
                    myUid: user.uid,
                    partnerUid: partnerUid,
                  );

                  final lastMessage = (data['last_message'] ?? '').toString();
                  final time = _formatTime(data['updated_at']);

                  // Search filter (local)
                  final combined = '${partnerName.toLowerCase()} '
                      '${lastMessage.toLowerCase()}';

                  if (_keyword.isNotEmpty && !combined.contains(_keyword)) {
                    continue;
                  }

                  items.add(
                    _ChatItem(
                      chatId: d.id,
                      partnerName: partnerName,
                      lastMessage: lastMessage,
                      time: time,
                      unread: data['unread_count'] is int
                          ? data['unread_count'] as int
                          : 0,
                    ),
                  );
                }

                if (items.isEmpty) {
                  return const Center(child: Text('Chat tidak ditemukan'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return ChatTile(
                      name: c.partnerName,
                      lastMessage: c.lastMessage,
                      time: c.time,
                      unread: c.unread,
                      isRead: c.unread == 0,
                      onTap: () {
                        context.go(
                          '/chat/detail',
                          extra: {
                            'chatId': c.chatId,
                            'partnerName': c.partnerName,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatItem {
  final String chatId;
  final String partnerName;
  final String lastMessage;
  final String time;
  final int unread;

  _ChatItem({
    required this.chatId,
    required this.partnerName,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}

class ChatTile extends StatelessWidget {
  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isRead;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unread > 0 ? Warna.blue : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            /// AVATAR
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Image.asset('assets/image/profile_default.png'),
            ),

            const SizedBox(width: 12),

            /// MESSAGE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                if (unread > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Warna.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unread.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isRead)
                  Image.asset( 'assets/image/icon/read.png', width: 18, ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
