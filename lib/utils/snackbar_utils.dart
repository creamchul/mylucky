import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// 스낵바 성능 최적화 유틸리티
class SnackBarUtils {
  static DateTime? _lastSnackBarTime;
  static const int _minIntervalMs = 500; // 최소 간격 500ms
  static const Duration _defaultDuration = Duration(milliseconds: 1500); // 기본 1.5초
  
  /// 성공 스낵바 표시 (최적화됨)
  static void showSuccess(BuildContext context, String message, {
    Duration? duration,
    bool force = false,
  }) {
    _showOptimizedSnackBar(
      context: context,
      message: message,
      backgroundColor: AppColors.green600,
      icon: Icons.check_circle_outline,
      duration: duration ?? _defaultDuration,
      force: force,
    );
  }
  
  /// 에러 스낵바 표시 (최적화됨)
  static void showError(BuildContext context, String message, {
    Duration? duration,
    bool force = false,
  }) {
    _showOptimizedSnackBar(
      context: context,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error_outline,
      duration: duration ?? _defaultDuration,
      force: force,
    );
  }
  
  /// 정보 스낵바 표시 (최적화됨)
  static void showInfo(BuildContext context, String message, {
    Duration? duration,
    bool force = false,
  }) {
    _showOptimizedSnackBar(
      context: context,
      message: message,
      backgroundColor: AppColors.blue600,
      icon: Icons.info_outline,
      duration: duration ?? _defaultDuration,
      force: force,
    );
  }
  
  /// 포인트 획득 스낵바 표시 (최적화됨)
  static void showPointsEarned(BuildContext context, int points, String activity, {
    Duration? duration,
    bool force = false,
  }) {
    _showOptimizedSnackBar(
      context: context,
      message: '$activity으로 $points 포인트 획득!',
      backgroundColor: Colors.orange.shade400,
      icon: Icons.stars,
      iconColor: Colors.amber.shade200,
      duration: duration ?? _defaultDuration,
      force: force,
    );
  }
  
  /// 습관 진행률 스낵바 표시 (최적화됨)
  static void showHabitProgress(BuildContext context, String progressText, {
    bool isCompleted = false,
    Duration? duration,
    bool force = false,
  }) {
    final message = isCompleted 
        ? '🎉 습관 목표 달성! $progressText'
        : '👍 진행률 업데이트: $progressText';
        
    _showOptimizedSnackBar(
      context: context,
      message: message,
      backgroundColor: isCompleted ? AppColors.green600 : AppColors.blue600,
      icon: isCompleted ? Icons.celebration : Icons.trending_up,
      duration: duration ?? _defaultDuration,
      force: force,
    );
  }
  
  /// 최적화된 스낵바 표시 (내부 메서드)
  static void _showOptimizedSnackBar({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Color? iconColor,
    Duration duration = _defaultDuration,
    bool force = false,
  }) {
    // 마운트 상태 확인
    if (!context.mounted) return;
    
    // 스낵바 표시 간격 제한 (force가 true가 아닌 경우)
    if (!force && _shouldThrottle()) return;
    
    // 기존 스낵바 즉시 제거 (성능 최적화)
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // 최적화된 스낵바 생성
    final snackBar = SnackBar(
      content: _buildOptimizedContent(message, icon, iconColor),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      // 애니메이션 최적화
      animation: null, // 기본 애니메이션 사용으로 성능 향상
    );
    
    // 스낵바 표시
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    
    // 마지막 표시 시간 업데이트
    _lastSnackBarTime = DateTime.now();
  }
  
  /// 스낵바 내용 위젯 생성 (최적화됨)
  static Widget _buildOptimizedContent(String message, IconData? icon, Color? iconColor) {
    if (icon == null) {
      return Text(
        message,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  
  /// 스낵바 표시 제한 확인
  static bool _shouldThrottle() {
    if (_lastSnackBarTime == null) return false;
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastSnackBarTime!).inMilliseconds;
    
    return timeDiff < _minIntervalMs;
  }
  
  /// 모든 스낵바 즉시 제거
  static void clearAll(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }
  
  /// 스낵바 설정 리셋 (테스트용)
  static void reset() {
    _lastSnackBarTime = null;
  }
} 