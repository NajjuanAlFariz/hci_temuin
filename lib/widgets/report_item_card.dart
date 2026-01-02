import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/time_ago.dart';

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
    'Aksesoris',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Kategori')),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('lost_items').snapshots(),
        builder: (context, lostSnapshot) {
          if (!lostSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('found_items')
                .snapshots(),
            builder: (context, foundSnapshot) {
              if (!foundSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              /// ================= MERGE DATA =================
              final lostItems = lostSnapshot.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'lost';
                return data;
              }).toList();

              final foundItems = foundSnapshot.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'found';
                return data;
              }).toList();

              final allItems = [...lostItems, ...foundItems];

              final filteredItems = selectedCategory == 'Semua'
                  ? allItems
                  : allItems
                      .where((e) =>
                          e['category'].toString().toLowerCase() ==
                          selectedCategory.toLowerCase())
                      .toList();

              final total = allItems.length;
              final found =
                  allItems.where((e) => e['type'] == 'found').length;
              final lost =
                  allItems.where((e) => e['type'] == 'lost').length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= STAT =================
                    Row(
                      children: [
                        _StatBox('Total Item', total, Colors.blue),
                        const SizedBox(width: 8),
                        _StatBox('Ditemukan', found, Colors.green),
                        const SizedBox(width: 8),
                        _StatBox('Dicari', lost, Colors.red),
                      ],
                    ),

                    const SizedBox(height: 16),

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
                        childAspectRatio: 0.70,
                      ),
                      itemBuilder: (_, i) {
                        return _ItemCard(filteredItems[i]);
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
/// STAT BOX
/// ============================================================
class _StatBox extends StatelessWidget {
  final String title;
  final int value;
  final Color color;

  const _StatBox(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// ITEM CARD (GAMBAR vs ICON)
/// ============================================================
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ItemCard(this.data);

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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ================= IMAGE / ICON =================
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: isLost && imageUrl != null
                  ? Image.network(imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Warna.blue,
                      alignment: Alignment.center,
                      child: CategoryIconMapper.buildIcon(
                        category,
                        size: 48,
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Text(
                  isLost
                      ? 'Hilang : $timeText'
                      : 'Ditemukan : $timeText',
                  style: TextStyle(
                    fontSize: 12,
                    color: isLost ? Colors.red : Colors.green,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Lokasi Terakhir : $location',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

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
                      color: isLost ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
