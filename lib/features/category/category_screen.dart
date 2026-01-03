import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/time_ago.dart';
import '../../widgets/report_detail_dialog.dart'; 

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Kategori')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
        builder: (context, lostSnap) {
          if (!lostSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('found_items')
                .snapshots(),
            builder: (context, foundSnap) {
              if (!foundSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              /// ================= MERGE DATA =================
              final lostItems = lostSnap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'lost';
                return data;
              });

              final foundItems = foundSnap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'found';
                return data;
              });

              final allItems = [...lostItems, ...foundItems];

              final filteredItems = selectedCategory == 'Semua'
                  ? allItems.toList()
                  : allItems.where((e) {
                      return e['category']
                              .toString()
                              .toLowerCase() ==
                          selectedCategory.toLowerCase();
                    }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= FILTER =================
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final active = cat == selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: active,
                              selectedColor: Warna.blue,
                              labelStyle: TextStyle(
                                color:
                                    active ? Colors.white : Colors.black,
                              ),
                              onSelected: (_) {
                                setState(() => selectedCategory = cat);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ================= GRID =================
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.68, // ANTI OVERFLOW
                      ),
                      itemBuilder: (_, i) {
                        return ReportItemCard(
                          data: filteredItems[i],
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

/// ============================================================
/// ITEM CARD (TAP → POP UP DETAIL)
/// ============================================================
class ReportItemCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReportItemCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isLost = data['type'] == 'lost';
    final String name = data['name'];
    final String category = data['category'];
    final String location = data['location'];
    final String? imageUrl = data['image_url'];
    final Timestamp? createdAt = data['created_at'];

    final String timeText =
        createdAt != null ? timeAgo(createdAt) : '-';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => ReportDetailDialog(
            data: data,
            type: isLost ? ReportType.lost : ReportType.found,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            /// IMAGE / ICON
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: isLost && imageUrl != null
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Warna.blue,
                        alignment: Alignment.center,
                        child: CategoryIconMapper.buildIcon(
                          category,
                          size: 44,
                        ),
                      ),
              ),
            ),

            /// CONTENT
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NAME
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// STATUS + TIME
                    Text(
                      isLost
                          ? 'Hilang • $timeText'
                          : 'Ditemukan • $timeText',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isLost ? Colors.red : Colors.green,
                      ),
                    ),

                    const SizedBox(height: 4),

                    /// LOCATION
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),

                    const Spacer(),

                    /// BADGE
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isLost
                            ? Colors.red.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isLost ? 'Di cari' : 'Ditemukan',
                        style: TextStyle(
                          color:
                              isLost ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
}
