import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class Navbar extends StatelessWidget {
  final int currentIndex;

  const Navbar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/kategori');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }

  Widget _buildIcon({
    required String assetPath,
    required bool isActive,
  }) {
    return Opacity(
      opacity: isActive ? 1.0 : 0.4,
      child: Image.asset(
        assetPath,
        height: 24,
        fit: BoxFit.contain,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTap(context, index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Warna.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(
              assetPath: 'assets/image/icon/home.png',
              isActive: currentIndex == 0,
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              assetPath: 'assets/image/icon/category.png',
              isActive: currentIndex == 1,
            ),
            label: 'Kategori',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              assetPath: 'assets/image/icon/profile.png',
              isActive: currentIndex == 2,
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
