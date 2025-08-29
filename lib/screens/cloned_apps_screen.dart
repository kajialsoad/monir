import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/app_info.dart';
import '../services/app_service.dart';

class ClonedAppsScreen extends StatefulWidget {
  const ClonedAppsScreen({super.key});

  @override
  ClonedAppsScreenState createState() => ClonedAppsScreenState();
}

class ClonedAppsScreenState extends State<ClonedAppsScreen> with AutomaticKeepAliveClientMixin {
  List<AppInfo> clonedApps = [];
  bool isLoading = true;
  Map<String, dynamic>? memoryInfo;
  Map<String, dynamic>? globalStats;

  @override
  bool get wantKeepAlive => false; // Don't keep alive to allow refresh

  @override
  void initState() {
    super.initState();
    print('🚀 ClonedAppsScreen.initState() called - Screen is being initialized');
    _loadClonedApps();
    _loadSystemInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible
    _refreshClonedApps();
  }

  /// Refresh cloned apps list
  Future<void> refreshClonedApps() async {
    print('🔄 ClonedAppsScreen.refreshClonedApps() called');
    await _loadClonedApps();
  }

  /// Private refresh method for internal use
  Future<void> _refreshClonedApps() async {
    await refreshClonedApps();
  }

  Future<void> _loadClonedApps() async {
    if (!mounted) return;
    print('🔄 ClonedAppsScreen._loadClonedApps() called');

    try {
      // Load cloned apps with increased timeout
      final apps = await AppService.getClonedApps()
          .timeout(const Duration(seconds: 10));
      print('📱 ClonedAppsScreen received ${apps.length} cloned apps from AppService');

      if (mounted) {
        setState(() {
          clonedApps = apps;
          isLoading = false;
        });
        print('✅ ClonedAppsScreen state updated with ${clonedApps.length} apps, isLoading: $isLoading');
      }
    } catch (e) {
      print('❌ Error loading cloned apps in ClonedAppsScreen: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          clonedApps = []; // Set empty list instead of crashing
        });
        print('⚠️ ClonedAppsScreen set to empty state due to error');
      }
    }
  }

  Future<void> _loadSystemInfo() async {
    if (!mounted) return;

    try {
      // Load system info with very short timeout
      final futures = await Future.wait([
        AppService.getMemoryInfo().timeout(const Duration(seconds: 1)),
        AppService.getGlobalStatistics().timeout(const Duration(seconds: 1)),
      ]).timeout(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          memoryInfo = futures[0];
          globalStats = futures[1];
        });
      }
    } catch (e) {
      print('System info timeout/error: $e');
      // Don't show error to user, just skip system info
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshClonedApps,
      color: Colors.orange,
      backgroundColor: Colors.grey[900],
      child: Column(
        children: [
          // System Info Header
          _buildSystemInfoHeader(),
          
          // Apps Grid
          Expanded(
            child: clonedApps.isEmpty ? _buildEmptyState() : _buildAppsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemInfoHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Status',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.orange),
                onPressed: () {
                  _loadSystemInfo();
                  _optimizeMemory();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  'Memory',
                  memoryInfo != null 
                    ? '${((memoryInfo!['usedMemory'] ?? 0) / 1024 / 1024).toStringAsFixed(1)} MB'
                    : 'Loading...',
                  Icons.memory,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'Cloned Apps',
                  '${clonedApps.length}',
                  Icons.apps,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoCard(
                  'Total Launches',
                  globalStats != null 
                    ? '${globalStats!['totalLaunches'] ?? 0}'
                    : '0',
                  Icons.launch,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No cloned apps yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap the + button to clone your first app\nand enjoy multiple accounts!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: clonedApps.length,
      itemBuilder: (context, index) {
        final app = clonedApps[index];
        
        return GestureDetector(
          onTap: () => _launchClonedApp(app),
          onLongPress: () => _showAppOptions(app),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: app.color,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: app.icon != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          app.icon!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.android,
                              color: Colors.white,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : FutureBuilder<Uint8List?>(
                        future: AppService.getAppIcon(app.packageName),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                snapshot.data!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.android,
                                    color: Colors.white,
                                    size: 30,
                                  );
                                },
                              ),
                            );
                          }
                          return const Icon(
                            Icons.android,
                            color: Colors.white,
                            size: 30,
                          );
                        },
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                app.displayName ?? app.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (app.cloneCount > 1)
                Text(
                  '(${app.cloneCount})',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _launchClonedApp(AppInfo app) async {
    // Show immediate feedback with optimized UI
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Launching ${app.displayName ?? app.appName}...'),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(milliseconds: 800),
      ),
    );

    try {
      // Use optimized launch method for cloned apps
      final ok = app.isCloned
          ? await AppService.launchClonedApp(
              app.packageName,
              clonedAppId: app.clonedAppId,
            )
          : await AppService.launchApp(app.packageName);

      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${app.displayName ?? app.appName} launched successfully'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(milliseconds: 1500),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to launch ${app.displayName ?? app.appName}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching app: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _showAppOptions(AppInfo app) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              app.displayName ?? app.appName,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.launch, color: Colors.orange),
              title: const Text('Launch App', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _launchClonedApp(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Rename', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _renameApp(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.orange),
              title: const Text('View Statistics', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showAppStatistics(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage, color: Colors.orange),
              title: const Text('Manage Storage', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showStorageManagement(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.orange),
              title: const Text('Clone Again', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _cloneAgain(app);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Remove Clone', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _removeClone(app);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _renameApp(AppInfo app) {
    final controller = TextEditingController(text: app.displayName ?? app.appName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rename App', style: TextStyle(color: Colors.orange)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(context);

                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Renaming app...'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 1),
                  ),
                );

                // Use the new rename method
                final success = await AppService.renameClonedApp(
                  app.packageName,
                  app.cloneCount,
                  newName
                );

                if (success) {
                  setState(() {
                    app.displayName = newName;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('App renamed to "$newName"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to rename app'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _cloneAgain(AppInfo app) {
    AppService.cloneApp(app.packageName).then((_) {
      // Refresh the entire list to show new clone instantly
      _refreshClonedApps();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.appName} cloned again successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _removeClone(AppInfo app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Remove Clone', style: TextStyle(color: Colors.red)),
        content: Text(
          'Are you sure you want to remove ${app.displayName ?? app.appName}? This action cannot be undone.',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppService.removeClonedApp(app.packageName).then((_) {
                setState(() {
                  clonedApps.remove(app);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${app.appName} removed successfully!'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _optimizeMemory() async {
    try {
      final result = await AppService.optimizeMemory();
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Memory optimized: ${result['freedMemory'] ?? 0} MB freed'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSystemInfo(); // Refresh system info
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to optimize memory'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAppStatistics(AppInfo app) async {
    try {
      final stats = await AppService.getInstanceStatistics(app.packageName, app.packageName);
      final usageStats = await AppService.getAppUsageStats(app.packageName);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            '${app.displayName ?? app.appName} Statistics',
            style: const TextStyle(color: Colors.orange),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatRow('Launch Count', '${stats?['launchCount'] ?? 0}'),
                _buildStatRow('Total Runtime', '${stats?['totalRuntime'] ?? 0} min'),
                _buildStatRow('Storage Used', '${usageStats?['storageUsage'] ?? 0} MB'),
                _buildStatRow('Last Access', usageStats?['lastAccessTime'] ?? 'Never'),
                _buildStatRow('Memory Usage', '${stats?['memoryUsage'] ?? 0} MB'),
                const SizedBox(height: 16),
                const Text(
                  'Performance Metrics:',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStatRow('Avg Launch Time', '${stats?['avgLaunchTime'] ?? 0} ms'),
                _buildStatRow('Crash Count', '${stats?['crashCount'] ?? 0}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load statistics'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showStorageManagement(AppInfo app) async {
    try {
      final storageStats = await AppService.getVirtualStorageStats(app.packageName, app.packageName);
      final files = await AppService.listVirtualSpaceFiles(app.packageName, app.packageName, '/');
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            '${app.displayName ?? app.appName} Storage',
            style: const TextStyle(color: Colors.orange),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Storage Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('Total Size', '${storageStats?['totalSize'] ?? 0} MB'),
                      _buildStatRow('Used Space', '${storageStats?['usedSpace'] ?? 0} MB'),
                      _buildStatRow('Free Space', '${storageStats?['freeSpace'] ?? 0} MB'),
                      _buildStatRow('File Count', '${files.length}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // File List
                const Text(
                  'Files & Directories:',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: files.length,
                    itemBuilder: (context, index) {
                      final file = files[index];
                      final isDirectory = file['isDirectory'] ?? false;
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isDirectory ? Icons.folder : Icons.insert_drive_file,
                          color: isDirectory ? Colors.orange : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          file['name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        subtitle: Text(
                          '${file['size'] ?? 0} bytes',
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _cleanupStorage(app);
              },
              child: const Text('Cleanup', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load storage information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cleanupStorage(AppInfo app) async {
    try {
      final result = await AppService.cleanupVirtualStorage(app.packageName, app.packageName);
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage cleaned up for ${app.displayName ?? app.appName}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cleanup storage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

