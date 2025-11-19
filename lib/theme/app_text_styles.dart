import 'package:flutter/material.dart';
import 'package:mobigpt/theme/appColors.dart';

class AppTextStyles {
  // ===== App Bar Styles =====
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textSecondary,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    fontSize: 12,
    color: AppColors.textGrey,
  );

  // ===== Chat Message Styles =====
  static const TextStyle messageText = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 20,
    height: 1.3,
  );

  static const TextStyle messageHeading1 = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle messageHeading2 = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle messageHeading3 = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 19,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle messageBold = TextStyle(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle messageItalic = TextStyle(
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle messageCode = TextStyle(
    backgroundColor: AppColors.backgroundPrimary,
    color: AppColors.textSecondary,
    fontFamily: 'monospace',
    fontSize: 18,
  );

  static const TextStyle messageBlockquote = TextStyle(
    color: AppColors.textTertiary,
    fontStyle: FontStyle.italic,
  );

  static const TextStyle messageListBullet = TextStyle(
    color: AppColors.textSecondary,
  );

  // ===== System Message Styles =====
  static const TextStyle systemMessage = TextStyle(
    fontSize: 13,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.w500,
  );

  // ===== Input Field Styles =====
  static const TextStyle inputText = TextStyle(
    color: AppColors.inputText,
    fontSize: 18,
  );

  static const TextStyle inputHint = TextStyle(
    color: AppColors.inputHint,
  );

  // ===== Error Styles =====
  static const TextStyle errorText = TextStyle(
    color: AppColors.error,
    fontSize: 12,
  );

  // ===== Info Banner Styles =====
  static const TextStyle infoBanner = TextStyle(
    color: AppColors.textTertiary,
    fontSize: 12,
  );

  // ===== Button Styles =====
  static const TextStyle buttonPrimary = TextStyle(
    color: AppColors.textWhite,
    fontWeight: FontWeight.bold,
  );

  // ===== Avatar Styles =====
  static const TextStyle avatarText = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16,
  );
}

