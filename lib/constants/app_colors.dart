import 'package:flutter/material.dart';

/// 앱에서 사용하는 색상 상수들
class AppColors {
  AppColors._(); // Private constructor

  // Primary Colors
  static const Color primaryPurple = Color(0xFFB39DDB);
  static const Color scaffoldBackground = Color(0xFFF8F6FF);

  // Gradient Colors
  static const List<Color> homeGradient = [
    Color(0xFFE1F5FE), // 연한 파란색
    Color(0xFFF3E5F5), // 연한 보라색
    Color(0xFFE8F5E8), // 연한 녹색
    Color(0xFFFFF3E0), // 연한 오렌지
  ];

  static const List<Color> fortunePageGradient = [
    Color(0xFFE8EAF6), // 연한 인디고
    Color(0xFFF3E5F5), // 연한 보라색
    Color(0xFFE1F5FE), // 연한 파란색
    Color(0xFFF1F8E9), // 연한 녹색
  ];

  // Feature Colors
  static Color get purple400 => Colors.purple.shade400;
  static Color get purple600 => Colors.purple.shade600;
  static Color get purple700 => Colors.purple.shade700;
  
  static Color get orange400 => Colors.orange.shade400;
  static Color get orange600 => Colors.orange.shade600;
  static Color get orange700 => Colors.orange.shade700;
  
  static Color get green400 => Colors.green.shade400;
  static Color get green600 => Colors.green.shade600;
  static Color get green700 => Colors.green.shade700;
  
  static Color get blue400 => Colors.blue.shade400;
  static Color get blue500 => Colors.blue.shade500;
  static Color get blue600 => Colors.blue.shade600;
  static Color get blue700 => Colors.blue.shade700;
  
  static Color get grey400 => Colors.grey.shade400;
  static Color get grey500 => Colors.grey.shade500;
  static Color get grey600 => Colors.grey.shade600;
  static Color get grey700 => Colors.grey.shade700;
  static Color get grey800 => Colors.grey.shade800;
}