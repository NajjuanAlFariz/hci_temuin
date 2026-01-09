import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/report_type.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String ownerId = (data['user_id'] ?? '').toString();
    final bool isMyReport = user != null && user.uid == ownerId;

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

            if (data['image_url'] != null &&
                data['image_url'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  data['image_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Text('Gambar gagal dimuat'),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black),
                children: [
                  const TextSpan(text: 'Lokasi Terakhir : '),
                  TextSpan(
                    text: (data['location'] ?? '-').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            if (type == ReportType.lost &&
                data['description'] != null &&
                data['description'].toString().isNotEmpty)
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
                        data['description'].toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            if (!isMyReport)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: _buildActionButton(context, ownerId: ownerId),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required String ownerId}) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

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
          await _openChatWithOwner(rootContext, ownerId: ownerId);
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

  Future<void> _openChatWithOwner(
    BuildContext rootContext, {
    required String ownerId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showSnackSafe(rootContext, 'User belum login');
      return;
    }

    if (ownerId.trim().isEmpty) {
      _showSnackSafe(rootContext, 'Owner tidak valid');
      return;
    }

    if (ownerId == currentUser.uid) {
      _showSnackSafe(rootContext, 'Tidak bisa chat dengan diri sendiri');
      return;
    }

    final db = FirebaseFirestore.instance;

    try {
      // ✅ Karena /users tidak bisa dibaca user lain (rules), ambil dari report data
      final ownerName = _resolveOwnerNameFromReport(data);

      // Nama saya dari auth (aman)
      final myName = currentUser.displayName ??
          currentUser.email?.split('@').first ??
          'User';

      // Chat ID deterministik
      final ids = [currentUser.uid, ownerId]..sort();
      final chatId = '${ids[0]}_${ids[1]}';

      final chatRef = db.collection('chats').doc(chatId);

      await chatRef.set({
        'participants': [currentUser.uid, ownerId],
        'participant_names': {
          currentUser.uid: myName,
          ownerId: ownerName,
        },
        'last_message': 'Chat dimulai',
        'updated_at': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Navigasi ke chat detail
      rootContext.go(
        '/chat/detail',
        extra: {
          'chatId': chatId,
          'partnerName': ownerName,
        },
      );
    } on FirebaseException catch (e) {
      _showSnackSafe(rootContext, 'Firebase error: ${e.message ?? e.code}');
    } catch (e) {
      _showSnackSafe(rootContext, 'Error: $e');
    }
  }

  /// Ambil nama owner dari data report (karena users collection private).
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

  void _showSnackSafe(BuildContext context, String msg) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }
}
