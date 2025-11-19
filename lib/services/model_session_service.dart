import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:mobigpt/models/model.dart';
import 'package:mobigpt/utils/logger.dart';

/// Holds a single model instance and manages per-chat InferenceChat sessions globally.
class ModelSessionService {
  ModelSessionService._internal();
  static final ModelSessionService instance = ModelSessionService._internal();

  final FlutterGemmaPlugin _gemma = FlutterGemmaPlugin.instance;

  InferenceModel? _model;
  Model? _configuredModel;
  PreferredBackend? _configuredBackend;

  final Map<String, InferenceChat> _chatIdToSession = <String, InferenceChat>{};

  bool get isInitialized => _model != null;

  Future<void> initializeIfNeeded({
    required Model model,
    required PreferredBackend backend,
  }) async {
    if (_model != null && _configuredModel == model && _configuredBackend == backend) {
      return;
    }

    await _recreateModel(model: model, backend: backend);
  }

  Future<InferenceChat> getOrCreateSession({
    required String chatId,
    required List<Message> messages,
    required Model model,
    required PreferredBackend backend,
  }) async {
    await initializeIfNeeded(model: model, backend: backend);

    final existing = _chatIdToSession[chatId];
    if (existing != null) {
      return existing;
    }

    Logger.context('SessionService: creating session for chat "$chatId"');
    final chat = await _model!.createChat(
      temperature: model.temperature,
      randomSeed: 1,
      topK: model.topK,
      topP: model.topP,
      tokenBuffer: 256,
      supportImage: model.supportImage,
      supportsFunctionCalls: model.supportsFunctionCalls,
      isThinking: model.isThinking,
      modelType: model.modelType,
    );

    _chatIdToSession[chatId] = chat;

    if (messages.isNotEmpty) {
      await _replayMessages(chat, messages);
    }

    return chat;
  }

  Future<void> disposeSession(String chatId) async {
    _chatIdToSession.remove(chatId);
  }

  Future<void> disposeAllSessions() async {
    _chatIdToSession.clear();
  }

  Future<void> disposeModel() async {
    await disposeAllSessions();
    try {
      await _gemma.modelManager.deleteModel();
    } catch (_) {}
    _model = null;
    _configuredModel = null;
    _configuredBackend = null;
  }

  Future<void> _recreateModel({
    required Model model,
    required PreferredBackend backend,
  }) async {
    await disposeAllSessions();

    final path = model.url;
    await _gemma.modelManager.setModelPath(path);

    _model = await _gemma.createModel(
      modelType: model.modelType,
      preferredBackend: backend,
      maxTokens: model.maxTokens,
      supportImage: model.supportImage,
      maxNumImages: model.maxNumImages,
    );

    _configuredModel = model;
    _configuredBackend = backend;
  }

  Future<void> _replayMessages(InferenceChat target, List<Message> messages) async {
    for (int i = 0; i < messages.length; i++) {
      await target.addQuery(messages[i]);
      if (i % 3 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }
}


