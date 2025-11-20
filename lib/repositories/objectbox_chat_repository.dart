import 'package:mobigpt/data/entities/chat_entity.dart';
import 'package:mobigpt/data/mappers/chat_mapper.dart';
import 'package:mobigpt/models/chat.dart';
import 'package:mobigpt/objectbox.g.dart';
import 'package:mobigpt/repositories/chat_repository.dart';

class ObjectBoxChatRepository implements ChatRepository {
  ObjectBoxChatRepository(this._chatBox, this._chatStateBox);

  final Box<ChatEntity> _chatBox;
  final Box<ChatStateEntity> _chatStateBox;

  @override
  Future<List<Chat>> getAllChats() async {
    final entities = _chatBox.getAll();
    entities.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entities.map(ChatMapper.fromEntity).toList(growable: false);
  }

  @override
  Future<Chat?> getChatById(String chatId) async {
    final entity = _findEntityByChatId(chatId);
    return entity == null ? null : ChatMapper.fromEntity(entity);
  }

  @override
  Future<Chat> upsertChat(Chat chat) async {
    final existing = _findEntityByChatId(chat.id);
    final entity = ChatMapper.toEntity(chat);
    if (existing != null) {
      entity.id = existing.id;
    }
    final savedId = _chatBox.put(entity, mode: PutMode.put);
    final savedEntity = _chatBox.get(savedId)!;
    return ChatMapper.fromEntity(savedEntity);
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final entity = _findEntityByChatId(chatId);
    if (entity != null) {
      _chatBox.remove(entity.id);
    }
  }

  @override
  Future<void> clearChats() async {
    _chatBox.removeAll();
    _chatStateBox.removeAll();
  }

  @override
  Future<String?> getCurrentChatId() async {
    final state = _chatStateBox.get(1);
    return state?.currentChatId;
  }

  @override
  Future<void> setCurrentChatId(String? chatId) async {
    _chatStateBox.put(
      ChatStateEntity(id: 1, currentChatId: chatId),
      mode: PutMode.put,
    );
  }

  ChatEntity? _findEntityByChatId(String chatId) {
    final query = _chatBox.query(ChatEntity_.chatId.equals(chatId)).build();
    final result = query.findFirst();
    query.close();
    return result;
  }
}
