import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/report_type.dart';
import '../utils/category_icon_mapper.dart';
import 'ownership_verification_dialog.dart';

class ReportDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final ReportType type;
  final String reportId;

  const ReportDetailDialog({
    super.key,
    required this.data,
    required this.type,
    required this.reportId,
  });

  // ============================================================
  // CHAT CONTEXT → disimpan ke chats/{chatId}.context
  // ============================================================
  Map<String, dynamic> _buildChatContext() {
    return {
      'report_id': reportId,
      'report_type': type == ReportType.lost ? 'lost' : 'found',
      'title': (data['name'] ?? '-').toString(),
      'category': (data['category'] ?? '-').toString(),
      'location': (data['location'] ?? '').toString(),
    };
  }

  // ============================================================
  // RESOLVE NAMA USER
  // ============================================================
  String _resolveOwnerName() {
    final keys = [
      'user_name',
      'owner_name',
      'reporter_name',
      'created_by_name',
    ];

    for (final k in keys) {
      final v = data[k];
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return 'User';
  }

  String _resolveMyName(User user) {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;

    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'User';
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg)));
  }

  // ============================================================
  // OPEN CHAT
  // ============================================================
  Future<void> _openChat({
    required BuildContext rootContext,
    required String ownerId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnack(rootContext, 'User belum login');
      return;
    }

    if (ownerId == currentUser.uid) {
      _showSnack(rootContext, 'Tidak bisa chat dengan diri sendiri');
      return;
    }

    final router = GoRouter.of(rootContext);
    final db = FirebaseFirestore.instance;

    final ownerName = _resolveOwnerName();
    final myName = _resolveMyName(currentUser);

    final ids = [currentUser.uid, ownerId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatRef = db.collection('chats').doc(chatId);

    await chatRef.set(
      {
        'participants': [currentUser.uid, ownerId],
        'participant_names': {
          currentUser.uid: myName,
          ownerId: ownerName,
        },
        'context': _buildChatContext(),
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    router.go(
      '/chat/detail',
      extra: {
        'chatId': chatId,
        'partnerName': ownerName,
      },
    );
  }

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final ownerId = (data['user_id'] ?? '').toString();
    final isMyReport = user != null && user.uid == ownerId;

    final category = (data['category'] ?? '-').toString();
    final location = (data['location'] ?? '-').toString();
    final description = (data['description'] ?? '').toString();
    final status = (data['status'] ?? 'active').toString();
    final isDone = status != 'active';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ================= TITLE =================
            Text(
              (data['name'] ?? '-').toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              type == ReportType.lost ? 'Barang Hilang' : 'Barang Temuan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: type == ReportType.lost ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 16),

            // ================= ICON KATEGORI (SELALU) =================
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 180,
                width: double.infinity,
                color: Warna.blue,
                alignment: Alignment.center,
                child: CategoryIconMapper.buildIcon(
                  category,
                  size: 72,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================= LOCATION =================
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                children: [
                  const TextSpan(text: 'Lokasi Terakhir : '),
                  TextSpan(
                    text: location,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            // ================= DESCRIPTION (LOST ONLY) =================
            if (type == ReportType.lost && description.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi Barang',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ================= ACTION BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 44,
              child: _buildActionButton(
                context,
                ownerId: ownerId,
                isMyReport: isMyReport,
                isDone: isDone,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String ownerId,
    required bool isMyReport,
    required bool isDone,
  }) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    // ✅ laporan selesai → tutup
    if (isDone || isMyReport) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Tutup'),
      );
    }

    if (type == ReportType.lost) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Warna.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          Navigator.of(context).pop();
          await _openChat(
            rootContext: rootContext,
            ownerId: ownerId,
          );
        },
        child: const Text('Hubungi'),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Warna.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        Navigator.of(context).pop();
        showDialog(
          context: rootContext,
          builder: (_) => OwnershipVerificationDialog(
            reportId: reportId,
            reportType: 'found',
            targetUserId: ownerId,
          ),
        );
      },
      child: const Text('Verifikasi Kepemilikan'),
    );
  }
}
