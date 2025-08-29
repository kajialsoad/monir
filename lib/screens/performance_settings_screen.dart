import 'package:flutter/material.dart';
import '../services/performance_service.dart';
import 'dart:async';

class PerformanceSettingsScreen extends StatefulWidget {
  const PerformanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PerformanceSettingsScreen> createState() => _PerformanceSettingsScreenState();
}

class _PerformanceSettingsScreenState extends State<PerformanceSettingsScreen> {
  final PerformanceService _performanceService = PerformanceService.instance;
  PerformanceStatus? _performanceStatus;
  List<PerformanceMetric> _performanceHistory = [];
  bool _isMonitoring = false;
  bool _isLoading = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPerformanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await _performanceService.getPerformanceStatus();
      final history = await _performanceService.getPerformanceHistory();
      
      setState(() {
        _performanceStatus = status;
        _performanceHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load performance data: $e');
    }
  }

  Future<void> _startMonitoring() async {
    try {
      setState(() {
        _isMonitoring = true;
      });
      
      // Start periodic refresh
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _loadPerformanceData();
      });
      
      _showSuccessSnackBar('Performance monitoring started');
    } catch (e) {
      _showErrorSnackBar('Failed to start monitoring: $e');
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      _refreshTimer?.cancel();
      setState(() {
        _isMonitoring = false;
      });
      _showSuccessSnackBar('Performance monitoring stopped');
    } catch (e) {
      _showErrorSnackBar('Failed to stop monitoring: $e');
    }
  }

  Future<void> _optimizePerformance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _performanceService.optimizePerformance();
      setState(() {
        _isLoading = false;
      });
      
      _showResultDialog('Performance Optimization', 
        result?.success == true ? 'Performance optimization completed successfully' : 
        result?.error ?? 'Performance optimization failed');
      _loadPerformanceData(); // Refresh data
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to optimize performance: $e');
    }
  }

  Future<void> _optimizeMemory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _performanceService.optimizeMemoryUsage();
      setState(() {
        _isLoading = false;
      });
      
      _showResultDialog('Memory Optimization', 
        'Memory optimized successfully\n'
        'Memory freed: ${result?.memoryFreed ?? 0} MB\n'
        'Cache cleared: ${result?.compressedCacheSize ?? 0} MB\n'
        'Temp files removed: ${result?.clearedTempFiles ?? 0}');
      _loadPerformanceData(); // Refresh data
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to optimize memory: $e');
    }
  }

  Future<void> _cleanupVirtualSpaces() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _performanceService.performGlobalCleanup();
      setState(() {
        _isLoading = false;
      });
      
      _showResultDialog('Virtual Space Cleanup', result ? 'Virtual space cleanup completed successfully' : 'Virtual space cleanup failed');
      _loadPerformanceData(); // Refresh data
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to cleanup virtual spaces: $e');
    }
  }

  Future<void> _performGlobalCleanup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _performanceService.performGlobalCleanup();
      setState(() {
        _isLoading = false;
      });
      
      _showResultDialog('Global Cleanup', result ? 'Global cleanup completed successfully' : 'Global cleanup failed');
      _loadPerformanceData(); // Refresh data
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to perform global cleanup: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonitoringSection(),
                  const SizedBox(height: 24),
                  _buildPerformanceStatusSection(),
                  const SizedBox(height: 24),
                  _buildOptimizationSection(),
                  const SizedBox(height: 24),
                  _buildPerformanceHistorySection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonitoringSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Monitoring',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isMonitoring 
                        ? 'Monitoring is active' 
                        : 'Monitoring is inactive',
                    style: TextStyle(
                      color: _isMonitoring ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isMonitoring ? _stopMonitoring : _startMonitoring,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMonitoring ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isMonitoring ? 'Stop' : 'Start'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStatusSection() {
    if (_performanceStatus == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No performance data available'),
        ),
      );
    }

    final status = _performanceStatus!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Performance Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusItem('CPU Status', status.cpuStatus, status.overallScore.toDouble()),
            _buildStatusItem('Memory Status', status.memoryStatus, status.overallScore.toDouble()),
            _buildStatusItem('Battery Status', status.batteryStatus, status.overallScore.toDouble()),
            const SizedBox(height: 8),
            Text(
              'Overall Score: ${status.overallScore}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Memory Status: ${status.memoryStatus}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Active Optimizations: ${status.activeOptimizations.length}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, double percentage) {
    Color color = Colors.green;
    if (percentage > 80) {
      color = Colors.red;
    } else if (percentage > 60) {
      color = Colors.orange;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Optimization',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildOptimizationButton(
                  'Optimize Performance',
                  Icons.speed,
                  Colors.blue,
                  _optimizePerformance,
                ),
                _buildOptimizationButton(
                  'Optimize Memory',
                  Icons.memory,
                  Colors.green,
                  _optimizeMemory,
                ),
                _buildOptimizationButton(
                  'Cleanup Virtual Spaces',
                  Icons.cleaning_services,
                  Colors.orange,
                  _cleanupVirtualSpaces,
                ),
                _buildOptimizationButton(
                  'Global Cleanup',
                  Icons.delete_sweep,
                  Colors.red,
                  _performGlobalCleanup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _loadPerformanceData,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_performanceHistory.isEmpty)
              const Text('No performance history available')
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _performanceHistory.length,
                  itemBuilder: (context, index) {
                    final metric = _performanceHistory[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.timeline,
                        color: _getMetricColor(metric.cpuUsage),
                      ),
                      title: Text(
                        'CPU: ${metric.cpuUsage.toStringAsFixed(1)}% | '
                        'Memory: ${metric.memoryUsage.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        'Battery: ${metric.batteryLevel.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 10),
                      ),
                      trailing: Text(
                        _formatTimestamp(metric.timestamp),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getMetricColor(double value) {
    if (value > 80) return Colors.red;
    if (value > 60) return Colors.orange;
    return Colors.green;
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}