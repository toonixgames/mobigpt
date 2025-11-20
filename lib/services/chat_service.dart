import 'package:mobigpt/models/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mobigpt/repositories/chat_repository.dart';
import 'package:mobigpt/services/model_session_service.dart';
import 'package:mobigpt/utils/logger.dart';

/// Service to manage multiple chat sessions
class ChatService {
  ChatService({required ChatRepository chatRepository})
      : _chatRepository = chatRepository;

  final ChatRepository _chatRepository;
  final ModelSessionService _modelSessionService = ModelSessionService.instance;

  List<Chat> _chats = [];
  String? _currentChatId;

  /// Get all chats
  List<Chat> get chats => List.unmodifiable(_chats);

  /// Get the current active chat
  Chat? get currentChat {
    if (_currentChatId == null) return null;
    return _chats.firstWhere(
      (chat) => chat.id == _currentChatId,
      orElse: () => _chats.isNotEmpty
          ? _chats.first
          : throw StateError('No chats available'),
    );
  }

  /// Get the current chat ID
  String? get currentChatId => _currentChatId;

  /// Initialize the service and load saved chats
  Future<void> initialize() async {
    _chats = List.from(await _chatRepository.getAllChats());
    _currentChatId = await _chatRepository.getCurrentChatId();

    if (_currentChatId != null &&
        !_chats.any((chat) => chat.id == _currentChatId)) {
      _currentChatId = _chats.isNotEmpty ? _chats.first.id : null;
      await _chatRepository.setCurrentChatId(_currentChatId);
    }
  }

  /// Create a new chat
  Future<Chat> createNewChat({
    required String title,
    String? modelName,
  }) async {
    // Check chat limit
    if (_chats.length >= 10) {
      throw Exception(
          'Maximum number of chats (10) reached. Please delete a chat first.');
    }

    final chat = Chat.createNew(
      title: title,
      modelName: modelName,
    );

    final savedChat = await _chatRepository.upsertChat(chat);
    _chats.insert(0, savedChat);
    _currentChatId = savedChat.id;

    _resortChats();
    await _chatRepository.setCurrentChatId(_currentChatId);

    return savedChat;
  }

  /// Create a new chat with smart naming based on first message
  Future<Chat> createNewChatWithSmartNaming({
    String? modelName,
    String? firstMessage,
  }) async {
    // Check chat limit
    if (_chats.length >= 10) {
      throw Exception(
          'Maximum number of chats (10) reached. Please delete a chat first.');
    }

    String title = 'New Chat';

    if (firstMessage != null && firstMessage.trim().isNotEmpty) {
      title = _generateSmartTitle(firstMessage);
    }

    return createNewChat(
      title: title,
      modelName: modelName,
    );
  }

  /// Generate a smart title based on the first message
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
      title = cleanMessage.length > 30
          ? cleanMessage.substring(0, 30) + '...'
          : cleanMessage;
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

  /// Switch to a different chat
  Future<void> switchToChat(String chatId) async {
    if (_chats.any((chat) => chat.id == chatId)) {
      _currentChatId = chatId;
      await _chatRepository.setCurrentChatId(_currentChatId);

      // Debug: Print the switched chat information
      final switchedChat = _chats.firstWhere((chat) => chat.id == chatId);
      Logger.chatService(
          'Switched to chat "${switchedChat.title}" with ${switchedChat.messages.length} messages');
    }
  }

  /// Add a message to the current chat
  Future<void> addMessageToCurrentChat(Message message) async {
    final current = currentChat;
    if (current == null) {
      Logger.warning('addMessageToCurrentChat - No current chat found',
          tag: 'ChatService');
      return;
    }

    Logger.chatService(
        'Adding message to chat "${current.title}" (${current.messages.length} -> ${current.messages.length + 1} messages)');

    final updatedChat = current.addMessage(message);
    final index = _chats.indexWhere((chat) => chat.id == current.id);
    if (index != -1) {
      final savedChat = await _chatRepository.upsertChat(updatedChat);
      _chats[index] = savedChat;
      _resortChats();
      Logger.chatService('Message saved successfully');
    } else {
      Logger.error('Could not find chat with ID ${current.id}',
          tag: 'ChatService');
    }
  }

  /// Update the title of a chat
  Future<void> updateChatTitle(String chatId, String newTitle) async {
    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      final updatedChat = _chats[index].copyWith(title: newTitle);
      final savedChat = await _chatRepository.upsertChat(updatedChat);
      _chats[index] = savedChat;
      _resortChats();
    }
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    final removedIndex = _chats.indexWhere((chat) => chat.id == chatId);
    await _chatRepository.deleteChat(chatId);
    await _modelSessionService.disposeSession(chatId);

    if (removedIndex == -1) {
      return;
    }

    _chats.removeAt(removedIndex);
    _resortChats();

    if (_currentChatId == chatId) {
      _currentChatId = _chats.isNotEmpty ? _chats.first.id : null;
      await _chatRepository.setCurrentChatId(_currentChatId);
    }
  }

  /// Clear all chats
  Future<void> clearAllChats() async {
    _chats.clear();
    _currentChatId = null;
    await _chatRepository.clearChats();
    await _chatRepository.setCurrentChatId(null);
  }

  void _resortChats() {
    _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }
}
