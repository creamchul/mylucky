import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// Constants imports
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
// Pages imports
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 초기화 (웹에서는 설정이 없으면 스킵)
  try {
    if (kIsWeb) {
      // 웹에서는 Firebase 설정이 있을 때만 초기화
      if (kDebugMode) {
        print('웹 환경: Firebase 설정이 없으므로 스킵합니다');
      }
    } else {
      await Firebase.initializeApp();
      if (kDebugMode) {
        print('Firebase 초기화 성공');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('Firebase 초기화 실패: $e');
      print('Firebase 없이 앱을 실행합니다');
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
