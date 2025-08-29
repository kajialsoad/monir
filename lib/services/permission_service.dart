import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for handling app permissions required for cloning functionality
class PermissionService {
  
  /// Check if all required permissions are granted
  static Future<bool> hasAllRequiredPermissions() async {
    if (kIsWeb) return true;
    
    // Check QUERY_ALL_PACKAGES permission first
    final systemPermissions = await checkSystemLevelPermissions();
    if (!(systemPermissions['android.permission.QUERY_ALL_PACKAGES'] ?? false)) {
      print('QUERY_ALL_PACKAGES permission missing');
      return false;
    }
    
    // Check other required permissions
    final permissions = await _getRequiredPermissions();
    for (Permission permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        return false;
      }
    }
    
    return true;
  }
  
  /// Request all required permissions
  static Future<bool> requestAllPermissions() async {
    if (kIsWeb) return true;
    
    // Check if we have QUERY_ALL_PACKAGES permission
    final hasQueryPermission = await checkSystemLevelPermissions();
    if (!(hasQueryPermission['android.permission.QUERY_ALL_PACKAGES'] ?? false)) {
      print('QUERY_ALL_PACKAGES permission not granted');
      return false;
    }
    
    // Request other required permissions
    final permissions = await _getRequiredPermissions();
    for (Permission permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        if (!result.isGranted) {
          print('Permission denied: $permission');
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Get list of required permissions
  static Future<List<Permission>> _getRequiredPermissions() async {
    if (kIsWeb) return <Permission>[];
    return [
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.accessNotificationPolicy,
      Permission.requestInstallPackages,
    ];
  }

  /// Get list of system-level permissions
  static Future<List<String>> _getSystemLevelPermissions() async {
    return [
      'android.permission.WRITE_SECURE_SETTINGS',
      'android.permission.INTERACT_ACROSS_USERS',
      'android.permission.MANAGE_USERS',
      'android.permission.CREATE_USERS',
      'android.permission.INSTALL_PACKAGES',
      'android.permission.DELETE_PACKAGES',
      'android.permission.CLEAR_APP_USER_DATA',
      'android.permission.FORCE_STOP_PACKAGES',
      'android.permission.GET_APP_OPS_STATS',
      'android.permission.MODIFY_APPOPS_MODE',
      'android.permission.PACKAGE_USAGE_STATS',
      'android.permission.QUERY_ALL_PACKAGES',
      'android.permission.MANAGE_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.READ_EXTERNAL_STORAGE',
    ];
  }
  
  /// Check specific permission status
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    if (kIsWeb) return PermissionStatus.granted;
    return await permission.status;
  }
  
  /// Request specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    if (kIsWeb) return PermissionStatus.granted;
    return await permission.request();
  }
  
  /// Show permission rationale dialog
  static Future<bool> showPermissionRationale(BuildContext context, String permissionName, String reason) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Permission Required',
          style: const TextStyle(color: Colors.orange),
        ),
        content: Text(
          'MultiSpace needs $permissionName permission to $reason.\n\nWould you like to grant this permission?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// Handle permission denied permanently
  static Future<void> handlePermissionDeniedPermanently(BuildContext context, String permissionName) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Permission Denied',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(
          '$permissionName permission has been permanently denied. Please enable it manually in app settings to use this feature.',
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
              if (!kIsWeb) {
                openAppSettings();
              }
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
  
  /// Request permissions with user-friendly flow
  static Future<bool> requestPermissionsWithFlow(BuildContext context) async {
    // On web, skip permission flow
    if (kIsWeb) return true;

    // Check if permissions are already granted
    if (await hasAllRequiredPermissions()) {
      return true;
    }
    
    // Show initial explanation
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Permissions Required',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Text(
          'MultiSpace needs several permissions to clone apps and manage their data securely:\n\n'
          '• Storage access - To create isolated app data\n'
          '• Notification access - For app management\n'
          '• Install packages - To install cloned apps\n\n'
          'These permissions ensure your cloned apps work properly with separate data.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldProceed) {
      return false;
    }
    
    // Request permissions
    final permissions = await _getRequiredPermissions();
    Map<Permission, PermissionStatus> statuses = {};
    
    for (Permission permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        String permissionName = _getPermissionDisplayName(permission);
        String reason = _getPermissionReason(permission);
        
        // Show rationale if needed
        if (status.isDenied) {
          final shouldRequest = await showPermissionRationale(context, permissionName, reason);
          if (!shouldRequest) {
            return false;
          }
        }
        
        // Request permission
        final result = await permission.request();
        statuses[permission] = result;
        
        // Handle permanently denied
        if (result.isPermanentlyDenied) {
          await handlePermissionDeniedPermanently(context, permissionName);
          return false;
        }
        
        if (!result.isGranted) {
          return false;
        }
      }
    }
    
    return true;
  }
  
  /// Get user-friendly permission name
  static String _getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'Storage';
      case Permission.manageExternalStorage:
        return 'Manage External Storage';
      case Permission.accessNotificationPolicy:
        return 'Notification Access';
      case Permission.requestInstallPackages:
        return 'Install Packages';
      default:
        return 'Unknown';
    }
  }
  
  /// Get permission usage reason
  static String _getPermissionReason(Permission permission) {
    switch (permission) {
      case Permission.storage:
        return 'create and manage isolated app data directories';
      case Permission.manageExternalStorage:
        return 'access and manage app files for cloning';
      case Permission.accessNotificationPolicy:
        return 'manage notifications for cloned apps';
      case Permission.requestInstallPackages:
        return 'install cloned app packages';
      case Permission.notification:
        return 'manage app notifications and alerts';
      default:
        return 'provide app cloning functionality';
    }
  }
  
  /// Check if permission is critical for app functionality
  static bool isPermissionCritical(Permission permission) {
    switch (permission) {
      case Permission.storage:
      case Permission.manageExternalStorage:
      case Permission.requestInstallPackages:
        return true;
      default:
        return false;
    }
  }
  
  /// Get permissions status summary
  static Future<Map<String, bool>> getPermissionsStatus() async {
    final permissions = await _getRequiredPermissions();
    Map<String, bool> status = {};
    
    for (Permission permission in permissions) {
      final permissionStatus = await permission.status;
      status[_getPermissionDisplayName(permission)] = permissionStatus.isGranted;
    }
    
    return status;
  }

  /// Check if device has root access
  static Future<bool> hasRootAccess() async {
    if (kIsWeb) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('hasRootAccess');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request root access
  static Future<bool> requestRootAccess() async {
    if (kIsWeb) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('requestRootAccess');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if device admin is enabled
  static Future<bool> isDeviceAdminEnabled() async {
    if (kIsWeb) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('isDeviceAdminEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request device admin privileges
  static Future<bool> requestDeviceAdmin(BuildContext context) async {
    if (kIsWeb) return false;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Device Administrator Required',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Text(
          'MultiSpace needs device administrator privileges to:\n\n'
          '• Manage app installations and uninstallations\n'
          '• Control app permissions and security\n'
          '• Provide advanced isolation features\n\n'
          'This will redirect you to system settings.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldRequest) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('requestDeviceAdmin');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if accessibility service is enabled
  static Future<bool> isAccessibilityServiceEnabled() async {
    if (kIsWeb) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('isAccessibilityServiceEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Request accessibility service
  static Future<bool> requestAccessibilityService(BuildContext context) async {
    if (kIsWeb) return false;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Accessibility Service Required',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Text(
          'MultiSpace needs accessibility service to:\n\n'
          '• Automatically manage app interactions\n'
          '• Provide seamless app switching\n'
          '• Monitor app behavior for security\n'
          '• Enable advanced automation features\n\n'
          'This will open accessibility settings.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Open Settings', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    ) ?? false;
    
    if (!shouldRequest) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('requestAccessibilityService');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check system-level permissions
  static Future<Map<String, bool>> checkSystemLevelPermissions() async {
    if (kIsWeb) return {};
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final permissions = await _getSystemLevelPermissions();
      Map<String, bool> status = {};
      
      for (String permission in permissions) {
        final result = await platform.invokeMethod('checkSystemPermission', {
          'permission': permission,
        });
        status[permission] = result ?? false;
      }
      
      return status;
    } catch (e) {
      return {};
    }
  }

  /// Request system-level permissions (requires root)
  static Future<bool> requestSystemLevelPermissions() async {
    if (kIsWeb) return false;
    
    try {
      const platform = MethodChannel('multispace_cloner/system');
      final result = await platform.invokeMethod('requestSystemLevelPermissions');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get comprehensive permission status
  static Future<Map<String, dynamic>> getComprehensivePermissionStatus() async {
    final basicPermissions = await getPermissionsStatus();
    final systemPermissions = await checkSystemLevelPermissions();
    final hasRoot = await hasRootAccess();
    final isDeviceAdmin = await isDeviceAdminEnabled();
    final isAccessibilityEnabled = await isAccessibilityServiceEnabled();
    
    return {
      'basicPermissions': basicPermissions,
      'systemPermissions': systemPermissions,
      'hasRootAccess': hasRoot,
      'isDeviceAdmin': isDeviceAdmin,
      'isAccessibilityEnabled': isAccessibilityEnabled,
      'securityLevel': _calculateSecurityLevel(basicPermissions, systemPermissions, hasRoot, isDeviceAdmin),
    };
  }

  /// Calculate security level based on permissions
  static String _calculateSecurityLevel(Map<String, bool> basic, Map<String, dynamic> system, bool hasRoot, bool isDeviceAdmin) {
    int score = 0;
    
    // Basic permissions (40 points max)
    final grantedBasic = basic.values.where((granted) => granted).length;
    score += (grantedBasic * 40 / basic.length).round();
    
    // System permissions (30 points max)
    if (system.isNotEmpty) {
      final grantedSystem = system.values.where((granted) => granted == true).length;
      score += (grantedSystem * 30 / system.length).round();
    }
    
    // Root access (20 points)
    if (hasRoot) score += 20;
    
    // Device admin (10 points)
    if (isDeviceAdmin) score += 10;
    
    if (score >= 90) return 'Maximum';
    if (score >= 70) return 'High';
    if (score >= 50) return 'Medium';
    if (score >= 30) return 'Low';
    return 'Minimal';
  }

  /// Show comprehensive permission setup flow
  static Future<bool> showComprehensivePermissionSetup(BuildContext context) async {
    return await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PermissionSetupScreen(),
      ),
    ) ?? false;
  }
}

/// Comprehensive permission setup screen
class PermissionSetupScreen extends StatefulWidget {
  const PermissionSetupScreen({super.key});

  @override
  State<PermissionSetupScreen> createState() => _PermissionSetupScreenState();
}

class _PermissionSetupScreenState extends State<PermissionSetupScreen> {
  Map<String, dynamic> permissionStatus = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissionStatus();
  }

  Future<void> _loadPermissionStatus() async {
    setState(() {
      isLoading = true;
    });

    final status = await PermissionService.getComprehensivePermissionStatus();
    setState(() {
      permissionStatus = status;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Permission Setup',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.orange),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityLevelCard(),
                  const SizedBox(height: 16),
                  _buildBasicPermissionsCard(),
                  const SizedBox(height: 16),
                  _buildAdvancedPermissionsCard(),
                  const SizedBox(height: 16),
                  _buildSystemPermissionsCard(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityLevelCard() {
    final securityLevel = permissionStatus['securityLevel'] ?? 'Unknown';
    Color levelColor = Colors.grey;
    
    switch (securityLevel) {
      case 'Maximum':
        levelColor = Colors.green;
        break;
      case 'High':
        levelColor = Colors.lightGreen;
        break;
      case 'Medium':
        levelColor = Colors.orange;
        break;
      case 'Low':
        levelColor = Colors.red;
        break;
      case 'Minimal':
        levelColor = Colors.red[800]!;
        break;
    }

    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: levelColor),
                const SizedBox(width: 8),
                const Text(
                  'Security Level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: levelColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: levelColor),
              ),
              child: Text(
                securityLevel,
                style: TextStyle(
                  color: levelColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicPermissionsCard() {
    final basicPermissions = Map<String, bool>.from(permissionStatus['basicPermissions'] ?? {});
    
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Basic Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...basicPermissions.entries.map(
              (entry) => _buildPermissionTile(
                entry.key,
                entry.value,
                Icons.check_circle,
                Icons.cancel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedPermissionsCard() {
    final hasRoot = permissionStatus['hasRootAccess'] ?? false;
    final isDeviceAdmin = permissionStatus['isDeviceAdmin'] ?? false;
    final isAccessibilityEnabled = permissionStatus['isAccessibilityEnabled'] ?? false;
    
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Advanced Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPermissionTile('Root Access', hasRoot, Icons.security, Icons.warning),
            _buildPermissionTile('Device Administrator', isDeviceAdmin, Icons.admin_panel_settings, Icons.warning),
            _buildPermissionTile('Accessibility Service', isAccessibilityEnabled, Icons.accessibility, Icons.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPermissionsCard() {
    final systemPermissions = Map<String, dynamic>.from(permissionStatus['systemPermissions'] ?? {});
    
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings_system_daydream, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'System Permissions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Requires root access',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (systemPermissions.isEmpty)
              const Text(
                'No system permissions available',
                style: TextStyle(color: Colors.grey),
              )
            else
              ...systemPermissions.entries.take(5).map(
                (entry) => _buildPermissionTile(
                  entry.key.split('.').last,
                  entry.value == true,
                  Icons.verified,
                  Icons.block,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(String name, bool granted, IconData grantedIcon, IconData deniedIcon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? grantedIcon : deniedIcon,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            granted ? 'Granted' : 'Denied',
            style: TextStyle(
              color: granted ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestBasicPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Request Basic Permissions',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _requestAdvancedPermissions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Request Advanced Permissions',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _refreshStatus,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Refresh Status',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _requestBasicPermissions() async {
    final granted = await PermissionService.requestPermissionsWithFlow(context);
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Basic permissions granted'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _loadPermissionStatus();
  }

  Future<void> _requestAdvancedPermissions() async {
    // Request device admin
    await PermissionService.requestDeviceAdmin(context);
    
    // Request accessibility service
    await PermissionService.requestAccessibilityService(context);
    
    // Request root access
    final hasRoot = await PermissionService.requestRootAccess();
    if (hasRoot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Root access granted'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    _loadPermissionStatus();
  }

  Future<void> _refreshStatus() async {
    _loadPermissionStatus();
  }
}
