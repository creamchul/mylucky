import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 성능 최적화 서비스
/// 메모리 관리, 리소스 정리, 배터리 최적화 등을 담당
class PerformanceService {
  static Timer? _memoryCheckTimer;
  static Timer? _resourceCleanupTimer;
  static final List<StreamSubscription> _subscriptions = [];
  static final List<Timer> _timers = [];
  
  /// 성능 최적화 초기화
  static Future<void> initialize() async {
    try {
      // 메모리 모니터링 시작 (디버그 모드에서만)
      if (kDebugMode) {
        _startMemoryMonitoring();
      }
      
      // 주기적 리소스 정리 시작
      _startResourceCleanup();
      
      // 시스템 최적화 설정
      await _optimizeSystemSettings();
      
      if (kDebugMode) {
        print('성능 최적화 서비스 초기화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('성능 최적화 서비스 초기화 실패: $e');
      }
    }
  }
  
  /// 메모리 모니터링 시작
  static void _startMemoryMonitoring() {
    _memoryCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _checkMemoryUsage(),
    );
  }
  
  /// 메모리 사용량 확인
  static void _checkMemoryUsage() {
    if (!kDebugMode) return;
    
    try {
      // 가비지 컬렉션 강제 실행 (필요시)
      if (_shouldForceGC()) {
        _forceGarbageCollection();
      }
      
      if (kDebugMode) {
        print('메모리 체크 완료 - ${DateTime.now()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('메모리 체크 실패: $e');
      }
    }
  }
  
  /// 가비지 컬렉션 필요 여부 확인
  static bool _shouldForceGC() {
    // 간단한 휴리스틱: 타이머나 구독이 많이 쌓였을 때
    return _timers.length > 10 || _subscriptions.length > 20;
  }
  
  /// 가비지 컬렉션 강제 실행
  static void _forceGarbageCollection() {
    try {
      // 사용하지 않는 리소스 정리
      _cleanupUnusedResources();
      
      if (kDebugMode) {
        print('가비지 컬렉션 실행됨');
      }
    } catch (e) {
      if (kDebugMode) {
        print('가비지 컬렉션 실패: $e');
      }
    }
  }
  
  /// 주기적 리소스 정리 시작
  static void _startResourceCleanup() {
    _resourceCleanupTimer = Timer.periodic(
      const Duration(minutes: 10),
      (timer) => _cleanupResources(),
    );
  }
  
  /// 리소스 정리
  static void _cleanupResources() {
    try {
      // 완료된 타이머 제거
      _timers.removeWhere((timer) => !timer.isActive);
      
      // 취소된 구독 제거
      _subscriptions.removeWhere((subscription) => subscription.isPaused);
      
      // 사용하지 않는 리소스 정리
      _cleanupUnusedResources();
      
      if (kDebugMode) {
        print('리소스 정리 완료 - 타이머: ${_timers.length}, 구독: ${_subscriptions.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('리소스 정리 실패: $e');
      }
    }
  }
  
  /// 사용하지 않는 리소스 정리
  static void _cleanupUnusedResources() {
    try {
      // 이미지 캐시 정리 (메모리 절약)
      PaintingBinding.instance.imageCache.clear();
      
      // 네트워크 이미지 캐시 정리
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      if (kDebugMode) {
        print('이미지 캐시 정리 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('리소스 정리 중 오류: $e');
      }
    }
  }
  
  /// 시스템 최적화 설정
  static Future<void> _optimizeSystemSettings() async {
    try {
      // 시스템 UI 오버레이 스타일 최적화
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      
      // 화면 방향 고정 (배터리 절약)
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      if (kDebugMode) {
        print('시스템 최적화 설정 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('시스템 최적화 설정 실패: $e');
      }
    }
  }
  
  /// 타이머 등록 (추적을 위해)
  static void registerTimer(Timer timer) {
    _timers.add(timer);
    
    if (kDebugMode && _timers.length > 15) {
      print('경고: 타이머가 많이 등록됨 (${_timers.length}개)');
    }
  }
  
  /// 구독 등록 (추적을 위해)
  static void registerSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
    
    if (kDebugMode && _subscriptions.length > 25) {
      print('경고: 구독이 많이 등록됨 (${_subscriptions.length}개)');
    }
  }
  
  /// 타이머 해제
  static void unregisterTimer(Timer timer) {
    _timers.remove(timer);
  }
  
  /// 구독 해제
  static void unregisterSubscription(StreamSubscription subscription) {
    _subscriptions.remove(subscription);
  }
  
  /// 배터리 최적화 모드 활성화
  static void enableBatteryOptimization() {
    try {
      // 애니메이션 지속 시간 단축
      timeDilation = 0.5;
      
      if (kDebugMode) {
        print('배터리 최적화 모드 활성화');
      }
    } catch (e) {
      if (kDebugMode) {
        print('배터리 최적화 모드 활성화 실패: $e');
      }
    }
  }
  
  /// 배터리 최적화 모드 비활성화
  static void disableBatteryOptimization() {
    try {
      // 애니메이션 지속 시간 복원
      timeDilation = 1.0;
      
      if (kDebugMode) {
        print('배터리 최적화 모드 비활성화');
      }
    } catch (e) {
      if (kDebugMode) {
        print('배터리 최적화 모드 비활성화 실패: $e');
      }
    }
  }
  
  /// 메모리 사용량 최적화
  static void optimizeMemoryUsage() {
    try {
      // 이미지 캐시 크기 제한
      PaintingBinding.instance.imageCache.maximumSize = 100;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
      
      // 불필요한 위젯 트리 정리
      WidgetsBinding.instance.buildOwner?.finalizeTree();
      
      if (kDebugMode) {
        print('메모리 사용량 최적화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('메모리 사용량 최적화 실패: $e');
      }
    }
  }
  
  /// 앱 일시정지 시 최적화
  static void onAppPaused() {
    try {
      // 백그라운드에서 불필요한 작업 중단
      _pauseNonEssentialOperations();
      
      // 메모리 정리
      _cleanupResources();
      
      if (kDebugMode) {
        print('앱 일시정지 최적화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('앱 일시정지 최적화 실패: $e');
      }
    }
  }
  
  /// 앱 재개 시 최적화
  static void onAppResumed() {
    try {
      // 필요한 작업 재개
      _resumeEssentialOperations();
      
      if (kDebugMode) {
        print('앱 재개 최적화 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('앱 재개 최적화 실패: $e');
      }
    }
  }
  
  /// 필수적이지 않은 작업 일시정지
  static void _pauseNonEssentialOperations() {
    // 메모리 모니터링 일시정지
    _memoryCheckTimer?.cancel();
    
    // 리소스 정리 타이머 일시정지
    _resourceCleanupTimer?.cancel();
  }
  
  /// 필수 작업 재개
  static void _resumeEssentialOperations() {
    // 메모리 모니터링 재개 (디버그 모드에서만)
    if (kDebugMode) {
      _startMemoryMonitoring();
    }
    
    // 리소스 정리 재개
    _startResourceCleanup();
  }
  
  /// 서비스 종료 및 정리
  static void dispose() {
    try {
      // 모든 타이머 정리
      _memoryCheckTimer?.cancel();
      _resourceCleanupTimer?.cancel();
      
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
      
      // 모든 구독 정리
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
      
      // 최종 리소스 정리
      _cleanupUnusedResources();
      
      if (kDebugMode) {
        print('성능 최적화 서비스 종료 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('성능 최적화 서비스 종료 실패: $e');
      }
    }
  }
  
  /// 현재 성능 상태 정보
  static Map<String, dynamic> getPerformanceInfo() {
    return {
      'activeTimers': _timers.length,
      'activeSubscriptions': _subscriptions.length,
      'imageCacheSize': PaintingBinding.instance.imageCache.currentSize,
      'imageCacheBytes': PaintingBinding.instance.imageCache.currentSizeBytes,
      'isMemoryMonitoring': _memoryCheckTimer?.isActive ?? false,
      'isResourceCleanup': _resourceCleanupTimer?.isActive ?? false,
    };
  }
} 