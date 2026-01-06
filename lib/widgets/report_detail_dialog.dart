import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    final String ownerId = data['user_id'] ?? '';
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
            /// ================= NAME =================
            Text(
              data['name'] ?? '-',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// ================= TYPE =================
            Text(
              type == ReportType.lost
                  ? 'Barang Hilang'
                  : 'Barang Temuan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    type == ReportType.lost ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 16),

            /// ================= IMAGE =================
            if (data['image_url'] != null &&
                data['image_url'].toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  data['image_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            /// ================= LOCATION =================
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(
                    text: 'Lokasi Terakhir : ',
                  ),
                  TextSpan(
                    text: data['location'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            /// ================= DESCRIPTION (LOST ONLY) =================
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
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        data['description'],
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

            /// ================= ACTION BUTTON =================
            if (!isMyReport)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: _buildActionButton(
                  context,
                  ownerId: ownerId,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ====================================================
  /// ACTION BUTTON LOGIC
  /// ====================================================
  Widget _buildActionButton(
    BuildContext context, {
    required String ownerId,
  }) {
    /// ===== LOST → HUBUNGI =====
    if (type == ReportType.lost) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Warna.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);

          /// 🔜 NEXT STEP (CHAT):
          /// context.push('/chat', extra: ownerId);
        },
        child: const Text('Hubungi'),
      );
    }

    /// ===== FOUND → VERIFIKASI =====
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Warna.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        Navigator.pop(context);

        showDialog(
          context: context,
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
