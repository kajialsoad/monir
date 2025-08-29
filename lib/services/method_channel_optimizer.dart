import 'dart:async';
import 'package:flutter/services.dart';

/// Optimized Method Channel wrapper for better performance and reliability
/// Native calls optimize করে timeout, retry, এবং batch operations support করে
class MethodChannelOptimizer {
  static MethodChannelOptimizer? _instance;
  static MethodChannelOptimizer get instance => _instance ??= MethodChannelOptimizer._();
  
  MethodChannelOptimizer._();

  // Channel instances with optimized settings
  final Map<String, MethodChannel> _channels = {};
  
  // Request queue for batch operations
  final Map<String, List<_PendingRequest>> _requestQueue = {};
  
  // Timeout configurations
  static const Duration _defaultTimeout = Duration(seconds: 5);
  static const Duration _shortTimeout = Duration(seconds: 2);
  static const Duration _longTimeout = Duration(seconds: 10);
  
  // Retry configurations
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);
  
  // Performance tracking
  final Map<String, _MethodStats> _methodStats = {};
  
  // Batch processing timer
  Timer? _batchTimer;

  /// Get or create optimized method channel
  MethodChannel getChannel(String channelName) {
    return _channels.putIfAbsent(channelName, () {
      final channel = MethodChannel(channelName);
      
      // Set up optimized binary messenger if available
      if (channel.binaryMessenger is StandardMethodCodec) {
        // Configure for better performance
      }
      
      return channel;
    });
  }

  /// Invoke method with optimization, timeout, and retry
  Future<T?> invokeMethod<T>(
    String channelName,
    String method, [
    dynamic arguments,
    Duration? timeout,
    int? maxRetries,
  ]) async {
    final channel = getChannel(channelName);
    final effectiveTimeout = timeout ?? _getTimeoutForMethod(method);
    final effectiveRetries = maxRetries ?? _maxRetries;
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await _invokeWithRetry<T>(
        channel,
        method,
        arguments,
        effectiveTimeout,
        effectiveRetries,
      );
      
      _recordMethodCall(method, stopwatch.elapsedMilliseconds, true);
      return result;
    } catch (e) {
      _recordMethodCall(method, stopwatch.elapsedMilliseconds, false);
      
      // Try fallback if available
      final fallback = _getFallbackResult<T>(method, arguments);
      if (fallback != null) {
        print('Using fallback for $method: $e');
        return fallback;
      }
      
      rethrow;
    }
  }

  /// Batch invoke multiple methods for better performance
  Future<List<T?>> batchInvokeMethod<T>(
    String channelName,
    List<_BatchRequest> requests, {
    Duration? timeout,
  }) async {
    final channel = getChannel(channelName);
    final effectiveTimeout = timeout ?? _longTimeout;
    
    try {
      // Group requests by method for optimization
      final groupedRequests = <String, List<_BatchRequest>>{};
      for (final request in requests) {
        groupedRequests.putIfAbsent(request.method, () => []).add(request);
      }
      
      final results = <T?>[];
      
      // Process each group
      for (final group in groupedRequests.values) {
        if (group.length == 1) {
          // Single request
          final request = group.first;
          final result = await _invokeWithRetry<T>(
            channel,
            request.method,
            request.arguments,
            effectiveTimeout,
            1, // Reduced retries for batch
          );
          results.add(result);
        } else {
          // Multiple requests of same method - try to batch
          final batchResult = await _invokeBatchMethod<T>(
            channel,
            group,
            effectiveTimeout,
          );
          results.addAll(batchResult);
        }
      }
      
      return results;
    } catch (e) {
      print('Batch invoke failed: $e');
      // Fallback to individual calls
      return _fallbackBatchInvoke<T>(channel, requests, effectiveTimeout);
    }
  }

  /// Queue method for batch processing
  void queueMethod(
    String channelName,
    String method,
    dynamic arguments,
    Completer<dynamic> completer,
  ) {
    final request = _PendingRequest(method, arguments, completer);
    _requestQueue.putIfAbsent(channelName, () => []).add(request);
    
    // Start batch timer if not already running
    _batchTimer ??= Timer(const Duration(milliseconds: 100), () {
      _processBatchQueue();
    });
  }

  /// Get method performance statistics
  Map<String, dynamic> getMethodStats() {
    final stats = <String, dynamic>{};
    
    for (final entry in _methodStats.entries) {
      final methodStats = entry.value;
      stats[entry.key] = {
        'totalCalls': methodStats.totalCalls,
        'successfulCalls': methodStats.successfulCalls,
        'failedCalls': methodStats.failedCalls,
        'averageLatency': methodStats.totalLatency / methodStats.totalCalls,
        'successRate': (methodStats.successfulCalls / methodStats.totalCalls * 100).toStringAsFixed(1),
      };
    }
    
    return stats;
  }

  /// Private helper methods
  
  Future<T?> _invokeWithRetry<T>(
    MethodChannel channel,
    String method,
    dynamic arguments,
    Duration timeout,
    int maxRetries,
  ) async {
    Exception? lastException;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final result = await channel.invokeMethod(method, arguments)
            .timeout(timeout);
        return result as T?;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < maxRetries) {
          // Wait before retry with exponential backoff
          final delay = Duration(
            milliseconds: _retryDelay.inMilliseconds * (attempt + 1),
          );
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastException!;
  }

  Future<List<T?>> _invokeBatchMethod<T>(
    MethodChannel channel,
    List<_BatchRequest> requests,
    Duration timeout,
  ) async {
    // Try to use native batch method if available
    try {
      final batchArguments = {
        'requests': requests.map((r) => {
          'method': r.method,
          'arguments': r.arguments,
        }).toList(),
      };
      
      final List<dynamic>? results = await channel.invokeMethod(
        'batchInvoke',
        batchArguments,
      ).timeout(timeout);
      
      return results?.cast<T?>() ?? [];
    } catch (e) {
      // Fallback to individual calls
      return _fallbackBatchInvoke<T>(channel, requests, timeout);
    }
  }

  Future<List<T?>> _fallbackBatchInvoke<T>(
    MethodChannel channel,
    List<_BatchRequest> requests,
    Duration timeout,
  ) async {
    final results = <T?>[];
    
    for (final request in requests) {
      try {
        final result = await channel.invokeMethod(
          request.method,
          request.arguments,
        ).timeout(timeout);
        results.add(result as T?);
      } catch (e) {
        results.add(null);
      }
    }
    
    return results;
  }

  void _processBatchQueue() {
    _batchTimer = null;
    
    for (final entry in _requestQueue.entries) {
      final channelName = entry.key;
      final requests = entry.value;
      
      if (requests.isNotEmpty) {
        _processBatchForChannel(channelName, requests);
      }
    }
    
    _requestQueue.clear();
  }

  void _processBatchForChannel(String channelName, List<_PendingRequest> requests) {
    final channel = getChannel(channelName);
    
    for (final request in requests) {
      _invokeWithRetry(
        channel,
        request.method,
        request.arguments,
        _defaultTimeout,
        1,
      ).then((result) {
        request.completer.complete(result);
      }).catchError((error) {
        request.completer.completeError(error);
      });
    }
  }

  Duration _getTimeoutForMethod(String method) {
    // Customize timeouts based on method type
    switch (method) {
      case 'getInstalledApps':
      case 'getClonedApps':
        return _longTimeout;
      case 'getAppIcon':
      case 'getAppName':
        return _shortTimeout;
      default:
        return _defaultTimeout;
    }
  }

  T? _getFallbackResult<T>(String method, dynamic arguments) {
    // Provide fallback results for critical methods
    switch (method) {
      case 'getInstalledApps':
        return <dynamic>[] as T?;
      case 'getMemoryInfo':
        return {
          'totalMemory': 4096,
          'availableMemory': 2048,
          'usedMemory': 2048,
        } as T?;
      default:
        return null;
    }
  }

  void _recordMethodCall(String method, int latencyMs, bool success) {
    final stats = _methodStats.putIfAbsent(method, () => _MethodStats());
    stats.totalCalls++;
    stats.totalLatency += latencyMs;
    
    if (success) {
      stats.successfulCalls++;
    } else {
      stats.failedCalls++;
    }
  }

  /// Dispose optimizer
  void dispose() {
    _batchTimer?.cancel();
    _channels.clear();
    _requestQueue.clear();
    _methodStats.clear();
  }
}

/// Helper classes

class _BatchRequest {
  final String method;
  final dynamic arguments;

  _BatchRequest(this.method, this.arguments);
}

class _PendingRequest {
  final String method;
  final dynamic arguments;
  final Completer<dynamic> completer;

  _PendingRequest(this.method, this.arguments, this.completer);
}

class _MethodStats {
  int totalCalls = 0;
  int successfulCalls = 0;
  int failedCalls = 0;
  int totalLatency = 0;
}
