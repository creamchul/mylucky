import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
// Constants imports
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
import 'constants/app_themes.dart';
// Pages imports
import 'pages/home_page.dart';
// Firebase options
import 'firebase_options.dart';
// Services
import 'services/firebase_service.dart';
import 'services/performance_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('MyLucky 앱 시작 - Firebase 초기화 완료');
    }
    
    // Firebase 연결 테스트
    try {
      final isConnected = await FirebaseService.checkConnection();
      if (kDebugMode) {
        print('Firebase 연결 테스트: ${isConnected ? "성공" : "실패"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase 연결 테스트 실패: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase 초기화 실패: $e');
      print('MyLucky 앱 시작 - 로컬 저장소 모드로 실행');
    }
  }
  
  // 성능 최적화 서비스 초기화
  await PerformanceService.initialize();
  
  // 테마 서비스 초기화
  await ThemeService().initialize();
  
  runApp(const MyLuckyApp());
}

class MyLuckyApp extends StatefulWidget {
  const MyLuckyApp({super.key});

  @override
  State<MyLuckyApp> createState() => _MyLuckyAppState();
}

class _MyLuckyAppState extends State<MyLuckyApp> {
  late ThemeService _themeService;

  @override
  void initState() {
    super.initState();
    _themeService = ThemeService();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      
      // 웹 호환성을 위해 기본 영어 localization 사용
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
      ],
      locale: const Locale('en', 'US'),
      
      // 테마 설정
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: _themeService.themeMode,
      
      home: const MyLuckyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
