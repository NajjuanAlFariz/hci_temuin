import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';
import '../utils/time_ago.dart';
import 'ownership_verification_dialog.dart';

class ReportDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String reportId;

  const ReportDetailBottomSheet({
    super.key,
    required this.data,
    required this.reportId,
  });

  // ============================================================
  // STATUS
  // ============================================================
  bool _isDone(String? status) => (status ?? 'active') != 'active';

  // ============================================================
  // RESOLVE NAMA USER
  // ============================================================
  String _resolveOwnerNameFromReport(Map<String, dynamic> reportData) {
    final candidates = [
      reportData['user_name'],
      reportData['owner_name'],
      reportData['reporter_name'],
      reportData['created_by_name'],
    ];

    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return c.toString().trim();
      }
    }
    return 'User';
  }

  String _resolveMyName(User user) {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;

    final email = user.email?.trim();
    if (email != null && email.contains('@')) return email.split('@').first;

    return 'User';
  }

  void _showSnackSafe(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ============================================================
  // CHAT CONTEXT → disimpan ke chats/{chatId}.context
  // ============================================================
  Map<String, dynamic> _buildChatContextFromReport() {
    return {
      'report_id': reportId,
      'report_type': (data['type'] ?? 'lost').toString(), // lost | found
      'title': (data['name'] ?? '-').toString(),
      'category': (data['category'] ?? '-').toString(),
      'location': (data['location'] ?? '').toString(),
    };
  }

  // ============================================================
  // OPEN CHAT + SIMPAN CONTEXT
  // ============================================================
  Future<void> _openChatWithOwner({
    required BuildContext rootContext,
    required String ownerId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackSafe(rootContext, 'User belum login');
      return;
    }

    final trimmedOwner = ownerId.trim();
    if (trimmedOwner.isEmpty) {
      _showSnackSafe(rootContext, 'Owner tidak valid');
      return;
    }

    if (trimmedOwner == currentUser.uid) {
      _showSnackSafe(rootContext, 'Tidak bisa chat dengan diri sendiri');
      return;
    }

    // ✅ simpan router sebelum await
    final router = GoRouter.of(rootContext);

    final db = FirebaseFirestore.instance;

    try {
      final ownerName = _resolveOwnerNameFromReport(data);
      final myName = _resolveMyName(currentUser);

      // chatId deterministik
      final ids = [currentUser.uid, trimmedOwner]..sort();
      final chatId = '${ids[0]}_${ids[1]}';

      final chatRef = db.collection('chats').doc(chatId);

      // simpan context report di chat doc
      final contextData = _buildChatContextFromReport();

      await chatRef.set({
        'participants': [currentUser.uid, trimmedOwner],
        'participant_names': {currentUser.uid: myName, trimmedOwner: ownerName},
        'context': contextData,
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // optional: bikin message awal kalau kosong
      final msgSnap = await chatRef.collection('messages').limit(1).get();
      if (msgSnap.docs.isEmpty) {
        await chatRef.collection('messages').add({
          'text': 'Chat dimulai',
          'sender_id': currentUser.uid,
          'created_at': FieldValue.serverTimestamp(),
        });

        await chatRef.set({
          'last_message': 'Chat dimulai',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // navigate
      router.go(
        '/chat/detail',
        extra: {'chatId': chatId, 'partnerName': ownerName},
      );
    } on FirebaseException catch (e) {
      // ignore: use_build_context_synchronously
      _showSnackSafe(rootContext, 'Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showSnackSafe(rootContext, 'Error: $e');
    }
  }

  // ============================================================
  // OPEN VERIFICATION
  // ============================================================
  void _openVerification({
    required BuildContext rootContext,
    required String ownerId,
  }) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackSafe(rootContext, 'User belum login');
      return;
    }

    final trimmedOwner = ownerId.trim();
    if (trimmedOwner.isEmpty) {
      _showSnackSafe(rootContext, 'Target user tidak ditemukan');
      return;
    }

    if (trimmedOwner == currentUser.uid) {
      _showSnackSafe(rootContext, 'Ini laporan milik kamu');
      return;
    }

    showDialog(
      context: rootContext,
      builder: (_) => OwnershipVerificationDialog(
        reportId: reportId,
        reportType: 'found',
        targetUserId: trimmedOwner,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    final ownerId = (data['user_id'] ?? '').toString().trim();
    final bool isMyReport =
        currentUser != null && ownerId.isNotEmpty && currentUser.uid == ownerId;

    final bool isLost = (data['type'] ?? 'lost') == 'lost';
    final String status = (data['status'] ?? 'active').toString();
    final bool done = _isDone(status);

    final String name = (data['name'] ?? '-').toString();
    final String category = (data['category'] ?? '-').toString();
    final String location = (data['location'] ?? '-').toString();
    final String description = (data['description'] ?? '-').toString();

    final Timestamp? createdAt = data['created_at'] is Timestamp
        ? data['created_at'] as Timestamp
        : null;

    final String timeText = createdAt != null ? timeAgo(createdAt) : '-';

    // ✅ root context untuk dialog / navigasi
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // ============================================================
            // ICON KATEGORI (SELALU) — sinkron dengan dialog
            // ============================================================
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 140,
                width: double.infinity,
                color: Warna.blue,
                alignment: Alignment.center,
                child: CategoryIconMapper.buildIcon(category, size: 64),
              ),
            ),

            const SizedBox(height: 16),

            // NAME
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // STATUS TEXT
            Text(
              done
                  ? 'Selesai'
                  : (isLost ? 'Hilang • $timeText' : 'Ditemukan • $timeText'),
              style: TextStyle(
                color: done ? Warna.blue : (isLost ? Colors.red : Colors.green),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            // LOCATION
            Text(
              'Lokasi Terakhir : $location',
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // DESCRIPTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(description),
            ),

            const SizedBox(height: 20),

            // ============================================================
            // ACTION BUTTON — sinkron dengan dialog:
            // - done => Tutup
            // - my report => Tutup
            // - active & bukan milik sendiri => Hubungi/Verifikasi
            // ============================================================
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: (done || isMyReport)
                      ? Colors.grey.shade400
                      : Warna.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  // ✅ selesai / laporan sendiri => tutup
                  if (done || isMyReport) {
                    Navigator.of(context).pop();
                    return;
                  }

                  // ✅ harus login untuk aksi
                  if (currentUser == null) {
                    _showSnackSafe(rootContext, 'User belum login');
                    return;
                  }

                  // tutup bottomsheet dulu biar aman UI
                  Navigator.of(context).pop();

                  if (isLost) {
                    await _openChatWithOwner(
                      rootContext: rootContext,
                      ownerId: ownerId,
                    );
                  } else {
                    _openVerification(
                      rootContext: rootContext,
                      ownerId: ownerId,
                    );
                  }
                },
                child: Text(
                  (done || isMyReport)
                      ? 'Tutup'
                      : (isLost ? 'Hubungi' : 'Verifikasi Kepemilikan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
