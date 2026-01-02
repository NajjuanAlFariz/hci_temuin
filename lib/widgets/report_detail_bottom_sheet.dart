import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';
import '../utils/time_ago.dart';

class ReportDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReportDetailBottomSheet({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isLost = data['type'] == 'lost';
    final String name = data['name'];
    final String category = data['category'];
    final String location = data['location'];
    final String description = data['description'] ?? '-';
    final String? imageUrl = data['image_url'];
    final Timestamp? createdAt = data['created_at'];

    final String timeText =
        createdAt != null ? timeAgo(createdAt) : '-';

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
                child: isLost && imageUrl != null
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
            ),

            const SizedBox(height: 6),

            /// STATUS
            Text(
              isLost
                  ? 'Hilang • $timeText'
                  : 'Ditemukan • $timeText',
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

            const SizedBox(height: 20),

            /// ACTION BUTTON
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
                onPressed: () {
                  // TODO: nanti ke chat / verifikasi
                },
                child: Text(
                  isLost ? 'Hubungi' : 'Verifikasi Kepemilikan',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
