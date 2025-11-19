import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mobigpt/theme/appColors.dart';
import 'package:mobigpt/theme/app_text_styles.dart';

class ChatMessageStyles {
  // ===== Markdown Style Sheet =====
  static MarkdownStyleSheet get markdownStyleSheet => MarkdownStyleSheet(
        p: AppTextStyles.messageText,
        h1: AppTextStyles.messageHeading1,
        h2: AppTextStyles.messageHeading2,
        h3: AppTextStyles.messageHeading3,
        strong: AppTextStyles.messageBold,
        em: AppTextStyles.messageItalic,
        code: AppTextStyles.messageCode,
        codeblockDecoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          color: AppColors.backgroundLightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: AppTextStyles.messageBlockquote,
        listBullet: AppTextStyles.messageListBullet,
      );

  // ===== Message Container Styles =====
  static BoxDecoration userMessageDecoration = BoxDecoration(
    color: AppColors.messageUserBackground,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColors.borderLight,
    ),
  );

  static BoxDecoration aiMessageDecoration = BoxDecoration(
    color: AppColors.messageAIBackground,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColors.borderLight,
    ),
  );

  static BoxDecoration systemMessageDecoration = BoxDecoration(
    color: AppColors.backgroundLight,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: AppColors.borderLight,
    ),
  );

  // ===== Avatar Styles =====
  static BoxDecoration userAvatarDecoration = BoxDecoration(
    color: AppColors.avatarBackground,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: AppColors.avatarBorder,
    ),
  );

  // ===== Image Widget Styles =====
  static List<BoxShadow> imageShadow = [
    BoxShadow(
      color: AppColors.blackWithOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // ===== Copy Button Styles =====
  static const double copyButtonSize = 16.0;
  static const Color copyButtonColor = AppColors.iconSecondary;
}

