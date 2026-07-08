import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await ApiConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FindMe Kampus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashScreen(),
    );
  }
}

class AuthResolver extends StatelessWidget {
  const AuthResolver({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ApiService.getToken(),
      builder: (context, snapshot) {
        // While waiting for shared preferences, display a splash loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.primary,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.accent,
              ),
            ),
          );
        }
        
        // If token exists, go to HomeScreen, otherwise LoginScreen
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
          return const HomeScreen();
        }
        
        return const LoginScreen();
      },
    );
  }
}
