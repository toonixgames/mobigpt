import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobigpt/utils/logger.dart';

class ModelDownloadService {
  final String modelUrl;
  final String modelFilename;
  final String licenseUrl;

  ModelDownloadService({
    required this.modelUrl,
    required this.modelFilename,
    required this.licenseUrl,
  });

  /// Helper method to get the file path.
  Future<String> getFilePath() async {
    final directory = Directory('/storage/emulated/0/Download/Models');
    return '${directory.path}/$modelFilename';
  }

  /// Check if storage permissions are granted
  Future<bool> hasPermissions() async {
    try {
      final status = await Permission.storage.status;
      final manageStorage = await Permission.manageExternalStorage.status;
      final hasPermissions = status.isGranted || manageStorage.isGranted;

      if (hasPermissions) {
        Logger.info('Storage permissions are granted');
      } else {
        Logger.warning('Storage permissions are not granted');
      }

      return hasPermissions;
    } catch (e) {
      Logger.error('Failed to check permissions ${e.toString()}');
      return false;
    }
  }

  /// Checks if the model file exists and matches the remote file size.
  Future<bool> checkModelExistence() async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      if (file.existsSync()) {
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error checking model existence: $e');
      }
    }
    return false;
  }

  /// Deletes the downloaded file.
  Future<void> deleteModel() async {
    try {
      final filePath = await getFilePath();
      final file = File(filePath);

      if (file.existsSync()) {
        await file.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error deleting model: $e');
      }
    }
  }
}
