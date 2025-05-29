import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
// Constants imports
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
// Pages imports
import 'pages/home_page.dart';
// Firebase options
import 'firebase_options.dart';
// Services
import 'services/firebase_service.dart';

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
  
  runApp(const MyLuckyApp());
}

class MyLuckyApp extends StatelessWidget {
  const MyLuckyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      
      // 국제화 설정
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
      ],
      locale: const Locale('ko', 'KR'), // 기본 로케일
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.scaffoldBackground,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MyLuckyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
