import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/focus_session_model.dart';
import '../models/user_model.dart';
import 'focus_service.dart';

/// 세션 복구 서비스
/// 앱 재시작 시 활성 세션을 감지하고 복구 기능 제공
class SessionRecoveryService {
  static const String _activeSessionKey = 'active_session';
  static const String _sessionBackupKey = 'session_backup';
  static const String _lastActiveTimeKey = 'last_active_time';
  
  /// 활성 세션 확인
  static Future<FocusSessionModel?> checkActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_activeSessionKey);
      final lastActiveTime = prefs.getInt(_lastActiveTimeKey);
      
      if (sessionJson == null || lastActiveTime == null) return null;
      
      final sessionMap = jsonDecode(sessionJson) as Map<String, dynamic>;
      final session = FocusSessionModel.fromMap(sessionMap);
      
      // 세션이 진행 중인지 확인
      if (session.status != FocusSessionStatus.running) return null;
      
      // 마지막 활성 시간으로부터 너무 오래 지났는지 확인 (6시간 이상)
      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveTime);
      final timeSinceLastActive = DateTime.now().difference(lastActive);
      
      if (timeSinceLastActive.inHours >= 6) {
        if (kDebugMode) {
          print('세션이 너무 오래됨 (${timeSinceLastActive.inHours}시간) - 자동 포기 처리');
        }
        await _abandonOldSession(session);
        return null;
      }
      
      if (kDebugMode) {
        print('활성 세션 발견: ${session.id} (${timeSinceLastActive.inMinutes}분 전)');
      }
      
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('활성 세션 확인 실패: $e');
      }
      return null;
    }
  }
  
  /// 세션 복구 다이얼로그 표시
  static Future<bool> showRecoveryDialog(
    BuildContext context, 
    FocusSessionModel session
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.restore,
                color: Colors.blue.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '세션 복구',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '진행 중이던 집중 세션이 있습니다.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          session.isStopwatchMode ? Icons.timer : Icons.timer_outlined,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          session.isStopwatchMode ? '스톱워치 모드' : '타이머 모드',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!session.isStopwatchMode) ...[
                      Text(
                        '목표 시간: ${_formatDuration(session.durationMinutesSet * 60)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      '경과 시간: ${session.formattedElapsedTime}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (!session.isStopwatchMode) ...[
                      const SizedBox(height: 4),
                      Text(
                        '남은 시간: ${_formatDuration(session.remainingSeconds)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '이 세션을 계속 진행하시겠어요?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                '새로 시작',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '계속 진행',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
  
  /// 세션 백업 저장
  static Future<void> backupSession(FocusSessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 활성 세션 저장
      await prefs.setString(_activeSessionKey, jsonEncode(session.toMap()));
      
      // 백업 저장 (추가 안전장치)
      await prefs.setString(_sessionBackupKey, jsonEncode(session.toMap()));
      
      // 마지막 활성 시간 저장
      await prefs.setInt(_lastActiveTimeKey, DateTime.now().millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('세션 백업 저장: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('세션 백업 실패: $e');
      }
    }
  }
  
  /// 활성 세션 제거
  static Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
      await prefs.remove(_lastActiveTimeKey);
      
      if (kDebugMode) {
        print('활성 세션 제거 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('활성 세션 제거 실패: $e');
      }
    }
  }
  
  /// 백업에서 세션 복구
  static Future<FocusSessionModel?> recoverFromBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupJson = prefs.getString(_sessionBackupKey);
      
      if (backupJson == null) return null;
      
      final sessionMap = jsonDecode(backupJson) as Map<String, dynamic>;
      final session = FocusSessionModel.fromMap(sessionMap);
      
      if (kDebugMode) {
        print('백업에서 세션 복구: ${session.id}');
      }
      
      return session;
    } catch (e) {
      if (kDebugMode) {
        print('백업 복구 실패: $e');
      }
      return null;
    }
  }
  
  /// 오래된 세션 자동 포기 처리
  static Future<void> _abandonOldSession(FocusSessionModel session) async {
    try {
      final abandonedSession = session.copyWith(
        status: FocusSessionStatus.abandoned,
        endedAt: DateTime.now(),
      );
      
      await FocusService.updateSession(abandonedSession);
      await clearActiveSession();
      
      if (kDebugMode) {
        print('오래된 세션 자동 포기 처리: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('오래된 세션 포기 처리 실패: $e');
      }
    }
  }
  
  /// 세션 복구 가능 여부 확인
  static Future<bool> hasRecoverableSession() async {
    final session = await checkActiveSession();
    return session != null;
  }
  
  /// 마지막 활성 시간 업데이트
  static Future<void> updateLastActiveTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastActiveTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('마지막 활성 시간 업데이트 실패: $e');
      }
    }
  }

  static String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
} 