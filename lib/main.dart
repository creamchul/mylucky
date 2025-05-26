import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
// Constants imports
import 'constants/app_colors.dart';
import 'constants/app_strings.dart';
// Pages imports
import 'pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    print('MyLucky 앱 시작 - 로컬 저장소 모드');
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
