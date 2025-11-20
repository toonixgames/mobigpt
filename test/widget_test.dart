// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mobigpt/data/entities/rating_entity.dart';

import 'package:mobigpt/main.dart';
import 'package:mobigpt/models/chat.dart';
import 'package:mobigpt/repositories/chat_repository.dart';
import 'package:mobigpt/repositories/rating_repository.dart';
import 'package:mobigpt/services/chat_service.dart';
import 'package:mobigpt/services/rating_service.dart';
import 'package:rate_popup/src/db/entities.dart';

void main() {
  testWidgets('ChatApp renders loading state', (WidgetTester tester) async {
    final chatService = ChatService(
      chatRepository: _FakeChatRepository(),
    );
    final ratingService = RatingService(
      ratingRepository: _FakeRatingRepository(),
    );

    await tester.pumpWidget(ChatApp(chatService: chatService, ratingService: ratingService,));

    expect(find.text('בודק מודלים זמינים...'), findsOneWidget);
  });
}

class _FakeChatRepository implements ChatRepository {
  final List<Chat> _chats = [];
  String? _currentChatId;

  @override
  Future<void> clearChats() async {
    _chats.clear();
    _currentChatId = null;
  }

  @override
  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((chat) => chat.id == chatId);
  }

  @override
  Future<List<Chat>> getAllChats() async {
    return List<Chat>.from(_chats);
  }

  @override
  Future<Chat?> getChatById(String chatId) async {
    try {
      return _chats.firstWhere((chat) => chat.id == chatId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getCurrentChatId() async => _currentChatId;

  @override
  Future<void> setCurrentChatId(String? chatId) async {
    _currentChatId = chatId;
  }

  @override
  Future<Chat> upsertChat(Chat chat) async {
    final index = _chats.indexWhere((element) => element.id == chat.id);
    if (index != -1) {
      _chats[index] = chat;
    } else {
      _chats.add(chat);
    }
    return chat;
  }
}

class _FakeRatingRepository implements RatingRepository {
  final List<RatingEntity> _ratings = [];

  void addRating(Rating rating) {
    RatingEntity ratingEntity = RatingEntity.fromRating(rating);
    _ratings.add(ratingEntity);
  }
}