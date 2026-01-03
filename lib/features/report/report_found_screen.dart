import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

class ReportFoundScreen extends StatefulWidget {
  const ReportFoundScreen({super.key});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  File? _image;
  bool _loading = false;

  String _selectedCategory = 'Pakaian';

  final List<String> categories = [
    'Pakaian',
    'Elektronik',
    'Alat Makan',
    'Alat Tulis',
  ];

  final ImagePicker _picker = ImagePicker();

  /* ============================================================
     IMAGE PICKER (CAMERA & GALLERY)
  ============================================================ */
  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _pickFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (picked != null && mounted) {
      setState(() => _image = File(picked.path));
    }
  }

  void _showPickImageSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() => _image = null);
  }

  /* ============================================================
     SUBMIT
  ============================================================ */
  Future<void> _submit() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty) {
      _showError('Nama dan lokasi wajib diisi');
      return;
    }

    setState(() => _loading = true);

    try {
      String? imageUrl;

      /// IMAGE OPSIONAL
      if (_image != null) {
        imageUrl = await StorageService.instance.uploadImage(
          file: _image!,
          folder: 'found_items',
        );
      }

      await FirestoreService.instance.createFoundReport(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      context.pop();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /* ============================================================
     UI
  ============================================================ */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.grey,

      /// ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Warna.white,
        elevation: 0,
        title: const Text(
          'Form Laporkan Temuan',
          style: TextStyle(color: Colors.black),
        ),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              /// ================= IMAGE =================
              GestureDetector(
                onTap: _showPickImageSheet,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: _image == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/image/icon/upload.png',
                                    width: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Tambah Foto (Opsional)',
                                    style: TextStyle(
                                      color: Warna.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
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
              ),

              const SizedBox(height: 16),

              _inputLabel('Nama Barang'),
              _textField(_nameController, 'Contoh: Jaket Hitam'),

              _inputLabel('Lokasi Ditemukan'),
              _textField(
                _locationController,
                'Contoh: Meja kantin',
              ),

              _inputLabel('Kategori'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: categories.map((cat) {
                  final isActive = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCategory = cat;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Warna.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isActive ? Warna.blue : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              /// ================= SUBMIT =================
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
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
      ),
    );
  }

  /* ============================================================
     HELPERS
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
            color: Warna.blue,
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
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
