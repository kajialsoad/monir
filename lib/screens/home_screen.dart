import 'dart:async';
import 'package:flutter/material.dart';
import 'app_list_screen.dart';
import 'cloned_apps_screen.dart';
import '../services/permission_service.dart';
import '../services/app_service.dart';
import 'security_settings_screen.dart';
import 'performance_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  // Removed system information variables
  final GlobalKey<ClonedAppsScreenState> _clonedAppsKey = GlobalKey<ClonedAppsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    print('🏠 HomeScreen.initState() called - Creating screens');
    _screens = [
      ClonedAppsScreen(key: _clonedAppsKey),
      _buildSettingsScreen(),
    ];
    print('📱 HomeScreen: Created ${_screens.length} screens, selectedIndex: $_selectedIndex');
    // Preload apps in background for better performance
    _preloadAppsInBackground();
  }
  
  /// Preload apps in background for better performance
  void _preloadAppsInBackground() {
    Future.delayed(const Duration(milliseconds: 500), () {
      AppService.preloadInstalledApps();
    });
  }

  // Removed system info and global stats loading methods

  @override
  Widget build(BuildContext context) {
    print('🔄 HomeScreen.build() called - selectedIndex: $_selectedIndex, showing screen: ${_selectedIndex == 0 ? "ClonedAppsScreen" : "SettingsScreen"}');
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF6366F1)),
          onPressed: () => _showAboutDialog(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.apps,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'MultiSpace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF6366F1)),
            onPressed: () => _showAboutDialog(),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.apps_rounded),
              label: 'Apps',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            print('🎯 HomeScreen: FloatingActionButton pressed - Navigating to AppListScreen');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppListScreen()),
            );
            // Refresh cloned apps when returning from AppListScreen
            if (result == true && _clonedAppsKey.currentState != null) {
              print('🔄 HomeScreen: Refreshing ClonedAppsScreen after returning from AppListScreen');
              _clonedAppsKey.currentState!.refreshClonedApps();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'About MultiSpace',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Text(
          'MultiSpace allows you to clone and run multiple instances of your favorite apps with separate data and accounts.\n\nVersion: 1.0.0\nDeveloped with Flutter',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Removed system info, memory management, and global stats cards
          const SizedBox(height: 16),
          
          // Settings Options
          _buildSettingsOptions(),
        ],
      ),
    );
  }

  // Removed system information card method

  // Removed memory management card method

  // Removed global statistics card method

  Widget _buildSettingsOptions() {
    return Card(
      color: Colors.grey[850],
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: _showHelpSupport,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }

  // Removed memory optimization methods

  // Removed complex settings methods (Security, Performance, Backup)

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.orange),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MultiSpace App Cloner\nVersion 1.0.0\n\nFor support and feedback:\n• Email: support@multispace.com\n• Website: www.multispace.com\n• GitHub: github.com/multispace',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

