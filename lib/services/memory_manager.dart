import 'dart:async';
import 'dart:typed_data';
import 'dart:collection';

/// Advanced Memory Manager for optimal performance
/// Memory leaks prevent করে এবং efficient memory usage ensure করে
class MemoryManager {
  static MemoryManager? _instance;
  static MemoryManager get instance => _instance ??= MemoryManager._();
  
  MemoryManager._();

  // LRU Cache for icons with automatic cleanup
  final LRUCache<String, Uint8List> _iconCache = LRUCache<String, Uint8List>(100);
  
  // Weak references for temporary data
  final Map<String, WeakReference<dynamic>> _weakReferences = {};
  
  // Memory usage tracking
  int _currentMemoryUsage = 0;
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB limit
  
  // Cleanup timer
  Timer? _cleanupTimer;
  
  // Performance metrics
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  /// Initialize memory manager
  void initialize() {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performCleanup();
    });
    
    print('MemoryManager initialized with ${_maxMemoryUsage ~/ (1024 * 1024)}MB limit');
  }

  /// Store icon in cache with memory management
  void cacheIcon(String packageName, Uint8List iconData) {
    if (iconData.lengthInBytes > 1024 * 1024) { // Skip icons larger than 1MB
      print('Warning: Icon too large for $packageName: ${iconData.lengthInBytes} bytes');
      return;
    }

    // Check memory limit
    if (_currentMemoryUsage + iconData.lengthInBytes > _maxMemoryUsage) {
      _performEmergencyCleanup();
    }

    final oldData = _iconCache.get(packageName);
    if (oldData != null) {
      _currentMemoryUsage -= oldData.lengthInBytes;
    }

    _iconCache.put(packageName, iconData);
    _currentMemoryUsage += iconData.lengthInBytes;
    
    _recordCacheOperation(packageName, true);
  }

  /// Get icon from cache
  Uint8List? getCachedIcon(String packageName) {
    final icon = _iconCache.get(packageName);
    _recordCacheOperation(packageName, icon != null);
    return icon;
  }

  /// Store weak reference for temporary data
  void storeWeakReference(String key, dynamic data) {
    _weakReferences[key] = WeakReference(data);
  }

  /// Get data from weak reference
  T? getWeakReference<T>(String key) {
    final ref = _weakReferences[key];
    if (ref == null) return null;
    
    final data = ref.target;
    if (data == null) {
      _weakReferences.remove(key);
      return null;
    }
    
    return data as T?;
  }

  /// Perform routine cleanup
  void _performCleanup() {
    int freedMemory = 0;
    
    // Clean up weak references
    final keysToRemove = <String>[];
    for (final entry in _weakReferences.entries) {
      if (entry.value.target == null) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _weakReferences.remove(key);
    }

    // Clean up least used cache entries if memory usage is high
    if (_currentMemoryUsage > _maxMemoryUsage * 0.8) {
      final removedEntries = _iconCache.removeOldest(20);
      for (final entry in removedEntries) {
        freedMemory += entry.lengthInBytes;
      }
      _currentMemoryUsage -= freedMemory;
    }

    if (freedMemory > 0) {
      print('Memory cleanup: freed ${freedMemory ~/ 1024}KB, current usage: ${_currentMemoryUsage ~/ 1024}KB');
    }
  }

  /// Emergency cleanup when memory limit is reached
  void _performEmergencyCleanup() {
    print('Emergency memory cleanup triggered');
    
    int freedMemory = 0;
    
    // Remove 50% of cache entries
    final removedEntries = _iconCache.removeOldest(_iconCache.length ~/ 2);
    for (final entry in removedEntries) {
      freedMemory += entry.lengthInBytes;
    }
    
    _currentMemoryUsage -= freedMemory;
    
    // Clear all weak references
    _weakReferences.clear();
    
    print('Emergency cleanup: freed ${freedMemory ~/ 1024}KB');
  }

  /// Get memory statistics
  Map<String, dynamic> getMemoryStats() {
    final totalCacheHits = _cacheHits.values.fold(0, (sum, hits) => sum + hits);
    final totalCacheMisses = _cacheMisses.values.fold(0, (sum, misses) => sum + misses);
    final hitRate = totalCacheHits + totalCacheMisses > 0 
        ? (totalCacheHits / (totalCacheHits + totalCacheMisses) * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'currentMemoryUsage': _currentMemoryUsage,
      'maxMemoryUsage': _maxMemoryUsage,
      'memoryUsagePercent': (_currentMemoryUsage / _maxMemoryUsage * 100).toStringAsFixed(1),
      'iconCacheSize': _iconCache.length,
      'weakReferencesCount': _weakReferences.length,
      'cacheHitRate': '$hitRate%',
      'totalCacheHits': totalCacheHits,
      'totalCacheMisses': totalCacheMisses,
    };
  }

  /// Record cache operation for analytics
  void _recordCacheOperation(String key, bool isHit) {
    if (isHit) {
      _cacheHits[key] = (_cacheHits[key] ?? 0) + 1;
    } else {
      _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
    }
  }

  /// Clear all caches
  void clearAllCaches() {
    _iconCache.clear();
    _weakReferences.clear();
    _currentMemoryUsage = 0;
    _cacheHits.clear();
    _cacheMisses.clear();
    print('All caches cleared');
  }

  /// Dispose memory manager
  void dispose() {
    _cleanupTimer?.cancel();
    clearAllCaches();
    _instance = null;
  }
}

/// LRU Cache implementation for efficient memory management
class LRUCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache(this._maxSize);

  V? get(K key) {
    if (!_cache.containsKey(key)) return null;
    
    // Move to end (most recently used)
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxSize) {
      // Remove least recently used
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = value;
  }

  List<V> removeOldest(int count) {
    final removed = <V>[];
    final keysToRemove = _cache.keys.take(count).toList();
    
    for (final key in keysToRemove) {
      final value = _cache.remove(key);
      if (value != null) {
        removed.add(value);
      }
    }
    
    return removed;
  }

  void clear() {
    _cache.clear();
  }

  int get length => _cache.length;
  
  bool containsKey(K key) => _cache.containsKey(key);
}
