import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

class ChatHomeScreen extends StatelessWidget {
  const ChatHomeScreen({super.key});

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

      /// ================= APP BAR =================
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

      /// ================= BODY =================
      body: Column(
        children: [
          /// ================= SEARCH =================
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
                decoration: InputDecoration(
                  hintText: 'Search',
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
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

          /// ================= CHAT LIST =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: user.uid)
                  .orderBy('updated_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final chats = snapshot.data!.docs;

                if (chats.isEmpty) {
                  return const Center(
                    child: Text('Belum ada chat'),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: chats.length,
                  itemBuilder: (_, i) {
                    final chat =
                        chats[i].data() as Map<String, dynamic>;
                    return _ChatTile(
                      chatId: chats[i].id,
                      data: chat,
                      currentUserId: user.uid,
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

/// ============================================================
/// CHAT TILE (REAL FIRESTORE)
/// ============================================================
class _ChatTile extends StatelessWidget {
  final String chatId;
  final Map<String, dynamic> data;
  final String currentUserId;

  const _ChatTile({
    required this.chatId,
    required this.data,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final String name =
        data['chat_name'] ?? 'Chat';
    final String lastMessage =
        data['last_message'] ?? '';
    final Timestamp? updatedAt =
        data['updated_at'];

    final String timeText = updatedAt != null
        ? _formatTime(updatedAt.toDate())
        : '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .snapshots(),
      builder: (context, snapshot) {
        int unread = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final msg =
                doc.data() as Map<String, dynamic>;
            final List readBy = msg['read_by'] ?? [];

            if (!readBy.contains(currentUserId)) {
              unread++;
            }
          }
        }

        return GestureDetector(
          onTap: () {
            /// 🔜 NANTI:
            /// context.go('/chat/$chatId');
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unread > 0
                    ? Warna.blue
                    : Colors.grey.shade300,
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
                  ),
                  child: Image.asset(
                    'assets/image/profile_default.png',
                  ),
                ),

                const SizedBox(width: 12),

                /// MESSAGE
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                /// RIGHT
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unread > 0)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Warna.blue,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Text(
                          unread.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Image.asset(
                        'assets/image/icon/read.png',
                        width: 18,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute =
        time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
