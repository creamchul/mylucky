import 'package:flutter/material.dart';

/// 🎨 MyLucky 앱 전용 색상 시스템
/// 
/// 설계 원칙:
/// 1. 눈의 피로도 최소화 (특히 다크모드)
/// 2. 완벽한 라이트/다크 모드 호환성
/// 3. 확장성 있는 구조 (새 색상 쉽게 추가)
/// 4. 일관성 있는 색상 적용
class AppColors {
  AppColors._(); // Private constructor

  // ================================
  // 🌈 CORE THEME COLORS (기본 테마 색상)
  // ================================
  
  /// 라이트 테마 기본 색상
  static const _LightTheme light = _LightTheme();
  
  /// 다크 테마 기본 색상  
  static const _DarkTheme dark = _DarkTheme();

  // ================================
  // 🎯 SEMANTIC COLORS (의미별 색상)
  // ================================
  
  /// 성공/긍정적 상황
  static const _SemanticColors success = _SemanticColors(
    light: Color(0xFF10B981), // 선명한 에메랄드 그린
    dark: Color(0xFF34D399),  // 부드러운 에메랄드 그린
  );
  
  /// 경고/주의 상황
  static const _SemanticColors warning = _SemanticColors(
    light: Color(0xFFF59E0B), // 따뜻한 앰버
    dark: Color(0xFFFBBF24),  // 부드러운 앰버
  );
  
  /// 오류/위험 상황
  static const _SemanticColors error = _SemanticColors(
    light: Color(0xFFEF4444), // 선명한 레드
    dark: Color(0xFFF87171),  // 부드러운 레드
  );
  
  /// 정보/중립적 상황
  static const _SemanticColors info = _SemanticColors(
    light: Color(0xFF3B82F6), // 선명한 블루
    dark: Color(0xFF60A5FA),  // 부드러운 블루
  );

  // ================================
  // 🎪 FEATURE COLORS (기능별 색상)
  // ================================
  
  /// 집중하기 기능
  static const _FeatureColors focus = _FeatureColors(
    primary: _SemanticColors(
      light: Color(0xFF059669), // 진한 에메랄드
      dark: Color(0xFF10B981),  // 밝은 에메랄드
    ),
    surface: _SemanticColors(
      light: Color(0xFFECFDF5), // 매우 연한 에메랄드
      dark: Color(0xFF064E3B),  // 매우 진한 에메랄드
    ),
    accent: _SemanticColors(
      light: Color(0xFF34D399), // 중간 에메랄드
      dark: Color(0xFF6EE7B7),  // 연한 에메랄드
    ),
  );
  
  /// 펫 케어 기능
  static const _FeatureColors pet = _FeatureColors(
    primary: _SemanticColors(
      light: Color(0xFFDC2626), // 따뜻한 레드
      dark: Color(0xFFEF4444),  // 밝은 레드
    ),
    surface: _SemanticColors(
      light: Color(0xFFFEF2F2), // 매우 연한 레드
      dark: Color(0xFF7F1D1D),  // 매우 진한 레드
    ),
    accent: _SemanticColors(
      light: Color(0xFFF87171), // 중간 레드
      dark: Color(0xFFFCA5A5),  // 연한 레드
    ),
  );
  
  /// 감정일기 기능
  static const _FeatureColors mood = _FeatureColors(
    primary: _SemanticColors(
      light: Color(0xFFBE185D), // 진한 핑크
      dark: Color(0xFFEC4899),  // 밝은 핑크
    ),
    surface: _SemanticColors(
      light: Color(0xFFFDF2F8), // 매우 연한 핑크
      dark: Color(0xFF831843),  // 매우 진한 핑크
    ),
    accent: _SemanticColors(
      light: Color(0xFFF472B6), // 중간 핑크
      dark: Color(0xFFF9A8D4),  // 연한 핑크
    ),
  );
  
  /// 오늘의 카드 기능
  static const _FeatureColors card = _FeatureColors(
    primary: _SemanticColors(
      light: Color(0xFF7C3AED), // 진한 바이올렛
      dark: Color(0xFF8B5CF6),  // 밝은 바이올렛
    ),
    surface: _SemanticColors(
      light: Color(0xFFF5F3FF), // 매우 연한 바이올렛
      dark: Color(0xFF581C87),  // 매우 진한 바이올렛
    ),
    accent: _SemanticColors(
      light: Color(0xFFA78BFA), // 중간 바이올렛
      dark: Color(0xFFC4B5FD),  // 연한 바이올렛
    ),
  );
  
  /// 루틴/할일 기능
  static const _FeatureColors routine = _FeatureColors(
    primary: _SemanticColors(
      light: Color(0xFF1D4ED8), // 진한 블루
      dark: Color(0xFF3B82F6),  // 밝은 블루
    ),
    surface: _SemanticColors(
      light: Color(0xFFEFF6FF), // 매우 연한 블루
      dark: Color(0xFF1E3A8A),  // 매우 진한 블루
    ),
    accent: _SemanticColors(
      light: Color(0xFF60A5FA), // 중간 블루
      dark: Color(0xFF93C5FD),  // 연한 블루
    ),
  );

  // ================================
  // 🎭 MOOD COLORS (감정별 색상)
  // ================================
  
  /// 최고 기분 (✨)
  static const _SemanticColors moodAmazing = _SemanticColors(
    light: Color(0xFFF59E0B), // 황금색
    dark: Color(0xFFFBBF24),  // 부드러운 황금색
  );
  
  /// 좋음 기분 (😊)
  static const _SemanticColors moodGood = _SemanticColors(
    light: Color(0xFF10B981), // 에메랄드 그린
    dark: Color(0xFF34D399),  // 부드러운 에메랄드
  );
  
  /// 보통 기분 (😐)
  static const _SemanticColors moodNormal = _SemanticColors(
    light: Color(0xFF6B7280), // 중성 그레이
    dark: Color(0xFF9CA3AF),  // 밝은 그레이
  );
  
  /// 별로 기분 (😕)
  static const _SemanticColors moodBad = _SemanticColors(
    light: Color(0xFFF97316), // 오렌지
    dark: Color(0xFFFB923C),  // 부드러운 오렌지
  );
  
  /// 최악 기분 (😓)
  static const _SemanticColors moodTerrible = _SemanticColors(
    light: Color(0xFF8B5CF6), // 퍼플
    dark: Color(0xFFA78BFA),  // 부드러운 퍼플
  );

  // ================================
  // 🌟 SPECIAL COLORS (특수 색상)
  // ================================
  
  /// 즐겨찾기/프리미엄
  static const _SemanticColors premium = _SemanticColors(
    light: Color(0xFFD97706), // 진한 앰버
    dark: Color(0xFFFBBF24),  // 밝은 앰버
  );
  
  /// 출석/성취
  static const _SemanticColors achievement = _SemanticColors(
    light: Color(0xFF059669), // 에메랄드
    dark: Color(0xFF10B981),  // 밝은 에메랄드
  );

  // ================================
  // 🎨 GRADIENT COLLECTIONS (그라데이션 모음)
  // ================================
  
  /// 홈 배경 그라데이션
  static List<Color> homeGradient(bool isDark) {
    return isDark ? [
      const Color(0xFF0F172A), // 매우 진한 슬레이트
      const Color(0xFF1E293B), // 진한 슬레이트
      const Color(0xFF334155), // 중간 슬레이트
      const Color(0xFF475569), // 밝은 슬레이트
    ] : [
      const Color(0xFFF8FAFC), // 매우 연한 슬레이트
      const Color(0xFFF1F5F9), // 연한 슬레이트
      const Color(0xFFE2E8F0), // 중간 연한 슬레이트
      const Color(0xFFCBD5E1), // 중간 슬레이트
    ];
  }
  
  /// 카드 배경 그라데이션
  static List<Color> cardGradient(bool isDark) {
    return isDark ? [
      const Color(0xFF581C87), // 진한 바이올렛
      const Color(0xFF7C3AED), // 바이올렛
      const Color(0xFF8B5CF6), // 밝은 바이올렛
    ] : [
      const Color(0xFFF5F3FF), // 연한 바이올렛
      const Color(0xFFEDE9FE), // 중간 연한 바이올렛
      const Color(0xFFDDD6FE), // 중간 바이올렛
    ];
  }

  // ================================
  // 🛠️ UTILITY METHODS (유틸리티 메서드)
  // ================================
  
  /// 테마에 따른 감정 색상 반환
  static Color getMoodColor(String moodType, bool isDark) {
    switch (moodType.toLowerCase()) {
      case 'amazing':
        return isDark ? moodAmazing.dark : moodAmazing.light;
      case 'good':
        return isDark ? moodGood.dark : moodGood.light;
      case 'normal':
        return isDark ? moodNormal.dark : moodNormal.light;
      case 'bad':
        return isDark ? moodBad.dark : moodBad.light;
      case 'terrible':
        return isDark ? moodTerrible.dark : moodTerrible.light;
      default:
        return isDark ? moodNormal.dark : moodNormal.light;
    }
  }
  
  /// 감정 배경 색상 (더 연한 버전)
  static Color getMoodBackgroundColor(String moodType, bool isDark) {
    final baseColor = getMoodColor(moodType, isDark);
    return isDark 
        ? baseColor.withOpacity(0.15) 
        : baseColor.withOpacity(0.1);
  }
  
  /// 감정 테두리 색상
  static Color getMoodBorderColor(String moodType, bool isDark) {
    final baseColor = getMoodColor(moodType, isDark);
    return isDark 
        ? baseColor.withOpacity(0.3) 
        : baseColor.withOpacity(0.2);
  }

  // ================================
  // 🎯 FEATURE COLOR GETTERS (기능별 색상 접근자)
  // ================================
  
  static Color getFocusColor(bool isDark) => focus.primary.resolve(isDark);
  static Color getFocusSurface(bool isDark) => focus.surface.resolve(isDark);
  static Color getFocusAccent(bool isDark) => focus.accent.resolve(isDark);
  
  static Color getPetColor(bool isDark) => pet.primary.resolve(isDark);
  static Color getPetSurface(bool isDark) => pet.surface.resolve(isDark);
  static Color getPetAccent(bool isDark) => pet.accent.resolve(isDark);
  
  static Color getMoodDiaryColor(bool isDark) => mood.primary.resolve(isDark);
  static Color getMoodDiarySurface(bool isDark) => mood.surface.resolve(isDark);
  static Color getMoodDiaryAccent(bool isDark) => mood.accent.resolve(isDark);
  
  static Color getCardColor(bool isDark) => card.primary.resolve(isDark);
  static Color getCardSurface(bool isDark) => card.surface.resolve(isDark);
  static Color getCardAccent(bool isDark) => card.accent.resolve(isDark);
  
  static Color getRoutineColor(bool isDark) => routine.primary.resolve(isDark);
  static Color getRoutineSurface(bool isDark) => routine.surface.resolve(isDark);
  static Color getRoutineAccent(bool isDark) => routine.accent.resolve(isDark);

  // ================================
  // 🌐 CORE THEME GETTERS (기본 테마 접근자)
  // ================================
  
  static Color getScaffoldBackground(bool isDark) {
    return isDark ? dark.scaffoldBackground : light.scaffoldBackground;
  }
  
  static Color getSurface(bool isDark) {
    return isDark ? dark.surface : light.surface;
  }
  
  static Color getSurfaceSecondary(bool isDark) {
    return isDark ? dark.surfaceSecondary : light.surfaceSecondary;
  }
  
  static Color getTextPrimary(bool isDark) {
    return isDark ? dark.textPrimary : light.textPrimary;
  }
  
  static Color getTextSecondary(bool isDark) {
    return isDark ? dark.textSecondary : light.textSecondary;
  }
  
  static Color getTextTertiary(bool isDark) {
    return isDark ? dark.textTertiary : light.textTertiary;
  }
  
  static Color getBorder(bool isDark) {
    return isDark ? dark.border : light.border;
  }
  
  static Color getDivider(bool isDark) {
    return isDark ? dark.divider : light.divider;
  }
  
  static Color getOverlay(bool isDark) {
    return isDark ? dark.overlay : light.overlay;
  }

  // ================================
  // 🚀 SEMANTIC COLOR GETTERS (의미별 색상 접근자)
  // ================================
  
  static Color getSuccess(bool isDark) => success.resolve(isDark);
  static Color getWarning(bool isDark) => warning.resolve(isDark);
  static Color getError(bool isDark) => error.resolve(isDark);
  static Color getInfo(bool isDark) => info.resolve(isDark);
  static Color getPremium(bool isDark) => premium.resolve(isDark);
  static Color getAchievement(bool isDark) => achievement.resolve(isDark);

  // ================================
  // 🔄 BACKWARD COMPATIBILITY (기존 호환성)
  // ================================
  
  /// 기존 코드와의 호환성을 위한 메서드들
  static List<Color> getHomeGradient(bool isDark) => homeGradient(isDark);
  static List<Color> getFortunePageGradient(bool isDark) => cardGradient(isDark);
  static Color getCardBackground(bool isDark) => getSurface(isDark);
  static Color getSurfaceColor(bool isDark) => getSurfaceSecondary(isDark);
  static Color getBorderColor(bool isDark) => getBorder(isDark);
  static Color getDividerColor(bool isDark) => getDivider(isDark);
  static Color getSuccessColor(bool isDark) => getSuccess(isDark);
  static Color getWarningColor(bool isDark) => getWarning(isDark);
  static Color getErrorColor(bool isDark) => getError(isDark);
  static Color getPointColor(bool isDark) => getPremium(isDark);
  static Color getAttendanceColor(bool isDark) => getAchievement(isDark);
  
  /// 기존 프라이머리 컬러 호환성
  static Color getPrimaryPink(bool isDark) => getMoodDiaryColor(isDark);
  static Color getPrimaryPurple(bool isDark) => getCardColor(isDark);

  // ================================
  // 🏗️ LEGACY COLOR GETTERS (레거시 색상 호환성)
  // ================================
  
  /// 기존 색상 시스템과의 호환성을 위한 정적 getter들
  /// 이 메서드들은 다크모드를 고려하지 않는 기존 방식이므로 점진적으로 교체 예정
  
  // Purple shades
  static Color get purple50 => const Color(0xFFF5F3FF);
  static Color get purple100 => const Color(0xFFEDE9FE);
  static Color get purple200 => const Color(0xFFDDD6FE);
  static Color get purple400 => const Color(0xFFA78BFA);
  static Color get purple500 => const Color(0xFF8B5CF6);
  static Color get purple600 => const Color(0xFF7C3AED);
  static Color get purple700 => const Color(0xFF6D28D9);
  
  // Orange shades
  static Color get orange300 => const Color(0xFFFCD34D);
  static Color get orange400 => const Color(0xFFFBBF24);
  static Color get orange500 => const Color(0xFFF59E0B);
  static Color get orange600 => const Color(0xFFD97706);
  static Color get orange700 => const Color(0xFFB45309);
  
  // Green shades
  static Color get green400 => const Color(0xFF34D399);
  static Color get green500 => const Color(0xFF10B981);
  static Color get green600 => const Color(0xFF059669);
  static Color get green700 => const Color(0xFF047857);
  
  // Blue shades
  static Color get blue50 => const Color(0xFFEFF6FF);
  static Color get blue200 => const Color(0xFFBFDBFE);
  static Color get blue400 => const Color(0xFF60A5FA);
  static Color get blue500 => const Color(0xFF3B82F6);
  static Color get blue600 => const Color(0xFF2563EB);
  static Color get blue700 => const Color(0xFF1D4ED8);
  
  // Grey shades
  static Color get grey50 => const Color(0xFFF9FAFB);
  static Color get grey200 => const Color(0xFFE5E7EB);
  static Color get grey300 => const Color(0xFFD1D5DB);
  static Color get grey400 => const Color(0xFF9CA3AF);
  static Color get grey500 => const Color(0xFF6B7280);
  static Color get grey600 => const Color(0xFF4B5563);
  static Color get grey700 => const Color(0xFF374151);
  static Color get grey800 => const Color(0xFF1F2937);
  
  // Red and Yellow shades
  static Color get red600 => const Color(0xFFDC2626);
  static Color get yellow400 => const Color(0xFFFBBF24);
  static Color get yellow600 => const Color(0xFFD97706);

  // ================================
  // 🎨 ENHANCED FEATURE COLORS (기존 기능 색상 호환성)
  // ================================
  
  // 집중하기 - 에메랄드 그린 계열
  static Color get focusMint => green500;
  static Color get focusMintLight => const Color(0xFFECFDF5);
  static Color get focusMintDark => green600;
  static Color get focusMintDarkMode => green400;
  
  // 펫 케어 - 코랄/레드 계열
  static Color get petCoral => const Color(0xFFEF4444);
  static Color get petCoralLight => const Color(0xFFFEF2F2);
  static Color get petCoralDark => red600;
  static Color get petCoralDarkMode => const Color(0xFFF87171);
  
  // 오늘의 카드 - 라벤더/퍼플 계열
  static Color get cardLavender => purple500;
  static Color get cardLavenderLight => purple50;
  static Color get cardLavenderDark => purple600;
  static Color get cardLavenderDarkMode => purple400;
  
  // 오늘의 루틴 - 스카이/블루 계열
  static Color get routineSky => blue600;
  static Color get routineSkyLight => blue50;
  static Color get routineSkyDark => blue700;
  static Color get routineSkyDarkMode => blue400;
  
  // 출석 - 성취감 그린
  static Color get attendanceGreen => green600;
  static Color get attendanceGreenLight => const Color(0xFFECFDF5);
  static Color get attendanceGreenDarkMode => green400;

  // ================================
  // 📱 MISSING LEGACY COLORS (빠진 레거시 색상)
  // ================================
  
  /// 기존 코드에서 직접 참조하는 색상들
  static Color get darkCardBackground => const Color(0xFF1E293B);
  static Color get lightCardBackground => const Color(0xFFFFFFFF);
  static Color get darkSurfaceColor => const Color(0xFF334155);
  static Color get lightSurfaceColor => const Color(0xFFF8FAFC);
  static Color get darkBorder => const Color(0xFF475569);
  static Color get lightBorder => const Color(0xFFE2E8F0);
}

// ================================
// 📦 PRIVATE THEME CLASSES (내부 테마 클래스들)
// ================================

/// 라이트 테마 색상 정의
class _LightTheme {
  const _LightTheme();
  
  /// 기본 배경
  Color get scaffoldBackground => const Color(0xFFFFFFFF);
  
  /// 카드/컨테이너 배경
  Color get surface => const Color(0xFFFFFFFF);
  
  /// 보조 표면 (인풋, 버튼 등)
  Color get surfaceSecondary => const Color(0xFFF8FAFC);
  
  /// 메인 텍스트
  Color get textPrimary => const Color(0xFF0F172A);
  
  /// 보조 텍스트
  Color get textSecondary => const Color(0xFF64748B);
  
  /// 힌트 텍스트
  Color get textTertiary => const Color(0xFF94A3B8);
  
  /// 테두리
  Color get border => const Color(0xFFE2E8F0);
  
  /// 구분선
  Color get divider => const Color(0xFFF1F5F9);
  
  /// 오버레이 (모달, 로딩 등)
  Color get overlay => const Color(0x80000000);
}

/// 다크 테마 색상 정의 (눈의 피로도 최소화)
class _DarkTheme {
  const _DarkTheme();
  
  /// 기본 배경 (완전한 검정 X, 부드러운 진한 색상)
  Color get scaffoldBackground => const Color(0xFF0F172A);
  
  /// 카드/컨테이너 배경
  Color get surface => const Color(0xFF1E293B);
  
  /// 보조 표면 (인풋, 버튼 등)
  Color get surfaceSecondary => const Color(0xFF334155);
  
  /// 메인 텍스트 (완전한 하얀색 X, 부드러운 밝은 색상)
  Color get textPrimary => const Color(0xFFF1F5F9);
  
  /// 보조 텍스트
  Color get textSecondary => const Color(0xFFCBD5E1);
  
  /// 힌트 텍스트
  Color get textTertiary => const Color(0xFF94A3B8);
  
  /// 테두리
  Color get border => const Color(0xFF475569);
  
  /// 구분선
  Color get divider => const Color(0xFF334155);
  
  /// 오버레이 (모달, 로딩 등)
  Color get overlay => const Color(0x80000000);
}

/// 의미별 색상 클래스
class _SemanticColors {
  const _SemanticColors({
    required this.light,
    required this.dark,
  });
  
  final Color light;
  final Color dark;
  
  /// 테마에 따른 색상 반환
  Color resolve(bool isDark) => isDark ? dark : light;
}

/// 기능별 색상 묶음
class _FeatureColors {
  const _FeatureColors({
    required this.primary,
    required this.surface,
    required this.accent,
  });
  
  final _SemanticColors primary;   // 메인 색상
  final _SemanticColors surface;   // 배경 색상
  final _SemanticColors accent;    // 강조 색상
} 