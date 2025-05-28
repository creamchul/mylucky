import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/challenge_model.dart';
import '../models/todo_item_model.dart';
import '../models/habit_tracker_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'todo_service.dart';
import 'habit_service.dart';
import 'reward_service.dart';

/// 챌린지 관리 서비스
class ChallengeService {
  static const String _challengesKey = 'user_challenges';
  static const String _templatesKey = 'challenge_templates';
  
  // ========================================
  // 로컬 저장 관리
  // ========================================
  
  /// 챌린지 목록을 로컬에 저장
  static Future<void> _saveChallengesToLocal(String userId, List<ChallengeModel> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = challenges.map((challenge) => challenge.toMap()).toList();
      await prefs.setString('${_challengesKey}_$userId', json.encode(challengesJson));
      
      if (kDebugMode) {
        print('ChallengeService: 챌린지 목록 로컬 저장 완료 (${challenges.length}개)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 목록 로컬 저장 실패 - $e');
      }
    }
  }
  
  /// 로컬에서 챌린지 목록 불러오기
  static Future<List<ChallengeModel>> _loadChallengesFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = prefs.getString('${_challengesKey}_$userId');
      
      if (challengesJson != null) {
        final List<dynamic> challengesList = json.decode(challengesJson);
        final challenges = challengesList.map((json) => ChallengeModel.fromMap(json)).toList();
        
        if (kDebugMode) {
          print('ChallengeService: 로컬에서 챌린지 목록 로드 완료 (${challenges.length}개)');
        }
        
        return challenges;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 로컬 챌린지 목록 로드 실패 - $e');
      }
    }
    
    return [];
  }

  // ========================================
  // 챌린지 CRUD 기능
  // ========================================
  
  /// 새 챌린지 생성
  static Future<ChallengeModel> createChallenge({
    required String userId,
    required String title,
    required String description,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> todoIds,
    Map<String, dynamic> settings = const {},
    List<String> tags = const [],
  }) async {
    try {
      final newChallenge = ChallengeModel.create(
        userId: userId,
        title: title,
        description: description,
        type: type,
        difficulty: difficulty,
        startDate: startDate,
        endDate: endDate,
        todoIds: todoIds,
        settings: settings,
        tags: tags,
      );

      // 로컬 저장
      final existingChallenges = await _loadChallengesFromLocal(userId);
      existingChallenges.add(newChallenge);
      await _saveChallengesToLocal(userId, existingChallenges);

      // Firebase 저장 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.createChallenge(newChallenge);
        } catch (e) {
          if (kDebugMode) {
            print('ChallengeService: Firebase 저장 실패, 로컬만 저장됨 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('ChallengeService: 새 챌린지 생성 완료 - ${newChallenge.title}');
      }

      return newChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 챌린지 목록 조회
  static Future<List<ChallengeModel>> getChallenges(String userId, {
    ChallengeStatus? status,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
  }) async {
    try {
      List<ChallengeModel> challenges = await _loadChallengesFromLocal(userId);

      // Firebase에서도 가져오기 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          final firebaseChallenges = await FirebaseService.getUserChallenges(userId);
          // 로컬과 Firebase 데이터 병합 (중복 제거)
          final localIds = challenges.map((c) => c.id).toSet();
          final newChallenges = firebaseChallenges.where((c) => !localIds.contains(c.id)).toList();
          challenges.addAll(newChallenges);
          
          // 병합된 데이터를 로컬에 저장
          if (newChallenges.isNotEmpty) {
            await _saveChallengesToLocal(userId, challenges);
          }
        } catch (e) {
          if (kDebugMode) {
            print('ChallengeService: Firebase 조회 실패, 로컬 데이터만 사용 - $e');
          }
        }
      }

      // 필터링
      if (status != null) {
        challenges = challenges.where((challenge) => challenge.status == status).toList();
      }
      
      if (type != null) {
        challenges = challenges.where((challenge) => challenge.type == type).toList();
      }

      if (difficulty != null) {
        challenges = challenges.where((challenge) => challenge.difficulty == difficulty).toList();
      }

      // 정렬 (상태 > 시작일 > 생성일)
      challenges.sort((a, b) {
        // 활성 챌린지를 먼저
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        
        // 시작일로 정렬
        final startDateCompare = a.startDate.compareTo(b.startDate);
        if (startDateCompare != 0) return startDateCompare;
        
        // 생성일로 정렬
        return b.createdAt.compareTo(a.createdAt);
      });

      if (kDebugMode) {
        print('ChallengeService: 챌린지 목록 조회 완료 (${challenges.length}개)');
      }

      return challenges;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 목록 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 활성 챌린지 조회
  static Future<List<ChallengeModel>> getActiveChallenges(String userId) async {
    return getChallenges(userId, status: ChallengeStatus.active);
  }

  /// 특정 챌린지 조회
  static Future<ChallengeModel?> getChallenge(String userId, String challengeId) async {
    try {
      final challenges = await _loadChallengesFromLocal(userId);
      
      try {
        return challenges.firstWhere((challenge) => challenge.id == challengeId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 조회 실패 - $e');
      }
      return null;
    }
  }

  // ========================================
  // 챌린지 진행 관리
  // ========================================

  /// 챌린지 시작
  static Future<ChallengeModel> startChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final challenges = await _loadChallengesFromLocal(userId);
      final challengeIndex = challenges.indexWhere((challenge) => challenge.id == challengeId);
      
      if (challengeIndex == -1) {
        throw Exception('챌린지를 찾을 수 없습니다: $challengeId');
      }

      final challenge = challenges[challengeIndex];
      final startedChallenge = challenge.start();
      
      challenges[challengeIndex] = startedChallenge;
      await _saveChallengesToLocal(userId, challenges);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateChallenge(startedChallenge);
        } catch (e) {
          if (kDebugMode) {
            print('ChallengeService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('ChallengeService: 챌린지 시작 완료 - ${startedChallenge.title}');
      }

      return startedChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 시작 실패 - $e');
      }
      rethrow;
    }
  }

  /// 챌린지 진행 상황 업데이트
  static Future<Map<String, dynamic>> updateChallengeProgress({
    required String userId,
    required String challengeId,
    required UserModel currentUser,
  }) async {
    try {
      final challenges = await _loadChallengesFromLocal(userId);
      final challengeIndex = challenges.indexWhere((challenge) => challenge.id == challengeId);
      
      if (challengeIndex == -1) {
        throw Exception('챌린지를 찾을 수 없습니다: $challengeId');
      }

      final challenge = challenges[challengeIndex];
      if (!challenge.isActive) {
        throw Exception('활성 상태가 아닌 챌린지입니다.');
      }

      // 연결된 투두들의 진행 상황 확인
      final todos = await TodoService.getTodos(userId);
      final challengeTodos = todos.where((todo) => challenge.todoIds.contains(todo.id)).toList();
      
      // 습관 추적기 정보 가져오기
      final habitTrackers = await HabitService.getAllHabitTrackers(userId);
      
      // 진행 상황 계산
      final progress = _calculateProgress(challenge, challengeTodos, habitTrackers);
      
      // 챌린지 업데이트
      final updatedChallenge = challenge.updateProgress(progress);
      
      // 완료 조건 확인
      ChallengeModel finalChallenge = updatedChallenge;
      bool isCompleted = false;
      
      if (_isCompleted(updatedChallenge, challengeTodos)) {
        finalChallenge = updatedChallenge.complete();
        isCompleted = true;
      } else if (_isFailed(updatedChallenge)) {
        finalChallenge = updatedChallenge.fail();
      }
      
      challenges[challengeIndex] = finalChallenge;
      await _saveChallengesToLocal(userId, challenges);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateChallenge(finalChallenge);
        } catch (e) {
          if (kDebugMode) {
            print('ChallengeService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 완료 시 보상 지급
      UserModel updatedUser = currentUser;
      if (isCompleted) {
        final rewardResult = await _giveChallengeReward(
          currentUser: currentUser,
          challenge: finalChallenge,
        );
        updatedUser = rewardResult['user'];
      }

      if (kDebugMode) {
        print('ChallengeService: 챌린지 진행 상황 업데이트 완료 - ${finalChallenge.title}');
      }

      return {
        'challenge': finalChallenge,
        'user': updatedUser,
        'isCompleted': isCompleted,
        'progress': progress,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 진행 상황 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  /// 챌린지 완료 보상 지급
  static Future<Map<String, dynamic>> _giveChallengeReward({
    required UserModel currentUser,
    required ChallengeModel challenge,
  }) async {
    try {
      final reward = challenge.reward;
      
      // 기본 포인트 지급
      final rewardResult = await RewardService.giveBonusReward(
        currentUser: currentUser,
        points: reward.points,
        description: '챌린지 완료: ${challenge.title}',
      );

      if (kDebugMode) {
        print('ChallengeService: 챌린지 완료 보상 지급 완료 - ${reward.points} 포인트');
      }

      return {
        'user': rewardResult['user'],
        'pointsEarned': reward.points,
        'experienceEarned': reward.experience,
        'badgeEarned': reward.badgeId,
        'titleEarned': reward.title,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 완료 보상 지급 실패 - $e');
      }
      return {
        'user': currentUser,
        'pointsEarned': 0,
        'experienceEarned': 0,
      };
    }
  }

  // ========================================
  // 챌린지 템플릿 시스템
  // ========================================

  /// 미리 정의된 챌린지 템플릿 목록
  static List<Map<String, dynamic>> getDefaultTemplates() {
    return [
      {
        'title': '7일 아침 운동 챌린지',
        'description': '매일 아침 30분 운동으로 건강한 하루를 시작해보세요!',
        'type': ChallengeType.daily,
        'difficulty': ChallengeDifficulty.beginner,
        'duration': 7,
        'category': TodoCategory.health,
        'tags': ['운동', '아침', '건강'],
        'emoji': '🏃‍♀️',
      },
      {
        'title': '21일 독서 습관 만들기',
        'description': '매일 30분씩 독서하여 지식을 쌓아보세요.',
        'type': ChallengeType.daily,
        'difficulty': ChallengeDifficulty.intermediate,
        'duration': 21,
        'category': TodoCategory.personal,
        'tags': ['독서', '학습', '성장'],
        'emoji': '📚',
      },
      {
        'title': '30일 물 마시기 챌린지',
        'description': '하루 8잔의 물을 마시며 건강을 챙겨보세요.',
        'type': ChallengeType.daily,
        'difficulty': ChallengeDifficulty.beginner,
        'duration': 30,
        'category': TodoCategory.health,
        'tags': ['건강', '물', '습관'],
        'emoji': '💧',
      },
      {
        'title': '66일 명상 마스터',
        'description': '매일 10분 명상으로 마음의 평화를 찾아보세요.',
        'type': ChallengeType.daily,
        'difficulty': ChallengeDifficulty.advanced,
        'duration': 66,
        'category': TodoCategory.personal,
        'tags': ['명상', '마음챙김', '평화'],
        'emoji': '🧘‍♀️',
      },
      {
        'title': '주간 정리 정돈',
        'description': '매주 집안 정리로 깔끔한 공간을 만들어보세요.',
        'type': ChallengeType.weekly,
        'difficulty': ChallengeDifficulty.beginner,
        'duration': 28, // 4주
        'category': TodoCategory.personal,
        'tags': ['정리', '청소', '공간'],
        'emoji': '🏠',
      },
    ];
  }

  /// 템플릿으로부터 챌린지 생성
  static Future<ChallengeModel> createChallengeFromTemplate({
    required String userId,
    required Map<String, dynamic> template,
    DateTime? customStartDate,
  }) async {
    try {
      final startDate = customStartDate ?? DateTime.now();
      final duration = template['duration'] as int;
      final endDate = startDate.add(Duration(days: duration - 1));
      
      // 템플릿에 맞는 투두 아이템 생성
      final todoIds = await _createTodosFromTemplate(userId, template, startDate, endDate);
      
      return createChallenge(
        userId: userId,
        title: template['title'],
        description: template['description'],
        type: template['type'],
        difficulty: template['difficulty'],
        startDate: startDate,
        endDate: endDate,
        todoIds: todoIds,
        tags: List<String>.from(template['tags']),
      );
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 템플릿으로부터 챌린지 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 템플릿에 맞는 투두 아이템들 생성
  static Future<List<String>> _createTodosFromTemplate(
    String userId,
    Map<String, dynamic> template,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final todoIds = <String>[];
      final category = template['category'] as TodoCategory;
      final type = template['type'] as ChallengeType;
      
      // 챌린지 타입에 따른 투두 생성
      if (type == ChallengeType.daily) {
        final todo = await TodoService.createTodo(
          userId: userId,
          title: template['title'],
          description: template['description'],
          type: TodoType.habit,
          category: category,
          priority: Priority.medium,
          difficulty: Difficulty.medium,
          dueDate: endDate,
          tags: List<String>.from(template['tags']),
        );
        todoIds.add(todo.id);
      } else if (type == ChallengeType.weekly) {
        // 주간 챌린지의 경우 주별로 투두 생성
        final weeks = endDate.difference(startDate).inDays ~/ 7 + 1;
        for (int i = 0; i < weeks; i++) {
          final weekStart = startDate.add(Duration(days: i * 7));
          final todo = await TodoService.createTodo(
            userId: userId,
            title: '${template['title']} - ${i + 1}주차',
            description: template['description'],
            type: TodoType.weekly,
            category: category,
            priority: Priority.medium,
            difficulty: Difficulty.medium,
            dueDate: weekStart.add(const Duration(days: 6)),
            tags: List<String>.from(template['tags']),
          );
          todoIds.add(todo.id);
        }
      }
      
      return todoIds;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 템플릿 투두 생성 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 통계 및 분석
  // ========================================

  /// 사용자 챌린지 통계 조회
  static Future<Map<String, dynamic>> getChallengeStats(String userId) async {
    try {
      final challenges = await getChallenges(userId);
      
      if (challenges.isEmpty) {
        return {
          'totalChallenges': 0,
          'activeChallenges': 0,
          'completedChallenges': 0,
          'failedChallenges': 0,
          'completionRate': 0.0,
          'totalPointsEarned': 0,
          'averageDuration': 0,
          'favoriteCategory': null,
        };
      }

      final activeChallenges = challenges.where((c) => c.isActive).length;
      final completedChallenges = challenges.where((c) => c.isCompleted).length;
      final failedChallenges = challenges.where((c) => c.isFailed).length;
      final finishedChallenges = completedChallenges + failedChallenges;
      
      final completionRate = finishedChallenges > 0 ? (completedChallenges / finishedChallenges) : 0.0;
      final totalPointsEarned = challenges
          .where((c) => c.isCompleted)
          .fold<int>(0, (sum, c) => sum + c.reward.points);
      
      final averageDuration = challenges.isNotEmpty 
          ? challenges.fold<int>(0, (sum, c) => sum + c.totalDuration) / challenges.length
          : 0;

      return {
        'totalChallenges': challenges.length,
        'activeChallenges': activeChallenges,
        'completedChallenges': completedChallenges,
        'failedChallenges': failedChallenges,
        'completionRate': completionRate,
        'totalPointsEarned': totalPointsEarned,
        'averageDuration': averageDuration.round(),
        'favoriteCategory': _getMostFrequentCategory(challenges),
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 통계 조회 실패 - $e');
      }
      return {
        'totalChallenges': 0,
        'activeChallenges': 0,
        'completedChallenges': 0,
        'failedChallenges': 0,
        'completionRate': 0.0,
        'totalPointsEarned': 0,
        'averageDuration': 0,
        'favoriteCategory': null,
      };
    }
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 챌린지 진행 상황 계산
  static ChallengeProgress _calculateProgress(
    ChallengeModel challenge,
    List<TodoItemModel> todos,
    List<HabitTrackerModel> habitTrackers,
  ) {
    final now = DateTime.now();
    final startDate = challenge.startDate;
    final currentDay = now.difference(startDate).inDays + 1;
    final totalDays = challenge.totalDuration;
    
    int completedTasks = 0;
    int totalTasks = todos.length;
    final completedDates = <DateTime>[];
    
    // 투두 완료 상황 확인
    for (final todo in todos) {
      if (todo.isCompleted) {
        completedTasks++;
        if (todo.completedAt != null) {
          completedDates.add(todo.completedAt!);
        }
      }
    }
    
    // 습관 추적기 정보 반영
    for (final tracker in habitTrackers) {
      if (challenge.todoIds.contains(tracker.habitId)) {
        final stats = tracker.calculateStats();
        completedDates.addAll(tracker.records
            .where((r) => r.completed)
            .map((r) => r.date));
      }
    }
    
    final completionRate = totalTasks > 0 ? (completedTasks / totalTasks) : 0.0;
    
    // 연속 달성일 계산
    completedDates.sort();
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    
    DateTime? lastDate;
    for (final date in completedDates) {
      if (lastDate == null || date.difference(lastDate).inDays == 1) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 1;
      }
      lastDate = date;
    }
    
    // 현재 연속 달성일 (오늘까지)
    if (completedDates.isNotEmpty) {
      final lastCompleted = completedDates.last;
      final daysSinceLastCompleted = now.difference(lastCompleted).inDays;
      if (daysSinceLastCompleted <= 1) {
        currentStreak = tempStreak;
      }
    }
    
    return ChallengeProgress(
      currentDay: currentDay.clamp(0, totalDays),
      totalDays: totalDays,
      completedTasks: completedTasks,
      totalTasks: totalTasks,
      completionRate: completionRate,
      completedDates: completedDates,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }

  /// 챌린지 완료 조건 확인
  static bool _isCompleted(ChallengeModel challenge, List<TodoItemModel> todos) {
    // 모든 투두가 완료되었거나, 완료율이 80% 이상이고 기간이 끝났을 때
    final allCompleted = todos.every((todo) => todo.isCompleted);
    final highCompletionRate = challenge.progress.completionRate >= 0.8;
    final periodEnded = DateTime.now().isAfter(challenge.endDate);
    
    return allCompleted || (highCompletionRate && periodEnded);
  }

  /// 챌린지 실패 조건 확인
  static bool _isFailed(ChallengeModel challenge) {
    // 기간이 끝났는데 완료율이 50% 미만일 때
    final periodEnded = DateTime.now().isAfter(challenge.endDate);
    final lowCompletionRate = challenge.progress.completionRate < 0.5;
    
    return periodEnded && lowCompletionRate;
  }

  /// 가장 많이 사용된 카테고리 찾기
  static String? _getMostFrequentCategory(List<ChallengeModel> challenges) {
    if (challenges.isEmpty) return null;
    
    final categoryCount = <String, int>{};
    for (final challenge in challenges) {
      for (final tag in challenge.tags) {
        categoryCount[tag] = (categoryCount[tag] ?? 0) + 1;
      }
    }
    
    if (categoryCount.isEmpty) return null;
    
    return categoryCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 챌린지 삭제
  static Future<void> deleteChallenge({
    required String userId,
    required String challengeId,
  }) async {
    try {
      final challenges = await _loadChallengesFromLocal(userId);
      challenges.removeWhere((challenge) => challenge.id == challengeId);
      await _saveChallengesToLocal(userId, challenges);

      // Firebase에서도 삭제 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.deleteChallenge(challengeId);
        } catch (e) {
          if (kDebugMode) {
            print('ChallengeService: Firebase 삭제 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('ChallengeService: 챌린지 삭제 완료 - $challengeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 삭제 실패 - $e');
      }
      rethrow;
    }
  }
} 