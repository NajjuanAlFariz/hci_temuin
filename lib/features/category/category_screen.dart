import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/time_ago.dart';
import '../../widgets/report_detail_dialog.dart';
import '../../utils/report_type.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String selectedCategory = 'Semua';

  final List<String> categories = [
    'Semua',
    'Pakaian',
    'Elektronik',
    'Alat Tulis',
    'Alat Makan',
  ];

  bool _isActive(String? status) => (status ?? 'active') == 'active';

  @override
  Widget build(BuildContext context) {
    final lostStream =
        FirebaseFirestore.instance.collection('lost_items').snapshots();
    final foundStream =
        FirebaseFirestore.instance.collection('found_items').snapshots();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ✅ NO BACK ARROW
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Kategori',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: lostStream,
        builder: (context, lostSnap) {
          if (lostSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lostSnap.hasError) {
            return const Center(child: Text('Gagal memuat data lost_items'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: foundStream,
            builder: (context, foundSnap) {
              if (foundSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (foundSnap.hasError) {
                return const Center(child: Text('Gagal memuat data found_items'));
              }

              final lostItems = (lostSnap.data?.docs ?? []).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  ...data,
                  'type': 'lost',
                  'doc_id': doc.id,
                };
              }).toList();

              final foundItems = (foundSnap.data?.docs ?? []).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  ...data,
                  'type': 'found',
                  'doc_id': doc.id,
                };
              }).toList();

              final allItems = [...lostItems, ...foundItems];

              // ✅ Sort manual (hindari index)
              allItems.sort((a, b) {
                final aTime = a['created_at'] as Timestamp?;
                final bTime = b['created_at'] as Timestamp?;
                if (aTime == null || bTime == null) return 0;
                return bTime.compareTo(aTime);
              });

              // ✅ Filter kategori
              final filtered = selectedCategory == 'Semua'
                  ? allItems
                  : allItems
                      .where((e) =>
                          (e['category'] ?? '').toString().toLowerCase() ==
                          selectedCategory.toLowerCase())
                      .toList();

              // ✅ Statistik
              final total = allItems.length;
              final totalFound = allItems
                  .where((e) =>
                      e['type'] == 'found' && _isActive(e['status']?.toString()))
                  .length;
              final totalLost = allItems
                  .where((e) =>
                      e['type'] == 'lost' && _isActive(e['status']?.toString()))
                  .length;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _StatsCard(
                      total: total,
                      found: totalFound,
                      lost: totalLost,
                    ),
                    const SizedBox(height: 10),

                    // ✅ Chips filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final active = cat == selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              text: cat,
                              active: active,
                              onTap: () => setState(() => selectedCategory = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ✅ Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        // ✅ sedikit lebih tinggi agar aman
                        childAspectRatio: 0.74,
                      ),
                      itemBuilder: (_, i) {
                        final data = filtered[i];
                        return _ReportCard(
                          data: data,
                          onTap: () {
                            final isLost = data['type'] == 'lost';
                            showDialog(
                              context: context,
                              builder: (_) => ReportDetailDialog(
                                data: data,
                                type: isLost ? ReportType.lost : ReportType.found,
                                reportId: (data['doc_id'] ?? '').toString(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),

      bottomNavigationBar: const Navbar(currentIndex: 1),
    );
  }
}

/// =======================
/// STATS CARD (TOP)
/// =======================
class _StatsCard extends StatelessWidget {
  final int total;
  final int found;
  final int lost;

  const _StatsCard({
    required this.total,
    required this.found,
    required this.lost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(label: 'Total Item', value: total.toString(), color: Warna.blue),
          _StatItem(label: 'Ditemukan', value: found.toString(), color: Colors.green),
          _StatItem(label: 'Di cari', value: lost.toString(), color: Colors.red),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }
}

/// =======================
/// CATEGORY CHIP
/// =======================
class _CategoryChip extends StatelessWidget {
  final String text;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Warna.blue : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Warna.blue),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Warna.blue,
          ),
        ),
      ),
    );
  }
}

/// =======================
/// REPORT CARD (GRID ITEM)
/// =======================
class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _ReportCard({
    required this.data,
    required this.onTap,
  });

  bool _isActive(String? status) => (status ?? 'active') == 'active';

  @override
  Widget build(BuildContext context) {
    final bool isLost = (data['type'] ?? 'lost') == 'lost';

    final String name = (data['name'] ?? '-').toString();
    final String category = (data['category'] ?? '-').toString();
    final String location = (data['location'] ?? '-').toString();
    final String? imageUrl = data['image_url']?.toString();
    final String status = (data['status'] ?? 'active').toString();

    final Timestamp? createdAt =
        data['created_at'] is Timestamp ? data['created_at'] as Timestamp : null;

    final String timeText = createdAt != null ? timeAgo(createdAt) : '-';
    final bool active = _isActive(status);

    final String statusText = active
        ? (isLost ? 'Di cari' : 'Ditemukan')
        : 'Selesai';

    final Color statusBg = active
        ? (isLost ? const Color(0xFFFFD6D6) : const Color(0xFFD8F5E0))
        : const Color(0xFFD6ECFF);

    final Color statusTextColor = active
        ? (isLost ? Colors.red : Colors.green)
        : Warna.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            // ✅ FIX: tinggi gambar dipastikan
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 112, // sedikit lebih pendek biar teks muat
                width: double.infinity,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackIcon(category),
                      )
                    : _fallbackIcon(category),
              ),
            ),

            // ✅ FIX: area teks dibuat flexible
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLost ? 'Hilang : $timeText' : 'Ditemukan : $timeText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      'Lokasi terakhir : $location',
                      maxLines: 1, // ✅ penting biar ga nambah tinggi
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),

                    const Spacer(), // ✅ dorong badge ke bawah tanpa overflow

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon(String category) {
    return Container(
      color: Warna.blue,
      alignment: Alignment.center,
      child: CategoryIconMapper.buildIcon(category, size: 60),
    );
  }
}
