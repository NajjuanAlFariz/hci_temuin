import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_colors.dart';
import '../services/firestore_service.dart';

class OwnershipVerificationDialog extends StatefulWidget {
  final String reportId;
  final String reportType; // lost | found
  final String targetUserId;

  const OwnershipVerificationDialog({
    super.key,
    required this.reportId,
    required this.reportType,
    required this.targetUserId,
  });

  @override
  State<OwnershipVerificationDialog> createState() =>
      _OwnershipVerificationDialogState();
}

class _OwnershipVerificationDialogState
    extends State<OwnershipVerificationDialog> {
  final TextEditingController _descController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    final description = _descController.text.trim();

    if (user == null) {
      _showError('User belum login');
      return;
    }

    if (description.isEmpty) {
      _showError('Deskripsi wajib diisi');
      return;
    }

    setState(() => _loading = true);

    try {
      await FirestoreService.instance.requestOwnershipVerification(
        reportId: widget.reportId,
        reportType: widget.reportType,
        description: description,
        targetUserId: widget.targetUserId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan verifikasi berhasil dikirim'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// ICON
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Warna.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 36,
              ),
            ),

            const SizedBox(height: 16),

            /// TITLE
            const Text(
              'Verifikasi Kepemilikan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Warna.blue,
              ),
            ),

            const SizedBox(height: 12),

            /// DESCRIPTION BOX
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Jelaskan ciri detail barang (warna, kondisi, ciri khusus)',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Warna.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
