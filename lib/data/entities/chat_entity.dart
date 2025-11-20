import 'package:objectbox/objectbox.dart';

/// ObjectBox entity used to persist chat sessions locally.
@Entity()
class ChatEntity {
  ChatEntity({
    this.id = 0,
    required this.chatId,
    required this.title,
    this.modelName,
    required this.createdAt,
    required this.updatedAt,
    required this.messagesJson,
  });

  @Id()
  int id;

  @Unique()
  String chatId;

  String title;
  String? modelName;

  @Property(type: PropertyType.dateNano)
  DateTime createdAt;

  @Property(type: PropertyType.dateNano)
  DateTime updatedAt;

  /// Serialized list of chat messages.
  String messagesJson;
}

/// Stores chat-level metadata such as the currently selected chat.
@Entity()
class ChatStateEntity {
  ChatStateEntity({
    this.id = 1,
    this.currentChatId,
  });

  /// Always keep a single row with ID = 1.
  @Id(assignable: true)
  int id;

  String? currentChatId;
}
