import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../services/storage_service.dart';
import '../../services/firestore_service.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _image;

  bool _isLoading = false;

  String _selectedCategory = 'Pakaian';

  final List<String> categories = [
    'Pakaian',
    'Elektronik',
    'Alat Makan',
    'Alat Tulis',
    'Aksesoris',
    'Lainnya',
  ];

  /* ============================================================
     IMAGE PICKER
  ============================================================ */
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
    });
  }

  /* ============================================================
     SUBMIT REPORT
  ============================================================ */
  Future<void> _submitReport() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _descController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua data')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // 1️⃣ Upload image ke Supabase
      final imageUrl = await StorageService.instance.uploadImage(
        file: _image!,
        folder: 'images',
      );

      // 2️⃣ Simpan data ke Firestore
      await FirestoreService.instance.createLostReport(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        description: _descController.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim')),
      );

      context.pop(); // kembali ke Home
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal submit: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /* ============================================================
     UI
  ============================================================ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      /// ================= APP BAR =================
      appBar: AppBar(
        title: const Text('Form Laporkan Hilang'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Image.asset(
            'assets/image/icon/arrow-back.png',
            width: 22,
          ),
        ),
      ),

      /// ================= BODY =================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ================= IMAGE UPLOAD =================
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  Center(
                    child: _image == null
                        ? GestureDetector(
                            onTap: _pickImage,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/image/icon/upload.png',
                                  width: 36,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Upload Your Photos',
                                  style: TextStyle(
                                    color: Warna.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              _image!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  if (_image != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Image.asset(
                          'assets/image/icon/delete.png',
                          width: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _inputLabel('Nama Barang'),
            _textField(_nameController, 'Contoh: Baju Hitam'),

            _inputLabel('Lokasi Terakhir'),
            _textField(
                _locationController, 'Contoh: Kamar mandi lantai 1'),

            _inputLabel('Deskripsi Barang'),
            _textArea(_descController, 'Ciri-ciri barang secara detail'),

            _inputLabel('Kategori'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((cat) {
                final isActive = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? Warna.blue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Warna.blue
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color:
                            isActive ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            /// ================= SUBMIT BUTTON =================
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Warna.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ============================================================
     HELPER WIDGETS
  ============================================================ */
  Widget _inputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _textArea(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
