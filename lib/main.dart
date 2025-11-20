import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gemma/pigeon.g.dart';
import 'package:mobigpt/widgets/chat_screen_enhanced.dart';
import 'package:mobigpt/models/model.dart';
import 'package:mobigpt/services/model_download_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobigpt/utils/logger.dart';

import 'db/DBConfig.dart';
import 'db/objectBoxDB.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request storage permissions at app startup
  await _requestStoragePermissions();

  WidgetsFlutterBinding.ensureInitialized();

  await DBConfig.init();
  await ObjectBoxDB.instance.init();

  runApp(const ChatApp());
}

// Request storage permissions for external storage access
Future<void> _requestStoragePermissions() async {
  try {
    Logger.info('Requesting storage permissions...');

    // Request storage permission
    final storageStatus = await Permission.storage.request();
    Logger.info('Storage permission status: $storageStatus');

    // Request manage external storage permission (for Android 11+)
    final manageStorageStatus = await Permission.manageExternalStorage.request();
    Logger.info('Manage external storage permission status: $manageStorageStatus');

    // Check if we have any storage permissions
    final hasStoragePermission = storageStatus.isGranted || manageStorageStatus.isGranted;

    if (hasStoragePermission) {
      Logger.info('Storage permissions granted successfully');
    } else {
      Logger.warning('Storage permissions denied - some features may not work properly');
    }
  } catch (e) {
    Logger.error('Failed to request storage permissions: $e');
  }
}

class ChatApp extends StatelessWidget {

  const ChatApp({super.key});

  // Get the first available model based on platform and existence check
  Future<Model> _getFirstAvailableModel() async {

    var models = Model.values.where((model) {
      if (model.localModel) {
        return kIsWeb;
      }
      if (!kIsWeb) return true;
      return model.preferredBackend == PreferredBackend.cpu && !model.needsAuth;
    }).toList();

    // Check each model to see if it exists using checkModelExistence
    for (final model in models) {
      try {
        final downloadService = ModelDownloadService(
          modelUrl: model.url,
          modelFilename: model.filename,
          licenseUrl: model.licenseUrl,
        );
        final exists = await downloadService.checkModelExistence();
        if (exists) {
          return model;
        }
      } catch (e) {
        // Continue to next model if this one fails
        continue;
      }
    }

    // If no existing models found, return the first available model
    return models.isNotEmpty ? models.first : Model.gemma3_1B;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MobiGPT',
      locale: const Locale('he', 'IL'), // Hebrew locale
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'), // Hebrew
        Locale('en', 'US'), // English
      ],
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      themeMode: ThemeMode.light,
      home: SafeArea(
        child: FutureBuilder<Model>(
          future: _getFirstAvailableModel(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: ChatScreenEnhanced(
                  model: snapshot.data!,
                ),
              );
            } else {
              return const Scaffold(
                backgroundColor: Color(0xFF0b2351),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'בודק מודלים זמינים...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
