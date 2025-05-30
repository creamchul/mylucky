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
  static Color get purple50 => Colors.purple.shade50;
  static Color get purple100 => Colors.purple.shade100;
  static Color get purple200 => Colors.purple.shade200;
  static Color get purple400 => Colors.purple.shade400;
  static Color get purple500 => Colors.purple.shade500;
  static Color get purple600 => Colors.purple.shade600;
  static Color get purple700 => Colors.purple.shade700;
  
  static Color get orange300 => Colors.orange.shade300;
  static Color get orange400 => Colors.orange.shade400;
  static Color get orange500 => Colors.orange.shade500;
  static Color get orange600 => Colors.orange.shade600;
  static Color get orange700 => Colors.orange.shade700;
  
  static Color get green400 => Colors.green.shade400;
  static Color get green500 => Colors.green.shade500;
  static Color get green600 => Colors.green.shade600;
  static Color get green700 => Colors.green.shade700;
  
  static Color get blue50 => Colors.blue.shade50;
  static Color get blue200 => Colors.blue.shade200;
  static Color get blue400 => Colors.blue.shade400;
  static Color get blue500 => Colors.blue.shade500;
  static Color get blue600 => Colors.blue.shade600;
  static Color get blue700 => Colors.blue.shade700;
  
  static Color get grey50 => Colors.grey.shade50;
  static Color get grey200 => Colors.grey.shade200;
  static Color get grey300 => Colors.grey.shade300;
  static Color get grey400 => Colors.grey.shade400;
  static Color get grey500 => Colors.grey.shade500;
  static Color get grey600 => Colors.grey.shade600;
  static Color get grey700 => Colors.grey.shade700;
  static Color get grey800 => Colors.grey.shade800;
  
  static Color get yellow400 => Colors.yellow.shade400;
  static Color get yellow600 => Colors.yellow.shade600;
  static Color get red600 => Colors.red.shade600;

  // New Pastel Color System for Home Features
  // 집중하기 - 연한 민트그린
  static const Color focusMint = Color(0xFF81C784);
  static const Color focusMintLight = Color(0xFFE8F5E8);
  static const Color focusMintDark = Color(0xFF66BB6A);
  
  // 펫 케어 - 연한 코랄  
  static const Color petCoral = Color(0xFFFF8A65);
  static const Color petCoralLight = Color(0xFFFFF3E0);
  static const Color petCoralDark = Color(0xFFFF7043);
  
  // 오늘의 카드 - 연한 라벤더
  static const Color cardLavender = Color(0xFFB39DDB);
  static const Color cardLavenderLight = Color(0xFFF3E5F5);
  static const Color cardLavenderDark = Color(0xFF9575CD);
  
  // 오늘의 루틴 - 연한 스카이블루
  static const Color routineSky = Color(0xFF64B5F6);
  static const Color routineSkyLight = Color(0xFFE1F5FE);
  static const Color routineSkyDark = Color(0xFF42A5F5);
  
  // 출석 - 성취감 민트그린
  static const Color attendanceGreen = Color(0xFF4CAF50);
  static const Color attendanceGreenLight = Color(0xFFE8F5E8);
}