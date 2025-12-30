import 'package:flutter/material.dart';

class CategoryIconMapper {
  static String getIconAsset(String category) {
    switch (category.toLowerCase()) {
      case 'pakaian':
        return 'assets/image/icon/pakaian.png';
      case 'elektronik':
        return 'assets/image/icon/elektronik.png';
      case 'alat makan':
        return 'assets/image/icon/alat_makan.png';
      case 'alat tulis':
        return 'assets/image/icon/alat_tulis.png';
      default:
        return 'assets/image/icon/default.png';
    }
  }
  static Widget buildIcon(
    String category, {
    double size = 48,
  }) {
    return Image.asset(
      getIconAsset(category),
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
