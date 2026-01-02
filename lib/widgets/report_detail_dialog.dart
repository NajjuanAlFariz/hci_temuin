import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';
import '../utils/time_ago.dart';

enum ReportType { lost, found }

class ReportDetailDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final ReportType type;

  const ReportDetailDialog({
    super.key,
    required this.data,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final String name = data['name'];
    final String category = data['category'];
    final String location = data['location'];
    final String? description = data['description'];
    final String? imageUrl = data['image_url'];
    final Timestamp? createdAt = data['created_at'];

    final String timeText =
        createdAt != null ? timeAgo(createdAt) : '-';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ================= HEADER VISUAL =================
            _buildHeaderVisual(category, imageUrl),

            const SizedBox(height: 16),

            /// ================= NAME =================
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            /// ================= STATUS =================
            Text(
              type == ReportType.lost
                  ? 'Hilang • $timeText'
                  : 'Ditemukan • $timeText',
              style: TextStyle(
                fontSize: 13,
                color: type == ReportType.lost
                    ? Colors.red
                    : Colors.green,
              ),
            ),

            const SizedBox(height: 6),

            /// ================= LOCATION =================
            Text(
              'Lokasi Terakhir : $location',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),

            /// ================= DESKRIPSI (KHUSUS HILANG) =================
            if (type == ReportType.lost && description != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],

            const SizedBox(height: 20),

            /// ================= ACTION BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: action hubungi / verifikasi
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Warna.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  type == ReportType.lost
                      ? 'Hubungi'
                      : 'Verifikasi Kepemilikan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================================================
  /// HEADER VISUAL (GAMBAR / ICON)
  /// ============================================================
  Widget _buildHeaderVisual(String category, String? imageUrl) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: type == ReportType.lost
            ? Colors.grey.shade100
            : Warna.blue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: type == ReportType.lost && imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: CategoryIconMapper.buildIcon(
                category,
                size: 60,
              ),
            ),
    );
  }
}
