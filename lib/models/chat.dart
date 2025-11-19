import 'package:flutter_gemma/flutter_gemma.dart';

/// Represents a chat session with its messages and metadata
class Chat {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modelName;

  const Chat({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.modelName,
  });

  /// Create a new chat with a title
  factory Chat.createNew({
    required String title,
    String? modelName,
  }) {
    final now = DateTime.now();
    return Chat(
      id: _generateId(),
      title: title,
      messages: [],
      createdAt: now,
      updatedAt: now,
      modelName: modelName,
    );
  }

  /// Create a copy of this chat with updated fields
  Chat copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? modelName,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelName: modelName ?? this.modelName,
    );
  }

  /// Add a message to this chat
  Chat addMessage(Message message) {
    final updatedMessages = List<Message>.from(messages)..add(message);
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Get the last message in this chat
  Message? get lastMessage {
    return messages.isNotEmpty ? messages.last : null;
  }

  /// Get a preview of the last message (first 50 characters)
  String get lastMessagePreview {
    final last = lastMessage;
    if (last == null) return 'No messages yet';
    
    final text = last.text;
    if (text.length <= 50) return text;
    return '${text.substring(0, 50)}...';
  }

  /// Generate a unique ID for the chat
  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => _messageToJson(m)).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'modelName': modelName,
    };
  }

  /// Create from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List)
          .map((m) => _messageFromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      modelName: json['modelName'] as String?,
    );
  }

  /// Convert Message to JSON
  static Map<String, dynamic> _messageToJson(Message message) {
    return {
      'text': message.text,
      'isUser': message.isUser,
      'type': message.type.name,
    };
  }

  /// Create Message from JSON
  static Message _messageFromJson(Map<String, dynamic> json) {
    final type = MessageType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MessageType.text,
    );
    
    return Message(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      type: type,
    );
  }
}
