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
      appBar: AppBar(
        title: const Text('Kategori'),
      ),

      /// ================= DATA =================
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
              });

              final foundItems = foundSnapshot.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                data['type'] = 'found';
                return data;
              });

              final allItems = [...lostItems, ...foundItems];

              final filteredItems = selectedCategory == 'Semua'
                  ? allItems.toList()
                  : allItems
                      .where((e) =>
                          e['category']
                              .toString()
                              .toLowerCase() ==
                          selectedCategory.toLowerCase())
                      .toList();

              final total = allItems.length;
              final found =
                  allItems.where((e) => e['type'] == 'found').length;
              final lost =
                  allItems.where((e) => e['type'] == 'lost').length;

              /// ================= UI =================
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ================= STAT BOX =================
                    Row(
                      children: [
                        _StatBox(
                          title: 'Total Item',
                          value: total,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          title: 'Ditemukan',
                          value: found,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _StatBox(
                          title: 'Dicari',
                          value: lost,
                          color: Colors.red,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// ================= CATEGORY TAB =================
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
                              onSelected: (_) {
                                setState(() => selectedCategory = cat);
                              },
                              labelStyle: TextStyle(
                                color:
                                    active ? Colors.white : Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ================= GRID ITEM =================
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (_, index) {
                        return _ItemCard(filteredItems[index]);
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

  const _StatBox({
    required this.title,
    required this.value,
    required this.color,
  });

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
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// ITEM CARD
/// ============================================================
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ItemCard(this.data);

  @override
  Widget build(BuildContext context) {
    final bool isLost = data['type'] == 'lost';
    final String category = data['category'];
    final String name = data['name'];
    final String location = data['location'];
    final Timestamp? createdAt = data['created_at'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Warna.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// ICON
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CategoryIconMapper.buildIcon(category),
          ),

          const SizedBox(height: 12),

          /// NAME
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          /// STATUS
          Text(
            isLost
                ? 'Hilang di $location'
                : 'Ditemukan di $location',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            maxLines: 2,
          ),

          const Spacer(),

          /// TIME
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
    );
  }
}
