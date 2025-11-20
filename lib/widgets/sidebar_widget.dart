import 'package:flutter/material.dart';
import 'package:mobigpt/models/chat.dart';
import 'package:mobigpt/services/chat_service.dart';
import 'package:mobigpt/theme/appColors.dart';

class SidebarWidget extends StatelessWidget {
  final ChatService chatService;
  final String? currentChatId;
  final Function(String chatId) onChatSelected;
  final Function(String chatId) onChatDeleted;
  final VoidCallback onNewChat;
  final VoidCallback onClose;

  const SidebarWidget({
    super.key,
    required this.chatService,
    required this.currentChatId,
    required this.onChatSelected,
    required this.onChatDeleted,
    required this.onNewChat,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.iconPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'היסטוריית שיחות',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.iconPrimary,
                  ),
                ),
              ],
            ),
          ),

          // New Chat Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        chatService.chats.length >= 10 ? null : onNewChat,
                    icon: const Icon(
                      Icons.add,
                      color: AppColors.textWhite,
                      size: 20,
                    ),
                    label: const Text(
                      'New Chat',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: chatService.chats.length >= 10
                          ? AppColors.textGrey
                          : AppColors.lightPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                // Show limit message when at max chats
                if (chatService.chats.length >= 10)
                  Container(
                    margin: const EdgeInsets.only(top: 8.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.warningBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'הגעת למגבלה של 10 שיחות. מחק שיחה כדי ליצור חדשה.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Chat List
          Expanded(
            child: chatService.chats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount: chatService.chats.length,
                    itemBuilder: (context, index) {
                      final chat = chatService.chats[index];
                      final isSelected = chat.id == currentChatId;

                      return _buildChatItem(chat, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppColors.textQuaternary,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No chats yet',
            style: TextStyle(
              color: AppColors.textQuaternary,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start a new conversation',
            style: TextStyle(
              color: AppColors.textQuaternary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(Chat chat, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
      child: Material(
        color: isSelected ? AppColors.backgroundPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onChatSelected(chat.id),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: AppColors.lightPrimary.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chat title
                      Text(
                        chat.title,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textSecondary
                              : AppColors.textTertiary,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Last message preview
                      Text(
                        chat.lastMessagePreview,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textTertiary
                              : AppColors.textQuaternary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Timestamp
                      Text(
                        _formatTimestamp(chat.updatedAt),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textQuaternary
                              : AppColors.textQuaternary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => _showDeleteChatDialog(context, chat),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showDeleteChatDialog(BuildContext context, Chat chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundWhite,
        title: const Text(
          'מחיקת שיחה',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        content: Text(
          'האם אתה בטוח שברצונך למחוק את "${chat.title}"? פעולה זו אינה ניתנת לביטול.',
          style: const TextStyle(color: AppColors.textTertiary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'ביטול',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await chatService.deleteChat(chat.id);
              onChatDeleted(chat.id);
              onClose();
            },
            child: const Text(
              'מחק',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
