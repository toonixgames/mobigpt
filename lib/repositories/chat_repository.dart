import 'package:mobigpt/models/chat.dart';

abstract class ChatRepository {
  Future<List<Chat>> getAllChats();
  Future<Chat?> getChatById(String chatId);
  Future<Chat> upsertChat(Chat chat);
  Future<void> deleteChat(String chatId);
  Future<void> clearChats();
  Future<String?> getCurrentChatId();
  Future<void> setCurrentChatId(String? chatId);
}
