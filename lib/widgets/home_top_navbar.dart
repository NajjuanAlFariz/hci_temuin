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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
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
            /// ================= LOGO =================
            Image.asset(
              'assets/image/icon/Temuin.png',
              height: 32,
              fit: BoxFit.contain,
            ),

            /// ================= ACTION ICON =================
            Row(
              children: [
                /// 🔔 NOTIFICATION (WITH BADGE)
                _NotificationIcon(
                  userId: user?.uid,
                  onTap: () => context.go('/notification'),
                ),

                const SizedBox(width: 12),

                /// 💬 CHAT
                _IconButton(
                  asset: 'assets/image/icon/chat.png',
                  onTap: () {
                    context.go('/chat');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// 🔔 NOTIFICATION ICON WITH BADGE
/// ============================================================
class _NotificationIcon extends StatelessWidget {
  final String? userId;
  final VoidCallback onTap;

  const _NotificationIcon({
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _IconButton(
        asset: 'assets/image/icon/bell.png',
        onTap: onTap,
      );
    }

    final query = FirebaseFirestore.instance
        .collection('ownership_verifications')
        .where('target_user_id', isEqualTo: userId)
        .where('read', isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          unreadCount = snapshot.data!.docs.length;
        }

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              /// ICON
              Container(
                width: 45,
                height: 45,
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/image/icon/bell.png',
                  fit: BoxFit.contain,
                ),
              ),

              /// 🔴 BADGE
              if (unreadCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
      },
    );
  }
}

/// ============================================================
/// ICON BUTTON (NORMAL)
/// ============================================================
class _IconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _IconButton({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
