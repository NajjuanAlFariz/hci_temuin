import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';

class ChatProductHeader extends StatelessWidget {
  final String title;
  final String category;
  final String reportType; // 'lost' | 'found'
  final String? imageUrl; // dipakai hanya untuk lost (kalau valid)
  final String status; // 'active' | 'done' (opsional tapi enak buat label)

  const ChatProductHeader({
    super.key,
    required this.title,
    required this.category,
    required this.reportType,
    required this.imageUrl,
    required this.status,
  });

  /// ✅ INI YANG KAMU BUTUH: biar bisa dipanggil dari chat_detail_screen.dart
  static Widget fromContext(Map<String, dynamic> contextData) {
    final String title = (contextData['title'] ?? '-').toString();
    final String category = (contextData['category'] ?? '-').toString();
    final String reportType = (contextData['report_type'] ?? 'lost').toString();
    final String status = (contextData['status'] ?? 'active').toString();

    final rawUrl = contextData['image_url'];
    final String? imageUrl = _validUrl(rawUrl?.toString());

    return ChatProductHeader(
      title: title,
      category: category,
      reportType: reportType,
      imageUrl: imageUrl,
      status: status,
    );
  }

  static String? _validUrl(String? raw) {
    if (raw == null) return null;
    final url = raw.trim();
    if (url.isEmpty) return null;
    if (url.toLowerCase() == 'null') return null;
    if (!(url.startsWith('http://') || url.startsWith('https://'))) return null;
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final bool isLost = reportType == 'lost';

    final bool showNetworkImage = isLost && imageUrl != null;
    final String typeLabel = isLost ? 'Barang Hilang' : 'Barang Temuan';

    // status label (kalau sudah done => Selesai)
    final bool isDone = status != 'active';
    final String statusText = isDone
        ? 'Selesai'
        : (isLost ? 'Di cari' : 'Ditemukan');

    final Color statusBg = isDone
        ? const Color(0xFFD6ECFF)
        : (isLost ? const Color(0xFFFFD6D6) : const Color(0xFFD8F5E0));

    final Color statusTextColor = isDone
        ? Warna.blue
        : (isLost ? Colors.red : Colors.green);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // IMAGE / ICON
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 68,
              height: 68,
              child: showNetworkImage
                  ? Image.network(
                      imageUrl!, // aman karena showNetworkImage true => imageUrl != null
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(category),
                    )
                  : _fallback(category),
            ),
          ),

          const SizedBox(width: 12),

          // TEXTS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLost ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),

                // status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusTextColor,
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

  Widget _fallback(String category) {
    return Container(
      color: Warna.blue,
      alignment: Alignment.center,
      child: CategoryIconMapper.buildIcon(category, size: 34),
    );
  }
}
