import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mobigpt/data/entities/chat_entity.dart';
import 'package:mobigpt/repositories/chat_repository.dart';
import 'package:mobigpt/repositories/objectbox_chat_repository.dart';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';

import 'package:mobigpt/objectbox.g.dart';

import '../../repositories/objectbox_rating_repository.dart';
import '../../repositories/rating_repository.dart';
import '../entities/rating_entity.dart';

class ObjectBoxStore {
  ObjectBoxStore._(this.store)
      : chatRepository = ObjectBoxChatRepository(
          store.box<ChatEntity>(),
          store.box<ChatStateEntity>(),
        ),
        ratingRepository = ObjectBoxRatingRepository(store.box<RatingEntity>());

  static ObjectBoxStore? _instance;

  final Store store;
  final ChatRepository chatRepository;
  final RatingRepository ratingRepository;
  Admin? _admin;

  static Future<ObjectBoxStore> init() async {
    if (_instance != null) {
      return _instance!;
    }

    if (kIsWeb) {
      throw UnsupportedError('ObjectBox is not supported on web');
    }

    final baseDirectory = await _resolveDirectory();
    final storeDirectory = Directory('${baseDirectory.path}/objectbox');
    if (!storeDirectory.existsSync()) {
      storeDirectory.createSync(recursive: true);
    }
    final store = await openStore(directory: storeDirectory.path);
    final objectBoxStore = ObjectBoxStore._(store);

    if (!kReleaseMode) {
      objectBoxStore._startAdminServer();
    }

    _instance = objectBoxStore;
    return _instance!;
  }

  static Future<Directory> _resolveDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return getApplicationDocumentsDirectory();
    }
    if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
      return getApplicationSupportDirectory();
    }
    throw UnsupportedError('Unsupported platform for ObjectBox');
  }

  void _startAdminServer() {
    try {
      if (!Admin.isAvailable()) {
        debugPrint('ObjectBox Admin not available in this build');
        return;
      }

      final adminInstance = Admin(store, bindUri: 'http://127.0.0.1:8090');
      _admin = adminInstance;
      debugPrint(
          'ObjectBox Admin running on http://127.0.0.1:${adminInstance.port}');
    } catch (e) {
      debugPrint('Failed to start ObjectBox Admin: $e');
    }
  }
}
