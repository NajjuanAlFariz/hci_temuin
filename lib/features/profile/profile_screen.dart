import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';
import '../../widgets/finish_posting_dialog.dart';
import '../../utils/category_icon_mapper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool showProcess = true;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User belum login')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final name = (data?['name'] ?? '').toString();
          final email = (data?['email'] ?? user!.email ?? '').toString();

          return Column(
            children: [
              /// ================= HEADER =================
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(36),
                    ),
                    child: Image.asset(
                      'assets/image/profile_bg.png',
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: -44,
                    child: Container(
                      width: 105,
                      height: 105,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/image/profile_default.png',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 56),

              /// ================= USER INFO =================
              Column(
                children: [
                  Text(
                    name.isEmpty ? 'User' : name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  /// LOGOUT
                  SizedBox(
                    height: 38,
                    child: OutlinedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        context.go('/login');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        side: const BorderSide(color: Colors.black),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// ================= TAB =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        label: 'Proses',
                        active: showProcess,
                        onTap: () => setState(() => showProcess = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tabButton(
                        label: 'Selesai',
                        active: !showProcess,
                        onTap: () => setState(() => showProcess = false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// ================= GRID REPORT =================
              Expanded(
                child: _UserReports(
                  uid: user!.uid,
                  showProcess: showProcess,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const Navbar(currentIndex: 2),
    );
  }

  Widget _tabButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Warna.blue : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Warna.blue),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Warna.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// USER REPORTS (lost_items + found_items) + popup selesai posting
/// ============================================================
class _UserReports extends StatelessWidget {
  final String uid;
  final bool showProcess;

  const _UserReports({
    required this.uid,
    required this.showProcess,
  });

  bool _matchStatus(String status) {
    final s = status.trim().toLowerCase();
    if (showProcess) return s != 'done'; // proses = bukan done (active)
    return s == 'done';
  }

  @override
  Widget build(BuildContext context) {
    final lostStream = FirebaseFirestore.instance
        .collection('lost_items')
        .where('user_id', isEqualTo: uid)
        .snapshots();

    final foundStream = FirebaseFirestore.instance
        .collection('found_items')
        .where('user_id', isEqualTo: uid)
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

            // Gabungkan lost + found jadi list item yang seragam
            final items = <_ProfileReportItem>[];

            for (final doc in lostSnap.data!.docs) {
              final map = doc.data() as Map<String, dynamic>;
              items.add(_ProfileReportItem.fromDoc(
                docId: doc.id,
                collection: 'lost_items',
                data: map,
              ));
            }

            for (final doc in foundSnap.data!.docs) {
              final map = doc.data() as Map<String, dynamic>;
              items.add(_ProfileReportItem.fromDoc(
                docId: doc.id,
                collection: 'found_items',
                data: map,
              ));
            }

            // Filter tab proses/selesai
            final filtered = items.where((e) => _matchStatus(e.status)).toList();

            if (filtered.isEmpty) {
              return Center(
                child: Text(showProcess ? 'Belum ada laporan proses' : 'Belum ada laporan selesai'),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];

                return GestureDetector(
                  onTap: () async {
                    await showFinishPostingPopupFirestore(
                      context,
                      collection: item.collection, // 'lost_items' / 'found_items'
                      docId: item.docId,
                      title: item.name.isEmpty ? 'Postingan' : item.name,
                      category: item.category,
                      status: item.status, // 'active' / 'done'
                      imageUrl: item.imageUrl,
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _GridThumb(
                      imageUrl: item.imageUrl,
                      category: item.category,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Thumbnail grid: gambar kalau ada, kalau tidak ada icon category
class _GridThumb extends StatelessWidget {
  final String? imageUrl;
  final String category;

  const _GridThumb({
    required this.imageUrl,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return Container(
      color: Colors.blue,
      alignment: Alignment.center,
      child: CategoryIconMapper.buildIcon(
        category.isEmpty ? '-' : category,
        size: 34,
      ),
    );
  }
}

/// Model item untuk profile grid
class _ProfileReportItem {
  final String docId;
  final String collection; // lost_items / found_items
  final String name;
  final String category;
  final String status; // active / done
  final String? imageUrl;

  _ProfileReportItem({
    required this.docId,
    required this.collection,
    required this.name,
    required this.category,
    required this.status,
    required this.imageUrl,
  });

  factory _ProfileReportItem.fromDoc({
    required String docId,
    required String collection,
    required Map<String, dynamic> data,
  }) {
    return _ProfileReportItem(
      docId: docId,
      collection: collection,
      name: (data['name'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      status: (data['status'] ?? 'active').toString(),
      imageUrl: data['image_url']?.toString(),
    );
  }
}
