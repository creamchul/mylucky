import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 집중하기 알림 서비스
/// 로컬 알림을 통해 집중 완료, 중간 알림, 휴식 알림 등을 제공
/// 웹 환경에서는 알림 기능이 비활성화됩니다.
class NotificationService {
  static bool _isInitialized = false;
  static bool _hasPermission = false;
  
  /// 알림 서비스 초기화
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 웹에서는 알림 기능 비활성화
      if (kIsWeb) {
        _hasPermission = false;
        _isInitialized = true;
        if (kDebugMode) {
          print('웹 환경: 알림 서비스 비활성화');
        }
        return;
      }
      
      // TODO: 모바일/데스크톱에서 실제 알림 패키지 초기화
      // 현재는 웹 테스트를 위해 비활성화
      _hasPermission = false;
      _isInitialized = true;
      
      if (kDebugMode) {
        print('알림 서비스 초기화 완료 (현재 비활성화 상태)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('알림 서비스 초기화 실패: $e');
      }
      _hasPermission = false;
      _isInitialized = true;
    }
  }
  
  /// 알림 권한 요청
  static Future<bool> requestPermission() async {
    try {
      // 웹에서는 권한 없음
      if (kIsWeb) {
        _hasPermission = false;
        return false;
      }
      
      // TODO: 모바일에서 실제 권한 요청
      _hasPermission = false;
      
      if (kDebugMode) {
        print('알림 권한 상태: $_hasPermission (현재 비활성화)');
      }
      
      return _hasPermission;
    } catch (e) {
      if (kDebugMode) {
        print('알림 권한 요청 실패: $e');
      }
      return false;
    }
  }
  
  /// 집중 완료 알림
  static Future<void> showFocusCompletedNotification({
    required int durationMinutes,
    required String categoryName,
  }) async {
    if (!_hasPermission || kIsWeb) {
      if (kDebugMode) {
        print('알림 비활성화: 집중 완료 알림 스킵 (${durationMinutes}분, $categoryName)');
      }
      return;
    }
    
    // TODO: 실제 알림 표시 로직
    if (kDebugMode) {
      print('집중 완료 알림: ${durationMinutes}분, $categoryName');
    }
  }
  
  /// 스톱워치 완료 알림
  static Future<void> showStopwatchCompletedNotification({
    required int elapsedMinutes,
    required String categoryName,
  }) async {
    if (!_hasPermission || kIsWeb) {
      if (kDebugMode) {
        print('알림 비활성화: 스톱워치 완료 알림 스킵 (${elapsedMinutes}분, $categoryName)');
      }
      return;
    }
    
    // TODO: 실제 알림 표시 로직
    if (kDebugMode) {
      print('스톱워치 완료 알림: ${elapsedMinutes}분, $categoryName');
    }
  }
  
  /// 중간 알림 (5분 남음)
  static Future<void> showFiveMinutesLeftNotification() async {
    if (!_hasPermission || kIsWeb) {
      if (kDebugMode) {
        print('알림 비활성화: 5분 남음 알림 스킵');
      }
      return;
    }
    
    // TODO: 실제 알림 표시 로직
    if (kDebugMode) {
      print('5분 남음 알림');
    }
  }
  
  /// 휴식 시간 알림
  static Future<void> showBreakTimeNotification({
    required int breakMinutes,
  }) async {
    if (!_hasPermission || kIsWeb) {
      if (kDebugMode) {
        print('알림 비활성화: 휴식 시간 알림 스킵 (${breakMinutes}분)');
      }
      return;
    }
    
    // TODO: 실제 알림 표시 로직
    if (kDebugMode) {
      print('휴식 시간 알림: ${breakMinutes}분');
    }
  }
  
  /// 포기 방지 알림 (백그라운드에서 일정 시간 후)
  static Future<void> showMotivationNotification() async {
    if (!_hasPermission || kIsWeb) {
      if (kDebugMode) {
        print('알림 비활성화: 동기부여 알림 스킵');
      }
      return;
    }
    
    // TODO: 실제 알림 표시 로직
    if (kDebugMode) {
      print('동기부여 알림');
    }
  }
  
  /// 모든 알림 취소
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('웹 환경: 알림 취소 스킵');
      }
      return;
    }
    
    // TODO: 실제 알림 취소 로직
    if (kDebugMode) {
      print('모든 알림 취소');
    }
  }
  
  /// 특정 알림 취소
  static Future<void> cancelNotification(int id) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('웹 환경: 알림 취소 스킵 (ID: $id)');
      }
      return;
    }
    
    // TODO: 실제 알림 취소 로직
    if (kDebugMode) {
      print('알림 취소: $id');
    }
  }
  
  /// 권한 상태 확인
  static bool get hasPermission => _hasPermission;
  
  /// 초기화 상태 확인
  static bool get isInitialized => _isInitialized;
} 