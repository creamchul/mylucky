import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/models.dart';
import '../utils/utils.dart';
import 'firebase_service.dart';
import 'reward_service.dart';

class UserService {
  static const String _userKey = 'current_user';
  
  // ========================================
  // 사용자 초기화 및 관리
  // ========================================

  /// 사용자 초기화 (웹/모바일 통합)
  static Future<Map<String, dynamic>> initializeUser() async {
    try {
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지 사용
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(_userKey);
        
        if (userJson != null) {
          // 기존 사용자
          final userData = json.decode(userJson);
          final user = UserModel.fromJson(userData);
          
          return {
            'userId': user.id,
            'nickname': user.nickname,
            'user': user,
            'isNewUser': false,
          };
        } else {
          // 새 사용자
          final userId = 'web_user_${DateTime.now().millisecondsSinceEpoch}';
          return {
            'userId': userId,
            'nickname': '',
            'user': null,
            'isNewUser': true,
          };
        }
      }
      
      // 모바일에서는 Firebase 사용
      final userId = await FirebaseService.getCurrentUserId();
      final user = await FirebaseService.getUser(userId);
      
      if (user != null) {
        // 기존 사용자
        return {
          'userId': userId,
          'nickname': user.nickname,
          'user': user,
          'isNewUser': false,
        };
      } else {
        // 새 사용자
        return {
          'userId': userId,
          'nickname': '',
          'user': null,
          'isNewUser': true,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 사용자 초기화 실패 - $e');
      }
      rethrow;
    }
  }

  /// 새 사용자 생성
  static Future<UserModel> createNewUser({
    required String userId,
    required String nickname,
  }) async {
    try {
      final newUser = UserModel.createNew(
        id: userId,
        nickname: nickname,
      );
      
      if (kIsWeb) {
        // 웹에서는 로컬 스토리지에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(newUser.toJson()));
      } else {
        // 모바일에서는 Firebase에 저장
        await FirebaseService.createUser(newUser);
      }
      
      if (kDebugMode) {
        print('UserService: 새 사용자 생성 완료 - $nickname');
      }
      
      return newUser;
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 새 사용자 생성 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 출석 관리
  // ========================================

  /// 출석 체크 및 연속 출석일수 계산
  static Future<Map<String, dynamic>> checkAndUpdateAttendance(UserModel currentUser) async {
    try {
      final today = DateTime.now();
      final todayFormatted = _formatDate(today);
      
      if (kIsWeb) {
        // 웹에서는 로컬 처리
        final prefs = await SharedPreferences.getInstance();
        final lastAttendanceKey = 'last_attendance_${currentUser.id}';
        final consecutiveDaysKey = 'consecutive_days_${currentUser.id}';
        
        final lastAttendance = prefs.getString(lastAttendanceKey);
        final consecutiveDays = prefs.getInt(consecutiveDaysKey) ?? 0;
        
        if (lastAttendance == todayFormatted) {
          // 이미 오늘 출석함
          return {
            'consecutiveDays': consecutiveDays,
            'isFirstAttendanceToday': false,
            'shouldShowCelebration': false,
            'user': currentUser,
            'pointsEarned': 0,
          };
        }
        
        // 연속 출석일수 계산
        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayFormatted = _formatDate(yesterday);
        
        int newConsecutiveDays;
        if (lastAttendance == yesterdayFormatted) {
          // 연속 출석
          newConsecutiveDays = consecutiveDays + 1;
        } else {
          // 연속 출석 끊김
          newConsecutiveDays = 1;
        }
        
        // 보상 계산
        final bonusPoints = RewardService.calculateAttendanceBonus(newConsecutiveDays);
        
        // 보상 지급
        final rewardResult = await RewardService.giveAttendanceReward(
          currentUser: currentUser,
          bonusPoints: bonusPoints,
        );
        
        // 로컬 저장
        await prefs.setString(lastAttendanceKey, todayFormatted);
        await prefs.setInt(consecutiveDaysKey, newConsecutiveDays);
        
        // 사용자 정보 업데이트
        final updatedUser = (rewardResult['user'] as UserModel).copyWith(
          consecutiveDays: newConsecutiveDays,
          lastActiveDate: today,
        ).withUpdatedScore();
        
        await prefs.setString(_userKey, json.encode(updatedUser.toJson()));
        
        final shouldShowCelebration = _shouldShowCelebration(newConsecutiveDays);
        
        return {
          'consecutiveDays': newConsecutiveDays,
          'isFirstAttendanceToday': true,
          'shouldShowCelebration': shouldShowCelebration,
          'user': updatedUser,
          'pointsEarned': rewardResult['pointsEarned'],
        };
      }
      
      // Firebase 처리
      final attendanceResult = await FirebaseService.checkTodayAttendance(
        userId: currentUser.id,
        today: today,
      );
      
      if (!attendanceResult['isFirstTime']) {
        // 이미 오늘 출석함
        return {
          'consecutiveDays': attendanceResult['consecutiveDays'],
          'isFirstAttendanceToday': false,
          'shouldShowCelebration': false,
          'user': currentUser,
          'pointsEarned': 0,
        };
      }
      
      // 새로운 출석
      final consecutiveDays = attendanceResult['consecutiveDays'] as int;
      final bonusPoints = RewardService.calculateAttendanceBonus(consecutiveDays);
      
      // 보상 지급
      final rewardResult = await RewardService.giveAttendanceReward(
        currentUser: currentUser,
        bonusPoints: bonusPoints,
      );
      
      // 사용자 연속 출석일수 업데이트
      final updatedUser = await FirebaseService.updateUserSimple(
        userId: currentUser.id,
        updates: {
          'consecutiveDays': consecutiveDays,
          'lastActiveDate': today,
        },
        currentUser: rewardResult['user'],
      );
      
      final shouldShowCelebration = _shouldShowCelebration(consecutiveDays);
      
      if (kDebugMode) {
        print('UserService: 출석 체크 완료 - 연속 $consecutiveDays일, 포인트 ${rewardResult['pointsEarned']}');
      }
      
      return {
        'consecutiveDays': consecutiveDays,
        'isFirstAttendanceToday': true,
        'shouldShowCelebration': shouldShowCelebration,
        'user': updatedUser,
        'pointsEarned': rewardResult['pointsEarned'],
      };
      
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 출석 체크 실패 - $e');
      }
      rethrow;
    }
  }

  /// 축하 메시지를 표시할지 결정하는 함수
  static bool _shouldShowCelebration(int days) {
    return days == 3 || days == 7 || days == 14 || days == 30 || 
           days == 50 || days == 100 || (days > 0 && days % 100 == 0);
  }

  /// 출석일수에 따른 축하 메시지 반환
  static String getCelebrationMessage(int days) {
    return TextUtils.getCelebrationMessage(days); // Utils 사용
  }

  // ========================================
  // 운세 관리
  // ========================================

  /// 오늘의 운세 확인 및 처리
  static Future<Map<String, dynamic>> handleTodayFortune(String userId) async {
    if (kIsWeb) {
      // 웹에서는 간단한 처리
      return {
        'hasFortuneToday': false,
        'fortuneMessage': '',
        'todayMission': '',
        'fortune': null,
      };
    }

    try {
      final fortune = await FirebaseService.getTodayFortune();
      
      if (fortune != null) {
        // 오늘 이미 뽑은 운세가 있음
        return {
          'hasFortuneToday': true,
          'fortuneMessage': fortune.message,
          'todayMission': fortune.mission,
          'fortune': fortune,
        };
      } else {
        // 오늘 아직 뽑지 않음
        return {
          'hasFortuneToday': false,
          'fortuneMessage': '',
          'todayMission': '',
          'fortune': null,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 오늘의 운세 확인 실패 - $e');
      }
      return {
        'hasFortuneToday': false,
        'fortuneMessage': '',
        'todayMission': '',
        'fortune': null,
      };
    }
  }

  /// 새로운 운세 저장
  static Future<Map<String, dynamic>> saveNewFortune({
    required UserModel currentUser,
    required String message,
    required String mission,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('UserService: 웹 환경에서는 운세 저장 스킵');
      }
      return {
        'fortune': FortuneModel.create(id: 'web_fortune', message: message, mission: mission),
        'user': currentUser,
      };
    }

    try {
      final fortune = await FirebaseService.saveFortune(
        message: message,
        mission: mission,
      );

      // 사용자 통계 업데이트
      final updatedUser = await FirebaseService.updateUser(
        currentUser: currentUser,
        addFortune: true,
      );

      if (kDebugMode) {
        print('UserService: 새로운 운세 저장 완료');
      }
      
      return {
        'fortune': fortune,
        'user': updatedUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 운세 저장 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 미션 관리
  // ========================================

  /// 미션 완료 처리
  static Future<Map<String, dynamic>> completeMission({
    required UserModel currentUser,
    required String mission,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('UserService: 웹 환경에서 미션 완료 처리');
      }
      return {
        'mission': MissionModel.create(id: 'web_mission', userId: currentUser.id, mission: mission),
        'user': currentUser,
      };
    }

    try {
      final missionModel = await FirebaseService.completeMission(
        userId: currentUser.id,
        mission: mission,
      );

      // 사용자 통계 업데이트
      final updatedUser = await FirebaseService.updateUser(
        currentUser: currentUser,
        completeMission: true,
      );

      if (kDebugMode) {
        print('UserService: 미션 완료 처리 완료');
      }
      
      return {
        'mission': missionModel,
        'user': updatedUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 미션 완료 처리 실패 - $e');
      }
      rethrow;
    }
  }

  /// 오늘의 미션 상태 확인
  static Future<bool> checkTodayMissionStatus(String userId) async {
    if (kIsWeb) {
      return false; // 웹에서는 항상 미완료로 처리
    }

    try {
      return await FirebaseService.checkTodayMissionStatus(userId);
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 미션 상태 확인 실패 - $e');
      }
      return false;
    }
  }

  /// 사용자의 미션 이력 조회
  static Future<List<MissionModel>> getUserMissionHistory(String userId) async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return [
        MissionModel.create(
          id: 'web_mission_1',
          userId: userId,
          mission: '웹 데모 미션 1',
        ),
        MissionModel.create(
          id: 'web_mission_2',
          userId: userId,
          mission: '웹 데모 미션 2',
        ),
      ];
    }

    try {
      return await FirebaseService.getUserMissionHistory(userId);
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 미션 이력 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 사용자의 운세 이력 조회
  static Future<List<FortuneModel>> getUserFortuneHistory(String userId) async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return [
        FortuneModel.create(
          id: 'web_fortune_1',
          message: '오늘은 좋은 일이 생길 거예요',
          mission: '웹 데모 미션 1',
        ),
        FortuneModel.create(
          id: 'web_fortune_2',
          message: '새로운 기회가 찾아올 것입니다',
          mission: '웹 데모 미션 2',
        ),
      ];
    }

    try {
      return await FirebaseService.getUserFortuneHistory(userId);
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 운세 이력 조회 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 통계 및 랭킹
  // ========================================

  /// 사용자 통계 조회
  static Future<UserModel?> getUserStats(String userId) async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return UserModel.createNew(id: userId, nickname: '웹 사용자').copyWith(
        totalFortunes: 15,
        totalMissions: 12,
        completedMissions: 10,
        consecutiveDays: 7,
        score: 180,
      );
    }

    try {
      return await FirebaseService.getUser(userId);
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 사용자 통계 조회 실패 - $e');
      }
      return null;
    }
  }

  /// 랭킹 조회
  static Future<List<RankingModel>> getRankings() async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return [
        RankingModel.fromUser('user1', {'nickname': '행운의 왕', 'score': 850, 'consecutiveDays': 45}, 1),
        RankingModel.fromUser('user2', {'nickname': '미션 마스터', 'score': 720, 'consecutiveDays': 38}, 2),
        RankingModel.fromUser('user3', {'nickname': '운세의 달인', 'score': 680, 'consecutiveDays': 32}, 3),
        RankingModel.fromUser('user4', {'nickname': '꾸준함의 힘', 'score': 590, 'consecutiveDays': 28}, 4),
        RankingModel.fromUser('user5', {'nickname': '행복한 하루', 'score': 520, 'consecutiveDays': 25}, 5),
      ];
    }

    try {
      return await FirebaseService.getRankings();
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 랭킹 조회 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 유틸리티
  // ========================================

  /// 앱 연결 상태 확인
  static Future<bool> checkAppHealth() async {
    if (kIsWeb) {
      return true; // 웹에서는 항상 정상
    }

    try {
      return await FirebaseService.checkConnection();
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 앱 상태 확인 실패 - $e');
      }
      return false;
    }
  }

  /// 사용자 ID 생성 (기기별 고유 ID)
  static String generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 웹 사용자 ID 생성
  static String generateWebUserId() {
    return 'web_user_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
