import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppThemes {
  AppThemes._();

  /// 라이트 테마
  static ThemeData get lightTheme {
    const bool isDark = false;
    
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      
      // 색상 스키마
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.getMoodDiaryColor(isDark),
        brightness: Brightness.light,
        surface: AppColors.getSurface(isDark),
        onSurface: AppColors.getTextPrimary(isDark),
        background: AppColors.getScaffoldBackground(isDark),
        onBackground: AppColors.getTextPrimary(isDark),
        primary: AppColors.getMoodDiaryColor(isDark),
        onPrimary: Colors.white,
        secondary: AppColors.getCardColor(isDark),
        onSecondary: Colors.white,
      ),
      
      // 스캐폴드 배경
      scaffoldBackgroundColor: AppColors.getScaffoldBackground(isDark),
      
      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.getTextPrimary(isDark),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
      
      // 카드 테마
      cardTheme: CardThemeData(
        color: AppColors.getSurface(isDark),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        displayMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        displaySmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineSmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleSmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        labelLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        labelMedium: TextStyle(color: AppColors.getTextSecondary(isDark)),
        labelSmall: TextStyle(color: AppColors.getTextSecondary(isDark)),
        bodyLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        bodyMedium: TextStyle(color: AppColors.getTextSecondary(isDark)),
        bodySmall: TextStyle(color: AppColors.getTextSecondary(isDark)),
      ),
      
      // 탭바 테마
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.getMoodDiaryColor(isDark),
        unselectedLabelColor: AppColors.getTextSecondary(isDark),
        indicatorColor: AppColors.getMoodDiaryColor(isDark),
        dividerColor: AppColors.getBorder(isDark),
      ),
      
      // 플로팅 액션 버튼 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.getMoodDiaryColor(isDark),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 다이얼로그 테마
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.getSurface(isDark),
        titleTextStyle: TextStyle(
          color: AppColors.getTextPrimary(isDark),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.getTextSecondary(isDark),
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 아이콘 테마
      iconTheme: IconThemeData(
        color: AppColors.getTextSecondary(isDark),
      ),
      
      // 분할선 테마
      dividerTheme: DividerThemeData(
        color: AppColors.getBorder(isDark),
        thickness: 1,
      ),
      
      fontFamily: 'Roboto',
    );
  }

  /// 다크 테마
  static ThemeData get darkTheme {
    const bool isDark = true;
    
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      
      // 색상 스키마
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.getMoodDiaryColor(isDark),
        brightness: Brightness.dark,
        surface: AppColors.getSurface(isDark),
        onSurface: AppColors.getTextPrimary(isDark),
        background: AppColors.getScaffoldBackground(isDark),
        onBackground: AppColors.getTextPrimary(isDark),
        primary: AppColors.getMoodDiaryColor(isDark),
        onPrimary: Colors.white,
        secondary: AppColors.getCardColor(isDark),
        onSecondary: Colors.white,
      ),
      
      // 스캐폴드 배경
      scaffoldBackgroundColor: AppColors.getScaffoldBackground(isDark),
      
      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.getTextPrimary(isDark),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.getTextPrimary(isDark),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
          color: AppColors.getTextSecondary(isDark),
        ),
      ),
      
      // 카드 테마
      cardTheme: CardThemeData(
        color: AppColors.getSurface(isDark),
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        displayMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        displaySmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        headlineSmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleMedium: TextStyle(color: AppColors.getTextPrimary(isDark)),
        titleSmall: TextStyle(color: AppColors.getTextPrimary(isDark)),
        labelLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        labelMedium: TextStyle(color: AppColors.getTextSecondary(isDark)),
        labelSmall: TextStyle(color: AppColors.getTextSecondary(isDark)),
        bodyLarge: TextStyle(color: AppColors.getTextPrimary(isDark)),
        bodyMedium: TextStyle(color: AppColors.getTextSecondary(isDark)),
        bodySmall: TextStyle(color: AppColors.getTextSecondary(isDark)),
      ),
      
      // 탭바 테마
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.getMoodDiaryColor(isDark),
        unselectedLabelColor: AppColors.getTextSecondary(isDark),
        indicatorColor: AppColors.getMoodDiaryColor(isDark),
        dividerColor: AppColors.getBorder(isDark),
      ),
      
      // 플로팅 액션 버튼 테마
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.getMoodDiaryColor(isDark),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 다이얼로그 테마
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.getSurface(isDark),
        titleTextStyle: TextStyle(
          color: AppColors.getTextPrimary(isDark),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: AppColors.getTextSecondary(isDark),
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // 아이콘 테마
      iconTheme: IconThemeData(
        color: AppColors.getTextSecondary(isDark),
      ),
      
      // 분할선 테마
      dividerTheme: DividerThemeData(
        color: AppColors.getBorder(isDark),
        thickness: 1,
      ),
      
      fontFamily: 'Roboto',
    );
  }
} 