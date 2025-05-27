import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import '../data/mission_data.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class ChallengeService {
  ChallengeService._(); // Private constructor

  // ========================================
  // 웹 환경용 로컬 저장소 메서드
  // ========================================

  /// 웹 환경에서 활성 챌린지 저장
  static Future<void> _saveActiveChallengesWeb(String userId, List<UserChallenge> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = challenges.map((c) => c.toJson()).toList();
      await prefs.setString('active_challenges_$userId', jsonEncode(challengesJson));
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 활성 챌린지 저장 실패 - $e');
      }
    }
  }

  /// 웹 환경에서 활성 챌린지 로드
  static Future<List<UserChallenge>> _loadActiveChallengesWeb(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesString = prefs.getString('active_challenges_$userId');
      if (challengesString == null) return [];
      
      final challengesJson = jsonDecode(challengesString) as List;
      return challengesJson.map((json) => UserChallenge.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 활성 챌린지 로드 실패 - $e');
      }
      return [];
    }
  }

  /// 웹 환경에서 챌린지 히스토리 저장
  static Future<void> _saveChallengeHistoryWeb(String userId, List<UserChallenge> challenges) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesJson = challenges.map((c) => c.toJson()).toList();
      await prefs.setString('challenge_history_$userId', jsonEncode(challengesJson));
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 히스토리 저장 실패 - $e');
      }
    }
  }

  /// 웹 환경에서 챌린지 히스토리 로드
  static Future<List<UserChallenge>> _loadChallengeHistoryWeb(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final challengesString = prefs.getString('challenge_history_$userId');
      if (challengesString == null) return [];
      
      final challengesJson = jsonDecode(challengesString) as List;
      return challengesJson.map((json) => UserChallenge.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 히스토리 로드 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 챌린지 관리
  // ========================================

  /// 새로운 챌린지 시작
  static Future<Map<String, dynamic>> startChallenge({
    required UserModel currentUser,
    required Challenge challenge,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('ChallengeService: 웹 환경에서 챌린지 시작');
      }
      
      // 기존 활성 챌린지 로드
      final existingChallenges = await _loadActiveChallengesWeb(currentUser.id);
      
      // 중복 체크
      final duplicateChallenge = existingChallenges.where(
        (uc) => uc.challengeId == challenge.id && uc.isActive,
      ).firstOrNull;

      if (duplicateChallenge != null) {
        throw Exception('이미 진행 중인 챌린지입니다.');
      }
      
      final userChallenge = UserChallenge.start(
        id: 'web_challenge_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        challenge: challenge,
      );
      
      // 새 챌린지를 활성 목록에 추가
      existingChallenges.add(userChallenge);
      await _saveActiveChallengesWeb(currentUser.id, existingChallenges);
      
      // 히스토리에도 추가
      final history = await _loadChallengeHistoryWeb(currentUser.id);
      history.add(userChallenge);
      await _saveChallengeHistoryWeb(currentUser.id, history);
      
      return {
        'userChallenge': userChallenge,
        'user': currentUser,
      };
    }

    try {
      // 이미 진행 중인 같은 챌린지가 있는지 확인
      final existingChallenges = await getUserActiveChallenges(currentUser.id);
      UserChallenge? duplicateChallenge;
      try {
        duplicateChallenge = existingChallenges.firstWhere(
          (uc) => uc.challengeId == challenge.id && uc.isActive,
        );
      } catch (e) {
        duplicateChallenge = null;
      }

      if (duplicateChallenge != null) {
        throw Exception('이미 진행 중인 챌린지입니다.');
      }

      // Firebase에 챌린지 저장
      final userChallenge = await FirebaseService.startChallenge(
        userId: currentUser.id,
        challenge: challenge,
      );

      if (kDebugMode) {
        print('ChallengeService: 챌린지 시작 완료 - ${challenge.title}');
      }
      
      return {
        'userChallenge': userChallenge,
        'user': currentUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 시작 실패 - $e');
      }
      rethrow;
    }
  }

  /// 오늘의 챌린지 완료 처리
  static Future<Map<String, dynamic>> completeTodayChallenge({
    required UserModel currentUser,
    required UserChallenge userChallenge,
  }) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('ChallengeService: 웹 환경에서 챌린지 완료 처리');
      }
      
      final updatedChallenge = userChallenge.completeToday();
      
      // 활성 챌린지 목록 업데이트
      final activeChallenges = await _loadActiveChallengesWeb(currentUser.id);
      final index = activeChallenges.indexWhere((c) => c.id == userChallenge.id);
      if (index != -1) {
        activeChallenges[index] = updatedChallenge;
        await _saveActiveChallengesWeb(currentUser.id, activeChallenges);
      }
      
      // 히스토리 업데이트
      final history = await _loadChallengeHistoryWeb(currentUser.id);
      final historyIndex = history.indexWhere((c) => c.id == userChallenge.id);
      if (historyIndex != -1) {
        history[historyIndex] = updatedChallenge;
        await _saveChallengeHistoryWeb(currentUser.id, history);
      }
      
      return {
        'userChallenge': updatedChallenge,
        'user': currentUser,
        'pointsEarned': updatedChallenge.totalPointsEarned - userChallenge.totalPointsEarned,
      };
    }

    try {
      if (!userChallenge.canCompleteToday) {
        throw Exception('오늘은 이미 완료했거나 완료할 수 없습니다.');
      }

      // 챌린지 완료 처리
      final updatedChallenge = userChallenge.completeToday();
      
      // Firebase에 업데이트
      await FirebaseService.updateUserChallenge(updatedChallenge);

      // 포인트 지급
      final pointsEarned = updatedChallenge.totalPointsEarned - userChallenge.totalPointsEarned;
      final updatedUser = await UserService.addPoints(
        currentUser: currentUser,
        points: pointsEarned,
        reason: '챌린지 완료',
      );

      if (kDebugMode) {
        print('ChallengeService: 챌린지 완료 처리 완료 - ${pointsEarned}포인트 획득');
      }
      
      return {
        'userChallenge': updatedChallenge,
        'user': updatedUser,
        'pointsEarned': pointsEarned,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 완료 처리 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 활성 챌린지 목록 조회
  static Future<List<UserChallenge>> getUserActiveChallenges(String userId) async {
    if (kIsWeb) {
      // 웹에서는 저장된 데이터 로드
      return await _loadActiveChallengesWeb(userId);
    }

    try {
      return await FirebaseService.getUserActiveChallenges(userId);
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 활성 챌린지 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 사용자의 모든 챌린지 이력 조회
  static Future<List<UserChallenge>> getUserChallengeHistory(String userId, {int limit = 20}) async {
    if (kIsWeb) {
      // 웹에서는 저장된 데이터 로드
      final history = await _loadChallengeHistoryWeb(userId);
      return history.take(limit).toList();
    }

    try {
      return await FirebaseService.getUserChallengeHistory(userId, limit: limit);
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 이력 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 사용자의 완료된 챌린지 목록 조회
  static Future<List<UserChallenge>> getUserCompletedChallenges(String userId) async {
    if (kIsWeb) {
      return [];
    }

    try {
      return await FirebaseService.getUserCompletedChallenges(userId);
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 완료된 챌린지 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 챌린지 일시정지
  static Future<UserChallenge> pauseChallenge({
    required UserChallenge userChallenge,
  }) async {
    if (kIsWeb) {
      final pausedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.paused,
        updatedAt: DateTime.now(),
      );
      
      // 활성 챌린지 목록 업데이트
      final activeChallenges = await _loadActiveChallengesWeb(userChallenge.userId);
      final index = activeChallenges.indexWhere((c) => c.id == userChallenge.id);
      if (index != -1) {
        activeChallenges[index] = pausedChallenge;
        await _saveActiveChallengesWeb(userChallenge.userId, activeChallenges);
      }
      
      // 히스토리 업데이트
      final history = await _loadChallengeHistoryWeb(userChallenge.userId);
      final historyIndex = history.indexWhere((c) => c.id == userChallenge.id);
      if (historyIndex != -1) {
        history[historyIndex] = pausedChallenge;
        await _saveChallengeHistoryWeb(userChallenge.userId, history);
      }
      
      return pausedChallenge;
    }

    try {
      final pausedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.paused,
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateUserChallenge(pausedChallenge);

      if (kDebugMode) {
        print('ChallengeService: 챌린지 일시정지 완료');
      }

      return pausedChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 일시정지 실패 - $e');
      }
      rethrow;
    }
  }

  /// 챌린지 재개
  static Future<UserChallenge> resumeChallenge({
    required UserChallenge userChallenge,
  }) async {
    if (kIsWeb) {
      final resumedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.inProgress,
        updatedAt: DateTime.now(),
      );
      
      // 활성 챌린지 목록 업데이트
      final activeChallenges = await _loadActiveChallengesWeb(userChallenge.userId);
      final index = activeChallenges.indexWhere((c) => c.id == userChallenge.id);
      if (index != -1) {
        activeChallenges[index] = resumedChallenge;
        await _saveActiveChallengesWeb(userChallenge.userId, activeChallenges);
      }
      
      // 히스토리 업데이트
      final history = await _loadChallengeHistoryWeb(userChallenge.userId);
      final historyIndex = history.indexWhere((c) => c.id == userChallenge.id);
      if (historyIndex != -1) {
        history[historyIndex] = resumedChallenge;
        await _saveChallengeHistoryWeb(userChallenge.userId, history);
      }
      
      return resumedChallenge;
    }

    try {
      final resumedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.inProgress,
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateUserChallenge(resumedChallenge);

      if (kDebugMode) {
        print('ChallengeService: 챌린지 재개 완료');
      }

      return resumedChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 재개 실패 - $e');
      }
      rethrow;
    }
  }

  /// 챌린지 포기
  static Future<UserChallenge> abandonChallenge({
    required UserChallenge userChallenge,
  }) async {
    if (kIsWeb) {
      final abandonedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.failed,
        endDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // 활성 챌린지 목록에서 제거
      final activeChallenges = await _loadActiveChallengesWeb(userChallenge.userId);
      activeChallenges.removeWhere((c) => c.id == userChallenge.id);
      await _saveActiveChallengesWeb(userChallenge.userId, activeChallenges);
      
      // 히스토리 업데이트
      final history = await _loadChallengeHistoryWeb(userChallenge.userId);
      final historyIndex = history.indexWhere((c) => c.id == userChallenge.id);
      if (historyIndex != -1) {
        history[historyIndex] = abandonedChallenge;
        await _saveChallengeHistoryWeb(userChallenge.userId, history);
      }
      
      return abandonedChallenge;
    }

    try {
      final abandonedChallenge = userChallenge.copyWith(
        status: ChallengeStatus.failed,
        endDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateUserChallenge(abandonedChallenge);

      if (kDebugMode) {
        print('ChallengeService: 챌린지 포기 완료');
      }

      return abandonedChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 포기 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 챌린지 추천 및 검색
  // ========================================

  /// 사용자 맞춤 챌린지 추천
  static List<Challenge> getRecommendedChallenges({
    required UserModel user,
    int limit = 6,
  }) {
    // 사용자의 레벨과 활동 패턴을 고려한 추천 로직
    List<Challenge> recommended = [];

    // 초보자라면 쉬운 챌린지 추천
    if (user.rewardPoints < 500) {
      recommended.addAll(ChallengeData.getBeginnerChallenges());
    } else {
      // 경험자라면 다양한 난이도 추천
      recommended.addAll(ChallengeData.getPopularChallenges());
    }

    // 중복 제거 및 셔플
    recommended = recommended.toSet().toList();
    recommended.shuffle();

    return recommended.take(limit).toList();
  }

  /// 카테고리별 챌린지 추천
  static List<Challenge> getChallengesByCategory(ChallengeCategory category) {
    return ChallengeData.getChallengesByCategory(category);
  }

  /// 난이도별 챌린지 추천
  static List<Challenge> getChallengesByDifficulty(ChallengeDifficulty difficulty) {
    return ChallengeData.getChallengesByDifficulty(difficulty);
  }

  /// 오늘의 추천 챌린지
  static Challenge getTodayRecommendedChallenge() {
    return ChallengeData.getTodayRecommendedChallenge(DateTime.now());
  }

  // ========================================
  // 통계 및 분석
  // ========================================

  /// 사용자의 챌린지 통계 계산
  static Future<Map<String, dynamic>> getUserChallengeStats(String userId) async {
    try {
      final allChallenges = await getUserChallengeHistory(userId, limit: 100);
      
      final totalChallenges = allChallenges.length;
      final completedChallenges = allChallenges.where((c) => c.isCompleted).length;
      final activeChallenges = allChallenges.where((c) => c.isActive).length;
      final failedChallenges = allChallenges.where((c) => c.isFailed).length;
      
      final completionRate = totalChallenges > 0 ? (completedChallenges / totalChallenges) : 0.0;
      
      final totalPointsFromChallenges = allChallenges
          .map((c) => c.totalPointsEarned)
          .fold(0, (sum, points) => sum + points);
      
      // 가장 많이 완료한 카테고리
      final categoryStats = <ChallengeCategory, int>{};
      for (final challenge in allChallenges.where((c) => c.isCompleted)) {
        categoryStats[challenge.challenge.category] = 
            (categoryStats[challenge.challenge.category] ?? 0) + 1;
      }
      
      final favoriteCategory = categoryStats.isNotEmpty
          ? categoryStats.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;
      
      // 최대 연속 완료 일수
      final maxStreak = allChallenges.isNotEmpty
          ? allChallenges.map((c) => c.maxStreak).reduce((a, b) => a > b ? a : b)
          : 0;
      
      return {
        'totalChallenges': totalChallenges,
        'completedChallenges': completedChallenges,
        'activeChallenges': activeChallenges,
        'failedChallenges': failedChallenges,
        'completionRate': completionRate,
        'totalPointsFromChallenges': totalPointsFromChallenges,
        'favoriteCategory': favoriteCategory,
        'maxStreak': maxStreak,
      };
    } catch (e) {
      if (kDebugMode) {
        print('ChallengeService: 챌린지 통계 계산 실패 - $e');
      }
      return {
        'totalChallenges': 0,
        'completedChallenges': 0,
        'activeChallenges': 0,
        'failedChallenges': 0,
        'completionRate': 0.0,
        'totalPointsFromChallenges': 0,
        'favoriteCategory': null,
        'maxStreak': 0,
      };
    }
  }

  /// 챌린지 달성률 계산
  static double calculateAchievementRate(List<UserChallenge> challenges) {
    if (challenges.isEmpty) return 0.0;
    
    final completedCount = challenges.where((c) => c.isCompleted).length;
    return completedCount / challenges.length;
  }

  /// 평균 완료 시간 계산 (일)
  static double calculateAverageCompletionTime(List<UserChallenge> completedChallenges) {
    if (completedChallenges.isEmpty) return 0.0;
    
    final durations = completedChallenges
        .where((c) => c.actualDuration != null)
        .map((c) => c.actualDuration!)
        .toList();
    
    if (durations.isEmpty) return 0.0;
    
    final totalDays = durations.fold(0, (sum, days) => sum + days);
    return totalDays / durations.length;
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 챌린지 ID로 챌린지 정보 가져오기
  static Challenge? getChallengeById(String challengeId) {
    return ChallengeData.getChallengeById(challengeId);
  }

  /// 모든 챌린지 목록 가져오기
  static List<Challenge> getAllChallenges() {
    return ChallengeData.curatedChallenges;
  }

  /// 카테고리 목록 가져오기
  static List<ChallengeCategory> getAllCategories() {
    return ChallengeData.allCategories;
  }

  /// 난이도 목록 가져오기
  static List<ChallengeDifficulty> getAllDifficulties() {
    return ChallengeData.allDifficulties;
  }

  /// 챌린지 검색
  static List<Challenge> searchChallenges(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return ChallengeData.curatedChallenges.where((challenge) {
      return challenge.title.toLowerCase().contains(lowercaseQuery) ||
             challenge.description.toLowerCase().contains(lowercaseQuery) ||
             challenge.category.displayName.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
} 