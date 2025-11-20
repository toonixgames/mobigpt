import 'package:flutter/material.dart';

class AppColors {
  // ===== Primary Colors =====
  static const Color lightPrimary = Color(0xFF2196F3);
  static const Color backgroundPrimary = Color(0xFFE5E5E5);

  // ===== Background Colors =====
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF7F7F8);
  static const Color backgroundLightGray = Color(0xFFF0F0F0);
  static const Color backgroundDark = Color(0xFF0b2351);

  // ===== Text Colors =====
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF000000); // black87
  static const Color textTertiary = Color(0xFF000000); // black54
  static const Color textQuaternary = Color(0xFF000000); // black38
  static const Color textGrey = Color(0xFF808080);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhite70 = Color(0xB3FFFFFF);

  // ===== Message Colors =====
  static const Color messageUserBackground = Color(0xFFAFAFB3);
  static const Color messageAIBackground = Color(0xFFF7F7F8);

  // ===== Border Colors =====
  static const Color borderLight = Color(0x33000000); // grey.withOpacity(0.2)
  static const Color borderMedium = Color(0x4D000000); // grey.withOpacity(0.3)
  static const Color borderDark = Color(0x80000000); // grey.withOpacity(0.5)

  // ===== Status Colors =====
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0x1AD32F2F); // red.withOpacity(0.1)
  static const Color errorBorder = Color(0x4DD32F2F); // red.withOpacity(0.3)
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0x1AFF9800); // orange.withOpacity(0.1)
  static const Color warningBorder = Color(0x4DFF9800); // orange.withOpacity(0.3)
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);

  // ===== Icon Colors =====
  static const Color iconPrimary = Color(0xFF000000); // black87
  static const Color iconSecondary = Color(0xFF000000); // black54
  static const Color iconTertiary = Color(0xFF000000); // black38
  static const Color iconWhite = Color(0xFFFFFFFF);
  static const Color iconGrey = Color(0xFF808080);

  // ===== Overlay Colors =====
  static const Color overlayDark = Color(0xCC000000); // black.withOpacity(0.8)

  // ===== System Message Colors =====
  static const Color systemBlue = Color(0xFF2196F3);
  static const Color systemOrange = Color(0xFFFF9800);
  static const Color systemGreen = Color(0xFF4CAF50);
  static const Color systemPurple = Color(0xFF9C27B0);
  static const Color systemRed = Color(0xFFD32F2F);

  // ===== Avatar Colors =====
  static const Color avatarBackground = Color(0xFFF7F7F8);
  static const Color avatarBorder = Color(0x33000000); // grey.withOpacity(0.2)

  // ===== Input Field Colors =====
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0x4D000000); // grey.withOpacity(0.3)
  static const Color inputText = Color(0xFF000000); // black87
  static const Color inputHint = Color(0xFF000000); // black38
  static const Color sendButtonBackground = Color(0xFF000000);
  static const Color sendButtonIcon = Color(0xFFFFFFFF);

  // ===== Image Preview Colors =====
  static const Color imagePreviewBackground = Color(0xFFFFFFFF);
  static const Color imagePreviewBorder = Color(0x4D000000); // grey.withOpacity(0.3)
  static const Color imagePreviewCloseBackground = Color(0xFF000000);
  static const Color imagePreviewCloseIcon = Color(0xFFFFFFFF);
  static const Color imagePreviewText = Color(0xFF000000); // black87
  static const Color imagePreviewTextSecondary = Color(0xFF000000); // black54

  // ===== Helper Methods =====
  static Color greyWithOpacity(double opacity) {
    return Colors.grey.withOpacity(opacity);
  }

  static Color blackWithOpacity(double opacity) {
    return Colors.black.withOpacity(opacity);
  }

  // ===== Rating =====
  static const Color ratingLightTextField = const Color(0xFFEEEEEE);
  static const Color ratingDarkTextField = const Color(0xFF424242);

}