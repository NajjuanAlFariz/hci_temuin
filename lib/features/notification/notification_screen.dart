import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';

enum NotificationTab { all, unread, history }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationTab _activeTab = NotificationTab.all;

  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            /// ⬅️ BALIK KE HOME
            context.go('/home');
          },
          icon: Image.asset(
            'assets/image/icon/arrow-back.png',
            width: 22,
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          const SizedBox(height: 12),

          /// ================= TAB =================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _tabButton('All', NotificationTab.all),
                const SizedBox(width: 8),
                _tabButton('Unread', NotificationTab.unread),
                const SizedBox(width: 8),
                _tabButton('History', NotificationTab.history),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// ================= LIST =================
          Expanded(
            child: _NotificationList(
              activeTab: _activeTab,
              userId: _user?.uid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, NotificationTab tab) {
    final isActive = _activeTab == tab;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = tab),
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Warna.blue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Warna.blue),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Warna.blue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// NOTIFICATION LIST
/// ============================================================
class _NotificationList extends StatelessWidget {
  final NotificationTab activeTab;
  final String? userId;

  const _NotificationList({
    required this.activeTab,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('User belum login'));
    }

    Query query = FirebaseFirestore.instance
        .collection('ownership_verifications')
        .where('target_user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true);


return StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('ownership_verifications')
      .where('target_user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .snapshots(),
  builder: (_, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData) {
      return const Center(child: Text('Tidak ada data'));
    }

    final allDocs = snapshot.data!.docs;

    final filteredDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isRead = data['read'] == true;

      if (activeTab == NotificationTab.unread) {
        return !isRead;
      }

      if (activeTab == NotificationTab.history) {
        return isRead;
      }

      return true; // ALL
    }).toList();

    if (filteredDocs.isEmpty) {
      return const Center(child: Text('Tidak ada notifikasi'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDocs.length,
      itemBuilder: (_, i) {
        final data = filteredDocs[i].data() as Map<String, dynamic>;
        return _NotificationCard(
          docId: filteredDocs[i].id,
          data: data,
        );
      },
    );
  },
);

  }
}

/// ============================================================
/// NOTIFICATION CARD
/// ============================================================
class _NotificationCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _NotificationCard({
    required this.docId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = data['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Warna.blue,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['requester_name'] ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Deskripsi: ${data['description']}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (isPending) ...[
            const SizedBox(height: 12),

            /// ACTION BUTTON
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Tolak',
                    color: Colors.red,
                    onTap: () => _updateStatus(context, 'rejected'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    label: 'Terima',
                    color: Colors.green,
                    onTap: () => _updateStatus(context, 'accepted'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance
        .collection('ownership_verifications')
        .doc(docId)
        .update({
      'status': status,
      'read': true,
    });

    if (!context.mounted) return;

    if (status == 'accepted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifikasi diterima. Lanjutkan ke chat.'),
        ),
      );
      // 🔜 NANTI: context.go('/chat/xxx');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi ditolak')),
      );
    }
  }
}
