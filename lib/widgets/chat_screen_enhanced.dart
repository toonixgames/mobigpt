import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mobigpt/widgets/chat_widget.dart';
import 'package:mobigpt/widgets/chat_input_field.dart';
import 'package:mobigpt/models/model.dart';
import 'package:mobigpt/models/chat.dart';
import 'package:mobigpt/services/chat_service.dart';
import 'package:mobigpt/services/model_download_service.dart';
import 'package:mobigpt/widgets/sidebar_widget.dart';
import 'package:mobigpt/theme/appColors.dart';
import 'package:mobigpt/theme/appImages.dart';
import 'package:mobigpt/utils/logger.dart';

class ChatScreenEnhanced extends StatefulWidget {
  const ChatScreenEnhanced({super.key, this.model = Model.gemma3_1B, this.selectedBackend});

  final Model model;
  final PreferredBackend? selectedBackend;

  @override
  ChatScreenEnhancedState createState() => ChatScreenEnhancedState();
}

class ChatScreenEnhancedState extends State<ChatScreenEnhanced> {
  final _gemma = FlutterGemmaPlugin.instance;
  final _chatService = ChatService();

  InferenceChat? chat;
  Chat? _currentChat;
  bool _isModelInitialized = false;
  bool _isStreaming = false;
  String? _error;
  Color _backgroundColor = AppColors.backgroundWhite;
  String _appTitle = 'MobiGPT';
  late Model _currentModel;
  late PreferredBackend _currentBackend;
  bool _useGPU = false;
  bool _isInitializing = false;
  bool _isSwitchingChat = false;

  @override
  void initState() {
    super.initState();
    _currentModel = widget.model;
    _currentBackend = widget.selectedBackend ?? PreferredBackend.cpu;
    _useGPU = _currentBackend == PreferredBackend.gpu;

    _initializeServices();
  }

  Future<void> _onChatSelectedFromSidebar(String chatId) async {
    // Close the drawer immediately and show loader
    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _isSwitchingChat = true;
      });
    }

    // Add a small delay to ensure UI updates are processed
    await Future.delayed(const Duration(milliseconds: 10));

    // Use scheduleMicrotask to ensure UI updates are processed first
    // This ensures the sidebar closes and spinner starts before any heavy operations
    scheduleMicrotask(() async {
      try {
        await _switchToChat(chatId);
      } finally {
        if (mounted) {
          setState(() {
            _isSwitchingChat = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _gemma.modelManager.deleteModel();
  }

  Future<void> _initializeServices() async {
    // Initialize chat service
    await _chatService.initialize();

    setState(() {
      _isModelInitialized = false;
      _isInitializing = false;
      _error = null;
    });

    // Create or reuse chat immediately so it shows in sidebar and user can start typing
    try {
      final existingEmptyChat = _findExistingEmptyChat();

      if (existingEmptyChat != null) {
        // Reuse the existing empty chat to avoid creating duplicates
        await _chatService.switchToChat(existingEmptyChat.id);
        _currentChat = existingEmptyChat;
      } else if (_chatService.chats.length < 10) {
        // Create new chat only when no empty chat is available
        _currentChat = await _chatService.createNewChatWithSmartNaming(
          modelName: _currentModel.displayName,
        );
      }

      // Update UI immediately so sidebar shows the selected chat
      if (mounted) {
        setState(() {
          _error = null;
          _isStreaming = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }

    // Initialize model in background - don't block UI
    // User can start typing even while model is initializing
    _initializeModelInBackground();
  }

  Future<void> _initializeModelInBackground() async {
    try {
      await _initializeModel();

      if (mounted) {
        setState(() {
          _isModelInitialized = true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isModelInitialized = false;
        });
      }
    }
  }

  Future<void> _initializeModel() async {
    _isInitializing = true;

    setState(() {
      _isModelInitialized = false;
      _error = null;
    });

    try {
      final path = _currentModel.url;
      await _gemma.modelManager.setModelPath(path);

      final model = await _gemma.createModel(
        modelType: _currentModel.modelType,
        preferredBackend: _currentBackend,
        maxTokens: _currentModel.maxTokens,
        supportImage: _currentModel.supportImage,
        maxNumImages: _currentModel.maxNumImages,
      );

      chat = await model.createChat(
        temperature: _currentModel.temperature,
        randomSeed: 1,
        topK: _currentModel.topK,
        topP: _currentModel.topP,
        tokenBuffer: 256,
        supportImage: _currentModel.supportImage,
        supportsFunctionCalls: _currentModel.supportsFunctionCalls,
        isThinking: _currentModel.isThinking,
        modelType: _currentModel.modelType,
      );

      if (mounted) {
        setState(() {
          _isModelInitialized = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'נכשל באתחול המודל עם ${_currentBackend.name.toUpperCase()}: $e';
          _isModelInitialized = false;
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _switchModel(Model newModel, PreferredBackend? newBackend) async {
    if (newModel == _currentModel && (newBackend ?? _currentBackend) == _currentBackend) {
      return;
    }

    setState(() {
      _currentModel = newModel;
      _currentBackend = newBackend ?? _currentBackend;
      _useGPU = _currentBackend == PreferredBackend.gpu;
    });

    await _initializeModel();
  }

  Future<void> _toggleBackend() async {
    final newBackend = _useGPU ? PreferredBackend.cpu : PreferredBackend.gpu;

    setState(() {
      _useGPU = !_useGPU;
      _currentBackend = newBackend;
      _isModelInitialized = false;
      _error = null;
    });

    await _initializeModel();
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundWhite,
          title: const Text(
            'ניקוי שיחה',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          content: const Text(
            'האם את/ה בטוח/ה שברצונך לנקות את השיחה? פעולה זו לא ניתנת לביטול.',
            style: TextStyle(color: AppColors.textTertiary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ביטול',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _chatService.deleteChat(_currentChat!.id);
                _currentChat = await _chatService.createNewChat(
                  title: 'New Chat',
                  modelName: _currentModel.displayName,
                );
                setState(() {
                  _error = null;
                  _isStreaming = false;
                });
              },
              child: const Text(
                'ניקוי',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleMessageFromLanding(Message message) async {
    // Chat should already exist from startup, but handle edge case
    if (_currentChat == null) {
      // Check chat limit first
      if (_chatService.chats.length >= 10) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הגעת למגבלה של 10 שיחות. מחק שיחה כדי ליצור חדשה.'),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Create chat immediately
      _currentChat = await _chatService.createNewChatWithSmartNaming(
        modelName: _currentModel.displayName,
      );

      if (mounted) {
        setState(() {});
      }
    }

    // Wait for model initialization if still in progress
    if (!_isModelInitialized) {
      await _initializeModelInBackground();
    }

    // Add message to chat immediately
    if (_currentChat != null) {
      final isFirstMessage = _currentChat!.messages.isEmpty;

      setState(() {
        _error = null;
        _currentChat = _currentChat!.addMessage(message);
        _isStreaming = true;
      });

      // Save message first
      await _chatService.addMessageToCurrentChat(message);

      // Update title after message is saved (only for first user message)
      if (isFirstMessage && message.isUser) {
        await _updateChatTitleFromMessage(message.text);
      }

      // The message will be processed by GemmaInputField when the chat view appears
      // No need to process it here to avoid duplicate processing
    }
  }

  Future<void> _createNewChat() async {
    // Check chat limit first
    if (_chatService.chats.length >= 10) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הגעת למגבלה של 10 שיחות. מחק שיחה כדי ליצור חדשה.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Close the drawer immediately
    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      if (mounted) {
        setState(() {
          _isSwitchingChat = true;
          _isModelInitialized = false;
        });
      }

      // Create new chat immediately
      _currentChat = await _chatService.createNewChatWithSmartNaming(
        modelName: _currentModel.displayName,
      );

      // Force a context reload so the model starts fresh for this chat
      await _reloadChatContext();

      if (mounted) {
        setState(() {
          _error = null;
          _isStreaming = false;
          _isModelInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSwitchingChat = false;
        });
      }
    }
  }

  Future<void> _switchToChat(String chatId) async {
    // Switch to chat with non-blocking operation
    await _performModelOperation(() => _chatService.switchToChat(chatId));
    _currentChat = _chatService.currentChat;

    // Debug: Print the loaded chat information
    if (_currentChat != null) {
      Logger.chatScreen('Switched to chat: ${_currentChat!.title}');
      Logger.chatScreen('Messages count: ${_currentChat!.messages.length}');
      for (int i = 0; i < _currentChat!.messages.length; i++) {
        final msg = _currentChat!.messages[i];
        Logger.chatScreen(
            'Message $i: ${msg.isUser ? "User" : "AI"} - ${msg.text.substring(0, msg.text.length > 50 ? 50 : msg.text.length)}...');
      }
    }

    // Reload chat context into AI model to ensure proper context separation
    await _reloadChatContext();
    if (mounted) {
      setState(() {
        _isModelInitialized = true;
      });
    }

    if (mounted) {
      setState(() {
        _error = null;
        _isStreaming = false;
      });
    }
  }

  Future<void> _handleChatDeleted(String chatId) async {
    // If the deleted chat was the current chat, create a new one to keep app ready
    if (_currentChat?.id == chatId) {
      try {
        // Check chat limit
        if (_chatService.chats.length < 10) {
          // Create new chat automatically (no context reload needed for new empty chat)
          _currentChat = await _chatService.createNewChatWithSmartNaming(
            modelName: _currentModel.displayName,
          );

          if (mounted) {
            setState(() {
              _error = null;
              _isStreaming = false;
            });
          }
        } else {
          // At limit, just clear current chat
          _currentChat = null;
          if (mounted) {
            setState(() {
              _error = null;
              _isStreaming = false;
            });
          }
        }
      } catch (e) {
        // If creation fails, just clear current chat
        _currentChat = null;
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isStreaming = false;
          });
        }
      }
    } else {
      setState(() {
        _error = null;
        _isStreaming = false;
      });
    }
  }

  Future<void> _updateChatTitleFromMessage(String messageText) async {
    if (_currentChat == null) return;

    // Only update if title is still "New Chat" to avoid overwriting user-set titles
    if (_currentChat!.title != 'New Chat' && _currentChat!.title.isNotEmpty) {
      return;
    }

    // Generate smart title from the message
    final smartTitle = _generateSmartTitle(messageText);

    // Skip if generated title is still "New Chat"
    if (smartTitle == 'New Chat') {
      return;
    }

    try {
      // Update the chat title in the service
      await _chatService.updateChatTitle(_currentChat!.id, smartTitle);

      // Reload the chat from service to ensure consistency
      final updatedChat = _chatService.currentChat;
      if (updatedChat != null && updatedChat.id == _currentChat!.id) {
        // Update the current chat object and rebuild UI (incl. sidebar)
        if (mounted) {
          setState(() {
            _currentChat = updatedChat;
          });
        } else {
          _currentChat = updatedChat;
        }
      } else {
        // Fallback: update locally if service doesn't return updated chat
        if (mounted) {
          setState(() {
            _currentChat = _currentChat!.copyWith(title: smartTitle);
          });
        } else {
          _currentChat = _currentChat!.copyWith(title: smartTitle);
        }
      }
    } catch (e) {
      Logger.error('Failed to update chat title: $e', tag: 'ChatScreen');
      // Still update locally even if service update fails
      if (mounted) {
        setState(() {
          _currentChat = _currentChat!.copyWith(title: smartTitle);
        });
      } else {
        _currentChat = _currentChat!.copyWith(title: smartTitle);
      }
    }
  }

  String _generateSmartTitle(String message) {
    // Clean the message
    String cleanMessage = message.trim();

    // If message is too short, use default
    if (cleanMessage.length < 10) {
      return 'New Chat';
    }

    // Extract first sentence or first 30 characters
    String title = cleanMessage;

    // Try to find the first sentence
    final sentenceEnd = cleanMessage.indexOf('.');
    if (sentenceEnd > 0 && sentenceEnd < 50) {
      title = cleanMessage.substring(0, sentenceEnd);
    } else {
      // If no sentence end found, take first 30 characters
      title = cleanMessage.length > 30 ? cleanMessage.substring(0, 30) + '...' : cleanMessage;
    }

    // Remove common prefixes that don't add value
    final prefixes = [
      'Hello',
      'Hi',
      'Hey',
      'Good morning',
      'Good afternoon',
      'Good evening',
      'Can you',
      'Could you',
      'Please',
      'I need',
      'I want',
      'I would like'
    ];

    for (final prefix in prefixes) {
      if (title.toLowerCase().startsWith(prefix.toLowerCase())) {
        title = title.substring(prefix.length).trim();
        if (title.startsWith(',')) {
          title = title.substring(1).trim();
        }
        break;
      }
    }

    // Capitalize first letter
    if (title.isNotEmpty) {
      title = title[0].toUpperCase() + title.substring(1);
    }

    // Ensure title is not too long
    if (title.length > 40) {
      title = title.substring(0, 37) + '...';
    }

    return title.isEmpty ? 'New Chat' : title;
  }

  /// Reload the current chat's context into the AI model
  Future<void> _reloadChatContext() async {
    if (_currentChat == null) return;

    try {
      Logger.context(
          'Reloading context for chat "${_currentChat!.title}" with ${_currentChat!.messages.length} messages');

      // Break up the heavy operations into smaller chunks to prevent UI blocking
      // Each operation will be wrapped in a way that allows UI updates

      // Step 1: Clear existing model context
      Logger.context('Clearing existing model context...');
      await _performModelOperation(() => _gemma.modelManager.deleteModel());
      Logger.context('Model context cleared');

      // Step 2: Set model path
      Logger.context('Reloading model...');
      final path = _currentModel.url;
      await _performModelOperation(() => _gemma.modelManager.setModelPath(path));
      Logger.context('Model path set');

      // Step 3: Create new model instance (this is the heaviest operation)
      Logger.context('Creating new model instance (TensorFlow Lite optimization in progress)...');
      final model = await _performModelOperation(() => _gemma.createModel(
            modelType: _currentModel.modelType,
            preferredBackend: _currentBackend,
            maxTokens: _currentModel.maxTokens,
            supportImage: _currentModel.supportImage,
            maxNumImages: _currentModel.maxNumImages,
          ));
      Logger.context('Model instance created');

      // Step 4: Create new chat session
      Logger.context('Creating chat session...');
      chat = await _performModelOperation(() => model.createChat(
            temperature: _currentModel.temperature,
            randomSeed: 1,
            topK: _currentModel.topK,
            topP: _currentModel.topP,
            tokenBuffer: 256,
            supportImage: _currentModel.supportImage,
            supportsFunctionCalls: _currentModel.supportsFunctionCalls,
            isThinking: _currentModel.isThinking,
            modelType: _currentModel.modelType,
          ));
      Logger.context('Chat session created');

      // Step 5: Rebuild context by replaying messages
      if (_currentChat != null && _currentChat!.messages.isNotEmpty) {
        Logger.context('Rebuilding context with ${_currentChat!.messages.length} messages...');
        await _replayMessages(_currentChat!.messages);
        Logger.context('Context rebuilt successfully');
      }

      Logger.context('Chat context reload completed');
    } catch (e) {
      Logger.error('Error reloading context: $e', tag: 'Context');
      // If context reload fails, try to reinitialize the model
      await _initializeModel();
    }
  }

  /// Finds the first chat without any messages, if it exists
  Chat? _findExistingEmptyChat() {
    for (final chat in _chatService.chats) {
      if (chat.messages.isEmpty) {
        return chat;
      }
    }
    return null;
  }

  /// Perform a model operation with UI yielding to prevent blocking
  Future<T> _performModelOperation<T>(Future<T> Function() operation) async {
    // Use a very short delay to allow UI to update before starting the operation
    await Future.delayed(const Duration(milliseconds: 1));

    // Use Timer.run to ensure the operation runs in the next event loop iteration
    // This allows the UI to update first
    final completer = Completer<T>();

    Timer.run(() async {
      try {
        final result = await operation();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Replay messages with UI yielding for long conversations
  Future<void> _replayMessages(List<Message> messages) async {
    for (int i = 0; i < messages.length; i++) {
      await chat?.addQuery(messages[i]);

      // Yield control to UI every few messages to prevent blocking
      if (i % 3 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  List<Model> _getAvailableModels() {
    return Model.values.where((model) {
      if (model.localModel) {
        return kIsWeb;
      }
      if (!kIsWeb) return true;
      return (model.preferredBackend == PreferredBackend.cpu || model.preferredBackend == PreferredBackend.gpu) &&
          !model.needsAuth;
    }).toList();
  }

  Future<List<Model>> _getExistingModels() async {
    final availableModels = _getAvailableModels();
    final existingModels = <Model>[];

    for (final model in availableModels) {
      try {
        final downloadService = ModelDownloadService(
          modelUrl: model.url,
          modelFilename: model.filename,
          licenseUrl: model.licenseUrl,
        );
        final exists = await downloadService.checkModelExistence();
        if (exists) {
          existingModels.add(model);
        }
      } catch (e) {
        continue;
      }
    }

    return existingModels;
  }

  Future<void> _handleFunctionCall(FunctionCallResponse functionCall) async {
    debugPrint('Function call received: ${functionCall.name}(${functionCall.args})');

    setState(() {
      _isStreaming = true;
      _currentChat = _currentChat!.addMessage(Message.systemInfo(
        text:
            "🔧 Calling: ${functionCall.name}(${functionCall.args.entries.map((e) => '${e.key}: \"${e.value}\"').join(', ')})",
      ));
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _currentChat = _currentChat!.addMessage(Message.systemInfo(
        text: "⚡ Executing function",
      ));
    });

    final toolResponse = await _executeTool(functionCall);
    debugPrint('Tool response: $toolResponse');

    setState(() {
      _currentChat = _currentChat!.addMessage(Message.systemInfo(
        text: "✅ Function completed: $toolResponse",
      ));
    });

    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _currentChat = _currentChat!.addMessage(Message.systemInfo(
        text: "🤖 Generating response...",
      ));
    });

    try {
      // Send tool response back to the model
      final toolMessage = Message.toolResponse(
        toolName: functionCall.name,
        response: {'message': toolResponse},
      );
      await chat?.addQuery(toolMessage);

      // The response will be handled by the stream in GemmaInputField
      debugPrint('Tool response sent to model');
    } catch (e) {
      debugPrint('Error sending tool response: $e');
      setState(() {
        _error = 'Error processing function result: $e';
      });
    }
  }

  Future<String> _executeTool(FunctionCallResponse functionCall) async {
    switch (functionCall.name) {
      case 'change_app_title':
        final title = functionCall.args['title'] as String?;
        if (title != null) {
          setState(() {
            _appTitle = title;
          });
          return 'App title changed to: $title';
        }
        return 'Title parameter is required';

      case 'change_background_color':
        final colorName = functionCall.args['color'] as String?;
        if (colorName != null) {
          Color newColor;
          switch (colorName.toLowerCase()) {
            case 'red':
              newColor = AppColors.error;
              break;
            case 'blue':
              newColor = AppColors.info;
              break;
            case 'green':
              newColor = AppColors.success;
              break;
            case 'yellow':
              newColor = AppColors.warning;
              break;
            case 'purple':
              newColor = AppColors.systemPurple;
              break;
            case 'orange':
              newColor = AppColors.warning;
              break;
            default:
              return 'Unknown color: $colorName';
          }
          setState(() {
            _backgroundColor = newColor;
          });
          return 'Background color changed to: $colorName';
        }
        return 'Color parameter is required';

      default:
        return 'Unknown function: ${functionCall.name}';
    }
  }

  void _handleGemmaResponse(dynamic response) async {
    if (response is TextResponse) {
      final aiMessage = Message(text: response.token, isUser: false);
      setState(() {
        _currentChat = _currentChat!.addMessage(aiMessage);
        _isStreaming = false;
      });
      // Save AI response to ChatService
      await _chatService.addMessageToCurrentChat(aiMessage);
    } else if (response is FunctionCallResponse) {
      _handleFunctionCall(response);
    } else if (response is ThinkingResponse) {
      final thinkingMessage = Message.thinking(text: response.content);
      setState(() {
        _currentChat = _currentChat!.addMessage(thinkingMessage);
      });
      // Save thinking message to ChatService
      await _chatService.addMessageToCurrentChat(thinkingMessage);
    }
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSupportInfo() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.image, color: AppColors.lightPrimary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'המודל תומך בתמונות. ניתן לצרף תמונות להודעות שלך',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        centerTitle: false,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.iconPrimary),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text.rich(TextSpan(children: [
                  TextSpan(
                      text: "Mobi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      )),
                  TextSpan(
                      text: "GPT",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightPrimary,
                      ))
                ])),
                Text(
                  _currentModel.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: SidebarWidget(
        chatService: _chatService,
        currentChatId: _currentChat?.id,
        onChatSelected: _onChatSelectedFromSidebar,
        onChatDeleted: _handleChatDeleted,
        onNewChat: _createNewChat,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
      body: Stack(children: [
        // Show landing view when chat is empty (no messages yet)
        // Always show input field - model initialization happens in background
        (_currentChat == null || (_currentChat?.messages.isEmpty ?? true))
            ? Column(children: [
                if (_error != null) _buildErrorBanner(_error!),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          AppImages.logoImage,
                          width: 200,
                          height: 200,
                        ),
                        SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 60.0),
                          child: ChatInputField(
                            handleSubmitted: _handleMessageFromLanding,
                            supportsImages: _currentModel.supportImage,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ])
            : Column(children: [
                if (_error != null) _buildErrorBanner(_error!),
                if (chat?.supportsImages == true && _currentChat?.messages.isEmpty == true) _buildImageSupportInfo(),
                Expanded(
                  child: ChatListWidget(
                    key: ValueKey(_currentChat?.id ?? 'no-chat'),
                    chat: chat,
                    gemmaHandler: _handleGemmaResponse,
                    messageHandler: (message) async {
                      final isFirstMessage = _currentChat!.messages.isEmpty;

                      setState(() {
                        _error = null;
                        _currentChat = _currentChat!.addMessage(message);
                        _isStreaming = true;
                      });

                      // Save message first
                      await _chatService.addMessageToCurrentChat(message);

                      // Update title after message is saved (only for first user message)
                      if (isFirstMessage && message.isUser) {
                        await _updateChatTitleFromMessage(message.text);
                      }
                    },
                    errorHandler: (err) {
                      setState(() {
                        _error = err;
                        _isStreaming = false;
                      });
                    },
                    messages: _currentChat?.messages ?? [],
                    isProcessing: _isStreaming,
                  ),
                ),
              ]),

        // Overlay loader while switching chats
        if (_isSwitchingChat)
          Container(
            color: AppColors.overlayDark,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.iconWhite,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'מתכונן לשיחה...',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'טוען מודל AI ומכין הקשר...',
                    style: TextStyle(
                      color: AppColors.textWhite70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }
}
