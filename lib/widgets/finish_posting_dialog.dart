import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_colors.dart';
import '../utils/category_icon_mapper.dart';

/// ============================================================
/// Popup Selesaikan Postingan (Firestore Integrated)
/// ============================================================
/// Cara pakai:
/// await showFinishPostingPopupFirestore(
///   context,
///   collection: 'lost_items' / 'found_items',
///   docId: 'xxx',
///   title: 'Baju Hitam',
///   imageUrl: 'https://...',
///   category: 'Pakaian',
///   status: 'active' / 'done',
/// );
///
Future<void> showFinishPostingPopupFirestore(
  BuildContext context, {
  required String collection,
  required String docId,
  required String title,
  required String category,
  required String status, // active / done
  String? imageUrl,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _FinishPostingDialog(
      collection: collection,
      docId: docId,
      title: title,
      category: category,
      status: status,
      imageUrl: imageUrl,
    ),
  );
}

class _FinishPostingDialog extends StatefulWidget {
  final String collection;
  final String docId;
  final String title;
  final String category;
  final String status;
  final String? imageUrl;

  const _FinishPostingDialog({
    required this.collection,
    required this.docId,
    required this.title,
    required this.category,
    required this.status,
    required this.imageUrl,
  });

  @override
  State<_FinishPostingDialog> createState() => _FinishPostingDialogState();
}

class _FinishPostingDialogState extends State<_FinishPostingDialog> {
  bool _loading = false;

  bool get _isDone => widget.status.trim().toLowerCase() == 'done';

  Future<void> _markAsDone() async {
    if (_isDone) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.docId)
          .update({
        'status': 'done',
        'updated_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Tutup dialog setelah sukses
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Gagal update status')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImage() {
    final url = widget.imageUrl?.trim();

    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 150,
              alignment: Alignment.center,
              color: Colors.grey.shade200,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: CategoryIconMapper.buildIcon(
        widget.category.isEmpty ? '-' : widget.category,
        size: 72,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = _isDone ? Warna.blue : Colors.green;
    final buttonText = _isDone ? 'Selesai' : 'Selesaikan Postingan';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(),
            const SizedBox(height: 14),

            Text(
              widget.title.isEmpty ? '-' : widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _loading
                    ? null
                    : () async {
                        if (_isDone) {
                          if (mounted) Navigator.pop(context);
                          return;
                        }
                        await _markAsDone();
                      },
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
