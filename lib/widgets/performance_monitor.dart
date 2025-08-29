import 'package:flutter/material.dart';

/// Performance monitoring widget to prevent UI blocking
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String screenName;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.screenName,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  bool _isLoading = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    // Monitor loading time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_startTime != null) {
        final loadTime = DateTime.now().difference(_startTime!);
        if (loadTime.inMilliseconds > 1000) {
          print('Performance Warning: ${widget.screenName} took ${loadTime.inMilliseconds}ms to load');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            ),
          ),
      ],
    );
  }

  /// Show loading overlay
  void showLoading() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
  }

  /// Hide loading overlay
  void hideLoading() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Mixin for performance monitoring
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  bool _isPerformanceLoading = false;

  /// Execute a function with performance monitoring
  Future<R> withPerformanceMonitoring<R>(
    String operationName,
    Future<R> Function() operation,
  ) async {
    final startTime = DateTime.now();
    
    try {
      setPerformanceLoading(true);
      final result = await operation();
      
      final duration = DateTime.now().difference(startTime);
      if (duration.inMilliseconds > 500) {
        print('Performance Warning: $operationName took ${duration.inMilliseconds}ms');
      }
      
      return result;
    } finally {
      setPerformanceLoading(false);
    }
  }

  /// Set loading state
  void setPerformanceLoading(bool loading) {
    if (mounted && _isPerformanceLoading != loading) {
      setState(() {
        _isPerformanceLoading = loading;
      });
    }
  }

  /// Get current loading state
  bool get isPerformanceLoading => _isPerformanceLoading;
}
