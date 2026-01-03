import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../widgets/navbar.dart';

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

          final name = data?['name'] ?? '';
          final email = data?['email'] ?? user!.email ?? '';

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
                      decoration: BoxDecoration(
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
                    name,
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

                  /// ✅ FIXED LOGOUT BUTTON
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
                        onTap: () =>
                            setState(() => showProcess = true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _tabButton(
                        label: 'Selesai',
                        active: !showProcess,
                        onTap: () =>
                            setState(() => showProcess = false),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              /// ================= RIWAYAT =================
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
/// USER REPORTS
/// ============================================================
class _UserReports extends StatelessWidget {
  final String uid;
  final bool showProcess;

  const _UserReports({
    required this.uid,
    required this.showProcess,
  });

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

            final reports = [
              ...lostSnap.data!.docs,
              ...foundSnap.data!.docs,
            ];

            if (reports.isEmpty) {
              return const Center(child: Text('Belum ada laporan'));
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: reports.length,
              itemBuilder: (_, i) {
                final data =
                    reports[i].data() as Map<String, dynamic>;

                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: data['image_url'] != null
                      ? Image.network(
                          data['image_url'],
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.inventory),
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
