import 'dart:async';
import 'dart:io';
import 'package:mobigpt/objectbox.g.dart';
import 'package:rate_popup/src/db/entities.dart';

import '../utils/logger.dart';
import 'DBConfig.dart';
import 'entities.dart';

class ObjectBoxDB {
  static final ObjectBoxDB _instance = ObjectBoxDB._internal();
  late Store? _store;
  Admin? _admin;

  // Rating
  late Box<RatingEntity>? _ratingBox;

  ObjectBoxDB._internal();

  static ObjectBoxDB get instance => _instance;

  Future<void> init() async {
    final storeDirectory = Directory(DBConfig.dbDirectoryPath);
    if (!await storeDirectory.exists()) {
      await storeDirectory.create(recursive: true);
      Logger.info("ObjectBox DB Created Successfully on: ${DBConfig.dbDirectoryPath}");
    }
    _store = Store(getObjectBoxModel(), directory: DBConfig.dbDirectoryPath);

    // Initialize Admin if available
    if (Admin.isAvailable()) {
      _admin = Admin(_store!);
      Logger.info("ObjectBox Admin initialized.");
    }

    // Initialize boxes
    _ratingBox = _store!.box<RatingEntity>();
  }

  /// DANGER: wipes the entire DB (files), resets ID sequence.
  Future<void> wipeAndReopen() async {
    // 1) Close the store (very important)
    await close();

    // 2) Delete database files
    final storeDirectory = Directory(DBConfig.dbDirectoryPath);
    if (await storeDirectory.exists()) {
      await storeDirectory.delete(recursive: true);
    }

    // 3) Reset all box references to null
    _resetBoxes();

    // 4) Reopen a fresh store (IDs start from 1 again)
    await init();
  }

  void _resetBoxes() {
    // Reset all box references to null
    _ratingBox = null;
  }

  Store get store => _store!;
  Admin? get admin => _admin;

  // Getters for boxes
  Box<RatingEntity>? get ratingBox => _ratingBox;

  // ************************* General CRUD Methods *************************

  void put<T>(Box<T> box, T entity) {
    try {
      box.put(entity);
    } catch (e) {
      Logger.error("Failed to put ${T.toString()} : ${e.toString()}");
    }
  }

  // ************************* encryption utils *************************
  Future<void> reopen() async {
    try {
      // Close admin first
      _admin?.close();
      _admin = null;

      // Close the existing store
      _store!.close();

      // Create a new store instance
      _store = Store(getObjectBoxModel(), directory: DBConfig.dbDirectoryPath);

      // Initialize Admin if available
      if (Admin.isAvailable()) {
        _admin = Admin(_store!);
      }

      // Initialize boxes again
      _ratingBox = _store!.box<RatingEntity>();

      Logger.info("ObjectBox store reopened successfully");
    } catch (e) {
      Logger.info("Failed to reopen ObjectBox store : ${e.toString()}");
      rethrow;
    }
  }

  // ************************* Cleanup Methods *************************

  Future<void> close() async {
    try {
      if (_admin != null) {
        _admin!.close();
        _admin = null;
      }
      if (_store != null) {
        _store!.close();
        _store = null;
      }
      Logger.info("ObjectBox store closed successfully");
    } catch (e) {
      Logger.error("Failed to close ObjectBox store: ${e.toString()}");
    }
  }

  // ************************* Entity-Specific Methods *************************

  void putRating(Rating rating) {
    final RatingEntity ratingEntity = RatingEntity.fromRating(rating); // converting Rating returned from RatingDialog widget to RatingEntity
    put(_ratingBox!, ratingEntity);
  }

}
