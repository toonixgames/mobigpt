import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobigpt/theme/appColors.dart';
import 'package:mobigpt/theme/appImages.dart';
import 'package:mobigpt/theme/app_text_styles.dart';
import 'package:mobigpt/theme/chat_message_styles.dart';
import 'package:mobigpt/utils/language_detector.dart';

class ChatMessageWidget extends StatelessWidget {
  const ChatMessageWidget({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    // Handle system info messages differently
    if (message.type == MessageType.systemInfo) {
      return _buildSystemMessage(context);
    }

    // Detect language direction for AI messages (non-user messages)
    final textDirection = !message.isUser && message.text.isNotEmpty
        ? LanguageDetector.getTextDirection(message.text)
        : TextDirection.ltr;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          message.isUser ? const SizedBox() : _buildAvatar(),
          const SizedBox(width: 8),
          Expanded(
            child: Directionality(
              textDirection: textDirection,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: message.isUser 
                    ? ChatMessageStyles.userMessageDecoration
                    : ChatMessageStyles.aiMessageDecoration,
                child: Column(
                  crossAxisAlignment: textDirection == TextDirection.rtl
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Display image if available
                    if (message.hasImage) ...[
                      _buildImageWidget(context),
                      if (message.text.isNotEmpty) const SizedBox(height: 8),
                    ],

                    // Display text
                    if (message.text.isNotEmpty)
                      MarkdownBody(
                        data: message.text,
                        styleSheet: ChatMessageStyles.markdownStyleSheet,
                      )
                    else if (!message.hasImage)
                      const Center(child: CircularProgressIndicator()),

                    // Add copy button for AI messages
                    if (!message.isUser && message.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCopyButton(context, textDirection),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          message.isUser ? _buildAvatar() : const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageDialog(context),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 300,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: ChatMessageStyles.imageShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            message.imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 100,
                color: AppColors.backgroundPrimary,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: AppColors.error),
                    SizedBox(height: 4),
                    Text(
                      'Image loading error',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full-size image
              Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    message.imageBytes!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.iconPrimary,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    IconData iconData;
    Color iconColor;

    // Determine icon based on message content
    if (message.text.contains('Calling')) {
      iconData = Icons.settings;
      iconColor = AppColors.systemBlue;
    } else if (message.text.contains('Executing')) {
      iconData = Icons.flash_on;
      iconColor = AppColors.systemOrange;
    } else if (message.text.contains('completed')) {
      iconData = Icons.check_circle;
      iconColor = AppColors.systemGreen;
    } else if (message.text.contains('Generating')) {
      iconData = Icons.psychology;
      iconColor = AppColors.systemPurple;
    } else {
      iconData = Icons.info;
      iconColor = AppColors.systemBlue;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: ChatMessageStyles.systemMessageDecoration,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconData, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.text,
                      style: AppTextStyles.systemMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return message.isUser
        ? Container(
            width: 35,
            height: 35,
            decoration: ChatMessageStyles.userAvatarDecoration,
            child: const Icon(
              Icons.person,
              color: AppColors.iconPrimary,
              size: 16,
            ),
          )
        : Container(
            width: 28,
            height: 28,
            child: SvgPicture.asset(
              AppImages.logoImage,
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          );
  }

  Widget _buildCopyButton(BuildContext context, TextDirection textDirection) {
    return Align(
      alignment: textDirection == TextDirection.rtl
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: IconButton(
        onPressed: () => _copyToClipboard(context),
        icon: const Icon(
          Icons.copy,
          size: ChatMessageStyles.copyButtonSize,
          color: ChatMessageStyles.copyButtonColor,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        tooltip: 'Copy message',
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'תוכן ההודעה הועתק',
          style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: AppColors.lightPrimary,
      ),
    );
  }
}
