import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'todo_service.dart';
import 'habit_service.dart';
import 'challenge_service.dart';
import 'reward_service.dart';

/// 시스템 통합 서비스 - Phase 4
/// 투두, 습관, 챌린지 시스템과 동물/포레스트 시스템을 연동
class IntegrationService {
  
  // ========================================
  // 동물 시스템 연동
  // ========================================
  
  /// 투두 완료 시 동물 시스템 연동
  static Future<Map<String, dynamic>> onTodoCompleted({
    required UserModel currentUser,
    required TodoItemModel todo,
  }) async {
    try {
      Map<String, dynamic> result = {
        'user': currentUser,
        'animalReward': null,
        'specialBonus': null,
      };

      // 기본 포인트 지급
      final rewardResult = await RewardService.giveTodoReward(
        currentUser: currentUser,
        todo: todo,
      );
      
      result['user'] = rewardResult['user'];
      final pointsEarned = rewardResult['pointsEarned'] as int;

      // 동물 시스템 특별 보너스 계산
      final animalBonus = _calculateAnimalBonus(todo, pointsEarned);
      if (animalBonus > 0) {
        final bonusResult = await RewardService.giveBonusReward(
          currentUser: result['user'],
          points: animalBonus,
          description: '동물 친구 보너스',
        );
        result['user'] = bonusResult['user'];
        result['animalReward'] = animalBonus;
      }

      // 연속 달성 특별 보너스 (습관의 경우)
      if (todo.type == TodoType.habit && todo.streak >= 7) {
        final streakBonus = _calculateStreakBonus(todo.streak);
        if (streakBonus > 0) {
          final streakResult = await RewardService.giveBonusReward(
            currentUser: result['user'],
            points: streakBonus,
            description: '${todo.streak}일 연속 달성 보너스',
          );
          result['user'] = streakResult['user'];
          result['specialBonus'] = streakBonus;
        }
      }

      if (kDebugMode) {
        print('IntegrationService: 투두 완료 동물 시스템 연동 완료');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('IntegrationService: 투두 완료 동물 시스템 연동 실패 - $e');
      }
      return {
        'user': currentUser,
        'animalReward': null,
        'specialBonus': null,
      };
    }
  }

  /// 습관 완료 시 동물 시스템 연동
  static Future<Map<String, dynamic>> onHabitCompleted({
    required UserModel currentUser,
    required HabitTrackerModel habitTracker,
    required String habitTitle,
  }) async {
    try {
      Map<String, dynamic> result = {
        'user': currentUser,
        'animalReward': null,
        'forestBonus': null,
      };

      final stats = habitTracker.calculateStats();
      
      // 습관 완료 기본 보상
      final basePoints = _calculateHabitPoints(stats);
      if (basePoints > 0) {
        final rewardResult = await RewardService.giveBonusReward(
          currentUser: currentUser,
          points: basePoints,
          description: '습관 완료: $habitTitle',
        );
        result['user'] = rewardResult['user'];
      }

      // 동물 친구 특별 보너스 (연속 달성 시)
      if (stats.currentStreak >= 3) {
        final animalBonus = _calculateAnimalStreakBonus(stats.currentStreak);
        if (animalBonus > 0) {
          final bonusResult = await RewardService.giveBonusReward(
            currentUser: result['user'],
            points: animalBonus,
            description: '동물 친구 연속 달성 보너스',
          );
          result['user'] = bonusResult['user'];
          result['animalReward'] = animalBonus;
        }
      }

      // 포레스트 시스템 연동 (장기 습관 시)
      if (stats.bestStreak >= 30) {
        final forestBonus = _calculateForestBonus(stats.bestStreak);
        if (forestBonus > 0) {
          final forestResult = await RewardService.giveBonusReward(
            currentUser: result['user'],
            points: forestBonus,
            description: '숲 키우기 보너스',
          );
          result['user'] = forestResult['user'];
          result['forestBonus'] = forestBonus;
        }
      }

      if (kDebugMode) {
        print('IntegrationService: 습관 완료 동물 시스템 연동 완료');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('IntegrationService: 습관 완료 동물 시스템 연동 실패 - $e');
      }
      return {
        'user': currentUser,
        'animalReward': null,
        'forestBonus': null,
      };
    }
  }

  /// 챌린지 완료 시 동물 시스템 연동
  static Future<Map<String, dynamic>> onChallengeCompleted({
    required UserModel currentUser,
    required ChallengeModel challenge,
  }) async {
    try {
      Map<String, dynamic> result = {
        'user': currentUser,
        'animalReward': null,
        'specialAnimal': null,
        'forestBonus': null,
      };

      // 챌린지 기본 보상
      final rewardResult = await RewardService.giveBonusReward(
        currentUser: currentUser,
        points: challenge.reward.points,
        description: '챌린지 완료: ${challenge.title}',
      );
      result['user'] = rewardResult['user'];

      // 난이도별 동물 친구 특별 보상
      final animalReward = _calculateChallengeAnimalReward(challenge);
      if (animalReward['points'] > 0) {
        final bonusResult = await RewardService.giveBonusReward(
          currentUser: result['user'],
          points: animalReward['points'],
          description: '챌린지 완료 동물 보너스',
        );
        result['user'] = bonusResult['user'];
        result['animalReward'] = animalReward['points'];
      }

      // 특별한 동물 친구 해금 (고급/전문가 챌린지)
      if (challenge.difficulty == ChallengeDifficulty.advanced || 
          challenge.difficulty == ChallengeDifficulty.expert) {
        result['specialAnimal'] = _getSpecialAnimalForChallenge(challenge);
      }

      // 포레스트 시스템 특별 보너스 (장기 챌린지)
      if (challenge.totalDuration >= 30) {
        final forestBonus = _calculateChallengeForestBonus(challenge);
        if (forestBonus > 0) {
          final forestResult = await RewardService.giveBonusReward(
            currentUser: result['user'],
            points: forestBonus,
            description: '장기 챌린지 숲 보너스',
          );
          result['user'] = forestResult['user'];
          result['forestBonus'] = forestBonus;
        }
      }

      if (kDebugMode) {
        print('IntegrationService: 챌린지 완료 동물 시스템 연동 완료');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('IntegrationService: 챌린지 완료 동물 시스템 연동 실패 - $e');
      }
      return {
        'user': currentUser,
        'animalReward': null,
        'specialAnimal': null,
        'forestBonus': null,
      };
    }
  }

  // ========================================
  // 포레스트 시스템 연동
  // ========================================

  /// 집중 모드와 투두/습관 시스템 연동
  static Future<Map<String, dynamic>> onFocusSessionCompleted({
    required UserModel currentUser,
    required Duration focusDuration,
    required String? linkedTodoId,
  }) async {
    try {
      Map<String, dynamic> result = {
        'user': currentUser,
        'todoBonus': null,
        'habitBonus': null,
        'forestGrowth': null,
      };

      // 기본 집중 보상
      final focusPoints = _calculateFocusPoints(focusDuration);
      final rewardResult = await RewardService.giveBonusReward(
        currentUser: currentUser,
        points: focusPoints,
        description: '집중 모드 완료',
      );
      result['user'] = rewardResult['user'];

      // 연결된 투두가 있는 경우 추가 보너스
      if (linkedTodoId != null) {
        final todos = await TodoService.getTodos(currentUser.id);
        final matchingTodos = todos.where((t) => t.id == linkedTodoId);
        final todo = matchingTodos.isNotEmpty ? matchingTodos.first : null;
        if (todo != null) {
          final todoBonus = _calculateLinkedTodoBonus(todo, focusDuration);
          if (todoBonus > 0) {
            final bonusResult = await RewardService.giveBonusReward(
              currentUser: result['user'],
              points: todoBonus,
              description: '집중 모드 투두 연동 보너스',
            );
            result['user'] = bonusResult['user'];
            result['todoBonus'] = todoBonus;
          }
        }
      }

      // 포레스트 성장 보너스
      final forestGrowth = _calculateForestGrowth(focusDuration);
      result['forestGrowth'] = forestGrowth;

      if (kDebugMode) {
        print('IntegrationService: 집중 모드 완료 연동 완료');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('IntegrationService: 집중 모드 완료 연동 실패 - $e');
      }
      return {
        'user': currentUser,
        'todoBonus': null,
        'habitBonus': null,
        'forestGrowth': null,
      };
    }
  }

  // ========================================
  // 통합 통계 및 분석
  // ========================================

  /// 전체 시스템 통합 통계 조회
  static Future<Map<String, dynamic>> getIntegratedStats(String userId) async {
    try {
      // 각 시스템별 통계 수집
      final todoStats = await TodoService.getTodoStats(userId);
      final habitStats = await HabitService.getHabitStats(userId);
      final challengeStats = await ChallengeService.getChallengeStats(userId);

      // 통합 지표 계산
      final totalActivities = todoStats['totalTodos'] + 
                             habitStats['totalHabits'] + 
                             challengeStats['totalChallenges'];

      final totalCompletions = todoStats['completedTodos'] + 
                              habitStats['totalCompletedDays'] + 
                              challengeStats['completedChallenges'];

      final overallCompletionRate = totalActivities > 0 ? 
                                   (totalCompletions / totalActivities) : 0.0;

      // 동물/포레스트 연동 지표
      final animalFriendshipLevel = _calculateAnimalFriendshipLevel(
        todoStats, habitStats, challengeStats
      );

      final forestHealthLevel = _calculateForestHealthLevel(
        habitStats, challengeStats
      );

      return {
        'todoStats': todoStats,
        'habitStats': habitStats,
        'challengeStats': challengeStats,
        'totalActivities': totalActivities,
        'totalCompletions': totalCompletions,
        'overallCompletionRate': overallCompletionRate,
        'animalFriendshipLevel': animalFriendshipLevel,
        'forestHealthLevel': forestHealthLevel,
        'integrationScore': _calculateIntegrationScore(
          overallCompletionRate, animalFriendshipLevel, forestHealthLevel
        ),
      };
    } catch (e) {
      if (kDebugMode) {
        print('IntegrationService: 통합 통계 조회 실패 - $e');
      }
      return {};
    }
  }

  // ========================================
  // 보너스 계산 메서드들
  // ========================================

  /// 동물 시스템 보너스 계산
  static int _calculateAnimalBonus(TodoItemModel todo, int basePoints) {
    // 카테고리별 동물 친화도 보너스
    final categoryMultiplier = switch (todo.category) {
      TodoCategory.health => 1.5,    // 건강 관련은 동물들이 좋아함
      TodoCategory.hobby => 1.3,     // 취미 활동도 동물들이 관심
      TodoCategory.personal => 1.2,  // 개인 관리도 좋음
      _ => 1.0,
    };

    // 난이도별 보너스
    final difficultyBonus = switch (todo.difficulty) {
      Difficulty.easy => 1,
      Difficulty.medium => 2,
      Difficulty.hard => 5,
    };

    return ((basePoints * categoryMultiplier).round() + difficultyBonus).clamp(0, 50);
  }

  /// 연속 달성 보너스 계산
  static int _calculateStreakBonus(int streak) {
    if (streak >= 30) return 50;
    if (streak >= 14) return 20;
    if (streak >= 7) return 10;
    return 0;
  }

  /// 습관 포인트 계산
  static int _calculateHabitPoints(HabitStats stats) {
    final basePoints = 5; // 기본 습관 완료 포인트
    final streakBonus = (stats.currentStreak / 7).floor() * 2; // 주간 보너스
    final completionBonus = (stats.completionRate * 10).round(); // 완료율 보너스
    
    return (basePoints + streakBonus + completionBonus).clamp(5, 30);
  }

  /// 동물 연속 달성 보너스
  static int _calculateAnimalStreakBonus(int streak) {
    if (streak >= 21) return 30;
    if (streak >= 14) return 20;
    if (streak >= 7) return 15;
    if (streak >= 3) return 5;
    return 0;
  }

  /// 포레스트 보너스 계산
  static int _calculateForestBonus(int bestStreak) {
    if (bestStreak >= 100) return 100;
    if (bestStreak >= 66) return 75;
    if (bestStreak >= 30) return 50;
    return 0;
  }

  /// 챌린지 동물 보상 계산
  static Map<String, dynamic> _calculateChallengeAnimalReward(ChallengeModel challenge) {
    final basePoints = switch (challenge.difficulty) {
      ChallengeDifficulty.beginner => 20,
      ChallengeDifficulty.intermediate => 50,
      ChallengeDifficulty.advanced => 100,
      ChallengeDifficulty.expert => 200,
    };

    final durationBonus = (challenge.totalDuration / 7).floor() * 10;
    
    return {
      'points': basePoints + durationBonus,
      'animalType': _getAnimalTypeForChallenge(challenge),
    };
  }

  /// 챌린지별 특별 동물 결정
  static String? _getSpecialAnimalForChallenge(ChallengeModel challenge) {
    // 챌린지 타입과 난이도에 따른 특별 동물
    if (challenge.difficulty == ChallengeDifficulty.expert) {
      return switch (challenge.type) {
        ChallengeType.daily => 'golden_phoenix',
        ChallengeType.weekly => 'silver_dragon',
        ChallengeType.monthly => 'crystal_unicorn',
        ChallengeType.custom => 'rainbow_butterfly',
      };
    }
    return null;
  }

  /// 동물 타입 결정
  static String _getAnimalTypeForChallenge(ChallengeModel challenge) {
    return switch (challenge.type) {
      ChallengeType.daily => 'cat',
      ChallengeType.weekly => 'dog',
      ChallengeType.monthly => 'rabbit',
      ChallengeType.custom => 'hamster',
    };
  }

  /// 챌린지 포레스트 보너스
  static int _calculateChallengeForestBonus(ChallengeModel challenge) {
    final baseBonus = challenge.totalDuration * 2;
    final difficultyMultiplier = switch (challenge.difficulty) {
      ChallengeDifficulty.beginner => 1.0,
      ChallengeDifficulty.intermediate => 1.5,
      ChallengeDifficulty.advanced => 2.0,
      ChallengeDifficulty.expert => 3.0,
    };
    
    return (baseBonus * difficultyMultiplier).round().clamp(0, 500);
  }

  /// 집중 모드 포인트 계산
  static int _calculateFocusPoints(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes >= 120) return 50; // 2시간 이상
    if (minutes >= 60) return 30;  // 1시간 이상
    if (minutes >= 30) return 20;  // 30분 이상
    if (minutes >= 15) return 10;  // 15분 이상
    return 5; // 기본
  }

  /// 연결된 투두 보너스
  static int _calculateLinkedTodoBonus(TodoItemModel todo, Duration focusDuration) {
    final baseBonus = 10;
    final difficultyBonus = switch (todo.difficulty) {
      Difficulty.easy => 5,
      Difficulty.medium => 10,
      Difficulty.hard => 20,
    };
    
    final durationBonus = (focusDuration.inMinutes / 30).floor() * 5;
    
    return baseBonus + difficultyBonus + durationBonus;
  }

  /// 포레스트 성장 계산
  static Map<String, dynamic> _calculateForestGrowth(Duration duration) {
    final minutes = duration.inMinutes;
    return {
      'treeGrowth': (minutes / 15).floor(), // 15분당 1 성장
      'forestHealth': (minutes / 60).floor(), // 1시간당 1 건강도
      'newSeeds': minutes >= 120 ? 1 : 0, // 2시간 이상 시 새 씨앗
    };
  }

  /// 동물 친화도 레벨 계산
  static int _calculateAnimalFriendshipLevel(
    Map<String, dynamic> todoStats,
    Map<String, dynamic> habitStats,
    Map<String, dynamic> challengeStats,
  ) {
    final totalPoints = (todoStats['totalPointsEarned'] ?? 0) +
                       (habitStats['totalCompletedDays'] ?? 0) * 5 +
                       (challengeStats['totalPointsEarned'] ?? 0);
    
    if (totalPoints >= 10000) return 10; // 전설
    if (totalPoints >= 5000) return 9;   // 마스터
    if (totalPoints >= 2000) return 8;   // 전문가
    if (totalPoints >= 1000) return 7;   // 숙련자
    if (totalPoints >= 500) return 6;    // 중급자
    if (totalPoints >= 200) return 5;    // 초급자
    if (totalPoints >= 100) return 4;    // 견습생
    if (totalPoints >= 50) return 3;     // 새싹
    if (totalPoints >= 20) return 2;     // 입문자
    return 1; // 초보자
  }

  /// 포레스트 건강도 레벨 계산
  static int _calculateForestHealthLevel(
    Map<String, dynamic> habitStats,
    Map<String, dynamic> challengeStats,
  ) {
    final habitStreak = habitStats['longestStreak'] ?? 0;
    final challengeCount = challengeStats['completedChallenges'] ?? 0;
    
    final healthScore = habitStreak + (challengeCount * 10);
    
    if (healthScore >= 500) return 10; // 신비한 숲
    if (healthScore >= 300) return 9;  // 고대 숲
    if (healthScore >= 200) return 8;  // 울창한 숲
    if (healthScore >= 150) return 7;  // 건강한 숲
    if (healthScore >= 100) return 6;  // 성장하는 숲
    if (healthScore >= 70) return 5;   // 젊은 숲
    if (healthScore >= 50) return 4;   // 새싹 숲
    if (healthScore >= 30) return 3;   // 작은 숲
    if (healthScore >= 15) return 2;   // 나무 몇 그루
    return 1; // 씨앗 상태
  }

  /// 통합 점수 계산
  static int _calculateIntegrationScore(
    double completionRate,
    int animalLevel,
    int forestLevel,
  ) {
    final completionScore = (completionRate * 40).round();
    final animalScore = animalLevel * 3;
    final forestScore = forestLevel * 3;
    
    return (completionScore + animalScore + forestScore).clamp(0, 100);
  }
} 