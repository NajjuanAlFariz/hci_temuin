import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';
import '../../widgets/upload_report_section.dart';
import '../../widgets/report_detail_bottom_sheet.dart';
import '../../widgets/home_top_navbar.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/time_ago.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

body: Column(
  children: [
    const HomeTopNavbar(),
    Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StatCardRow(),
            const SizedBox(height: 20),

            const UploadReportSection(),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAFA),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _LatestHeader(),
                  SizedBox(height: 12),
                  LatestReports(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),

      bottomNavigationBar: const Navbar(currentIndex: 0),
    );
  }
}

class _StatCardRow extends StatelessWidget {
  const _StatCardRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        LostItemStatCard(),
        SizedBox(width: 12),
        FoundItemStatCard(),
      ],
    );
  }
}

class LostItemStatCard extends StatelessWidget {
  const LostItemStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
        builder: (_, snapshot) {
          final total = snapshot.data?.docs.length ?? 0;
          return _StatCard(
            title: 'Barang Hilang',
            count: total,
            iconAsset: 'assets/image/icon/lost.png',
            iconBgColor: Colors.red.shade100,
          );
        },
      ),
    );
  }
}

class FoundItemStatCard extends StatelessWidget {
  const FoundItemStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('found_items').snapshots(),
        builder: (_, snapshot) {
          final total = snapshot.data?.docs.length ?? 0;
          return _StatCard(
            title: 'Barang Temuan',
            count: total,
            iconAsset: 'assets/image/icon/found.png',
            iconBgColor: Colors.green.shade100,
          );
        },
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final String iconAsset;
  final Color iconBgColor;

  const _StatCard({
    required this.title,
    required this.count,
    required this.iconAsset,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(iconAsset),
          ),
        ],
      ),
    );
  }
}


class LatestReports extends StatelessWidget {
  const LatestReports({super.key});

  @override
  Widget build(BuildContext context) {
    final lostStream = FirebaseFirestore.instance
        .collection('lost_items')
        .orderBy('created_at', descending: true)
        .limit(5)
        .snapshots();

    final foundStream = FirebaseFirestore.instance
        .collection('found_items')
        .orderBy('created_at', descending: true)
        .limit(5)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: lostStream,
      builder: (_, lostSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: foundStream,
          builder: (_, foundSnap) {
            if (!lostSnap.hasData || !foundSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final reports = [
              ...lostSnap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'lost';
                return data;
              }),
              ...foundSnap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'found';
                return data;
              }),
            ];

            if (reports.isEmpty) {
              return const Text('Belum ada laporan');
            }

            reports.sort((a, b) {
              final aTime = a['created_at'] as Timestamp?;
              final bTime = b['created_at'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

            return Column(
              children: reports.take(5).map((data) {
                final String name = data['name'];
                final String category = data['category'];
                final String location = data['location'];
                final String type = data['type'];
                final Timestamp? createdAt = data['created_at'];

                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) =>
                          ReportDetailBottomSheet(data: data),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Warna.blue,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child:
                              CategoryIconMapper.buildIcon(category, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                type == 'lost'
                                    ? 'Hilang di $location'
                                    : 'Ditemukan di $location',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              if (createdAt != null)
                                Text(
                                  timeAgo(createdAt),
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _LatestHeader extends StatelessWidget {
  const _LatestHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Laporan Terbaru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        TextButton(
          onPressed: () => context.go('/kategori'),
          child: const Text('Lihat Semua'),
        ),
      ],
    );
  }
}
