import 'dart:async';
import 'package:flutter/foundation.dart';

/// 고정밀 타이머 서비스
/// 시스템 시간 기반으로 정확한 타이머 기능 제공
class PrecisionTimerService {
  static const Duration _updateInterval = Duration(milliseconds: 100);
  
  Timer? _timer;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  bool _isRunning = false;
  bool _isPaused = false;
  
  // 콜백 함수들
  Function(Duration elapsed)? onTick;
  Function()? onComplete;
  
  // 타이머 설정
  Duration? targetDuration;
  bool isStopwatchMode = false;
  
  /// 타이머 시작
  void start({
    Duration? duration,
    bool stopwatchMode = false,
    Function(Duration elapsed)? onTickCallback,
    Function()? onCompleteCallback,
  }) {
    if (_isRunning) return;
    
    targetDuration = duration;
    isStopwatchMode = stopwatchMode;
    onTick = onTickCallback;
    onComplete = onCompleteCallback;
    
    _startTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _isRunning = true;
    _isPaused = false;
    
    _startPeriodicTimer();
    
    if (kDebugMode) {
      print('PrecisionTimer 시작: ${stopwatchMode ? '스톱워치' : '타이머'} 모드');
    }
  }
  
  /// 타이머 일시정지
  void pause() {
    if (!_isRunning || _isPaused) return;
    
    _pauseTime = DateTime.now();
    _isPaused = true;
    _timer?.cancel();
    
    if (kDebugMode) {
      print('PrecisionTimer 일시정지');
    }
  }
  
  /// 타이머 재개
  void resume() {
    if (!_isRunning || !_isPaused) return;
    
    if (_pauseTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseTime!);
    }
    _isPaused = false;
    _startPeriodicTimer();
    
    if (kDebugMode) {
      print('PrecisionTimer 재개');
    }
  }
  
  /// 타이머 중지
  void stop() {
    _timer?.cancel();
    _isRunning = false;
    _isPaused = false;
    _startTime = null;
    _pauseTime = null;
    _pausedDuration = Duration.zero;
    
    if (kDebugMode) {
      print('PrecisionTimer 중지');
    }
  }
  
  /// 현재 경과 시간 가져오기
  Duration get elapsedTime {
    if (_startTime == null) return Duration.zero;
    
    DateTime endTime;
    if (_isPaused && _pauseTime != null) {
      endTime = _pauseTime!;
    } else {
      endTime = DateTime.now();
    }
    
    final totalElapsed = endTime.difference(_startTime!);
    return totalElapsed - _pausedDuration;
  }
  
  /// 남은 시간 (타이머 모드에서만)
  Duration get remainingTime {
    if (isStopwatchMode || targetDuration == null) return Duration.zero;
    
    final remaining = targetDuration! - elapsedTime;
    return remaining.isNegative ? Duration.zero : remaining;
  }
  
  /// 진행률 (0.0 ~ 1.0)
  double get progress {
    if (isStopwatchMode) {
      return _getStopwatchProgress();
    }
    
    if (targetDuration == null || targetDuration!.inSeconds == 0) return 0.0;
    
    final elapsed = elapsedTime.inSeconds;
    final total = targetDuration!.inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
  
  /// 스톱워치 모드 진행률 계산
  double _getStopwatchProgress() {
    final minutes = elapsedTime.inMinutes;
    if (minutes < 15) return minutes / 15 * 0.25; // 0-15분: 0-25%
    if (minutes < 30) return 0.25 + (minutes - 15) / 15 * 0.25; // 15-30분: 25-50%
    if (minutes < 60) return 0.50 + (minutes - 30) / 30 * 0.25; // 30-60분: 50-75%
    if (minutes < 90) return 0.75 + (minutes - 60) / 30 * 0.20; // 60-90분: 75-95%
    return 0.95 + ((minutes - 90) / 60 * 0.05).clamp(0.0, 0.05); // 90분+: 95-100%
  }
  
  /// 타이머 상태
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isActive => _isRunning && !_isPaused;
  
  /// 주기적 타이머 시작
  void _startPeriodicTimer() {
    _timer = Timer.periodic(_updateInterval, (timer) {
      if (!_isRunning || _isPaused) {
        timer.cancel();
        return;
      }
      
      final elapsed = elapsedTime;
      onTick?.call(elapsed);
      
      // 타이머 모드에서 목표 시간 도달 시 완료
      if (!isStopwatchMode && 
          targetDuration != null && 
          elapsed >= targetDuration!) {
        timer.cancel();
        _isRunning = false;
        onComplete?.call();
        
        if (kDebugMode) {
          print('PrecisionTimer 완료: ${elapsed.inSeconds}초');
        }
      }
    });
  }
  
  /// 백그라운드 진입 시 호출
  void onAppPaused() {
    if (_isRunning && !_isPaused) {
      _pauseTime = DateTime.now();
      if (kDebugMode) {
        print('앱 백그라운드 진입 - 시간 기록: $_pauseTime');
      }
    }
  }
  
  /// 포그라운드 복귀 시 호출
  void onAppResumed() {
    if (_isRunning && _pauseTime != null) {
      final backgroundDuration = DateTime.now().difference(_pauseTime!);
      
      if (kDebugMode) {
        print('앱 포그라운드 복귀 - 백그라운드 시간: ${backgroundDuration.inSeconds}초');
      }
      
      // 백그라운드 시간을 경과 시간에 반영하지 않음 (일시정지 상태로 처리)
      _pauseTime = null;
      
      // 즉시 현재 상태 업데이트
      final elapsed = elapsedTime;
      onTick?.call(elapsed);
      
      // 타이머 모드에서 목표 시간 초과 시 완료 처리
      if (!isStopwatchMode && 
          targetDuration != null && 
          elapsed >= targetDuration!) {
        _isRunning = false;
        onComplete?.call();
      }
    }
  }
  
  /// 리소스 정리
  void dispose() {
    stop();
  }
  
  /// 개발자 모드용: 시작 시간을 조정하여 시간을 앞당김
  void adjustStartTime(Duration adjustment) {
    if (_startTime != null && _isRunning) {
      _startTime = _startTime!.subtract(adjustment);
      
      if (kDebugMode) {
        print('PrecisionTimer 시작 시간 조정: ${adjustment.inMinutes}분 앞당김');
      }
      
      // 즉시 현재 상태 업데이트
      final elapsed = elapsedTime;
      onTick?.call(elapsed);
      
      // 타이머 모드에서 목표 시간 초과 시 완료 처리
      if (!isStopwatchMode && 
          targetDuration != null && 
          elapsed >= targetDuration!) {
        _isRunning = false;
        onComplete?.call();
      }
    }
  }
} 