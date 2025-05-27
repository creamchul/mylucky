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
      // 웹과 모바일 모두 SharedPreferences 사용
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        // 기존 사용자
        final userData = json.decode(userJson);
        final user = UserModel.fromJson(userData);
        
        if (kDebugMode) {
          print('UserService: 기존 사용자 로드 - ${user.nickname}');
        }
        
        return {
          'userId': user.id,
          'nickname': user.nickname,
          'user': user,
          'isNewUser': false,
        };
      } else {
        // 새 사용자
        final userId = kIsWeb 
            ? 'web_user_${DateTime.now().millisecondsSinceEpoch}'
            : 'mobile_user_${DateTime.now().millisecondsSinceEpoch}';
            
        if (kDebugMode) {
          print('UserService: 새 사용자 감지 - $userId');
        }
        
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
      
      // 웹과 모바일 모두 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(newUser.toJson()));
      
      // Firebase는 선택적으로 사용 (모바일에서만)
      if (!kIsWeb) {
        try {
          await FirebaseService.createUser(newUser);
          if (kDebugMode) {
            print('UserService: Firebase에도 사용자 저장 완료');
          }
        } catch (e) {
          if (kDebugMode) {
            print('UserService: Firebase 저장 실패 (로컬 저장은 성공) - $e');
          }
        }
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
        // 오늘 이미 받은 카드가 있음
        return {
          'hasFortuneToday': true,
          'fortuneMessage': fortune.message,
          'todayMission': fortune.mission,
          'fortune': fortune,
        };
      } else {
        // 오늘 아직 받지 않음
        return {
          'hasFortuneToday': false,
          'fortuneMessage': '',
          'todayMission': '',
          'fortune': null,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 오늘의 카드 확인 실패 - $e');
      }
      return {
        'hasFortuneToday': false,
        'fortuneMessage': '',
        'todayMission': '',
        'fortune': null,
      };
    }
  }

  /// 새로운 카드 저장
  static Future<Map<String, dynamic>> saveNewFortune({
    required UserModel currentUser,
    required String message,
    required String mission,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('UserService: 웹 환경에서는 카드 저장 스킵');
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
        print('UserService: 새로운 카드 저장 완료');
      }
      
      return {
        'fortune': fortune,
        'user': updatedUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 카드 저장 실패 - $e');
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

  /// 사용자의 카드 이력 조회
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
        print('UserService: 카드 이력 조회 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 통계 및 랭킹
  // ========================================

  /// 사용자 통계 조회
  static Future<UserModel> getUserStats(String userId) async {
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
      // 먼저 로컬 사용자 데이터 가져오기
      final currentUser = await getCurrentUser();
      
      // Firebase 연결 상태 확인
      final isConnected = await FirebaseService.checkConnection();
      if (!isConnected) {
        // Firebase 연결 실패 시 로컬 사용자 데이터 반환
        if (currentUser != null) {
          return currentUser;
        }
        // 로컬 데이터도 없으면 기본 데이터 반환
        return UserModel.createNew(id: userId, nickname: '로컬 사용자').copyWith(
          totalFortunes: 5,
          totalMissions: 3,
          completedMissions: 2,
          consecutiveDays: 1,
          score: 50,
        );
      }
      
      // Firebase에서 사용자 데이터 가져오기 시도
      final firebaseUser = await FirebaseService.getUser(userId);
      if (firebaseUser != null) {
        return firebaseUser;
      }
      
      // Firebase에 데이터가 없으면 로컬 데이터 반환
      if (currentUser != null) {
        return currentUser;
      }
      
      // 모든 데이터가 없으면 기본 데이터 반환
      return UserModel.createNew(id: userId, nickname: '새 사용자').copyWith(
        totalFortunes: 0,
        totalMissions: 0,
        completedMissions: 0,
        consecutiveDays: 0,
        score: 0,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 사용자 통계 조회 실패 - $e');
      }
      
      // 오류 발생 시 로컬 사용자 데이터 반환
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        return currentUser;
      }
      
      // 로컬 데이터도 없으면 기본 데이터 반환
      return UserModel.createNew(id: userId, nickname: '사용자').copyWith(
        totalFortunes: 0,
        totalMissions: 0,
        completedMissions: 0,
        consecutiveDays: 0,
        score: 0,
      );
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
      // Firebase 연결 상태 확인
      final isConnected = await FirebaseService.checkConnection();
      if (!isConnected) {
        // Firebase 연결 실패 시 로컬 데모 데이터 반환
        return [
          RankingModel.fromUser('local1', {'nickname': '로컬 챔피언', 'score': 450, 'consecutiveDays': 25}, 1),
          RankingModel.fromUser('local2', {'nickname': '꾸준한 도전자', 'score': 380, 'consecutiveDays': 20}, 2),
          RankingModel.fromUser('local3', {'nickname': '행운의 주인', 'score': 320, 'consecutiveDays': 18}, 3),
          RankingModel.fromUser('local4', {'nickname': '미션 완주자', 'score': 280, 'consecutiveDays': 15}, 4),
          RankingModel.fromUser('local5', {'nickname': '새로운 도전', 'score': 220, 'consecutiveDays': 12}, 5),
        ];
      }
      
      return await FirebaseService.getRankings();
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 랭킹 조회 실패 - $e');
      }
      // 오류 발생 시 로컬 데모 데이터 반환
      return [
        RankingModel.fromUser('offline1', {'nickname': '오프라인 왕', 'score': 300, 'consecutiveDays': 15}, 1),
        RankingModel.fromUser('offline2', {'nickname': '로컬 마스터', 'score': 250, 'consecutiveDays': 12}, 2),
        RankingModel.fromUser('offline3', {'nickname': '단독 플레이어', 'score': 200, 'consecutiveDays': 10}, 3),
      ];
    }
  }

  // ========================================
  // 포인트 관리
  // ========================================

  /// 사용자에게 포인트 추가
  static Future<UserModel> addPoints({
    required UserModel currentUser,
    required int points,
    required String reason,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('UserService: 웹 환경에서 포인트 추가 - $points점');
      }
      
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore();
      
      await updateUser(updatedUser);
      return updatedUser;
    }

    try {
      // Firebase에 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: points,
        currentUser: currentUser,
      );

      // 로컬에도 저장
      await updateUser(updatedUser);

      if (kDebugMode) {
        print('UserService: 포인트 추가 완료 - $points점 ($reason)');
      }
      
      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 포인트 추가 실패 - $e');
      }
      
      // Firebase 실패 시 로컬에만 저장
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore();
      
      await updateUser(updatedUser);
      return updatedUser;
    }
  }

  /// 사용자 포인트 차감
  static Future<UserModel> deductPoints({
    required UserModel currentUser,
    required int points,
    required String reason,
  }) async {
    if (currentUser.rewardPoints < points) {
      throw Exception('포인트가 부족합니다.');
    }

    if (kIsWeb) {
      if (kDebugMode) {
        print('UserService: 웹 환경에서 포인트 차감 - $points점');
      }
      
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - points,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore();
      
      await updateUser(updatedUser);
      return updatedUser;
    }

    try {
      // Firebase에 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: -points,
        currentUser: currentUser,
      );

      // 로컬에도 저장
      await updateUser(updatedUser);

      if (kDebugMode) {
        print('UserService: 포인트 차감 완료 - $points점 ($reason)');
      }
      
      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 포인트 차감 실패 - $e');
      }
      
      // Firebase 실패 시 로컬에만 저장
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - points,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore();
      
      await updateUser(updatedUser);
      return updatedUser;
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

  // ========================================
  // 사용자 정보 업데이트
  // ========================================

  /// 사용자 정보 업데이트 (SharedPreferences에 저장)
  static Future<void> updateUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user.toJson()));
      
      if (kDebugMode) {
        print('UserService: 사용자 정보 업데이트 완료 - ${user.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 사용자 정보 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  /// 현재 사용자 정보 가져오기
  static Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      
      if (userJson != null) {
        final userData = json.decode(userJson);
        return UserModel.fromJson(userData);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('UserService: 현재 사용자 정보 가져오기 실패 - $e');
      }
      return null;
    }
  }

  // ========================================
  // 오늘의 운세 로컬 저장/불러오기 (웹)
  // ========================================
  static Future<void> saveTodayFortuneWeb({
    required String userId,
    required String fortuneMessage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'fortune_${userId}_${DateTime.now().toIso8601String().substring(0, 10)}';
    await prefs.setString(todayKey, fortuneMessage);
  }

  static Future<String?> loadTodayFortuneWeb({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = 'fortune_${userId}_${DateTime.now().toIso8601String().substring(0, 10)}';
    return prefs.getString(todayKey);
  }
}
