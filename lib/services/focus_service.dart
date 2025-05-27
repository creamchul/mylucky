import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/focus_session_model.dart';
import '../models/user_model.dart'; // 사용자 모델 필요
import './user_service.dart'; // 사용자 서비스 필요 (리워드 포인트 업데이트 등)

class FocusService {
  static const String _sessionsKey = 'focus_sessions';
  static const String _activeSessionKey = 'active_session';

  // 새로운 집중 세션 생성
  static Future<FocusSessionModel> createSession({
    required String userId,
    required int durationMinutes,
    TreeType treeType = TreeType.basic,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final newSession = FocusSessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        durationMinutesSet: durationMinutes,
        treeType: treeType,
      );

      // 활성 세션으로 저장
      await prefs.setString(_activeSessionKey, jsonEncode(newSession.toMap()));
      
      if (kDebugMode) {
        print('집중 세션 생성 성공: ${newSession.id}');
      }
      
      return newSession;
    } catch (e) {
      if (kDebugMode) {
        print('집중 세션 생성 실패: $e');
      }
      rethrow;
    }
  }

  // 세션 업데이트
  static Future<void> updateSession(FocusSessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 활성 세션 업데이트
      await prefs.setString(_activeSessionKey, jsonEncode(session.toMap()));
      
      if (kDebugMode) {
        print('세션 업데이트 성공: ${session.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('세션 업데이트 실패: $e');
      }
      rethrow;
    }
  }

  // 특정 세션 가져오기
  static Future<FocusSessionModel?> getSession(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSessionJson = prefs.getString(_activeSessionKey);
      
      if (activeSessionJson != null) {
        final sessionMap = jsonDecode(activeSessionJson) as Map<String, dynamic>;
        final session = FocusSessionModel.fromMap(sessionMap);
        if (session.id == sessionId) {
          return session;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('세션 조회 실패: $e');
      }
      return null;
    }
  }

  // 사용자의 모든 집중 세션 가져오기
  static Future<List<FocusSessionModel>> getUserSessions(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      List<FocusSessionModel> sessions = [];
      
      if (sessionsJson != null) {
        final sessionsList = jsonDecode(sessionsJson) as List<dynamic>;
        sessions = sessionsList
            .map((json) => FocusSessionModel.fromMap(json as Map<String, dynamic>))
            .where((session) => session.userId == userId)
            .toList();
      }
      
      // 데이터가 없으면 데모 데이터 생성
      if (sessions.isEmpty) {
        sessions = await _createDemoSessions(userId);
      }
      
      return sessions;
    } catch (e) {
      if (kDebugMode) {
        print('사용자 세션 조회 실패: $e');
      }
      // 오류 발생 시에도 데모 데이터 반환
      return await _createDemoSessions(userId);
    }
  }
  
  // 데모 세션 데이터 생성
  static Future<List<FocusSessionModel>> _createDemoSessions(String userId) async {
    final now = DateTime.now();
    final demoSessions = [
      // 완료된 세션들
      FocusSessionModel(
        id: 'demo_1',
        userId: userId,
        durationMinutesSet: 25,
        elapsedSeconds: 25 * 60,
        status: FocusSessionStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
        endedAt: now.subtract(const Duration(days: 1, hours: -1)),
      ),
      FocusSessionModel(
        id: 'demo_2',
        userId: userId,
        durationMinutesSet: 15,
        elapsedSeconds: 15 * 60,
        status: FocusSessionStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        endedAt: now.subtract(const Duration(days: 2, hours: -1)),
      ),
      FocusSessionModel(
        id: 'demo_3',
        userId: userId,
        durationMinutesSet: 30,
        elapsedSeconds: 30 * 60,
        status: FocusSessionStatus.completed,
        createdAt: now.subtract(const Duration(days: 3)),
        endedAt: now.subtract(const Duration(days: 3, hours: -1)),
      ),
      // 포기한 세션들
      FocusSessionModel(
        id: 'demo_4',
        userId: userId,
        durationMinutesSet: 20,
        elapsedSeconds: (8 * 60).clamp(0, 20 * 60), // 8분만 집중하고 포기, 안전한 범위로 제한
        status: FocusSessionStatus.abandoned,
        createdAt: now.subtract(const Duration(days: 4)),
        endedAt: now.subtract(const Duration(days: 4, hours: -1)),
      ),
      FocusSessionModel(
        id: 'demo_5',
        userId: userId,
        durationMinutesSet: 45,
        elapsedSeconds: 45 * 60,
        status: FocusSessionStatus.completed,
        createdAt: now.subtract(const Duration(days: 5)),
        endedAt: now.subtract(const Duration(days: 5, hours: -1)),
      ),
    ];
    
    // 데모 데이터를 로컬 저장소에 저장
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsList = demoSessions.map((s) => s.toMap()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(sessionsList));
      
      if (kDebugMode) {
        print('데모 집중 세션 데이터 생성 완료: ${demoSessions.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('데모 데이터 저장 실패: $e');
      }
    }
    
    return demoSessions;
  }

  // 집중 완료 처리
  static Future<FocusSessionModel> completeSession(FocusSessionModel session, UserModel currentUser) async {
    try {
      final completedSession = session.copyWith(
        status: FocusSessionStatus.completed,
        elapsedSeconds: session.durationSecondsSet,
        endedAt: DateTime.now(),
      );
      
      // 완료된 세션을 저장소에 추가
      await _saveCompletedSession(completedSession);
      
      // 활성 세션 제거
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);

      // 리워드 포인트 지급
      int reward = session.durationMinutesSet;
      final updatedUser = currentUser.copyWith(rewardPoints: currentUser.rewardPoints + reward);
      await UserService.updateUser(updatedUser);

      if (kDebugMode) {
        print('집중 완료 처리 성공: ${completedSession.id}');
      }

      return completedSession;
    } catch (e) {
      if (kDebugMode) {
        print('집중 완료 처리 실패: $e');
      }
      rethrow;
    }
  }

  // 집중 포기 처리
  static Future<FocusSessionModel> abandonSession(FocusSessionModel session) async {
    try {
      final abandonedSession = session.copyWith(
        status: FocusSessionStatus.abandoned,
        endedAt: DateTime.now(),
      );
      
      // 포기된 세션을 저장소에 추가
      await _saveCompletedSession(abandonedSession);
      
      // 활성 세션 제거
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
      
      if (kDebugMode) {
        print('집중 포기 처리 성공: ${abandonedSession.id}');
      }
      
      return abandonedSession;
    } catch (e) {
      if (kDebugMode) {
        print('집중 포기 처리 실패: $e');
      }
      rethrow;
    }
  }

  // 활성화된 세션 확인
  static Future<FocusSessionModel?> getActiveSession(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeSessionJson = prefs.getString(_activeSessionKey);
      
      if (activeSessionJson != null) {
        final sessionMap = jsonDecode(activeSessionJson) as Map<String, dynamic>;
        final session = FocusSessionModel.fromMap(sessionMap);
        if (session.userId == userId && session.status == FocusSessionStatus.running) {
          return session;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('활성 세션 조회 실패: $e');
      }
      return null;
    }
  }

  // 완료된 세션을 저장소에 추가하는 헬퍼 메서드
  static Future<void> _saveCompletedSession(FocusSessionModel session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);
    
    List<Map<String, dynamic>> sessionsList = [];
    if (sessionsJson != null) {
      final decoded = jsonDecode(sessionsJson) as List<dynamic>;
      sessionsList = decoded.cast<Map<String, dynamic>>();
    }
    
    sessionsList.insert(0, session.toMap()); // 최신 세션을 맨 앞에 추가
    
    // 최대 100개 세션만 보관
    if (sessionsList.length > 100) {
      sessionsList = sessionsList.take(100).toList();
    }
    
    await prefs.setString(_sessionsKey, jsonEncode(sessionsList));
  }
} 