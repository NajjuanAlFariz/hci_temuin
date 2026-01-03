import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class HomeTopNavbar extends StatelessWidget {
  const HomeTopNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// ================= LOGO =================
            Image.asset(
              'assets/image/icon/Temuin.png', // 🔴 PNG LOGO
              height: 32,
              fit: BoxFit.contain,
            ),

            /// ================= ACTION ICON =================
            Row(
              children: [
                _IconButton(
                  asset: 'assets/image/icon/bell.png',
                  onTap: () {
                    // TODO: ke halaman notifikasi
                  },
                ),
                const SizedBox(width: 12),
                _IconButton(
                  asset: 'assets/image/icon/chat.png',
                  onTap: () {
                    context.go('/chat'); // nanti ke realtime chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// ICON BUTTON
/// ============================================================
class _IconButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;

  const _IconButton({
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
        ),
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
