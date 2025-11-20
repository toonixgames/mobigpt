import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:mobigpt/models/chat.dart';

import '../entities/chat_entity.dart';

class ChatMapper {
  const ChatMapper._();

  static ChatEntity toEntity(Chat chat) {
    return ChatEntity(
      chatId: chat.id,
      title: chat.title,
      modelName: chat.modelName,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
      messagesJson: _encodeMessages(chat.messages),
    )..id = 0;
  }

  static Chat fromEntity(ChatEntity entity) {
    return Chat(
      id: entity.chatId,
      title: entity.title,
      messages: _decodeMessages(entity.messagesJson),
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      modelName: entity.modelName,
    );
  }

  static String _encodeMessages(List<Message> messages) {
    final encoded = messages
        .map((message) => Chat.messageToJson(message))
        .toList(growable: false);
    return json.encode(encoded);
  }

  static List<Message> _decodeMessages(String jsonString) {
    if (jsonString.isEmpty) {
      return <Message>[];
    }

    final decoded = json.decode(jsonString);
    if (decoded is! List) {
      return <Message>[];
    }

    return decoded.map((dynamic item) {
      if (item is Map<String, dynamic>) {
        return Chat.messageFromJson(item);
      }
      return Chat.messageFromJson(Map<String, dynamic>.from(item as Map));
    }).toList(growable: false);
  }
}
