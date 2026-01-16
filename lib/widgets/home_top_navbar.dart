import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeTopNavbar extends StatelessWidget {
  const HomeTopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/image/icon/Temuin.png',
              height: 32,
              fit: BoxFit.contain,
            ),

            Row(
              children: [
                _NotificationIcon(
                  userId: user?.uid,
                  onTap: () => context.go('/notification'),
                ),

                const SizedBox(width: 12),

                /// ✅ CHAT WITH BADGE
                _ChatIcon(userId: user?.uid, onTap: () => context.go('/chat')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  final String? userId;
  final VoidCallback onTap;

  const _NotificationIcon({required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _IconButton(asset: 'assets/image/icon/bell.png', onTap: onTap);
    }

    final query = FirebaseFirestore.instance
        .collection('ownership_verifications')
        .where('target_user_id', isEqualTo: userId)
        .where('read', isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;
        if (snapshot.hasData) unreadCount = snapshot.data!.docs.length;

        return _BadgeIcon(
          asset: 'assets/image/icon/bell.png',
          count: unreadCount,
          onTap: onTap,
        );
      },
    );
  }
}

/// ✅ CHAT BADGE: jumlah total unread_for[userId] dari semua chat
class _ChatIcon extends StatelessWidget {
  final String? userId;
  final VoidCallback onTap;

  const _ChatIcon({required this.userId, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _IconButton(asset: 'assets/image/icon/chat.png', onTap: onTap);
    }

    final query = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: userId);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (_, snapshot) {
        int totalUnread = 0;

        if (snapshot.hasData) {
          for (final d in snapshot.data!.docs) {
            final data = d.data();
            final unreadRaw = data['unread_for'];
            if (unreadRaw is Map) {
              final unread = Map<String, dynamic>.from(unreadRaw);
              final v = unread[userId];
              if (v is int) totalUnread += v;
              if (v is num) totalUnread += v.toInt();
            }
          }
        }

        return _BadgeIcon(
          asset: 'assets/image/icon/chat.png',
          count: totalUnread,
          onTap: onTap,
        );
      },
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final String asset;
  final int count;
  final VoidCallback onTap;

  const _BadgeIcon({
    required this.asset,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 45,
            height: 45,
            padding: const EdgeInsets.all(8),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _IconButton({required this.asset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        padding: const EdgeInsets.all(8),
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}
