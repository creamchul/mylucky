import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get isInitialized => _isInitialized;

  /// 초기화 - 저장된 테마 설정 불러오기
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.system; // 기본값
      }
      
      _isInitialized = true;
      if (kDebugMode) {
        print('테마 초기화 완료: $_themeMode');
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('테마 초기화 실패: $e');
      }
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 테마 모드 변경
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themeKey, mode.index);
        if (kDebugMode) {
          print('테마 저장 완료: $mode');
        }
      } catch (e) {
        if (kDebugMode) {
          print('테마 저장 실패: $e');
        }
      }
    }
  }

  /// 다크모드 토글
  Future<void> toggleDarkMode() async {
    final newMode = _themeMode == ThemeMode.dark 
        ? ThemeMode.light 
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// 시스템 테마 사용
  Future<void> useSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// 현재 브라이트니스 반환 (시스템 설정 고려)
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// 현재 다크모드 여부 반환 (시스템 설정 고려)
  bool isDarkModeActive(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }
} 