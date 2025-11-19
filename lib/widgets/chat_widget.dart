import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mobigpt/widgets/chat_input_field.dart';
import 'package:mobigpt/widgets/chat_message.dart';
import 'package:mobigpt/widgets/gemma_input_field.dart';
import 'package:mobigpt/widgets/thinking_widget.dart';
import 'package:mobigpt/theme/appColors.dart';
import 'package:mobigpt/utils/logger.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({
    required this.messages,
    required this.gemmaHandler,
    required this.messageHandler,
    required this.errorHandler,
    this.chat,
    this.isProcessing = false,
    super.key,
  });

  final InferenceChat? chat;
  final List<Message> messages;
  final ValueChanged<ModelResponse> gemmaHandler; // Accepts ModelResponse (TextToken | FunctionCall)
  final ValueChanged<Message> messageHandler; // Handles all message additions to history
  final ValueChanged<String> errorHandler;
  final bool isProcessing; // Indicates if the model is currently processing (including function calls)

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget> {
  // Current streaming thinking state
  String _currentThinkingContent = '';
  bool _isCurrentThinkingExpanded = false;

  // Expanded state for each thinking widget in history (by message index)
  final Map<int, bool> _thinkingExpandedStates = {};

  void _handleGemmaResponse(ModelResponse response) {
    // Capture thinking content before passing to parent
    if (response is ThinkingResponse) {
      setState(() {
        _currentThinkingContent += response.content;
      });
    }
    widget.gemmaHandler(response);
  }

  void _handleNewMessage(Message message) {
    // Reset current thinking for new conversation
    setState(() {
      _currentThinkingContent = '';
      _isCurrentThinkingExpanded = false;
    });
    widget.messageHandler(message);
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print messages when widget builds
    Logger.debug('Building with ${widget.messages.length} messages', tag: 'ChatListWidget');
    for (int i = 0; i < widget.messages.length; i++) {
      final msg = widget.messages[i];
      Logger.debug(
          'Message $i: ${msg.isUser ? "User" : "AI"} - ${msg.text.substring(0, msg.text.length > 30 ? 30 : msg.text.length)}...',
          tag: 'ChatListWidget');
    }

    // Don't show empty state - always show the input field

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          reverse: true,
          physics: widget.isProcessing ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
          itemCount: widget.messages.length + 3,
          // +1 for thinking widget
          itemBuilder: (context, index) {
            if (index == 0) {
              // Always show input field when no messages or when not processing
              if (widget.messages.isEmpty || !widget.isProcessing) {
                return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ChatInputField(
                      handleSubmitted: _handleNewMessage,
                      supportsImages: widget.chat?.supportsImages ?? false,
                    ));
              }
              // Show GemmaInputField only when processing and there are messages
              else if (widget.isProcessing && widget.messages.isNotEmpty && widget.messages.last.isUser) {
                return GemmaInputField(
                  chat: widget.chat,
                  messages: widget.messages,
                  streamHandler: _handleGemmaResponse,
                  errorHandler: widget.errorHandler,
                  isProcessing: widget.isProcessing,
                  onThinkingCompleted: (String thinkingContent) {
                    // Add thinking as special thinking message to history
                    if (thinkingContent.isNotEmpty) {
                      debugPrint(
                          'ChatListWidget: Adding thinking as thinking message: ${thinkingContent.length} chars');
                      final thinkingMessage = Message.thinking(text: thinkingContent);
                      widget.messageHandler(thinkingMessage); // Add to history through message handler

                      setState(() {
                        _currentThinkingContent = ''; // Clear current thinking as it's now in history
                      });
                    }
                  },
                );
              }
            } else if (index == 1) {
              // Thinking widget - only show current streaming thinking
              if (_currentThinkingContent.isNotEmpty) {
                return ThinkingWidget(
                  thinking: ThinkingResponse(_currentThinkingContent),
                  isExpanded: _isCurrentThinkingExpanded,
                  onToggle: () {
                    setState(() {
                      _isCurrentThinkingExpanded = !_isCurrentThinkingExpanded;
                    });
                  },
                );
              }
              return const SizedBox.shrink();
            } else if (index == 2) {
              return const Divider(height: 1.0);
            } else {
              final messageIndex = index - 3;

              // Debug: Check bounds
              if (messageIndex < 0 || messageIndex >= widget.messages.length) {
                Logger.error('messageIndex=$messageIndex is out of bounds (0-${widget.messages.length - 1})',
                    tag: 'ChatListWidget');
                return const SizedBox.shrink();
              }

              final message = widget.messages.reversed.toList()[messageIndex];

              // Debug: Print message indexing
              Logger.debug(
                  'itemBuilder index=$index, messageIndex=$messageIndex, message="${message.text.substring(0, message.text.length > 20 ? 20 : message.text.length)}..."',
                  tag: 'ChatListWidget');

              // If this is a thinking message, show as ThinkingWidget
              if (message.type == MessageType.thinking) {
                final originalMessageIndex = widget.messages.length - 1 - messageIndex;
                final isExpanded = _thinkingExpandedStates[originalMessageIndex] ?? false;

                return ThinkingWidget(
                  thinking: ThinkingResponse(message.text),
                  isExpanded: isExpanded,
                  onToggle: () {
                    setState(() {
                      _thinkingExpandedStates[originalMessageIndex] = !isExpanded;
                    });
                  },
                );
              }

              // Regular message
              return ChatMessageWidget(
                message: message,
              );
            }
            return null;
          },
        ),
        // Visual indicator when processing
        if (widget.isProcessing)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderLight,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'המודל בעבודה... לא ניתן לגלול',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
