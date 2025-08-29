import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class AppInfo {
  final String appName;
  final String packageName;
  final Uint8List? icon;
  final bool isSystemApp;
  final bool isCloned;
  final Color color;
  String? displayName;
  int cloneCount;
  int? clonedAppId; // ID for cloned apps from database

  AppInfo({
    required this.appName,
    required this.packageName,
    this.icon,
    this.isSystemApp = false,
    this.isCloned = false,
    this.color = Colors.blue,
    this.displayName,
    this.cloneCount = 1,
    this.clonedAppId,
  });

  factory AppInfo.fromMap(Map<String, dynamic> map) {
    // Convert base64 icon string to Uint8List if needed
    Uint8List? iconData;
    if (map['icon'] != null) {
      if (map['icon'] is String) {
        try {
          // Decode base64 string to Uint8List
          iconData = base64Decode(map['icon']);
        } catch (e) {
          print('Error decoding icon for ${map['packageName']}: $e');
          iconData = null;
        }
      } else if (map['icon'] is Uint8List) {
        iconData = map['icon'];
      }
    }

    return AppInfo(
      appName: map['appName'] ?? 'Unknown App',
      packageName: map['packageName'] ?? '',
      icon: iconData,
      isSystemApp: map['isSystemApp'] ?? false,
      isCloned: map['isCloned'] ?? false,
      color: _getColorFromPackage(map['packageName'] ?? ''),
      displayName: map['displayName'],
      cloneCount: map['cloneCount'] ?? 1,
      clonedAppId: map['clonedAppId'],
    );
  }

  static Color _getColorFromPackage(String packageName) {
    final colors = [
      const Color(0xFF25D366), // WhatsApp Green
      const Color(0xFF0084FF), // Messenger Blue
      const Color(0xFF1877F2), // Facebook Blue
      const Color(0xFFE4405F), // Instagram Pink
      const Color(0xFFFFFC00), // Snapchat Yellow
      const Color(0xFF4285F4), // Google Blue
      const Color(0xFF2196F3), // Material Blue
      const Color(0xFFFFC107), // Amber
      const Color(0xFFE91E63), // Pink
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF673AB7), // Deep Purple
      const Color(0xFF3F51B5), // Indigo
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFF009688), // Teal
      const Color(0xFF4CAF50), // Green
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFFCDDC39), // Lime
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFF795548), // Brown
    ];
    
    final hash = packageName.hashCode;
    return colors[hash.abs() % colors.length];
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'packageName': packageName,
      'icon': icon,
      'isSystemApp': isSystemApp,
      'isCloned': isCloned,
      'displayName': displayName,
      'cloneCount': cloneCount,
      'clonedAppId': clonedAppId,
    };
  }

  AppInfo copyWith({
    String? appName,
    String? packageName,
    Uint8List? icon,
    bool? isSystemApp,
    bool? isCloned,
    Color? color,
    String? displayName,
    int? cloneCount,
    int? clonedAppId,
  }) {
    return AppInfo(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      icon: icon ?? this.icon,
      isSystemApp: isSystemApp ?? this.isSystemApp,
      isCloned: isCloned ?? this.isCloned,
      color: color ?? this.color,
      displayName: displayName ?? this.displayName,
      cloneCount: cloneCount ?? this.cloneCount,
      clonedAppId: clonedAppId ?? this.clonedAppId,
    );
  }
}

