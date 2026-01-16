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

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: Image.asset('assets/image/icon/arrow-back.png', width: 22),
        ),
        title: const Text('Notifikasi', style: TextStyle(color: Colors.black)),
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

          Expanded(
            child: _NotificationList(activeTab: _activeTab, userId: _user?.uid),
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
/// NOTIFICATION LIST (ownership_verifications)
/// ============================================================
class _NotificationList extends StatelessWidget {
  final NotificationTab activeTab;
  final String? userId;

  const _NotificationList({required this.activeTab, required this.userId});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text('User belum login'));
    }

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('ownership_verifications')
        .where('target_user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true);

    if (activeTab == NotificationTab.unread) {
      query = query.where('read', isEqualTo: false);
    } else if (activeTab == NotificationTab.history) {
      query = query.where('read', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Terjadi kesalahan:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Tidak ada notifikasi'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            return _NotificationCard(docId: docs[i].id, data: docs[i].data());
          },
        );
      },
    );
  }
}

/// ============================================================
/// NOTIFICATION CARD
/// ============================================================
class _NotificationCard extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const _NotificationCard({required this.docId, required this.data});

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    final status = (data['status'] ?? '').toString();
    final isPending = status == 'pending';

    final requesterName = (data['requester_name'] ?? 'User').toString();
    final description = data['description'] != null
        ? data['description'].toString()
        : '-';

    return AbsorbPointer(
      absorbing: _isLoading,
      child: Container(
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: Image.asset('assets/image/profile_default.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Deskripsi Barang:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_isLoading) ...[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 3),
            ],

            if (isPending && !_isLoading) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      label: 'Tolak',
                      color: Colors.red,
                      onTap: () => _handleDecision(accepted: false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      label: 'Terima',
                      color: Colors.green,
                      onTap: () => _handleDecision(accepted: true),
                    ),
                  ),
                ],
              ),
            ],

            if (!isPending) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status: $status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status == 'accepted'
                        ? Colors.green
                        : (status == 'rejected' ? Colors.red : Colors.black54),
                  ),
                ),
              ),
            ],
          ],
        ),
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

  // ============================================================
  // BUILD CHAT CONTEXT dari report doc (lost_items / found_items)
  // ============================================================
  Future<Map<String, dynamic>?> _buildChatContextFromVerification({
    required FirebaseFirestore db,
    required Map<String, dynamic> verification,
  }) async {
    final reportId = (verification['report_id'] ?? '').toString().trim();
    final reportType = (verification['report_type'] ?? '')
        .toString()
        .trim(); // lost|found

    if (reportId.isEmpty || reportType.isEmpty) return null;

    final collection = reportType == 'lost' ? 'lost_items' : 'found_items';
    final snap = await db.collection(collection).doc(reportId).get();
    if (!snap.exists) return null;

    final r = (snap.data() as Map<String, dynamic>);

    return {
      'report_id': reportId,
      'report_type': reportType,
      'title': (r['name'] ?? '-').toString(),
      'category': (r['category'] ?? '-').toString(),
      'location': (r['location'] ?? '').toString(),
      // header chat kamu tidak wajib image, tapi aman kita simpan jika ada
      'image_url': r['image_url']?.toString(),
    };
  }

  // ============================================================
  // ACCEPT / REJECT + CREATE CHAT + SIMPAN CONTEXT + NAVIGATE
  // ============================================================
  Future<void> _handleDecision({required bool accepted}) async {
    if (_isLoading) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnack('User belum login');
      return;
    }

    // ✅ simpan router sebelum async
    final router = GoRouter.of(context);

    final data = widget.data;

    final requesterId = (data['requester_user_id'] ?? '').toString().trim();
    if (requesterId.isEmpty) {
      _showSnack('requester_user_id tidak ditemukan');
      return;
    }

    final requesterName = (data['requester_name'] ?? 'User').toString();

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // 1) Update status + read
      await firestore
          .collection('ownership_verifications')
          .doc(widget.docId)
          .update({
            'status': accepted ? 'accepted' : 'rejected',
            'read': true,
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (!accepted) {
        _showSnack('Verifikasi ditolak');
        return;
      }

      // 2) chatId deterministik
      final myUid = currentUser.uid;
      final ids = [myUid, requesterId]..sort();
      final chatId = '${ids[0]}_${ids[1]}';

      final myName =
          currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'User';

      final chatRef = firestore.collection('chats').doc(chatId);

      // 3) Create chat (merge)
      await chatRef.set({
        'participants': [myUid, requesterId],
        'participant_names': {myUid: myName, requesterId: requesterName},
        'last_message': 'Chat dimulai',
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ✅ 4) SIMPAN CONTEXT PRODUK KE CHAT (INI FIX HEADER!)
      final ctx = await _buildChatContextFromVerification(
        db: firestore,
        verification: data,
      );

      if (ctx != null) {
        await chatRef.set({
          'context': ctx,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 5) Add first message if empty
      final lastMsg = await chatRef
          .collection('messages')
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (lastMsg.docs.isEmpty) {
        await chatRef.collection('messages').add({
          'sender_id': myUid,
          'text': 'Chat dimulai',
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      // 6) Navigate
      router.go(
        '/chat/detail',
        extra: {'chatId': chatId, 'partnerName': requesterName},
      );
    } on FirebaseException catch (e) {
      _showSnack('Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
