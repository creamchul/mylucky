import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'firebase_service.dart';

class RewardService {
  
  // ========================================
  // 포인트 지급
  // ========================================
  
  /// 출석 보상 지급
  static Future<Map<String, dynamic>> giveAttendanceReward({
    required UserModel currentUser,
    int? bonusPoints,
  }) async {
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final points = RewardModel.attendancePoints + (bonusPoints ?? 0);
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
      );
      
      if (kDebugMode) {
        print('RewardService: 웹 환경에서 출석 보상 $points 포인트 지급');
      }
      
      return {
        'user': updatedUser,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    }

    try {
      final points = RewardModel.attendancePoints + (bonusPoints ?? 0);
      
      // 보상 기록 저장
      final reward = await FirebaseService.addReward(
        userId: currentUser.id,
        type: RewardType.attendance,
        points: points,
        description: bonusPoints != null && bonusPoints > 0
            ? '출석 보상 + 연속출석 보너스로 $points 포인트 획득'
            : null,
      );
      
      // 사용자 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: points,
        currentUser: currentUser,
      );
      
      if (kDebugMode) {
        print('RewardService: 출석 보상 $points 포인트 지급 완료');
      }
      
      return {
        'user': updatedUser,
        'reward': reward,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 출석 보상 지급 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 운세 보상 지급
  static Future<Map<String, dynamic>> giveFortuneReward({
    required UserModel currentUser,
  }) async {
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      const points = RewardModel.fortunePoints;
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
      );
      
      if (kDebugMode) {
        print('RewardService: 웹 환경에서 운세 보상 $points 포인트 지급');
      }
      
      return {
        'user': updatedUser,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    }

    try {
      const points = RewardModel.fortunePoints;
      
      // 보상 기록 저장
      final reward = await FirebaseService.addReward(
        userId: currentUser.id,
        type: RewardType.fortune,
        points: points,
      );
      
      // 사용자 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: points,
        currentUser: currentUser,
      );
      
      if (kDebugMode) {
        print('RewardService: 운세 보상 $points 포인트 지급 완료');
      }
      
      return {
        'user': updatedUser,
        'reward': reward,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 운세 보상 지급 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 미션 보상 지급
  static Future<Map<String, dynamic>> giveMissionReward({
    required UserModel currentUser,
  }) async {
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      const points = RewardModel.missionPoints;
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
      );
      
      if (kDebugMode) {
        print('RewardService: 웹 환경에서 미션 보상 $points 포인트 지급');
      }
      
      return {
        'user': updatedUser,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    }

    try {
      const points = RewardModel.missionPoints;
      
      // 보상 기록 저장
      final reward = await FirebaseService.addReward(
        userId: currentUser.id,
        type: RewardType.mission,
        points: points,
      );
      
      // 사용자 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: points,
        currentUser: currentUser,
      );
      
      if (kDebugMode) {
        print('RewardService: 미션 보상 $points 포인트 지급 완료');
      }
      
      return {
        'user': updatedUser,
        'reward': reward,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 미션 보상 지급 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 보너스 포인트 지급
  static Future<Map<String, dynamic>> giveBonusReward({
    required UserModel currentUser,
    required int points,
    required String description,
  }) async {
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + points,
      );
      
      if (kDebugMode) {
        print('RewardService: 웹 환경에서 보너스 보상 $points 포인트 지급');
      }
      
      return {
        'user': updatedUser,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    }

    try {
      // 보상 기록 저장
      final reward = await FirebaseService.addReward(
        userId: currentUser.id,
        type: RewardType.bonus,
        points: points,
        description: description,
      );
      
      // 사용자 포인트 업데이트
      final updatedUser = await FirebaseService.updateUserPoints(
        userId: currentUser.id,
        pointsToAdd: points,
        currentUser: currentUser,
      );
      
      if (kDebugMode) {
        print('RewardService: 보너스 보상 $points 포인트 지급 완료');
      }
      
      return {
        'user': updatedUser,
        'reward': reward,
        'pointsEarned': points,
        'totalPoints': updatedUser.rewardPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 보너스 보상 지급 실패 - $e');
      }
      rethrow;
    }
  }
  
  // ========================================
  // 포인트 사용
  // ========================================
  
  /// 포인트 사용 (펫 성장 등)
  static Future<Map<String, dynamic>> usePoints({
    required UserModel currentUser,
    required int pointsToUse,
    required String petId,
    required String description,
  }) async {
    if (currentUser.rewardPoints < pointsToUse) {
      throw Exception('포인트가 부족합니다. (필요: $pointsToUse, 보유: ${currentUser.rewardPoints})');
    }
    
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - pointsToUse,
      );
      
      if (kDebugMode) {
        print('RewardService: 웹 환경에서 $pointsToUse 포인트 사용');
      }
      
      return {
        'user': updatedUser,
        'pointsUsed': pointsToUse,
        'remainingPoints': updatedUser.rewardPoints,
      };
    }

    try {
      // Firebase에서 포인트 사용 기록 저장 시도
      try {
        final usage = await FirebaseService.addPointsUsage(
          userId: currentUser.id,
          petId: petId,
          pointsUsed: pointsToUse,
          description: description,
        );
        
        // 사용자 포인트 차감
        final updatedUser = await FirebaseService.updateUserPoints(
          userId: currentUser.id,
          pointsToAdd: -pointsToUse, // 음수로 차감
          currentUser: currentUser,
        );
        
        if (kDebugMode) {
          print('RewardService: Firebase에서 $pointsToUse 포인트 사용 완료');
        }
        
        return {
          'user': updatedUser,
          'usage': usage,
          'pointsUsed': pointsToUse,
          'remainingPoints': updatedUser.rewardPoints,
        };
      } catch (firebaseError) {
        if (kDebugMode) {
          print('RewardService: Firebase 포인트 사용 실패, 로컬 모드로 처리 - $firebaseError');
        }
        
        // Firebase 실패 시 로컬 모드로 처리
        final updatedUser = currentUser.copyWith(
          rewardPoints: currentUser.rewardPoints - pointsToUse,
        );
        
        if (kDebugMode) {
          print('RewardService: 로컬 모드에서 $pointsToUse 포인트 사용 완료');
        }
        
        return {
          'user': updatedUser,
          'pointsUsed': pointsToUse,
          'remainingPoints': updatedUser.rewardPoints,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 포인트 사용 실패 - $e');
      }
      rethrow;
    }
  }
  
  // ========================================
  // 조회 기능
  // ========================================
  
  /// 사용자의 보상 내역 조회
  static Future<List<RewardModel>> getUserRewards(String userId, {int limit = 20}) async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return [
        RewardModel.create(
          id: 'web_reward_1',
          userId: userId,
          type: RewardType.attendance,
          points: RewardModel.attendancePoints,
        ),
        RewardModel.create(
          id: 'web_reward_2',
          userId: userId,
          type: RewardType.fortune,
          points: RewardModel.fortunePoints,
        ),
      ];
    }

    try {
      return await FirebaseService.getUserRewards(userId, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 보상 내역 조회 실패 - $e');
      }
      return [];
    }
  }
  
  /// 사용자의 포인트 사용 내역 조회
  static Future<List<PointsUsageModel>> getUserPointsUsage(String userId, {int limit = 20}) async {
    if (kIsWeb) {
      // 웹에서는 데모 데이터
      return [];
    }

    try {
      return await FirebaseService.getUserPointsUsage(userId, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('RewardService: 포인트 사용 내역 조회 실패 - $e');
      }
      return [];
    }
  }
  
  // ========================================
  // 유틸리티
  // ========================================
  
  /// 연속 출석 보너스 계산
  static int calculateAttendanceBonus(int consecutiveDays) {
    if (consecutiveDays >= 30) return 30; // 30일 이상: +30 포인트
    if (consecutiveDays >= 14) return 20; // 14일 이상: +20 포인트
    if (consecutiveDays >= 7) return 10;  // 7일 이상: +10 포인트
    if (consecutiveDays >= 3) return 5;   // 3일 이상: +5 포인트
    return 0; // 보너스 없음
  }
  
  /// 포인트 충분 여부 확인
  static bool hasEnoughPoints(UserModel user, int requiredPoints) {
    return user.rewardPoints >= requiredPoints;
  }
} 