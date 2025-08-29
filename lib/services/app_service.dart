import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';
import 'method_channel_optimizer.dart';
import 'data_isolation_service.dart';
import 'memory_manager.dart';
import 'background_service.dart';

class AppService {
  static const String _channelName = 'multispace/apps';
  static const String _clonedAppsKey = 'cloned_apps';

  // Use optimized method channel
  static MethodChannelOptimizer get _optimizer => MethodChannelOptimizer.instance;

  // Helper method for optimized channel calls
  static Future<T?> _invokeOptimized<T>(String method, [dynamic arguments, Duration? timeout]) {
    return _optimizer.invokeMethod<T>(_channelName, method, arguments, timeout);
  }

  // Optimized cache for better performance
  static List<AppInfo>? _cachedApps;
  static List<AppInfo>? _cachedClonedApps;
  static DateTime? _lastCacheTime;
  static DateTime? _lastClonedCacheTime;
  static const Duration _cacheValidDuration = Duration(minutes: 2); // Reduced for faster updates

  // Optimized cache configurations
  static const int _maxCacheSize = 2000;
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static const Duration _iconCacheExpiry = Duration(hours: 12);
  static const int _maxIconCacheSize = 500;
  static const Duration _backgroundRefreshInterval = Duration(minutes: 5);

  // Cache for app icons with size limit
  static final Map<String, Uint8List?> _iconCache = {};

  // Performance optimization flags
  static bool _isInitialized = false;
  static final Map<String, dynamic> _performanceCache = {};

  // Optimized timeout configurations
  static const Duration _defaultTimeout = Duration(seconds: 8);
  static const Duration _shortTimeout = Duration(seconds: 3);
  static const Duration _longTimeout = Duration(seconds: 15);
  static const Duration _fastTimeout = Duration(seconds: 2);

  // Advanced performance optimizations
  static final Map<String, Future<List<AppInfo>>> _pendingRequests = {};
  static bool _backgroundProcessingEnabled = true;
  static int _maxConcurrentOperations = 3;
  static final List<String> _preloadedPackages = [];

  /// Initialize app service for optimal performance
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize memory manager first
      MemoryManager.instance.initialize();

      // Initialize background service for better performance
      await BackgroundService.initialize();

      // Pre-warm the method channel and setup performance optimizations
      await _optimizer.invokeMethod(_channelName, 'initializeService', null, const Duration(seconds: 3));

      // Enable background processing
      _enableBackgroundProcessing();

      // Pre-load commonly used data with priority (non-blocking)
      unawaited(Future.wait([
        _preloadInstalledApps(),
        _preloadClonedApps(),
        _preloadSystemInfo(),
      ], eagerError: false));

      // Initialize performance monitoring
      _initializePerformanceMonitoring();

      _isInitialized = true;
      print('AppService initialized successfully with memory management and background processing');
    } catch (e) {
      print('Service initialization warning: $e');
      _isInitialized = true; // Continue even if initialization fails
    }
  }

  /// Get all installed apps from the device with optimized caching and background processing
  static Future<List<AppInfo>> getInstalledApps({
    bool forceRefresh = false,
    bool excludeSystemApps = false,
    bool includeIcons = true,
    bool useCache = true,
    bool optimizeForSpeed = false,
    int? maxResults,
    int offset = 0,
    bool backgroundLoad = false,
  }) async {
    // Return cached data immediately if available and not expired
    if (!forceRefresh && useCache && _cachedApps != null && _lastCacheTime != null) {
      final timeSinceCache = DateTime.now().difference(_lastCacheTime!);
      if (timeSinceCache < _cacheValidDuration) {
        final result = _cachedApps!.skip(offset);
        return maxResults != null ? result.take(maxResults).toList() : result.toList();
      }
    }

    // For background loading, use shorter timeout
    final timeout = backgroundLoad ? _fastTimeout : (optimizeForSpeed ? _shortTimeout : _defaultTimeout);

    try {
      // Initialize service only if needed
      if (!_isInitialized) {
        await initialize();
      }

      print('🔄 Calling getInstalledApps via method channel...');
      print('📋 Parameters: excludeSystemApps=$excludeSystemApps, includeIcons=$includeIcons, backgroundLoad=$backgroundLoad, maxResults=$maxResults');
      
      // Try direct method channel call first to bypass optimizer
      final directChannel = MethodChannel(_channelName);
      List<dynamic>? result;
      
      try {
        print('🔧 Trying direct method channel call...');
        result = await directChannel.invokeMethod<List<dynamic>>(
          'getInstalledApps',
          {
            'excludeSystemApps': excludeSystemApps,
            'includeIcons': includeIcons && !backgroundLoad, // Skip icons for background loads
            'optimizeForSpeed': optimizeForSpeed || backgroundLoad,
            'maxResults': maxResults ?? (backgroundLoad ? 100 : 500), // Increased limits
            'offset': offset,
          },
        ).timeout(const Duration(seconds: 15)); // Longer timeout
        print('✅ Direct method channel call succeeded. Result length: ${result?.length ?? 'null'}');
      } catch (directError) {
        print('❌ Direct method channel failed: $directError');
        print('🔄 Falling back to optimized method channel...');
        
        // Fallback to optimized method channel
        result = await _optimizer.invokeMethod<List<dynamic>>(
          _channelName,
          'getInstalledApps',
          {
            'excludeSystemApps': excludeSystemApps,
            'includeIcons': includeIcons && !backgroundLoad, // Skip icons for background loads
            'optimizeForSpeed': optimizeForSpeed || backgroundLoad,
            'maxResults': maxResults ?? (backgroundLoad ? 100 : 500), // Increased limits
            'offset': offset,
          },
          timeout, // Use dynamic timeout based on load type
        );
        print('✅ Optimized method channel call completed. Result length: ${result?.length ?? 'null'}');
      }

      if (result != null && result.isNotEmpty) {
        // Process apps in background isolate to avoid UI blocking
        try {
          final apps = await BackgroundService.processAppList(result);

          // Cache the results
          _cachedApps = apps;
          _lastCacheTime = DateTime.now();

          return apps;
        } catch (e) {
          print('Background processing failed, using fallback: $e');
          // Fallback to sync processing
          return _processSyncFallback(result);
        }
      }
    } catch (e) {
      print('❌ ERROR getting apps via method channel: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Stack trace: ${StackTrace.current}');

      // Handle specific permission errors
      if (e is PlatformException) {
        if (e.code == 'PERMISSION_ERROR' || e.code == 'NO_APPS_FOUND') {
          print('🔒 Permission error detected: ${e.message}');
          
          // Return cached data as fallback if available
          if (useCache && _cachedApps != null && _cachedApps!.isNotEmpty) {
            print('⚠️ Returning cached apps as fallback due to permission error (${_cachedApps!.length} apps)');
            final result = _cachedApps!.skip(offset);
            return maxResults != null ? result.take(maxResults).toList() : result.toList();
          }
          
          // For background loads, return empty list instead of throwing
          if (backgroundLoad) {
            print('⚠️ Background load failed due to permission, returning empty list');
            return [];
          }
          
          // Throw a more user-friendly error
          throw Exception('Permission required: Please grant "Display over other apps" permission in Android settings for this app to access installed applications.');
        }
      }

      // Return cached data as fallback if available
      if (useCache && _cachedApps != null && _cachedApps!.isNotEmpty) {
        print('⚠️ Returning cached apps as fallback (${_cachedApps!.length} apps)');
        final result = _cachedApps!.skip(offset);
        return maxResults != null ? result.take(maxResults).toList() : result.toList();
      }

      // For background loads, return empty list instead of throwing
      if (backgroundLoad) {
        print('⚠️ Background load failed, returning empty list');
        return [];
      }

      // Throw the error instead of falling back to sample apps
      throw Exception('Failed to get installed apps: $e');
    }

    // If we reach here, method channel returned null/empty - throw error
    throw Exception('Method channel returned null or empty result');
  }

  /// Sync fallback processing when background service fails
  static List<AppInfo> _processSyncFallback(List<dynamic> result) {
    final apps = <AppInfo>[];
    for (final appData in result) {
      try {
        final app = AppInfo.fromMap(Map<String, dynamic>.from(appData));
        if (!app.isSystemApp && app.packageName.isNotEmpty) {
          apps.add(app);
        }
      } catch (e) {
        continue; // Skip invalid apps
      }
    }

    // Sort by app name for better UX
    apps.sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));

    // Cache the results
    _cachedApps = apps;
    _lastCacheTime = DateTime.now();

    return apps;
  }

  /// Get cloned apps with enhanced error handling and fallback
  static Future<List<AppInfo>> getClonedApps() async {
    print('🔍 Starting getClonedApps...');
    
    try {
      // Try to get from native first
      print('🔄 Calling native getClonedApps...');
      final dynamic nativeResult = await _invokeOptimized('getClonedApps', {});
      
      print('📋 Native result type: ${nativeResult.runtimeType}');
      print('📋 Native result: $nativeResult');
      
      if (nativeResult != null && nativeResult is List) {
        print('✅ Native result is a list with ${nativeResult.length} items');
        final List<AppInfo> clonedApps = [];
        
        for (int i = 0; i < nativeResult.length; i++) {
          final item = nativeResult[i];
          print('🔍 Processing item $i: ${item.runtimeType} - $item');
          
          try {
            // Convert Map<Object?, Object?> to Map<String, dynamic> safely
            Map<String, dynamic> appData;
            if (item is Map<String, dynamic>) {
              appData = item;
            } else if (item is Map) {
              // Handle Map<Object?, Object?> conversion more safely
              appData = <String, dynamic>{};
              item.forEach((key, value) {
                if (key != null) {
                  final keyStr = key.toString();
                  // Handle different value types safely
                  if (value != null) {
                    appData[keyStr] = value;
                  } else {
                    appData[keyStr] = null;
                  }
                }
              });
            } else {
              print('❌ Skipping invalid item: ${item.runtimeType}');
              continue; // Skip invalid items
            }
            
            print('📱 App data: $appData');
            
            if (appData.containsKey('packageName') && appData.containsKey('appName')) {
              final appInfo = AppInfo(
                packageName: appData['packageName'] ?? '',
                appName: appData['appName'] ?? '',
                isCloned: appData['isCloned'] ?? true,
                clonedAppId: appData['id'],
                icon: null, // Will be loaded separately for performance
              );
              clonedApps.add(appInfo);
              print('✅ Added cloned app: ${appInfo.appName} (${appInfo.packageName})');
            } else {
              print('❌ Missing required fields in app data: $appData');
            }
          } catch (e) {
            print('❌ Error parsing cloned app item $i: $e');
          }
        }
        
        if (clonedApps.isNotEmpty) {
          print('🎯 Returning ${clonedApps.length} cloned apps from native');
          return clonedApps;
        } else {
          print('⚠️ No valid cloned apps found in native result');
        }
      } else {
        print('⚠️ Native result is null or not a list');
      }
    } catch (e) {
      print('❌ Error getting cloned apps from native: $e');
    }
    
    // Fallback to SharedPreferences if native method fails
    print('🔄 Falling back to SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    final clonedAppsJson = prefs.getStringList(_clonedAppsKey) ?? [];
    print('📦 SharedPreferences has ${clonedAppsJson.length} stored cloned apps');

    List<AppInfo> clonedApps = [];
    for (String appJson in clonedAppsJson) {
      try {
        final parts = appJson.split('|');
        if (parts.length >= 3) {
          final cloneId = int.tryParse(parts[2]) ?? 1;
          final storageUsage = await DataIsolationService.getClonedAppStorageUsage(parts[1], cloneId);

          clonedApps.add(AppInfo(
            appName: parts[0],
            packageName: parts[1],
            isCloned: true,
            displayName: parts.length > 3 ? parts[3] : 'Clone $cloneId',
            cloneCount: cloneId,
            clonedAppId: cloneId, // Set the cloned app ID
          ));
          print('✅ Added from SharedPreferences: ${parts[0]} (ID: $cloneId)');
        } else if (parts.length >= 2) {
          // Legacy format support
          clonedApps.add(AppInfo(
            appName: parts[0],
            packageName: parts[1],
            isCloned: true,
            displayName: parts.length > 2 ? parts[2] : null,
            clonedAppId: 1, // Default ID for legacy format
          ));
          print('✅ Added legacy format: ${parts[0]}');
        }
      } catch (e) {
        print('Error parsing cloned app: $e');
      }
    }

    print('🎯 Returning ${clonedApps.length} cloned apps from SharedPreferences fallback');
    return clonedApps;
  }

  /// Clone an app with optimized performance (allows multiple clones)
  static Future<bool> cloneApp(String packageName, {String? customName}) async {
    try {
      // Get next clone ID quickly (removed restriction for multiple clones)
      final cloneId = await _getNextCloneId(packageName);

      // Try native cloning with timeout to prevent hanging
      try {
        final dynamic rawResult = await _optimizer.invokeMethod(
          _channelName,
          'cloneApp',
          {
            'packageName': packageName,
            'cloneId': cloneId,
            'customName': customName,
            'fastMode': true, // Enable fast cloning mode
            'skipValidation': true, // Skip validation for speed
          },
          const Duration(seconds: 3), // Quick timeout
        );
        
        // Convert the result to Map<String, dynamic> safely
        Map<String, dynamic>? result;
        if (rawResult is Map<String, dynamic>) {
          result = rawResult;
        } else if (rawResult is Map) {
          // Handle Map<Object?, Object?> conversion more safely
          result = <String, dynamic>{};
          rawResult.forEach((key, value) {
            if (key != null && value != null) {
              result![key.toString()] = value;
            }
          });
        }

        if (result != null && result['success'] == true) {
          // Create isolated data directory synchronously to ensure proper isolation
          await DataIsolationService.createIsolatedDataDirectory(packageName, cloneId);

          // Save clone info with custom name support
          await _addToClonedApps(packageName, cloneId, customName: customName);

          // Clear cache to reflect new clone
          _cachedApps = null;
          _cachedClonedApps = null;

          return true;
        }
      } catch (e) {
        print('Native cloning timeout or error: $e');
        // Continue to fallback
      }
    } catch (e) {
      print('Error in cloning setup: $e');
    }

    // Fallback: Simulate cloning for demo (fast mode)
    try {
      final fallbackCloneId = await _getNextCloneId(packageName);
      await DataIsolationService.createIsolatedDataDirectory(packageName, fallbackCloneId);
      await _addToClonedApps(packageName, fallbackCloneId, customName: customName);

      // Clear cache
      _cachedApps = null;
      _cachedClonedApps = null;

      return true;
    } catch (e) {
      print('Error in fallback cloning: $e');
      return false;
    }
  }

  /// Rename a cloned app
  static Future<bool> renameClonedApp(String packageName, int cloneId, String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clonedAppsJson = prefs.getStringList(_clonedAppsKey) ?? [];

      // Find and update the specific clone
      final updatedApps = clonedAppsJson.map((appJson) {
        final parts = appJson.split('|');
        if (parts.length >= 3 && parts[1] == packageName && int.tryParse(parts[2]) == cloneId) {
          // Update the display name (4th part)
          return '${parts[0]}|${parts[1]}|${parts[2]}|$newName';
        }
        return appJson;
      }).toList();

      await prefs.setStringList(_clonedAppsKey, updatedApps);

      // Clear cache to reflect changes
      _cachedClonedApps = null;

      return true;
    } catch (e) {
      print('Error renaming cloned app: $e');
      return false;
    }
  }

  /// Remove a cloned app
  static Future<bool> removeClonedApp(String packageName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('removeClonedApp', {
        'packageName': packageName,
      });
      
      if (result == true) {
        await _removeFromClonedApps(packageName);
        return true;
      }
    } catch (e) {
      print('Error removing cloned app: $e');
    }

    // Fallback: Remove from local storage
    await _removeFromClonedApps(packageName);
    return true;
  }

  /// Update app display name
  static Future<void> updateAppDisplayName(String packageName, String displayName) async {
    final prefs = await SharedPreferences.getInstance();
    final clonedApps = prefs.getStringList(_clonedAppsKey) ?? [];
    
    for (int i = 0; i < clonedApps.length; i++) {
      final parts = clonedApps[i].split('|');
      if (parts.length >= 2 && parts[1] == packageName) {
        clonedApps[i] = '${parts[0]}|${parts[1]}|$displayName';
        break;
      }
    }
    
    await prefs.setStringList(_clonedAppsKey, clonedApps);
  }

  /// Get app icon with advanced memory management and caching
  static Future<Uint8List?> getAppIcon(String packageName) async {
    // Check memory manager cache first
    final cachedIcon = MemoryManager.instance.getCachedIcon(packageName);
    if (cachedIcon != null) {
      return cachedIcon;
    }

    try {
      // Android returns base64 string, so we need to get it as String first
      final String? base64IconData = await _invokeOptimized<String>('getAppIcon', {
        'packageName': packageName,
        'compressed': true, // Request compressed icons for better performance
        'size': 64, // Standard icon size
        'quality': 80, // Balanced quality/size ratio
      }, const Duration(seconds: 2)); // Add timeout

      if (base64IconData != null && base64IconData.isNotEmpty) {
        try {
          // Convert base64 string to Uint8List
          final iconData = base64Decode(base64IconData);

          // Cache the icon using memory manager
          MemoryManager.instance.cacheIcon(packageName, iconData);

          return iconData;
        } catch (e) {
          print('Error decoding base64 icon for $packageName: $e');
          return null;
        }
      }

      return null;
    } catch (e) {
      print('Error getting app icon: $e');
      return null;
    }
  }
  
  /// Clear icon cache to free memory
  static void clearIconCache() {
    _iconCache.clear();
  }
  
  /// Clear all caches
  static void clearAllCaches() {
    _cachedApps = null;
    _lastCacheTime = null;
    _iconCache.clear();
  }

  /// Get cached apps (used for fallback)
  static List<AppInfo>? getCachedApps() {
    return _cachedApps;
  }

  /// Load more apps with pagination
  static Future<List<AppInfo>> loadMoreApps({
    required int offset,
    required int limit,
    bool includeIcons = true,
  }) async {
    return await getInstalledApps(
      offset: offset,
      maxResults: limit,
      includeIcons: includeIcons,
      useCache: true,
      optimizeForSpeed: true,
    );
  }

  /// Launch an app by package name
  static Future<bool> launchApp(String packageName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('launchApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      print('Error launching app: $e');
      return false;
    }
  }

  /// Launch cloned app
  static Future<bool> launchClonedApp(String packageName, {int? clonedAppId}) async {
    try {
      final Map<String, dynamic> params = {
        'packageName': packageName,
      };
      
      // Add cloned app ID if provided
      if (clonedAppId != null) {
        params['id'] = clonedAppId;
      }
      
      final dynamic result = await _invokeOptimized('launchClonedApp', params);
      
      // Handle different response types from native code
      if (result is bool) {
        return result;
      } else if (result is Map) {
        // Native code returns a Map with success info
        return result['success'] == true;
      } else {
        return false;
      }
    } catch (e) {
      print('Error launching cloned app: $e');
      return false;
    }
  }

  /// Check if app can be cloned
  static Future<bool> canCloneApp(String packageName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('canCloneApp', {
        'packageName': packageName,
      });
      return result ?? true; // Default to true for demo
    } catch (e) {
      print('Error checking if app can be cloned: $e');
      return true; // Default to true for demo
    }
  }

  /// Get app usage statistics
  static Future<Map<String, dynamic>?> getAppUsageStats(String packageName) async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getAppUsageStats', {
        'packageName': packageName,
      });
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting app usage stats: $e');
      return null;
    }
  }

  /// Advanced Features for Cloned Apps

  /// Optimize memory usage
  static Future<Map<String, dynamic>?> optimizeMemory() async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('optimizeMemory');
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error optimizing memory: $e');
      return null;
    }
  }

  /// Get memory information
  static Future<Map<String, dynamic>?> getMemoryInfo() async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getMemoryInfo');
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting memory info: $e');
      return null;
    }
  }

  /// Get instance statistics for a cloned app
  static Future<Map<String, dynamic>?> getInstanceStatistics(String packageName, String virtualSpaceId) async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getInstanceStatistics', {
        'packageName': packageName,
        'virtualSpaceId': virtualSpaceId,
      });
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting instance statistics: $e');
      return null;
    }
  }

  /// Get global statistics
  static Future<Map<String, dynamic>?> getGlobalStatistics() async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getGlobalStatistics');
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting global statistics: $e');
      return null;
    }
  }

  /// Analyze clone suggestions
  static Future<List<Map<String, dynamic>>> analyzeCloneSuggestions() async {
    try {
      final List<dynamic>? result = await _invokeOptimized<List<dynamic>>('analyzeCloneSuggestions');
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error analyzing clone suggestions: $e');
      return [];
    }
  }

  /// Get saved clone suggestions
  static Future<List<Map<String, dynamic>>> getCloneSuggestions() async {
    try {
      final List<dynamic>? result = await _invokeOptimized<List<dynamic>>('getCloneSuggestions');
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error getting clone suggestions: $e');
      return [];
    }
  }

  /// Analyze specific app for cloning
  static Future<Map<String, dynamic>?> analyzeSpecificApp(String packageName) async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('analyzeSpecificApp', {
        'packageName': packageName,
      });
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error analyzing specific app: $e');
      return null;
    }
  }

  /// Virtual Storage Management
  
  /// Create virtual file system for a cloned app
  static Future<bool> createVirtualFileSystem(String virtualSpaceId, String packageName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('createVirtualFileSystem', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      print('Error creating virtual file system: $e');
      return false;
    }
  }

  /// Get virtual storage statistics
  static Future<Map<String, dynamic>?> getVirtualStorageStats(String virtualSpaceId, String packageName) async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getVirtualStorageStats', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
      });
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting virtual storage stats: $e');
      return null;
    }
  }

  /// Copy file to virtual space
  static Future<bool> copyFileToVirtualSpace(String virtualSpaceId, String packageName, String sourcePath, String targetPath) async {
    try {
      final bool? result = await _invokeOptimized<bool>('copyFileToVirtualSpace', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
        'sourcePath': sourcePath,
        'targetPath': targetPath,
      });
      return result ?? false;
    } catch (e) {
      print('Error copying file to virtual space: $e');
      return false;
    }
  }

  /// Read file from virtual space
  static Future<Uint8List?> readFileFromVirtualSpace(String virtualSpaceId, String packageName, String filePath) async {
    try {
      final Uint8List? result = await _invokeOptimized<Uint8List>('readFileFromVirtualSpace', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
        'filePath': filePath,
      });
      return result;
    } catch (e) {
      print('Error reading file from virtual space: $e');
      return null;
    }
  }

  /// Write file to virtual space
  static Future<bool> writeFileToVirtualSpace(String virtualSpaceId, String packageName, String filePath, Uint8List data) async {
    try {
      final bool? result = await _invokeOptimized<bool>('writeFileToVirtualSpace', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
        'filePath': filePath,
        'data': data,
      });
      return result ?? false;
    } catch (e) {
      print('Error writing file to virtual space: $e');
      return false;
    }
  }

  /// Delete file from virtual space
  static Future<bool> deleteFileFromVirtualSpace(String virtualSpaceId, String packageName, String filePath) async {
    try {
      final bool? result = await _invokeOptimized<bool>('deleteFileFromVirtualSpace', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      print('Error deleting file from virtual space: $e');
      return false;
    }
  }

  /// List files in virtual space directory
  static Future<List<Map<String, dynamic>>> listVirtualSpaceFiles(String virtualSpaceId, String packageName, String directoryPath) async {
    try {
      final List<dynamic>? result = await _invokeOptimized<List<dynamic>>('listVirtualSpaceFiles', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
        'directoryPath': directoryPath,
      });
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error listing virtual space files: $e');
      return [];
    }
  }

  /// Cleanup virtual storage
  static Future<bool> cleanupVirtualStorage(String virtualSpaceId, String packageName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('cleanupVirtualStorage', {
        'virtualSpaceId': virtualSpaceId,
        'packageName': packageName,
      });
      return result ?? false;
    } catch (e) {
      print('Error cleaning up virtual storage: $e');
      return false;
    }
  }

  /// Update cloned app display name
  static Future<bool> updateClonedAppDisplayName(String packageName, String displayName) async {
    try {
      final bool? result = await _invokeOptimized<bool>('updateClonedAppDisplayName', {
        'packageName': packageName,
        'displayName': displayName,
      });
      
      if (result == true) {
        // Also update local storage
        await updateAppDisplayName(packageName, displayName);
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating cloned app display name: $e');
      // Fallback to local update
      await updateAppDisplayName(packageName, displayName);
      return true;
    }
  }

  /// Get detailed cloned apps information
  static Future<List<Map<String, dynamic>>> getDetailedClonedApps() async {
    try {
      final List<dynamic>? result = await _invokeOptimized<List<dynamic>>('getClonedApps');
      return result?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print('Error getting detailed cloned apps: $e');
      return [];
    }
  }

  /// Get virtual space information
  static Future<Map<String, dynamic>?> getVirtualSpaceInfo(String virtualSpaceId) async {
    try {
      final Map<dynamic, dynamic>? result = await _invokeOptimized<Map<dynamic, dynamic>>('getVirtualSpaceInfo', {
        'virtualSpaceId': virtualSpaceId,
      });
      return result?.cast<String, dynamic>();
    } catch (e) {
      print('Error getting virtual space info: $e');
      return null;
    }
  }

  /// Private helper methods
  static Future<Set<String>> _getClonedPackageNames() async {
    final prefs = await SharedPreferences.getInstance();
    final clonedApps = prefs.getStringList(_clonedAppsKey) ?? [];
    
    return clonedApps.map((app) {
      final parts = app.split('|');
      return parts.length >= 2 ? parts[1] : '';
    }).where((pkg) => pkg.isNotEmpty).toSet();
  }

  static Future<void> _addToClonedApps(String packageName, int cloneId, {String? customName}) async {
    final prefs = await SharedPreferences.getInstance();
    final clonedApps = prefs.getStringList(_clonedAppsKey) ?? [];

    // Get app name from installed apps (optimized)
      String appName = 'Unknown';
      if (_cachedApps != null) {
        final app = _cachedApps!.firstWhere(
          (app) => app.packageName == packageName,
          orElse: () => AppInfo(appName: 'Unknown', packageName: packageName),
        );
        appName = app.appName;
      } else {
        // Fallback to method channel for app name only
        try {
          final result = await _invokeOptimized<String>('getAppName', {'packageName': packageName});
          appName = result ?? 'Unknown';
        } catch (e) {
          print('Error getting app name: $e');
        }
      }

    // Create display name
    final displayName = customName ?? 'Clone $cloneId';

    // Format: appName|packageName|cloneId|displayName
    final appEntry = '$appName|$packageName|$cloneId|$displayName';

    // Always add (removed duplicate check for multiple clones support)
    clonedApps.add(appEntry);
    await prefs.setStringList(_clonedAppsKey, clonedApps);
  }

  static Future<int> _getNextCloneId(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final clonedApps = prefs.getStringList(_clonedAppsKey) ?? [];

    int maxId = 0;
    for (String entry in clonedApps) {
      final parts = entry.split('|');
      if (parts.length >= 3 && parts[1] == packageName) {
        final cloneId = int.tryParse(parts[2]) ?? 0;
        if (cloneId > maxId) {
          maxId = cloneId;
        }
      }
    }

    return maxId + 1;
  }

  static Future<void> _removeFromClonedApps(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final clonedApps = prefs.getStringList(_clonedAppsKey) ?? [];
    
    clonedApps.removeWhere((app) {
      final parts = app.split('|');
      return parts.length >= 2 && parts[1] == packageName;
    });
    
    await prefs.setStringList(_clonedAppsKey, clonedApps);
  }

  /// Sample apps for demonstration when real device apps can't be fetched
  static List<AppInfo> _getSampleApps() {
    return [
      AppInfo(
        appName: 'WhatsApp',
        packageName: 'com.whatsapp',
        color: const Color(0xFF25D366),
      ),
      AppInfo(
        appName: 'Messenger',
        packageName: 'com.facebook.orca',
        color: const Color(0xFF0084FF),
      ),
      AppInfo(
        appName: 'Facebook',
        packageName: 'com.facebook.katana',
        color: const Color(0xFF1877F2),
      ),
      AppInfo(
        appName: 'Instagram',
        packageName: 'com.instagram.android',
        color: const Color(0xFFE4405F),
      ),
      AppInfo(
        appName: 'Snapchat',
        packageName: 'com.snapchat.android',
        color: const Color(0xFFFFFC00),
      ),
      AppInfo(
        appName: 'Google Podcasts',
        packageName: 'com.google.android.apps.podcasts',
        color: const Color(0xFF4285F4),
      ),
      AppInfo(
        appName: 'Telegram',
        packageName: 'org.telegram.messenger',
        color: const Color(0xFF0088CC),
      ),
      AppInfo(
        appName: 'Twitter',
        packageName: 'com.twitter.android',
        color: const Color(0xFF1DA1F2),
      ),
      AppInfo(
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        color: const Color(0xFF000000),
      ),
      AppInfo(
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        color: const Color(0xFFFF0000),
      ),
      AppInfo(
        appName: 'Gmail',
        packageName: 'com.google.android.gm',
        color: const Color(0xFFEA4335),
      ),
      AppInfo(
        appName: 'Chrome',
        packageName: 'com.android.chrome',
        color: const Color(0xFF4285F4),
      ),
      AppInfo(
        appName: 'Spotify',
        packageName: 'com.spotify.music',
        color: const Color(0xFF1DB954),
      ),
      AppInfo(
        appName: 'Netflix',
        packageName: 'com.netflix.mediaclient',
        color: const Color(0xFFE50914),
      ),
      AppInfo(
        appName: 'Amazon',
        packageName: 'com.amazon.mShop.android.shopping',
        color: const Color(0xFFFF9900),
      ),
      AppInfo(
        appName: 'Uber',
        packageName: 'com.ubercab',
        color: const Color(0xFF000000),
      ),
      AppInfo(
        appName: 'Maps',
        packageName: 'com.google.android.apps.maps',
        color: const Color(0xFF4285F4),
      ),
      AppInfo(
        appName: 'Photos',
        packageName: 'com.google.android.apps.photos',
        color: const Color(0xFF4285F4),
      ),
      AppInfo(
        appName: 'Discord',
        packageName: 'com.discord',
        color: const Color(0xFF5865F2),
      ),
      AppInfo(
        appName: 'Reddit',
        packageName: 'com.reddit.frontpage',
        color: const Color(0xFFFF4500),
      ),
    ];
  }

  // Advanced Performance Optimization Methods

  /// Enable background processing for better performance
  static void _enableBackgroundProcessing() {
    _backgroundProcessingEnabled = true;
  }

  /// Get fallback apps when main loading fails
  static List<AppInfo> _getFallbackApps() {
    return [
      AppInfo(
        packageName: 'com.android.settings',
        appName: 'Settings',
        icon: null,
        color: Colors.grey,
      ),
      AppInfo(
        packageName: 'com.android.chrome',
        appName: 'Chrome',
        icon: null,
        color: Colors.blue,
      ),
    ];
  }

  /// Preload installed apps in background
  static Future<void> _preloadInstalledApps() async {
    if (!_backgroundProcessingEnabled) return;

    try {
      // Load apps in background without blocking UI
      getInstalledApps(forceRefresh: false);
    } catch (e) {
      print('Background preload error: $e');
    }
  }

  /// Preload installed apps in background for better performance
  static Future<void> preloadInstalledApps() async {
    try {
      print('🔄 Preloading installed apps in background...');
      await getInstalledApps(
        forceRefresh: true,
        backgroundLoad: true,
        includeIcons: false,
        maxResults: 100,
      );
      print('✅ Apps preloaded successfully');
    } catch (e) {
      print('❌ Error preloading apps: $e');
    }
  }



  /// Preload cloned apps in background
  static Future<void> _preloadClonedApps() async {
    if (!_backgroundProcessingEnabled) return;

    try {
      // Load cloned apps in background
      getClonedApps();
    } catch (e) {
      print('Background cloned apps preload error: $e');
    }
  }

  /// Preload system information
  static Future<void> _preloadSystemInfo() async {
    if (!_backgroundProcessingEnabled) return;

    try {
      // Preload system info for faster access
      getMemoryInfo();
    } catch (e) {
      print('System info preload error: $e');
    }
  }

  /// Initialize performance monitoring
  static void _initializePerformanceMonitoring() {
    // Setup performance monitoring
    _performanceCache['initialized'] = DateTime.now();
  }

  /// Cleanup icon cache intelligently
  static void _cleanupIconCache() {
    if (_iconCache.length <= _maxIconCacheSize ~/ 2) return;

    // Remove half of the cache entries (simple LRU simulation)
    final keysToRemove = _iconCache.keys.take(_iconCache.length ~/ 2).toList();
    for (String key in keysToRemove) {
      _iconCache.remove(key);
    }
  }

  /// Batch process multiple operations for better performance
  static Future<List<T>> batchProcess<T>(
    List<Future<T> Function()> operations, {
    int? maxConcurrent,
  }) async {
    final concurrent = maxConcurrent ?? _maxConcurrentOperations;
    final results = <T>[];

    for (int i = 0; i < operations.length; i += concurrent) {
      final batch = operations.skip(i).take(concurrent);
      final batchResults = await Future.wait(
        batch.map((op) => op()),
        eagerError: false,
      );
      results.addAll(batchResults);
    }

    return results;
  }


}

