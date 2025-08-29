import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/permission_service.dart';
import 'services/app_service.dart';

void main() async {
  // Ensure Flutter binding is initialized for better performance
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 MAIN: App starting - MultiSpace Cloner');
// Pre-initialize services for faster startup
  try {
    await AppService.initialize();
    print('✅ MAIN: AppService initialized successfully');
  } catch (e) {
    print('Service initialization warning: $e');
  }

  print('🏁 MAIN: Running MultiSpaceApp widget');
  runApp(const MultiSpaceApp());
}

class MultiSpaceApp extends StatelessWidget {
  const MultiSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MultiSpace',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A1A),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Colors.white54,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
