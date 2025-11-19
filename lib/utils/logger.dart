import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// A utility class for logging throughout the application
class Logger {
  static const String _appName = 'MobiAI';
  
  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      final logMessage = _formatMessage(message, tag);
      developer.log(logMessage, name: _appName, level: 800); // Debug level
    }
  }
  
  /// Log info messages
  static void info(String message, {String? tag}) {
    final logMessage = _formatMessage(message, tag);
    developer.log(logMessage, name: _appName, level: 700); // Info level
  }
  
  /// Log warning messages
  static void warning(String message, {String? tag}) {
    final logMessage = _formatMessage(message, tag);
    developer.log(logMessage, name: _appName, level: 900); // Warning level
  }
  
  /// Log error messages
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final logMessage = _formatMessage(message, tag);
    developer.log(
      logMessage,
      name: _appName,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Format log message with optional tag
  static String _formatMessage(String message, String? tag) {
    if (tag != null && tag.isNotEmpty) {
      return '[$tag] $message';
    }
    return message;
  }
  
  /// Log chat service operations
  static void chatService(String message) {
    info(message, tag: 'ChatService');
  }
  
  /// Log chat screen operations
  static void chatScreen(String message) {
    info(message, tag: 'ChatScreen');
  }
  
  /// Log gemma input field operations
  static void gemmaInput(String message) {
    info(message, tag: 'GemmaInput');
  }
  
  /// Log model operations
  static void model(String message) {
    info(message, tag: 'Model');
  }
  
  /// Log context switching operations
  static void context(String message) {
    info(message, tag: 'Context');
  }
}

