import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/logger.dart';

class DBConfig {
  static late final String dataDir;
  static late final String dbDirectoryPath;

  /// Call this early in main()
  static Future<void> init() async {
    dataDir = await getAppDataDir();
    dbDirectoryPath = p.join(dataDir, 'Database');
  }

  static Future<String> getAppDataDir() async {
    final directory = await getApplicationSupportDirectory(); // /data/user/0/com.example.mobinotes/files
    return directory.path;
  }

}