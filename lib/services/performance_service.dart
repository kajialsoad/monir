import 'package:flutter/services.dart';

class PerformanceService {
  static const MethodChannel _channel = MethodChannel('multispace_cloner/performance');
  static PerformanceService? _instance;
  
  static PerformanceService get instance {
    _instance ??= PerformanceService._internal();
    return _instance!;
  }
  
  PerformanceService._internal();
  
  /// Initialize performance monitoring
  Future<bool> initializePerformanceMonitoring() async {
    try {
      final result = await _channel.invokeMethod('initializePerformanceMonitoring');
      return result as bool? ?? false;
    } catch (e) {
      print('Error initializing performance monitoring: $e');
      return false;
    }
  }
  
  /// Stop performance monitoring
  Future<bool> stopPerformanceMonitoring() async {
    try {
      final result = await _channel.invokeMethod('stopPerformanceMonitoring');
      return result as bool? ?? false;
    } catch (e) {
      print('Error stopping performance monitoring: $e');
      return false;
    }
  }
  
  /// Get current performance status
  Future<PerformanceStatus?> getPerformanceStatus() async {
    try {
      final result = await _channel.invokeMethod('getPerformanceStatus');
      if (result != null) {
        return PerformanceStatus.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Error getting performance status: $e');
      return null;
    }
  }
  
  /// Optimize performance
  Future<PerformanceOptimizationResult?> optimizePerformance() async {
    try {
      final result = await _channel.invokeMethod('optimizePerformance');
      if (result != null) {
        return PerformanceOptimizationResult.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Error optimizing performance: $e');
      return null;
    }
  }
  
  /// Get CPU usage percentage
  Future<double> getCpuUsage() async {
    try {
      final result = await _channel.invokeMethod('getCpuUsage');
      return (result as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      print('Error getting CPU usage: $e');
      return 0.0;
    }
  }
  
  /// Get memory information
  Future<MemoryInfo?> getMemoryInfo() async {
    try {
      final result = await _channel.invokeMethod('getMemoryInfo');
      if (result != null) {
        return MemoryInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Error getting memory info: $e');
      return null;
    }
  }
  
  /// Get battery information
  Future<BatteryInfo?> getBatteryInfo() async {
    try {
      final result = await _channel.invokeMethod('getBatteryInfo');
      if (result != null) {
        return BatteryInfo.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Error getting battery info: $e');
      return null;
    }
  }
  
  /// Register a background task
  Future<bool> registerBackgroundTask({
    required String id,
    required String name,
    required TaskPriority priority,
    String? virtualSpaceId,
  }) async {
    try {
      final result = await _channel.invokeMethod('registerBackgroundTask', {
        'id': id,
        'name': name,
        'priority': priority.name,
        'virtualSpaceId': virtualSpaceId,
      });
      return result as bool? ?? false;
    } catch (e) {
      print('Error registering background task: $e');
      return false;
    }
  }
  
  /// Unregister a background task
  Future<bool> unregisterBackgroundTask(String id) async {
    try {
      final result = await _channel.invokeMethod('unregisterBackgroundTask', {
        'id': id,
      });
      return result as bool? ?? false;
    } catch (e) {
      print('Error unregistering background task: $e');
      return false;
    }
  }
  
  /// Get performance metrics history
  Future<List<PerformanceMetric>> getPerformanceHistory({int hours = 24}) async {
    try {
      final result = await _channel.invokeMethod('getPerformanceHistory', {
        'hours': hours,
      });
      if (result != null) {
        final List<dynamic> metrics = result as List<dynamic>;
        return metrics
            .map((metric) => PerformanceMetric.fromMap(Map<String, dynamic>.from(metric)))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting performance history: $e');
      return [];
    }
  }
  
  /// Optimize memory usage
  Future<MemoryOptimizationResult?> optimizeMemoryUsage() async {
    try {
      final result = await _channel.invokeMethod('optimizeMemoryUsage');
      if (result != null) {
        return MemoryOptimizationResult.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      print('Error optimizing memory: $e');
      return null;
    }
  }
  
  /// Clean up virtual space
  Future<bool> cleanupVirtualSpace(String virtualSpaceId) async {
    try {
      final result = await _channel.invokeMethod('cleanupVirtualSpace', {
        'virtualSpaceId': virtualSpaceId,
      });
      return result as bool? ?? false;
    } catch (e) {
      print('Error cleaning up virtual space: $e');
      return false;
    }
  }
  
  /// Perform global cleanup
  Future<bool> performGlobalCleanup() async {
    try {
      final result = await _channel.invokeMethod('performGlobalCleanup');
      return result as bool? ?? false;
    } catch (e) {
      print('Error performing global cleanup: $e');
      return false;
    }
  }
}

// Data Models

class PerformanceStatus {
  final int overallScore;
  final String cpuStatus;
  final String memoryStatus;
  final String batteryStatus;
  final List<String> recommendations;
  final List<String> activeOptimizations;
  
  PerformanceStatus({
    required this.overallScore,
    required this.cpuStatus,
    required this.memoryStatus,
    required this.batteryStatus,
    required this.recommendations,
    required this.activeOptimizations,
  });
  
  factory PerformanceStatus.fromMap(Map<String, dynamic> map) {
    return PerformanceStatus(
      overallScore: map['overallScore'] as int? ?? 0,
      cpuStatus: map['cpuStatus'] as String? ?? 'Unknown',
      memoryStatus: map['memoryStatus'] as String? ?? 'Unknown',
      batteryStatus: map['batteryStatus'] as String? ?? 'Unknown',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      activeOptimizations: List<String>.from(map['activeOptimizations'] ?? []),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'overallScore': overallScore,
      'cpuStatus': cpuStatus,
      'memoryStatus': memoryStatus,
      'batteryStatus': batteryStatus,
      'recommendations': recommendations,
      'activeOptimizations': activeOptimizations,
    };
  }
}

class PerformanceOptimizationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? cpuOptimization;
  final Map<String, dynamic>? memoryOptimization;
  final Map<String, dynamic>? batteryOptimization;
  final Map<String, dynamic>? taskOptimization;
  final int timestamp;
  
  PerformanceOptimizationResult({
    required this.success,
    this.error,
    this.cpuOptimization,
    this.memoryOptimization,
    this.batteryOptimization,
    this.taskOptimization,
    required this.timestamp,
  });
  
  factory PerformanceOptimizationResult.fromMap(Map<String, dynamic> map) {
    return PerformanceOptimizationResult(
      success: map['success'] as bool? ?? false,
      error: map['error'] as String?,
      cpuOptimization: map['cpuOptimization'] != null ? Map<String, dynamic>.from(map['cpuOptimization']) : null,
      memoryOptimization: map['memoryOptimization'] != null ? Map<String, dynamic>.from(map['memoryOptimization']) : null,
      batteryOptimization: map['batteryOptimization'] != null ? Map<String, dynamic>.from(map['batteryOptimization']) : null,
      taskOptimization: map['taskOptimization'] != null ? Map<String, dynamic>.from(map['taskOptimization']) : null,
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}

class MemoryInfo {
  final int availableMemory;
  final int totalMemory;
  final bool lowMemory;
  final int threshold;
  final int usedMemory;
  final int dalvikPss;
  final int nativePss;
  final int otherPss;
  final int totalPss;
  final int cacheSize;
  
  MemoryInfo({
    required this.availableMemory,
    required this.totalMemory,
    required this.lowMemory,
    required this.threshold,
    required this.usedMemory,
    required this.dalvikPss,
    required this.nativePss,
    required this.otherPss,
    required this.totalPss,
    required this.cacheSize,
  });
  
  factory MemoryInfo.fromMap(Map<String, dynamic> map) {
    return MemoryInfo(
      availableMemory: (map['availableMemory'] as num?)?.toInt() ?? 0,
      totalMemory: (map['totalMemory'] as num?)?.toInt() ?? 0,
      lowMemory: map['lowMemory'] as bool? ?? false,
      threshold: (map['threshold'] as num?)?.toInt() ?? 0,
      usedMemory: (map['usedMemory'] as num?)?.toInt() ?? 0,
      dalvikPss: (map['dalvikPss'] as num?)?.toInt() ?? 0,
      nativePss: (map['nativePss'] as num?)?.toInt() ?? 0,
      otherPss: (map['otherPss'] as num?)?.toInt() ?? 0,
      totalPss: (map['totalPss'] as num?)?.toInt() ?? 0,
      cacheSize: (map['cacheSize'] as num?)?.toInt() ?? 0,
    );
  }
  
  double get memoryUsagePercentage {
    if (totalMemory == 0) return 0.0;
    return (usedMemory / totalMemory) * 100;
  }
  
  String get formattedAvailableMemory {
    return _formatBytes(availableMemory);
  }
  
  String get formattedTotalMemory {
    return _formatBytes(totalMemory);
  }
  
  String get formattedUsedMemory {
    return _formatBytes(usedMemory);
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

class BatteryInfo {
  final int level;
  final double temperature;
  final int voltage;
  final bool isCharging;
  final int health;
  final int status;
  
  BatteryInfo({
    required this.level,
    required this.temperature,
    required this.voltage,
    required this.isCharging,
    required this.health,
    required this.status,
  });
  
  factory BatteryInfo.fromMap(Map<String, dynamic> map) {
    return BatteryInfo(
      level: map['level'] as int? ?? -1,
      temperature: (map['temperature'] as num?)?.toDouble() ?? -1.0,
      voltage: map['voltage'] as int? ?? -1,
      isCharging: map['isCharging'] as bool? ?? false,
      health: map['health'] as int? ?? -1,
      status: map['status'] as int? ?? -1,
    );
  }
  
  String get batteryHealthText {
    switch (health) {
      case 2: return 'Good';
      case 3: return 'Overheat';
      case 4: return 'Dead';
      case 5: return 'Over Voltage';
      case 6: return 'Unspecified Failure';
      case 7: return 'Cold';
      default: return 'Unknown';
    }
  }
  
  String get batteryStatusText {
    switch (status) {
      case 1: return 'Unknown';
      case 2: return 'Charging';
      case 3: return 'Discharging';
      case 4: return 'Not Charging';
      case 5: return 'Full';
      default: return 'Unknown';
    }
  }
}

class PerformanceMetric {
  final int timestamp;
  final double cpuUsage;
  final int memoryUsage;
  final int batteryLevel;
  final double batteryTemperature;
  final bool isCharging;
  final int activeVirtualSpaces;
  final int backgroundTaskCount;
  
  PerformanceMetric({
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.batteryTemperature,
    required this.isCharging,
    required this.activeVirtualSpaces,
    required this.backgroundTaskCount,
  });
  
  factory PerformanceMetric.fromMap(Map<String, dynamic> map) {
    return PerformanceMetric(
      timestamp: map['timestamp'] as int? ?? 0,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (map['memoryUsage'] as num?)?.toInt() ?? 0,
      batteryLevel: map['batteryLevel'] as int? ?? 0,
      batteryTemperature: (map['batteryTemperature'] as num?)?.toDouble() ?? 0.0,
      isCharging: map['isCharging'] as bool? ?? false,
      activeVirtualSpaces: map['activeVirtualSpaces'] as int? ?? 0,
      backgroundTaskCount: map['backgroundTaskCount'] as int? ?? 0,
    );
  }
  
  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);
}

class MemoryOptimizationResult {
  final bool success;
  final String? error;
  final Map<String, dynamic> beforeMemory;
  final Map<String, dynamic> afterMemory;
  final int memoryFreed;
  final int clearedSpaces;
  final int compressedCacheSize;
  final int clearedTempFiles;
  
  MemoryOptimizationResult({
    required this.success,
    this.error,
    required this.beforeMemory,
    required this.afterMemory,
    required this.memoryFreed,
    required this.clearedSpaces,
    required this.compressedCacheSize,
    required this.clearedTempFiles,
  });
  
  factory MemoryOptimizationResult.fromMap(Map<String, dynamic> map) {
    return MemoryOptimizationResult(
      success: map['success'] as bool? ?? false,
      error: map['error'] as String?,
      beforeMemory: Map<String, dynamic>.from(map['beforeMemory'] ?? {}),
      afterMemory: Map<String, dynamic>.from(map['afterMemory'] ?? {}),
      memoryFreed: (map['memoryFreed'] as num?)?.toInt() ?? 0,
      clearedSpaces: map['clearedSpaces'] as int? ?? 0,
      compressedCacheSize: (map['compressedCacheSize'] as num?)?.toInt() ?? 0,
      clearedTempFiles: map['clearedTempFiles'] as int? ?? 0,
    );
  }
}

enum TaskPriority {
  low,
  medium,
  high,
  critical,
}