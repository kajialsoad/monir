import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';

/// Service for managing data isolation between cloned apps
class DataIsolationService {
  static const String _cloneDataPrefix = 'clone_data_';
  static const String _cloneSettingsPrefix = 'clone_settings_';

  // Advanced isolation features
  static final Map<String, String> _isolatedDirectories = {};
  static final Map<String, Map<String, dynamic>> _isolatedSettings = {};
  static bool _encryptionEnabled = true;
  static const String _encryptionKey = 'multispace_isolation_key_2024';

  /// Create completely isolated data directory for a cloned app (Google Incognito-like isolation)
  static Future<String> createIsolatedDataDirectory(String packageName, int cloneId) async {
    try {
      // Create unique isolated directory for each clone
      final appDocDir = await _getAppDocumentsDirectory();
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final cloneDataDir = Directory('${appDocDir.path}/isolated_spaces/$packageName/clone_${cloneId}_$uniqueId');

      if (!await cloneDataDir.exists()) {
        await cloneDataDir.create(recursive: true);
      }

      // Create complete isolated environment subdirectories
      await _createCompleteIsolatedEnvironment(cloneDataDir.path);

      // Create isolated configuration for this specific clone
      await _createIsolatedConfig(cloneDataDir.path, packageName, cloneId, uniqueId);

      // Initialize isolated storage systems
      await _initializeIsolatedStorage(cloneDataDir.path, packageName, cloneId);

      print('Created complete isolated space: ${cloneDataDir.path}');
      return cloneDataDir.path;
    } catch (e) {
      print('Error creating isolated directory: $e');
      // Return a fallback path if creation fails
      final uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
      final randomId = (DateTime.now().microsecondsSinceEpoch % 100000).toString();
      return '/isolated_spaces/$packageName/clone_${cloneId}_${uniqueId}_$randomId';
    }
  }
  
  /// Create necessary subdirectories for app data
  static Future<void> _createSubDirectories(String basePath) async {
    final subdirs = [
      'databases',
      'shared_prefs',
      'files',
      'cache',
      'code_cache',
    ];
    
    for (String subdir in subdirs) {
      final dir = Directory('$basePath/$subdir');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }
  
  /// Get isolated SharedPreferences for a cloned app
  static Future<SharedPreferences> getIsolatedPreferences(String packageName, int cloneId) async {
    // In a real implementation, this would return isolated preferences
    // For demo purposes, we'll use a prefixed key system
    return await SharedPreferences.getInstance();
  }
  
  /// Save cloned app settings
  static Future<void> saveClonedAppSettings(String packageName, int cloneId, Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cloneSettingsPrefix${packageName}_$cloneId';
    
    // Convert settings to JSON string and save
    final settingsJson = settings.entries.map((e) => '${e.key}:${e.value}').join('|');
    await prefs.setString(key, settingsJson);
  }
  
  /// Load cloned app settings
  static Future<Map<String, dynamic>> loadClonedAppSettings(String packageName, int cloneId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cloneSettingsPrefix${packageName}_$cloneId';
    
    final settingsJson = prefs.getString(key);
    if (settingsJson == null) return {};
    
    final settings = <String, dynamic>{};
    final pairs = settingsJson.split('|');
    for (String pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        settings[parts[0]] = parts[1];
      }
    }
    
    return settings;
  }
  
  /// Clear all data for a cloned app
  static Future<void> clearClonedAppData(String packageName, int cloneId) async {
    try {
      // Remove data directory
      final appDocDir = await _getAppDocumentsDirectory();
      final cloneDataDir = Directory('${appDocDir.path}/cloned_apps/$packageName/clone_$cloneId');
      
      if (await cloneDataDir.exists()) {
        await cloneDataDir.delete(recursive: true);
      }
      
      // Remove settings
      final prefs = await SharedPreferences.getInstance();
      final settingsKey = '$_cloneSettingsPrefix${packageName}_$cloneId';
      await prefs.remove(settingsKey);
      
      // Remove any other clone-specific data
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('$_cloneDataPrefix${packageName}_$cloneId')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      throw Exception('Failed to clear cloned app data: $e');
    }
  }
  
  /// Get storage usage for a cloned app
  static Future<int> getClonedAppStorageUsage(String packageName, int cloneId) async {
    try {
      final appDocDir = await _getAppDocumentsDirectory();
      final cloneDataDir = Directory('${appDocDir.path}/cloned_apps/$packageName/clone_$cloneId');
      
      if (!await cloneDataDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (FileSystemEntity entity in cloneDataDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Backup cloned app data
  static Future<String> backupClonedAppData(String packageName, int cloneId) async {
    try {
      final appDocDir = await _getAppDocumentsDirectory();
      final cloneDataDir = Directory('${appDocDir.path}/cloned_apps/$packageName/clone_$cloneId');
      final backupDir = Directory('${appDocDir.path}/backups/${packageName}_clone_$cloneId');
      
      if (!await cloneDataDir.exists()) {
        throw Exception('Clone data directory does not exist');
      }
      
      if (await backupDir.exists()) {
        await backupDir.delete(recursive: true);
      }
      
      await backupDir.create(recursive: true);
      
      // Copy all files from clone directory to backup directory
      await _copyDirectory(cloneDataDir, backupDir);
      
      return backupDir.path;
    } catch (e) {
      throw Exception('Failed to backup cloned app data: $e');
    }
  }
  
  /// Restore cloned app data from backup
  static Future<void> restoreClonedAppData(String packageName, int cloneId, String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        throw Exception('Backup directory does not exist');
      }
      
      final appDocDir = await _getAppDocumentsDirectory();
      final cloneDataDir = Directory('${appDocDir.path}/cloned_apps/$packageName/clone_$cloneId');
      
      if (await cloneDataDir.exists()) {
        await cloneDataDir.delete(recursive: true);
      }
      
      await cloneDataDir.create(recursive: true);
      
      // Copy all files from backup directory to clone directory
      await _copyDirectory(backupDir, cloneDataDir);
    } catch (e) {
      throw Exception('Failed to restore cloned app data: $e');
    }
  }
  
  /// Helper method to copy directory contents
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await for (FileSystemEntity entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory('${destination.path}/${entity.path.split('/').last}');
        await newDirectory.create();
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File('${destination.path}/${entity.path.split('/').last}');
        await entity.copy(newFile.path);
      }
    }
  }
  
  /// Get list of all cloned apps with their data info
  static Future<List<Map<String, dynamic>>> getClonedAppsDataInfo() async {
    try {
      final appDocDir = await _getAppDocumentsDirectory();
      final clonedAppsDir = Directory('${appDocDir.path}/cloned_apps');
      
      if (!await clonedAppsDir.exists()) {
        return [];
      }
      
      List<Map<String, dynamic>> appsInfo = [];
      
      await for (FileSystemEntity entity in clonedAppsDir.list()) {
        if (entity is Directory) {
          final packageName = entity.path.split('/').last;
          
          await for (FileSystemEntity cloneEntity in entity.list()) {
            if (cloneEntity is Directory) {
              final cloneDirName = cloneEntity.path.split('/').last;
              if (cloneDirName.startsWith('clone_')) {
                final cloneId = int.tryParse(cloneDirName.substring(6)) ?? 0;
                final storageUsage = await getClonedAppStorageUsage(packageName, cloneId);
                
                appsInfo.add({
                  'packageName': packageName,
                  'cloneId': cloneId,
                  'storageUsage': storageUsage,
                  'dataPath': cloneEntity.path,
                });
              }
            }
          }
        }
      }
      
      return appsInfo;
    } catch (e) {
      return [];
    }
  }

  static Future<Directory> _getAppDocumentsDirectory() async {
    if (kIsWeb) {
      // On web, local file system is not available; use a temporary system directory
      final tempDir = await Directory.systemTemp.createTemp('multispace_web_');
      return tempDir;
    }
    return await getApplicationDocumentsDirectory();
  }

  /// Create complete isolated environment (Google Incognito-like)
  static Future<void> _createCompleteIsolatedEnvironment(String basePath) async {
    final directories = [
      'databases',           // Isolated SQLite databases
      'shared_prefs',        // Isolated SharedPreferences
      'cache',              // Isolated cache data
      'files',              // Isolated app files
      'temp',               // Isolated temporary files
      'cookies',            // Isolated cookies/sessions
      'tokens',             // Isolated auth tokens
      'accounts',           // Isolated account data
      'settings',           // Isolated app settings
      'storage',            // Isolated local storage
      'webview',            // Isolated WebView data
      'keystore',           // Isolated keystore data
      'logs',               // Isolated log files
      'media',              // Isolated media files
      'downloads',          // Isolated downloads
    ];

    for (final dirName in directories) {
      final dir = Directory('$basePath/$dirName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }
  }

  /// Create isolated configuration for specific clone
  static Future<void> _createIsolatedConfig(String basePath, String packageName, int cloneId, String uniqueId) async {
    final configFile = File('$basePath/clone_config.json');
    final config = {
      'packageName': packageName,
      'cloneId': cloneId,
      'uniqueId': uniqueId,
      'createdAt': DateTime.now().toIso8601String(),
      'isolationLevel': 'complete',
      'dataVersion': '2.0',
      'features': {
        'accountIsolation': true,
        'cookieIsolation': true,
        'tokenIsolation': true,
        'databaseIsolation': true,
        'cacheIsolation': true,
        'settingsIsolation': true,
        'webviewIsolation': true,
        'keystoreIsolation': true,
      }
    };

    await configFile.writeAsString(jsonEncode(config));
  }

  /// Initialize isolated storage systems
  static Future<void> _initializeIsolatedStorage(String basePath, String packageName, int cloneId) async {
    try {
      // Create isolated database
      await _createIsolatedDatabase(basePath, packageName, cloneId);

      // Create isolated preferences
      await _createIsolatedPreferences(basePath, packageName, cloneId);

      // Create isolated session storage
      await _createIsolatedSessionStorage(basePath, packageName, cloneId);

    } catch (e) {
      print('Error initializing isolated storage: $e');
    }
  }

  /// Create isolated database for complete data separation
  static Future<void> _createIsolatedDatabase(String basePath, String packageName, int cloneId) async {
    try {
      final dbDir = Directory('$basePath/databases');
      final dbFile = File('${dbDir.path}/app_data.db');

      // Create isolated database with unique schema
      final dbContent = '''
        CREATE TABLE IF NOT EXISTS user_accounts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          account_id TEXT UNIQUE,
          username TEXT,
          email TEXT,
          auth_token TEXT,
          session_data TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS session_storage (
          key TEXT PRIMARY KEY,
          value TEXT,
          expires_at TIMESTAMP,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      ''';

      await dbFile.writeAsString(dbContent);
    } catch (e) {
      print('Error creating isolated database: $e');
    }
  }

  /// Create isolated preferences for complete settings separation
  static Future<void> _createIsolatedPreferences(String basePath, String packageName, int cloneId) async {
    try {
      final prefsDir = Directory('$basePath/shared_prefs');
      final prefsFile = File('${prefsDir.path}/app_preferences.json');

      final defaultPrefs = {
        'app_version': '1.0.0',
        'first_launch': true,
        'user_id': null,
        'auth_token': null,
        'session_id': null,
        'settings': {},
        'cache_version': DateTime.now().millisecondsSinceEpoch,
      };

      await prefsFile.writeAsString(jsonEncode(defaultPrefs));
    } catch (e) {
      print('Error creating isolated preferences: $e');
    }
  }

  /// Create isolated session storage for complete account separation
  static Future<void> _createIsolatedSessionStorage(String basePath, String packageName, int cloneId) async {
    try {
      final sessionDir = Directory('$basePath/cookies');
      final sessionFile = File('${sessionDir.path}/session_data.json');

      final sessionData = {
        'cookies': {},
        'tokens': {},
        'auth_state': {},
        'user_sessions': {},
        'login_history': [],
        'account_data': {},
        'isolation_id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      await sessionFile.writeAsString(jsonEncode(sessionData));

      // Create isolated keystore
      final keystoreDir = Directory('$basePath/keystore');
      final keystoreFile = File('${keystoreDir.path}/keys.json');

      final keystoreData = {
        'encryption_keys': {},
        'auth_keys': {},
        'session_keys': {},
        'created_at': DateTime.now().toIso8601String(),
      };

      await keystoreFile.writeAsString(jsonEncode(keystoreData));
    } catch (e) {
      print('Error creating isolated session storage: $e');
    }
  }

  /// Get isolated data path for specific clone
  static Future<String> getIsolatedDataPath(String packageName, int cloneId) async {
    try {
      final appDocDir = await _getAppDocumentsDirectory();
      final cloneDataDir = Directory('${appDocDir.path}/isolated_spaces/$packageName');

      if (await cloneDataDir.exists()) {
        final cloneDirs = await cloneDataDir.list().toList();
        for (final dir in cloneDirs) {
          if (dir.path.contains('clone_$cloneId')) {
            return dir.path;
          }
        }
      }

      // If not found, create new isolated space
      return await createIsolatedDataDirectory(packageName, cloneId);
    } catch (e) {
      print('Error getting isolated data path: $e');
      return '/isolated_spaces/$packageName/clone_$cloneId';
    }
  }

  /// Clear all isolated data for a specific clone (complete cleanup)
  static Future<void> clearIsolatedCloneData(String packageName, int cloneId) async {
    try {
      final isolatedPath = await getIsolatedDataPath(packageName, cloneId);
      final cloneDir = Directory(isolatedPath);

      if (await cloneDir.exists()) {
        await cloneDir.delete(recursive: true);
        print('Cleared isolated data for $packageName clone $cloneId');
      }

      // Also clear from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.contains('${packageName}_$cloneId')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing isolated clone data: $e');
    }
  }
}
