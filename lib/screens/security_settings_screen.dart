import 'package:flutter/material.dart';
import '../services/security_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final SecurityService _securityService = SecurityService.instance;
  
  SecurityStatus? _securityStatus;
  SecurityCheckResult? _lastSecurityCheck;
  bool _isLoading = false;
  bool _runtimeProtectionEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _initializeSecurity();
  }
  
  Future<void> _initializeSecurity() async {
    setState(() => _isLoading = true);
    
    try {
      await _securityService.initializeSecurity();
      await _loadSecurityStatus();
    } catch (e) {
      _showErrorSnackBar('Failed to initialize security: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _loadSecurityStatus() async {
    try {
      final status = await _securityService.getSecurityStatus();
      final checkResult = await _securityService.performSecurityCheck();
      
      setState(() {
        _securityStatus = status;
        _lastSecurityCheck = checkResult;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load security status: $e');
    }
  }
  
  Future<void> _performSecurityCheck() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _securityService.performSecurityCheck();
      setState(() => _lastSecurityCheck = result);
      
      _showInfoSnackBar('Security check completed');
    } catch (e) {
      _showErrorSnackBar('Security check failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _toggleRuntimeProtection() async {
    setState(() => _isLoading = true);
    
    try {
      bool success;
      if (_runtimeProtectionEnabled) {
        success = await _securityService.disableRuntimeProtection();
      } else {
        success = await _securityService.enableRuntimeProtection();
      }
      
      if (success) {
        setState(() => _runtimeProtectionEnabled = !_runtimeProtectionEnabled);
        _showInfoSnackBar(
          _runtimeProtectionEnabled 
            ? 'Runtime protection enabled' 
            : 'Runtime protection disabled'
        );
      } else {
        _showErrorSnackBar('Failed to toggle runtime protection');
      }
    } catch (e) {
      _showErrorSnackBar('Error toggling runtime protection: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testEncryption() async {
    setState(() => _isLoading = true);
    
    try {
      const testData = 'This is a test message for encryption';
      
      // Test AES encryption
      final encrypted = await _securityService.encryptData(testData);
      if (encrypted != null) {
        final decrypted = await _securityService.decryptData(encrypted);
        
        if (decrypted == testData) {
          _showInfoSnackBar('Encryption test passed ✓');
        } else {
          _showErrorSnackBar('Encryption test failed: Data mismatch');
        }
      } else {
        _showErrorSnackBar('Encryption test failed: Encryption returned null');
      }
    } catch (e) {
      _showErrorSnackBar('Encryption test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _testObfuscation() async {
    setState(() => _isLoading = true);
    
    try {
      const testString = 'Secret configuration data';
      
      // Test string obfuscation
      final obfuscated = await _securityService.obfuscateString(testString);
      final deobfuscated = await _securityService.deobfuscateString(obfuscated);
      
      if (deobfuscated == testString) {
        _showInfoSnackBar('Obfuscation test passed ✓');
      } else {
        _showErrorSnackBar('Obfuscation test failed: Data mismatch');
      }
    } catch (e) {
      _showErrorSnackBar('Obfuscation test failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showInfoSnackBar(String message) {
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
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  Color _getSecurityLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getSecurityLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'high':
        return Icons.security;
      case 'medium':
        return Icons.warning;
      case 'low':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSecurityStatus,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSecurityStatusCard(),
                  const SizedBox(height: 16),
                  _buildSecurityActionsCard(),
                  const SizedBox(height: 16),
                  _buildSecurityTestsCard(),
                  const SizedBox(height: 16),
                  _buildThreatsCard(),
                ],
              ),
            ),
    );
  }
  
  Widget _buildSecurityStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getSecurityLevelIcon(_securityStatus?.securityLevel),
                  color: _getSecurityLevelColor(_securityStatus?.securityLevel),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Security Status',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_securityStatus != null) ...[
              _buildStatusRow(
                'Security Level',
                _securityStatus!.securityLevel.toUpperCase(),
                _getSecurityLevelColor(_securityStatus!.securityLevel),
              ),
              _buildStatusRow(
                'Debugging Detected',
                _securityStatus!.isDebuggingDetected ? 'YES' : 'NO',
                _securityStatus!.isDebuggingDetected ? const Color.fromARGB(255, 255, 52, 37) : Colors.green,
              ),
              _buildStatusRow(
                'Root Detected',
                _securityStatus!.isRootDetected ? 'YES' : 'NO',
                _securityStatus!.isRootDetected ? Colors.red : Colors.green,
              ),
              _buildStatusRow(
                'Tamper Detected',
                _securityStatus!.isTamperDetected ? 'YES' : 'NO',
                _securityStatus!.isTamperDetected ? Colors.red : Colors.green,
              ),
              _buildStatusRow(
                'Emulator Detected',
                _securityStatus!.isEmulatorDetected ? 'YES' : 'NO',
                _securityStatus!.isEmulatorDetected ? Colors.red : Colors.green,
              ),
            ] else ...[
              const Text('Security status not available'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _performSecurityCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Run Security Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSecurityActionsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Runtime Protection'),
              subtitle: const Text('Enable real-time security monitoring'),
              value: _runtimeProtectionEnabled,
              onChanged: _isLoading ? null : (value) => _toggleRuntimeProtection(),
              activeColor: Colors.green,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.vpn_key, color: Colors.blue),
              title: const Text('Generate Master Key'),
              subtitle: const Text('Create new encryption master key'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _isLoading ? null : () async {
                final success = await _securityService.generateSecureKey('multispace_master_key');
                if (success) {
                  _showInfoSnackBar('Master key generated successfully');
                } else {
                  _showErrorSnackBar('Failed to generate master key');
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.verified_user, color: Colors.green),
              title: const Text('Check App Integrity'),
              subtitle: const Text('Verify application has not been tampered'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _isLoading ? null : () async {
                final isValid = await _securityService.checkAppIntegrity();
                if (isValid) {
                  _showInfoSnackBar('App integrity verified ✓');
                } else {
                  _showErrorSnackBar('App integrity check failed ✗');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSecurityTestsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Tests',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testEncryption,
                    icon: const Icon(Icons.lock),
                    label: const Text('Test Encryption'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testObfuscation,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Test Obfuscation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThreatsCard() {
    final threats = _lastSecurityCheck?.threats ?? [];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  threats.isEmpty ? Icons.check_circle : Icons.warning,
                  color: threats.isEmpty ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security Threats',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (threats.isEmpty) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'No security threats detected',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ] else ...[
              ...threats.map((threat) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        threat.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            if (_lastSecurityCheck != null) ...[
              const SizedBox(height: 12),
              Text(
                'Last check: ${_lastSecurityCheck!.timestamp.toString().substring(0, 19)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}