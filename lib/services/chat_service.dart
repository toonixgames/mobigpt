import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobigpt/models/chat.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mobigpt/utils/logger.dart';

/// Service to manage multiple chat sessions
class ChatService {
  static const String _chatsKey = 'saved_chats';
  static const String _currentChatIdKey = 'current_chat_id';
  
  List<Chat> _chats = [];
  String? _currentChatId;
  
  /// Get all chats
  List<Chat> get chats => List.unmodifiable(_chats);
  
  /// Get the current active chat
  Chat? get currentChat {
    if (_currentChatId == null) return null;
    return _chats.firstWhere(
      (chat) => chat.id == _currentChatId,
      orElse: () => _chats.isNotEmpty ? _chats.first : throw StateError('No chats available'),
    );
  }
  
  /// Get the current chat ID
  String? get currentChatId => _currentChatId;
  
  /// Initialize the service and load saved chats
  Future<void> initialize() async {
    await _loadChats();
    await _loadCurrentChatId();
  }
  
  /// Create a new chat
  Future<Chat> createNewChat({
    required String title,
    String? modelName,
  }) async {
    // Check chat limit
    if (_chats.length >= 10) {
      throw Exception('Maximum number of chats (10) reached. Please delete a chat first.');
    }
    
    final chat = Chat.createNew(
      title: title,
      modelName: modelName,
    );
    
    _chats.insert(0, chat); // Add to beginning
    _currentChatId = chat.id;
    
    await _saveChats();
    await _saveCurrentChatId();
    
    return chat;
  }

  /// Create a new chat with smart naming based on first message
  Future<Chat> createNewChatWithSmartNaming({
    String? modelName,
    String? firstMessage,
  }) async {
    // Check chat limit
    if (_chats.length >= 10) {
      throw Exception('Maximum number of chats (10) reached. Please delete a chat first.');
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
      'Hello', 'Hi', 'Hey', 'Good morning', 'Good afternoon', 'Good evening',
      'Can you', 'Could you', 'Please', 'I need', 'I want', 'I would like'
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
      await _saveCurrentChatId();
      
      // Debug: Print the switched chat information
      final switchedChat = _chats.firstWhere((chat) => chat.id == chatId);
      Logger.chatService('Switched to chat "${switchedChat.title}" with ${switchedChat.messages.length} messages');
    }
  }
  
  /// Add a message to the current chat
  Future<void> addMessageToCurrentChat(Message message) async {
    final current = currentChat;
    if (current == null) {
      Logger.warning('addMessageToCurrentChat - No current chat found', tag: 'ChatService');
      return;
    }
    
    Logger.chatService('Adding message to chat "${current.title}" (${current.messages.length} -> ${current.messages.length + 1} messages)');
    
    final updatedChat = current.addMessage(message);
    final index = _chats.indexWhere((chat) => chat.id == current.id);
    if (index != -1) {
      _chats[index] = updatedChat;
      await _saveChats();
      Logger.chatService('Message saved successfully');
    } else {
      Logger.error('Could not find chat with ID ${current.id}', tag: 'ChatService');
    }
  }
  
  /// Update the title of a chat
  Future<void> updateChatTitle(String chatId, String newTitle) async {
    final index = _chats.indexWhere((chat) => chat.id == chatId);
    if (index != -1) {
      _chats[index] = _chats[index].copyWith(title: newTitle);
      await _saveChats();
    }
  }
  
  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((chat) => chat.id == chatId);
    
    // If we deleted the current chat, switch to the first available chat
    if (_currentChatId == chatId) {
      _currentChatId = _chats.isNotEmpty ? _chats.first.id : null;
      await _saveCurrentChatId();
    }
    
    await _saveChats();
  }
  
  /// Clear all chats
  Future<void> clearAllChats() async {
    _chats.clear();
    _currentChatId = null;
    await _saveChats();
    await _saveCurrentChatId();
  }
  
  /// Load chats from storage
  Future<void> _loadChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString(_chatsKey);
      
      Logger.chatService('Loading chats from storage...');
      Logger.chatService('chatsJson length: ${chatsJson?.length ?? 0}');
      
      if (chatsJson != null) {
        final List<dynamic> chatsList = json.decode(chatsJson);
        Logger.chatService('Decoded ${chatsList.length} chats from JSON');
        
        _chats = chatsList
            .map((chatJson) {
              final chat = Chat.fromJson(chatJson as Map<String, dynamic>);
              Logger.chatService('Loaded chat "${chat.title}" with ${chat.messages.length} messages');
              return chat;
            })
            .toList();
      } else {
        Logger.chatService('No chats found in storage');
        _chats = [];
      }
    } catch (e) {
      Logger.error('Error loading chats: $e', tag: 'ChatService');
      _chats = [];
    }
  }
  
  /// Save chats to storage
  Future<void> _saveChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = json.encode(_chats.map((chat) => chat.toJson()).toList());
      await prefs.setString(_chatsKey, chatsJson);
      
      Logger.chatService('Saved ${_chats.length} chats to storage');
      for (final chat in _chats) {
        Logger.chatService('Saved chat "${chat.title}" with ${chat.messages.length} messages');
      }
    } catch (e) {
      Logger.error('Error saving chats: $e', tag: 'ChatService');
    }
  }
  
  /// Load current chat ID from storage
  Future<void> _loadCurrentChatId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentChatId = prefs.getString(_currentChatIdKey);
      
      // If current chat ID doesn't exist in chats, reset it
      if (_currentChatId != null && !_chats.any((chat) => chat.id == _currentChatId)) {
        _currentChatId = _chats.isNotEmpty ? _chats.first.id : null;
        await _saveCurrentChatId();
      }
    } catch (e) {
      Logger.error('Error loading current chat ID: $e', tag: 'ChatService');
      _currentChatId = _chats.isNotEmpty ? _chats.first.id : null;
    }
  }
  
  /// Save current chat ID to storage
  Future<void> _saveCurrentChatId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentChatId != null) {
        await prefs.setString(_currentChatIdKey, _currentChatId!);
      } else {
        await prefs.remove(_currentChatIdKey);
      }
    } catch (e) {
      Logger.error('Error saving current chat ID: $e', tag: 'ChatService');
    }
  }
}
