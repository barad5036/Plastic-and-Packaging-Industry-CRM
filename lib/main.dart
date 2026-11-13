import 'package:crm/core/providers/auth_provider.dart';
import 'package:crm/core/providers/dashboard_provider.dart';
import 'package:crm/core/providers/dealer_provider.dart';
import 'package:crm/core/providers/lead_provider.dart';
import 'package:crm/core/providers/quote_provider.dart';
import 'package:crm/core/providers/task_provider.dart';
import 'package:crm/core/network/api_client.dart';
import 'package:crm/core/theme/app_theme.dart';
import 'package:crm/screens/auth/login_screen.dart';
import 'package:crm/screens/main_layout.dart';
import 'package:crm/core/network/remote_config_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.initialize();
  
  // Explicitly allow both portrait and landscape orientations system-wide
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize Firebase (wrapped in try-catch to not crash if unconfigured on desktop)
  try {
    await Firebase.initializeApp();
    // Fetch admin credentials from Remote Config
    await RemoteConfigService().init();
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => LeadProvider()),
        ChangeNotifierProvider(create: (_) => QuoteProvider()),
        ChangeNotifierProvider(create: (_) => DealerProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const CRMApp(),
    ),
  );
}

class CRMApp extends StatelessWidget {
  const CRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SalesHub CRM',
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainLayout();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
