import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';
import '../utils/time_ago.dart';
import '../utils/report_type.dart';
import 'ownership_verification_dialog.dart';

class ReportDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String reportId;

  const ReportDetailBottomSheet({
    super.key,
    required this.data,
    required this.reportId,
  });

  String _resolveMyName(User user) {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;

    final email = user.email?.trim();
    if (email != null && email.contains('@')) return email.split('@').first;

    return 'User';
  }

  Future<String> _getOwnerNameSafe({
    required FirebaseFirestore db,
    required ReportType type,
    required String reportId,
    required Map<String, dynamic> reportDataFromList,
  }) async {
    final fromList = (reportDataFromList['user_name'] ?? '').toString().trim();
    if (fromList.isNotEmpty) return fromList;

    final collection = type == ReportType.lost ? 'lost_items' : 'found_items';
    final snap = await db.collection(collection).doc(reportId).get();
    if (snap.exists) {
      final doc = snap.data() as Map<String, dynamic>;
      final fromDoc = (doc['user_name'] ?? '').toString().trim();
      if (fromDoc.isNotEmpty) return fromDoc;
    }

    return 'User';
  }

  Future<void> _openChatWithOwner(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ownerId = (data['user_id'] ?? '').toString().trim();
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner tidak ditemukan')),
      );
      return;
    }

    if (ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ini laporan milik kamu')),
      );
      return;
    }

    final isLost = (data['type'] ?? 'lost') == 'lost';
    final type = isLost ? ReportType.lost : ReportType.found;

    final db = FirebaseFirestore.instance;

    final ownerName = await _getOwnerNameSafe(
      db: db,
      type: type,
      reportId: reportId,
      reportDataFromList: data,
    );

    final myName = _resolveMyName(user);

    final a = user.uid;
    final b = ownerId;
    final chatId = (a.compareTo(b) < 0) ? '${a}_$b' : '${b}_$a';

    final chatRef = db.collection('chats').doc(chatId);
    final snap = await chatRef.get();

    if (!snap.exists) {
      await chatRef.set({
        'participants': [user.uid, ownerId],
        'participant_names': {
          user.uid: myName,
          ownerId: ownerName,
        },
        'last_message': 'Chat dimulai',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await chatRef.collection('messages').add({
        'sender_id': user.uid,
        'text': 'Chat dimulai',
        'created_at': FieldValue.serverTimestamp(),
      });
    } else {
      final dataChat = snap.data() as Map<String, dynamic>;
      final namesRaw = dataChat['participant_names'];
      if (namesRaw is Map) {
        final names = Map<String, dynamic>.from(namesRaw);
        final currentName = (names[ownerId] ?? '').toString().trim();
        if ((currentName.isEmpty || currentName == 'User') &&
            ownerName.isNotEmpty &&
            ownerName != 'User') {
          await chatRef.update({
            'participant_names.$ownerId': ownerName,
          });
        }
      }
    }

    if (!context.mounted) return;

    context.pop(); // tutup bottomsheet
    if (!context.mounted) return;

    context.go(
      '/chat/detail',
      extra: {
        'chatId': chatId,
        'partnerName': ownerName,
      },
    );
  }

  void _openVerification(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ownerId = (data['user_id'] ?? '').toString().trim();
    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target user tidak ditemukan')),
      );
      return;
    }

    if (ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ini laporan milik kamu')),
      );
      return;
    }

    context.pop(); // close bottom sheet

    showDialog(
      context: context,
      builder: (_) => OwnershipVerificationDialog(
        reportId: reportId,
        reportType: 'found',
        targetUserId: ownerId,
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

    final String name = (data['name'] ?? '-').toString();
    final String category = (data['category'] ?? '-').toString();
    final String location = (data['location'] ?? '-').toString();
    final String description = (data['description'] ?? '-').toString();
    final String? imageUrl = data['image_url']?.toString();

    final Timestamp? createdAt =
        data['created_at'] is Timestamp ? data['created_at'] as Timestamp : null;

    final String timeText = createdAt != null ? timeAgo(createdAt) : '-';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            /// IMAGE / ICON
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Warna.blue,
                        alignment: Alignment.center,
                        child: CategoryIconMapper.buildIcon(
                          category,
                          size: 64,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            /// NAME
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            /// STATUS
            Text(
              isLost ? 'Hilang • $timeText' : 'Ditemukan • $timeText',
              style: TextStyle(
                color: isLost ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            /// LOCATION
            Text(
              'Lokasi Terakhir : $location',
              style: const TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            /// DESCRIPTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(description),
            ),

            /// ACTION BUTTON (HANYA JIKA BUKAN LAPORAN SENDIRI & USER LOGIN)
            if (currentUser != null && !isMyReport) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warna.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (isLost) {
                      await _openChatWithOwner(context);
                    } else {
                      _openVerification(context);
                    }
                  },
                  child: Text(
                    isLost ? 'Hubungi' : 'Verifikasi Kepemilikan',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
