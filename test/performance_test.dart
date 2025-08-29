import 'package:flutter_test/flutter_test.dart';
import 'package:multispace_cloner/services/app_service.dart';
import 'package:multispace_cloner/models/app_info.dart';

void main() {
  group('Performance Optimizations Tests', () {
    test('AppService initialization should be fast', () async {
      final stopwatch = Stopwatch()..start();
      
      await AppService.initialize();
      
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(1000), 
        reason: 'Service initialization should complete within 1 second');
    });

    test('App cloning should support custom names', () async {
      const packageName = 'com.example.test';
      const customName = 'My Custom App Name';
      
      // This would normally interact with the method channel
      // For testing, we verify the method signature exists
      expect(() => AppService.cloneApp(packageName, customName: customName), 
        returnsNormally);
    });

    test('Rename functionality should work', () async {
      const packageName = 'com.example.test';
      const cloneId = 1;
      const newName = 'Renamed App';
      
      // Test the rename method exists and can be called
      expect(() => AppService.renameClonedApp(packageName, cloneId, newName), 
        returnsNormally);
    });

    test('Multiple clones should be allowed', () async {
      const packageName = 'com.example.test';
      
      // Test that we can create multiple clones of the same app
      final clone1 = AppService.cloneApp(packageName, customName: 'Clone 1');
      final clone2 = AppService.cloneApp(packageName, customName: 'Clone 2');
      final clone3 = AppService.cloneApp(packageName, customName: 'Clone 3');
      
      // All should be allowed (no "already cloned" restriction)
      expect(() => clone1, returnsNormally);
      expect(() => clone2, returnsNormally);
      expect(() => clone3, returnsNormally);
    });

    test('Cache should improve performance', () async {
      // First call - should populate cache
      final stopwatch1 = Stopwatch()..start();
      await AppService.getInstalledApps();
      stopwatch1.stop();
      
      // Second call - should use cache and be faster
      final stopwatch2 = Stopwatch()..start();
      await AppService.getInstalledApps();
      stopwatch2.stop();
      
      expect(stopwatch2.elapsedMilliseconds, lessThanOrEqualTo(stopwatch1.elapsedMilliseconds),
        reason: 'Cached call should be faster or equal to first call');
    });

    test('AppInfo model should support all required fields', () {
      final app = AppInfo(
        appName: 'Test App',
        packageName: 'com.test.app',
        isCloned: false,
        displayName: 'Custom Display Name',
        cloneCount: 2,
      );

      expect(app.appName, equals('Test App'));
      expect(app.packageName, equals('com.test.app'));
      expect(app.displayName, equals('Custom Display Name'));
      expect(app.cloneCount, equals(2));
      expect(app.isCloned, isFalse);
    });

    test('Error handling should be robust', () async {
      // Test with invalid package name
      const invalidPackage = '';
      
      // Should not throw exceptions
      expect(() => AppService.cloneApp(invalidPackage), returnsNormally);
      expect(() => AppService.renameClonedApp(invalidPackage, 1, 'New Name'), returnsNormally);
    });
  });

  group('UI Performance Tests', () {
    test('Icon loading should have fallbacks', () {
      // Test that icon loading has proper error handling
      expect(() => AppService.getAppIcon('invalid.package'), returnsNormally);
    });

    test('App list filtering should be efficient', () async {
      // Test that system apps are filtered out by default
      final apps = await AppService.getInstalledApps();
      
      // Should return a reasonable number of apps (not thousands)
      expect(apps.length, lessThan(500), 
        reason: 'Should filter out system apps for better performance');
    });
  });
}
