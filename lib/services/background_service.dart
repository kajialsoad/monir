import 'dart:isolate';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/app_info.dart';

/// High-performance background service using Dart Isolates
/// UI thread block না করে background এ heavy operations চালায়
class BackgroundService {
  static Isolate? _backgroundIsolate;
  static SendPort? _sendPort;
  static final Completer<SendPort> _isolateReady = Completer<SendPort>();
  static bool _isInitialized = false;

  /// Initialize background isolate for heavy operations
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final receivePort = ReceivePort();
      
      // Create background isolate
      _backgroundIsolate = await Isolate.spawn(
        _backgroundIsolateEntryPoint,
        receivePort.sendPort,
      );

      // Listen for isolate ready signal
      receivePort.listen((message) {
        if (message is SendPort) {
          _sendPort = message;
          if (!_isolateReady.isCompleted) {
            _isolateReady.complete(message);
          }
        }
      });

      // Wait for isolate to be ready
      await _isolateReady.future.timeout(const Duration(seconds: 5));
      _isInitialized = true;
      
      print('Background service initialized successfully');
    } catch (e) {
      print('Background service initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Background isolate entry point
  static void _backgroundIsolateEntryPoint(SendPort mainSendPort) {
    final receivePort = ReceivePort();
    mainSendPort.send(receivePort.sendPort);

    receivePort.listen((message) async {
      if (message is Map<String, dynamic>) {
        final operation = message['operation'] as String;
        final data = message['data'];
        final responsePort = message['responsePort'] as SendPort;

        try {
          dynamic result;
          
          switch (operation) {
            case 'processAppList':
              result = await _processAppListInBackground(data);
              break;
            case 'optimizeMemory':
              result = await _optimizeMemoryInBackground();
              break;
            case 'cleanupCache':
              result = await _cleanupCacheInBackground(data);
              break;
            case 'batchIconLoad':
              result = await _batchIconLoadInBackground(data);
              break;
            default:
              result = {'error': 'Unknown operation: $operation'};
          }

          responsePort.send({'success': true, 'result': result});
        } catch (e) {
          responsePort.send({'success': false, 'error': e.toString()});
        }
      }
    });
  }

  /// Process app list in background without blocking UI
  static Future<List<AppInfo>> processAppList(List<dynamic> rawAppData) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final responsePort = ReceivePort();
      _sendPort!.send({
        'operation': 'processAppList',
        'data': rawAppData,
        'responsePort': responsePort.sendPort,
      });

      final response = await responsePort.first.timeout(const Duration(seconds: 10));
      responsePort.close();

      if (response['success'] == true) {
        final List<dynamic> processedData = response['result'];
        return processedData.map((data) => AppInfo.fromMap(Map<String, dynamic>.from(data))).toList();
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      print('Background app processing failed: $e');
      // Fallback to main thread processing
      return _processAppListSync(rawAppData);
    }
  }

  /// Optimize memory in background
  static Future<Map<String, dynamic>> optimizeMemory() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final responsePort = ReceivePort();
      _sendPort!.send({
        'operation': 'optimizeMemory',
        'data': null,
        'responsePort': responsePort.sendPort,
      });

      final response = await responsePort.first.timeout(const Duration(seconds: 5));
      responsePort.close();

      if (response['success'] == true) {
        return response['result'];
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      print('Background memory optimization failed: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Batch load icons in background
  static Future<Map<String, Uint8List?>> batchLoadIcons(List<String> packageNames) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final responsePort = ReceivePort();
      _sendPort!.send({
        'operation': 'batchIconLoad',
        'data': packageNames,
        'responsePort': responsePort.sendPort,
      });

      final response = await responsePort.first.timeout(const Duration(seconds: 15));
      responsePort.close();

      if (response['success'] == true) {
        return Map<String, Uint8List?>.from(response['result']);
      } else {
        throw Exception(response['error']);
      }
    } catch (e) {
      print('Background icon loading failed: $e');
      return {};
    }
  }

  /// Cleanup cache in background
  static Future<bool> cleanupCache(Map<String, dynamic> cacheData) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final responsePort = ReceivePort();
      _sendPort!.send({
        'operation': 'cleanupCache',
        'data': cacheData,
        'responsePort': responsePort.sendPort,
      });

      final response = await responsePort.first.timeout(const Duration(seconds: 5));
      responsePort.close();

      return response['success'] == true;
    } catch (e) {
      print('Background cache cleanup failed: $e');
      return false;
    }
  }

  /// Background processing methods (run in isolate)
  
  static Future<List<Map<String, dynamic>>> _processAppListInBackground(List<dynamic> rawData) async {
    final processedApps = <Map<String, dynamic>>[];
    
    for (final appData in rawData) {
      try {
        final Map<String, dynamic> appMap = Map<String, dynamic>.from(appData);
        
        // Filter out system apps and invalid entries
        if (appMap['isSystemApp'] != true && 
            appMap['packageName'] != null && 
            appMap['packageName'].toString().isNotEmpty) {
          
          // Add performance optimizations
          appMap['processedAt'] = DateTime.now().millisecondsSinceEpoch;
          processedApps.add(appMap);
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    // Sort by app name for better UX
    processedApps.sort((a, b) => 
      (a['appName'] ?? '').toString().toLowerCase().compareTo(
        (b['appName'] ?? '').toString().toLowerCase()
      )
    );

    return processedApps;
  }

  static Future<Map<String, dynamic>> _optimizeMemoryInBackground() async {
    // Simulate memory optimization
    await Future.delayed(const Duration(milliseconds: 500));
    
    return {
      'optimizedMemory': true,
      'freedMemoryMB': 50,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<bool> _cleanupCacheInBackground(Map<String, dynamic> cacheData) async {
    // Simulate cache cleanup
    await Future.delayed(const Duration(milliseconds: 200));
    return true;
  }

  static Future<Map<String, Uint8List?>> _batchIconLoadInBackground(List<String> packageNames) async {
    final icons = <String, Uint8List?>{};
    
    // Simulate icon loading (in real implementation, this would use method channels)
    for (final packageName in packageNames) {
      await Future.delayed(const Duration(milliseconds: 50));
      icons[packageName] = null; // Placeholder
    }
    
    return icons;
  }

  /// Fallback sync processing
  static List<AppInfo> _processAppListSync(List<dynamic> rawData) {
    final apps = <AppInfo>[];
    
    for (final appData in rawData) {
      try {
        final app = AppInfo.fromMap(Map<String, dynamic>.from(appData));
        if (!app.isSystemApp && app.packageName.isNotEmpty) {
          apps.add(app);
        }
      } catch (e) {
        continue;
      }
    }
    
    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
    return apps;
  }

  /// Dispose background service
  static void dispose() {
    _backgroundIsolate?.kill(priority: Isolate.immediate);
    _backgroundIsolate = null;
    _sendPort = null;
    _isInitialized = false;
  }
}
