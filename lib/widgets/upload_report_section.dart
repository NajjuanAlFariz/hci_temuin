import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class UploadReportSection extends StatelessWidget {
  const UploadReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unggah Laporan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _UploadButton(
                backgroundColor: Warna.red,
                iconAsset: 'assets/image/icon/upload_lost.png',
                label: 'Laporkan hilang',
                onTap: () {
                  context.push('/report-lost');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadButton(
                backgroundColor: Warna.blue,
                iconAsset: 'assets/image/icon/upload_found.png',
                label: 'Laporkan temuan',
                onTap: () {
                  context.push('/report-found');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/* ============================================================
   BUTTON UPLOAD
============================================================ */
class _UploadButton extends StatelessWidget {
  final Color backgroundColor;
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _UploadButton({
    required this.backgroundColor,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
