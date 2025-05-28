import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/habit_tracker_model.dart';
import '../models/todo_item_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'reward_service.dart';

/// 습관 관리 서비스
class HabitService {
  static const String _habitsKey = 'user_habits';
  
  // ========================================
  // 로컬 저장 관리
  // ========================================
  
  /// 습관 추적기 목록을 로컬에 저장
  static Future<void> _saveHabitsToLocal(String userId, List<HabitTrackerModel> habits) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = habits.map((habit) => habit.toMap()).toList();
      await prefs.setString('${_habitsKey}_$userId', json.encode(habitsJson));
      
      if (kDebugMode) {
        print('HabitService: 습관 목록 로컬 저장 완료 (${habits.length}개)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 목록 로컬 저장 실패 - $e');
      }
    }
  }
  
  /// 로컬에서 습관 추적기 목록 불러오기
  static Future<List<HabitTrackerModel>> _loadHabitsFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsJson = prefs.getString('${_habitsKey}_$userId');
      
      if (habitsJson != null) {
        final List<dynamic> habitsList = json.decode(habitsJson);
        final habits = habitsList.map((json) => HabitTrackerModel.fromMap(json)).toList();
        
        if (kDebugMode) {
          print('HabitService: 로컬에서 습관 목록 로드 완료 (${habits.length}개)');
        }
        
        return habits;
      }
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 로컬 습관 목록 로드 실패 - $e');
      }
    }
    
    return [];
  }

  // ========================================
  // 습관 추적기 관리
  // ========================================
  
  /// 새 습관 추적기 생성
  static Future<HabitTrackerModel> createHabitTracker({
    required String habitId,
    required String userId,
  }) async {
    try {
      final newTracker = HabitTrackerModel.create(
        habitId: habitId,
        userId: userId,
      );

      // 로컬 저장
      final existingHabits = await _loadHabitsFromLocal(userId);
      existingHabits.add(newTracker);
      await _saveHabitsToLocal(userId, existingHabits);

      // Firebase 저장 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.createHabitTracker(newTracker);
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 저장 실패, 로컬만 저장됨 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('HabitService: 새 습관 추적기 생성 완료 - $habitId');
      }

      return newTracker;
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 추적기 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 습관 추적기 조회
  static Future<HabitTrackerModel?> getHabitTracker(String userId, String habitId) async {
    try {
      final habits = await _loadHabitsFromLocal(userId);
      
      try {
        return habits.firstWhere((habit) => habit.habitId == habitId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 추적기 조회 실패 - $e');
      }
      return null;
    }
  }

  /// 모든 습관 추적기 조회
  static Future<List<HabitTrackerModel>> getAllHabitTrackers(String userId) async {
    try {
      List<HabitTrackerModel> habits = await _loadHabitsFromLocal(userId);

      // Firebase에서도 가져오기 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          final firebaseHabits = await FirebaseService.getUserHabitTrackers(userId);
          // 로컬과 Firebase 데이터 병합 (중복 제거)
          final localIds = habits.map((h) => h.habitId).toSet();
          final newHabits = firebaseHabits.where((h) => !localIds.contains(h.habitId)).toList();
          habits.addAll(newHabits);
          
          // 병합된 데이터를 로컬에 저장
          if (newHabits.isNotEmpty) {
            await _saveHabitsToLocal(userId, habits);
          }
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 조회 실패, 로컬 데이터만 사용 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('HabitService: 습관 추적기 목록 조회 완료 (${habits.length}개)');
      }

      return habits;
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 추적기 목록 조회 실패 - $e');
      }
      return [];
    }
  }

  // ========================================
  // 습관 기록 관리
  // ========================================

  /// 습관 완료 기록
  static Future<Map<String, dynamic>> recordHabitCompletion({
    required String userId,
    required String habitId,
    required UserModel currentUser,
    DateTime? date,
    int? value,
    String? note,
  }) async {
    try {
      final recordDate = date ?? DateTime.now();
      final habits = await _loadHabitsFromLocal(userId);
      final habitIndex = habits.indexWhere((habit) => habit.habitId == habitId);
      
      if (habitIndex == -1) {
        // 습관 추적기가 없으면 생성
        await createHabitTracker(habitId: habitId, userId: userId);
        return recordHabitCompletion(
          userId: userId,
          habitId: habitId,
          currentUser: currentUser,
          date: date,
          value: value,
          note: note,
        );
      }

      final habit = habits[habitIndex];
      
      // 같은 날짜에 이미 완료 기록이 있는지 확인
      final existingRecord = habit.getRecordForDate(recordDate);
      if (existingRecord != null && existingRecord.completed) {
        if (kDebugMode) {
          print('HabitService: 이미 완료된 날짜입니다 - $habitId (${recordDate.toString().split(' ')[0]})');
        }
        
        // 기존 기록과 통계 반환
        final stats = habit.calculateStats();
        return {
          'habit': habit,
          'stats': stats,
          'user': currentUser,
          'isNewRecord': false,
        };
      }
      
      // 새 기록 생성
      final newRecord = HabitRecord(
        date: recordDate,
        completed: true,
        value: value,
        note: note,
        recordedAt: DateTime.now(),
      );

      // 습관 추적기 업데이트
      final updatedHabit = habit.addRecord(newRecord);
      habits[habitIndex] = updatedHabit;
      await _saveHabitsToLocal(userId, habits);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateHabitTracker(updatedHabit);
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 통계 계산
      final stats = updatedHabit.calculateStats();

      if (kDebugMode) {
        print('HabitService: 습관 완료 기록 완료 - $habitId (연속: ${stats.currentStreak}일)');
      }

      return {
        'habit': updatedHabit,
        'stats': stats,
        'user': currentUser,
        'isNewRecord': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 완료 기록 실패 - $e');
      }
      rethrow;
    }
  }

  /// 습관 기록 취소
  static Future<Map<String, dynamic>> cancelHabitRecord({
    required String userId,
    required String habitId,
    DateTime? date,
  }) async {
    try {
      final recordDate = date ?? DateTime.now();
      final habits = await _loadHabitsFromLocal(userId);
      final habitIndex = habits.indexWhere((habit) => habit.habitId == habitId);
      
      if (habitIndex == -1) {
        throw Exception('습관 추적기를 찾을 수 없습니다: $habitId');
      }

      final habit = habits[habitIndex];
      
      // 취소 기록 생성
      final cancelRecord = HabitRecord(
        date: recordDate,
        completed: false,
        recordedAt: DateTime.now(),
      );

      // 습관 추적기 업데이트
      final updatedHabit = habit.addRecord(cancelRecord);
      habits[habitIndex] = updatedHabit;
      await _saveHabitsToLocal(userId, habits);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateHabitTracker(updatedHabit);
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 통계 계산
      final stats = updatedHabit.calculateStats();

      if (kDebugMode) {
        print('HabitService: 습관 기록 취소 완료 - $habitId');
      }

      return {
        'habit': updatedHabit,
        'stats': stats,
        'isCancelled': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 기록 취소 실패 - $e');
      }
      rethrow;
    }
  }

  /// 습관 완료 기록 제거 (완료 취소 시 사용)
  static Future<Map<String, dynamic>> removeHabitCompletion({
    required String userId,
    required String habitId,
    required DateTime date,
  }) async {
    try {
      final habits = await _loadHabitsFromLocal(userId);
      final habitIndex = habits.indexWhere((habit) => habit.habitId == habitId);
      
      if (habitIndex == -1) {
        // 습관 추적기가 없으면 아무것도 하지 않음
        return {
          'habit': null,
          'stats': null,
          'removed': false,
        };
      }

      final habit = habits[habitIndex];
      
      // 해당 날짜의 기록 제거
      final updatedRecords = habit.records.where((record) {
        return !_isSameDay(record.date, date);
      }).toList();

      // 습관 추적기 업데이트
      final updatedHabit = habit.copyWith(
        records: updatedRecords,
        updatedAt: DateTime.now(),
      );
      
      habits[habitIndex] = updatedHabit;
      await _saveHabitsToLocal(userId, habits);

      // Firebase 업데이트 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.updateHabitTracker(updatedHabit);
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 업데이트 실패 - $e');
          }
        }
      }

      // 통계 재계산
      final stats = updatedHabit.calculateStats();

      if (kDebugMode) {
        print('HabitService: 습관 완료 기록 제거 완료 - $habitId');
      }

      return {
        'habit': updatedHabit,
        'stats': stats,
        'removed': true,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 완료 기록 제거 실패 - $e');
      }
      return {
        'habit': null,
        'stats': null,
        'removed': false,
      };
    }
  }

  /// 같은 날짜인지 확인하는 헬퍼 메서드
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // ========================================
  // 통계 및 분석
  // ========================================

  /// 사용자의 모든 습관 통계 조회
  static Future<Map<String, dynamic>> getUserHabitStats(String userId) async {
    try {
      final habits = await getAllHabitTrackers(userId);
      
      if (habits.isEmpty) {
        return {
          'totalHabits': 0,
          'activeHabits': 0,
          'totalCompletions': 0,
          'averageCompletionRate': 0.0,
          'longestStreak': 0,
          'habitsCompletedToday': 0,
        };
      }

      int totalCompletions = 0;
      double totalCompletionRate = 0.0;
      int longestStreak = 0;
      int habitsCompletedToday = 0;

      for (final habit in habits) {
        final stats = habit.calculateStats();
        totalCompletions += stats.completedDays;
        totalCompletionRate += stats.completionRate;
        
        if (stats.bestStreak > longestStreak) {
          longestStreak = stats.bestStreak;
        }
        
        if (habit.isCompletedToday) {
          habitsCompletedToday++;
        }
      }

      final averageCompletionRate = totalCompletionRate / habits.length;

      return {
        'totalHabits': habits.length,
        'activeHabits': habits.length, // 모든 습관이 활성 상태로 간주
        'totalCompletions': totalCompletions,
        'averageCompletionRate': averageCompletionRate,
        'longestStreak': longestStreak,
        'habitsCompletedToday': habitsCompletedToday,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 사용자 습관 통계 조회 실패 - $e');
      }
      return {
        'totalHabits': 0,
        'activeHabits': 0,
        'totalCompletions': 0,
        'averageCompletionRate': 0.0,
        'longestStreak': 0,
        'habitsCompletedToday': 0,
      };
    }
  }

  /// 오늘 완료해야 할 습관 목록
  static Future<List<String>> getTodayHabits(String userId) async {
    try {
      final habits = await getAllHabitTrackers(userId);
      final todayHabits = <String>[];
      
      for (final habit in habits) {
        if (!habit.isCompletedToday) {
          todayHabits.add(habit.habitId);
        }
      }

      if (kDebugMode) {
        print('HabitService: 오늘 완료해야 할 습관 ${todayHabits.length}개');
      }

      return todayHabits;
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 오늘 습관 목록 조회 실패 - $e');
      }
      return [];
    }
  }

  /// 습관 달력 데이터 (특정 월)
  static Future<Map<int, bool>> getHabitCalendarData({
    required String userId,
    required String habitId,
    required int year,
    required int month,
  }) async {
    try {
      final habit = await getHabitTracker(userId, habitId);
      if (habit == null) {
        return {};
      }

      final calendarData = <int, bool>{};
      final daysInMonth = DateTime(year, month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final record = habit.getRecordForDate(date);
        calendarData[day] = record?.completed ?? false;
      }

      return calendarData;
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 달력 데이터 조회 실패 - $e');
      }
      return {};
    }
  }

  // ========================================
  // 동물/포레스트 연동
  // ========================================

  /// 습관 완료 시 동물 성장 포인트 지급 (포인트 지급 비활성화)
  static Future<Map<String, dynamic>> giveHabitCompletionReward({
    required String userId,
    required String habitId,
    required UserModel currentUser,
    required int streakDays,
  }) async {
    // 사용자가 직접 생성한 습관에 대해서는 포인트를 지급하지 않음
    if (kDebugMode) {
      print('HabitService: 사용자 생성 습관 - 포인트 지급 안함 (연속: ${streakDays}일)');
    }

    return {
      'user': currentUser,
      'pointsEarned': 0,
      'basePoints': 0,
      'bonusPoints': 0,
      'streakDays': streakDays,
    };
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 습관 추적기 삭제
  static Future<void> deleteHabitTracker({
    required String userId,
    required String habitId,
  }) async {
    try {
      final habits = await _loadHabitsFromLocal(userId);
      habits.removeWhere((habit) => habit.habitId == habitId);
      await _saveHabitsToLocal(userId, habits);

      // Firebase에서도 삭제 (웹이 아닌 경우)
      if (!kIsWeb) {
        try {
          await FirebaseService.deleteHabitTracker(habitId);
        } catch (e) {
          if (kDebugMode) {
            print('HabitService: Firebase 삭제 실패 - $e');
          }
        }
      }

      if (kDebugMode) {
        print('HabitService: 습관 추적기 삭제 완료 - $habitId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 추적기 삭제 실패 - $e');
      }
      rethrow;
    }
  }

  /// 습관 성취도 계산 (0-100)
  static int calculateHabitAchievement(HabitStats stats) {
    if (stats.totalDays == 0) return 0;
    
    // 완료율 70% + 연속 달성 30%
    final completionScore = (stats.completionRate * 70).round();
    final streakScore = (stats.currentStreak / 30 * 30).clamp(0, 30).round();
    final totalScore = (completionScore + streakScore).clamp(0, 100);
    
    return totalScore;
  }

  // ========================================
  // 통계 및 분석 기능 (새로 추가)
  // ========================================

  /// 사용자 습관 통계 조회
  static Future<Map<String, dynamic>> getHabitStats(String userId) async {
    try {
      final trackers = await getAllHabitTrackers(userId);
      
      if (trackers.isEmpty) {
        return {
          'totalHabits': 0,
          'activeHabits': 0,
          'averageCompletionRate': 0.0,
          'longestStreak': 0,
          'totalCompletedDays': 0,
          'thisWeekCompletions': 0,
          'thisMonthCompletions': 0,
        };
      }

      int totalHabits = trackers.length;
      int activeHabits = 0;
      double totalCompletionRate = 0.0;
      int longestStreak = 0;
      int totalCompletedDays = 0;
      int thisWeekCompletions = 0;
      int thisMonthCompletions = 0;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      for (final tracker in trackers) {
        final stats = tracker.calculateStats();
        
        // 활성 습관 (최근 7일 내 기록이 있는 경우)
        final recentRecords = tracker.records.where((r) => 
          r.date.isAfter(now.subtract(const Duration(days: 7)))
        ).toList();
        
        if (recentRecords.isNotEmpty) {
          activeHabits++;
        }

        // 완료율 누적
        totalCompletionRate += stats.completionRate;
        
        // 최장 연속 기록
        final currentStreak = stats.bestStreak;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }

        // 총 완료일수
        totalCompletedDays += tracker.records.where((r) => r.completed).length;

        // 이번 주 완료 수
        thisWeekCompletions += tracker.records.where((r) => 
          r.completed && r.date.isAfter(weekStart)
        ).length;

        // 이번 달 완료 수
        thisMonthCompletions += tracker.records.where((r) => 
          r.completed && r.date.isAfter(monthStart)
        ).length;
      }

      final averageCompletionRate = totalHabits > 0 ? totalCompletionRate / totalHabits : 0.0;

      if (kDebugMode) {
        print('HabitService: 습관 통계 계산 완료');
      }

      return {
        'totalHabits': totalHabits,
        'activeHabits': activeHabits,
        'averageCompletionRate': averageCompletionRate,
        'longestStreak': longestStreak,
        'totalCompletedDays': totalCompletedDays,
        'thisWeekCompletions': thisWeekCompletions,
        'thisMonthCompletions': thisMonthCompletions,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 통계 계산 실패 - $e');
      }
      return {
        'totalHabits': 0,
        'activeHabits': 0,
        'averageCompletionRate': 0.0,
        'longestStreak': 0,
        'totalCompletedDays': 0,
        'thisWeekCompletions': 0,
        'thisMonthCompletions': 0,
      };
    }
  }

  /// 습관별 상세 통계 조회
  static Future<Map<String, dynamic>> getHabitDetailStats(String userId, String habitId) async {
    try {
      final tracker = await getHabitTracker(userId, habitId);
      if (tracker == null) {
        return {};
      }

      final stats = tracker.calculateStats();
      final records = tracker.records;

      // 주간 패턴 분석
      final weeklyPattern = <int, int>{}; // 요일별 완료 횟수
      for (int i = 1; i <= 7; i++) {
        weeklyPattern[i] = 0;
      }

      for (final record in records.where((r) => r.completed)) {
        final weekday = record.date.weekday;
        weeklyPattern[weekday] = (weeklyPattern[weekday] ?? 0) + 1;
      }

      // 월별 완료율
      final monthlyCompletion = <String, double>{};
      final groupedByMonth = <String, List<HabitRecord>>{};
      
      for (final record in records) {
        final monthKey = '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
        groupedByMonth.putIfAbsent(monthKey, () => []).add(record);
      }

      for (final entry in groupedByMonth.entries) {
        final monthRecords = entry.value;
        final completedCount = monthRecords.where((r) => r.completed).length;
        final completionRate = monthRecords.isNotEmpty ? completedCount / monthRecords.length : 0.0;
        monthlyCompletion[entry.key] = completionRate;
      }

      return {
        'basicStats': stats,
        'weeklyPattern': weeklyPattern,
        'monthlyCompletion': monthlyCompletion,
        'totalRecords': records.length,
        'completedRecords': records.where((r) => r.completed).length,
        'missedRecords': records.where((r) => !r.completed).length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('HabitService: 습관 상세 통계 조회 실패 - $e');
      }
      return {};
    }
  }
} 