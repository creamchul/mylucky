import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_entry_model.dart';
import 'firebase_service.dart';

class MoodService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'mood_entries';

  /// 감정일기 저장
  static Future<bool> saveMoodEntry(MoodEntryModel entry) async {
    try {
      if (kDebugMode) {
        print('감정일기 저장 시작: ${entry.id}');
        print('사용자 ID: ${entry.userId}');
        print('감정: ${entry.mood.displayName}');
        print('내용 길이: ${entry.content.length}');
        print('활동: ${entry.activities}');
      }

      await _firestore
          .collection(_collectionName)
          .doc(entry.id)
          .set(entry.toFirestore());

      if (kDebugMode) {
        print('감정일기 저장 완료: ${entry.mood.displayName}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 저장 실패: $e');
        print('에러 상세: ${e.runtimeType}');
        if (e.toString().contains('permission')) {
          print('Firebase 권한 문제일 가능성이 높습니다.');
        }
      }
      return false;
    }
  }

  /// 특정 날짜의 감정일기 조회 - 해당 날짜의 모든 기록 반환
  static Future<List<MoodEntryModel>> getMoodEntriesByDate(String userId, DateTime date) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final dateStart = DateTime(date.year, date.month, date.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final entries = <MoodEntryModel>[];
      
      // 클라이언트에서 날짜 필터링
      for (final doc in query.docs) {
        final entry = MoodEntryModel.fromFirestore(doc.id, doc.data());
        if (entry.createdAt.isAfter(dateStart.subtract(const Duration(seconds: 1))) && 
            entry.createdAt.isBefore(dateEnd)) {
          entries.add(entry);
        }
      }
      
      // 시간순 정렬 (최신이 위로)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('날짜별 감정일기 조회 실패: $e');
      }
      return [];
    }
  }

  /// 월별 감정일기 조회 - 새로운 핵심 기능
  static Future<List<MoodEntryModel>> getMoodEntriesByMonth(String userId, int year, int month) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);

      final entries = <MoodEntryModel>[];
      
      // 클라이언트에서 월 필터링
      for (final doc in query.docs) {
        final entry = MoodEntryModel.fromFirestore(doc.id, doc.data());
        if (entry.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
            entry.createdAt.isBefore(monthEnd)) {
          entries.add(entry);
        }
      }
      
      // 시간순 정렬 (최신이 위로)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('월별 감정일기 조회 실패: $e');
      }
      return [];
    }
  }

  /// 사용자의 모든 감정일기 조회 (최신순) - 인덱스 없이 작동하도록 단순화
  static Future<List<MoodEntryModel>> getAllMoodEntries(String userId) async {
    try {
      // 단순 쿼리로 변경 (orderBy 제거)
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final entries = query.docs
          .map((doc) => MoodEntryModel.fromFirestore(doc.id, doc.data()))
          .toList();
      
      // 클라이언트에서 정렬
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 목록 조회 실패: $e');
      }
      return [];
    }
  }

  /// 기간별 감정일기 조회 - 인덱스 없이 작동하도록 단순화
  static Future<List<MoodEntryModel>> getMoodEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // 단순 쿼리로 변경
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final entries = query.docs
          .map((doc) => MoodEntryModel.fromFirestore(doc.id, doc.data()))
          .where((entry) => 
              entry.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
              entry.createdAt.isBefore(endDate.add(const Duration(seconds: 1))))
          .toList();
      
      // 클라이언트에서 정렬
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('기간별 감정일기 조회 실패: $e');
      }
      return [];
    }
  }

  /// 감정일기 수정
  static Future<bool> updateMoodEntry(MoodEntryModel entry) async {
    try {
      if (kDebugMode) {
        print('감정일기 수정 시작: ${entry.id}');
        print('사용자 ID: ${entry.userId}');
      }

      final updatedEntry = entry.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_collectionName)
          .doc(entry.id)
          .update(updatedEntry.toFirestore());

      if (kDebugMode) {
        print('감정일기 수정 완료: ${entry.id}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 수정 실패: $e');
        print('에러 상세: ${e.runtimeType}');
      }
      return false;
    }
  }

  /// 감정일기 삭제
  static Future<bool> deleteMoodEntry(String entryId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .delete();

      if (kDebugMode) {
        print('감정일기 삭제 완료: $entryId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 삭제 실패: $e');
      }
      return false;
    }
  }

  /// 감정 통계 조회 - 인덱스 없이 작동하도록 단순화
  static Future<Map<MoodType, int>> getMoodStatistics(String userId, {int? days}) async {
    try {
      // 단순 쿼리로 변경
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final now = DateTime.now();
      final startDate = days != null 
          ? now.subtract(Duration(days: days))
          : DateTime(2020); // 전체 기간

      final Map<MoodType, int> statistics = {};
      for (final moodType in MoodType.values) {
        statistics[moodType] = 0;
      }

      // 클라이언트에서 날짜 필터링 및 통계 계산
      for (final doc in query.docs) {
        final data = doc.data();
        final entryDate = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // 날짜 필터링
        if (entryDate.isAfter(startDate.subtract(const Duration(seconds: 1)))) {
          final moodType = MoodType.values.firstWhere(
            (e) => e.name == data['mood'],
            orElse: () => MoodType.normal,
          );
          statistics[moodType] = (statistics[moodType] ?? 0) + 1;
        }
      }

      return statistics;
    } catch (e) {
      if (kDebugMode) {
        print('감정 통계 조회 실패: $e');
      }
      return {};
    }
  }

  /// 오늘 감정일기 작성 여부 확인 - 하루 여러 번 작성 가능하므로 개수 반환
  static Future<int> getTodayEntryCount(String userId) async {
    final today = DateTime.now();
    final entries = await getMoodEntriesByDate(userId, today);
    return entries.length;
  }

  /// 오늘의 감정일기 목록 조회
  static Future<List<MoodEntryModel>> getTodayEntries(String userId) async {
    final today = DateTime.now();
    return await getMoodEntriesByDate(userId, today);
  }

  /// 연속 작성일 계산
  static Future<int> getConsecutiveDays(String userId) async {
    try {
      final entries = await getAllMoodEntries(userId);
      if (entries.isEmpty) return 0;

      // 날짜별로 그룹핑
      final Map<String, List<MoodEntryModel>> entriesByDate = {};
      for (final entry in entries) {
        final dateKey = '${entry.createdAt.year}-${entry.createdAt.month}-${entry.createdAt.day}';
        entriesByDate[dateKey] = entriesByDate[dateKey] ?? [];
        entriesByDate[dateKey]!.add(entry);
      }

      // 연속 작성일 계산
      int consecutiveDays = 0;
      final today = DateTime.now();
      DateTime checkDate = DateTime(today.year, today.month, today.day);

      while (true) {
        final dateKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
        if (entriesByDate.containsKey(dateKey)) {
          consecutiveDays++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return consecutiveDays;
    } catch (e) {
      if (kDebugMode) {
        print('연속 작성일 계산 실패: $e');
      }
      return 0;
    }
  }

  /// 최근 7일 감정 트렌드 조회
  static Future<List<MoodEntryModel>> getWeeklyMoodTrend(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return await getMoodEntriesByDateRange(userId, weekAgo, now);
  }

  /// 활동 통계 조회 - 새로운 기능
  static Future<Map<String, int>> getActivityStatistics(String userId, {int? days}) async {
    try {
      final now = DateTime.now();
      final startDate = days != null 
          ? now.subtract(Duration(days: days))
          : DateTime(2020);

      final entries = await getMoodEntriesByDateRange(userId, startDate, now);
      final Map<String, int> activityStats = {};

      for (final entry in entries) {
        for (final activity in entry.activities) {
          activityStats[activity] = (activityStats[activity] ?? 0) + 1;
        }
      }

      return activityStats;
    } catch (e) {
      if (kDebugMode) {
        print('활동 통계 조회 실패: $e');
      }
      return {};
    }
  }

  /// 날짜별 그룹핑된 감정일기 조회 - UI용
  static Future<Map<String, List<MoodEntryModel>>> getGroupedMoodEntriesByMonth(
    String userId, 
    int year, 
    int month
  ) async {
    final entries = await getMoodEntriesByMonth(userId, year, month);
    final Map<String, List<MoodEntryModel>> groupedEntries = {};

    for (final entry in entries) {
      final dateKey = '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}';
      groupedEntries[dateKey] = groupedEntries[dateKey] ?? [];
      groupedEntries[dateKey]!.add(entry);
    }

    // 각 날짜 내에서 시간순 정렬
    for (final dateEntries in groupedEntries.values) {
      dateEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return groupedEntries;
  }

  /// 요일별 감정 통계 조회 - 새로운 기능
  static Future<Map<int, Map<MoodType, int>>> getWeeklyMoodStatistics(String userId, {int? days}) async {
    try {
      final now = DateTime.now();
      final startDate = days != null 
          ? now.subtract(Duration(days: days))
          : DateTime(2020);

      final entries = await getMoodEntriesByDateRange(userId, startDate, now);
      final Map<int, Map<MoodType, int>> weeklyStats = {};

      // 요일별 통계 초기화 (0: 일요일, 1: 월요일, ..., 6: 토요일)
      for (int i = 0; i < 7; i++) {
        weeklyStats[i] = {};
        for (final mood in MoodType.values) {
          weeklyStats[i]![mood] = 0;
        }
      }

      for (final entry in entries) {
        final weekday = entry.createdAt.weekday % 7; // 0: 일요일, 1: 월요일, ..., 6: 토요일
        weeklyStats[weekday]![entry.mood] = (weeklyStats[weekday]![entry.mood] ?? 0) + 1;
      }

      return weeklyStats;
    } catch (e) {
      if (kDebugMode) {
        print('요일별 감정 통계 조회 실패: $e');
      }
      return {};
    }
  }

  /// 감정별 평균 활동 수 조회 - 감정과 활동의 연관성 분석
  static Future<Map<MoodType, double>> getAverageActivitiesByMood(String userId, {int? days}) async {
    try {
      final now = DateTime.now();
      final startDate = days != null 
          ? now.subtract(Duration(days: days))
          : DateTime(2020);

      final entries = await getMoodEntriesByDateRange(userId, startDate, now);
      final Map<MoodType, List<int>> moodActivityCounts = {};

      for (final mood in MoodType.values) {
        moodActivityCounts[mood] = [];
      }

      for (final entry in entries) {
        moodActivityCounts[entry.mood]!.add(entry.activities.length);
      }

      final Map<MoodType, double> averages = {};
      for (final mood in MoodType.values) {
        final counts = moodActivityCounts[mood]!;
        if (counts.isNotEmpty) {
          averages[mood] = counts.reduce((a, b) => a + b) / counts.length;
        } else {
          averages[mood] = 0.0;
        }
      }

      return averages;
    } catch (e) {
      if (kDebugMode) {
        print('감정별 평균 활동 수 조회 실패: $e');
      }
      return {};
    }
  }

  /// 월별 감정 트렌드 조회 - 감정 변화 추이 분석
  static Future<Map<String, Map<MoodType, int>>> getMonthlyMoodTrend(String userId, int monthCount) async {
    try {
      final now = DateTime.now();
      final Map<String, Map<MoodType, int>> monthlyTrend = {};

      for (int i = 0; i < monthCount; i++) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final monthKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}';
        
        final entries = await getMoodEntriesByMonth(userId, targetDate.year, targetDate.month);
        
        monthlyTrend[monthKey] = {};
        for (final mood in MoodType.values) {
          monthlyTrend[monthKey]![mood] = 0;
        }

        for (final entry in entries) {
          monthlyTrend[monthKey]![entry.mood] = (monthlyTrend[monthKey]![entry.mood] ?? 0) + 1;
        }
      }

      return monthlyTrend;
    } catch (e) {
      if (kDebugMode) {
        print('월별 감정 트렌드 조회 실패: $e');
      }
      return {};
    }
  }

  /// 감정 다양성 지수 계산 - 얼마나 다양한 감정을 경험하는지
  static Future<double> getEmotionalDiversityIndex(String userId, {int? days}) async {
    try {
      final moodStats = await getMoodStatistics(userId, days: days);
      final totalEntries = moodStats.values.fold(0, (sum, count) => sum + count);
      
      if (totalEntries == 0) return 0.0;

      // 섀넌 다양성 지수 계산
      double diversity = 0.0;
      for (final count in moodStats.values) {
        if (count > 0) {
          final proportion = count / totalEntries;
          diversity -= proportion * (proportion > 0 ? (proportion * 3.32193).floor() / 3.32193 : 0); // log2 approximation
        }
      }

      return diversity;
    } catch (e) {
      if (kDebugMode) {
        print('감정 다양성 지수 계산 실패: $e');
      }
      return 0.0;
    }
  }

  /// 최장 연속 기록 일수 조회
  static Future<int> getLongestStreak(String userId) async {
    try {
      final entries = await getAllMoodEntries(userId);
      if (entries.isEmpty) return 0;

      // 날짜별로 그룹핑
      final Set<String> recordDates = {};
      for (final entry in entries) {
        final dateKey = '${entry.createdAt.year}-${entry.createdAt.month}-${entry.createdAt.day}';
        recordDates.add(dateKey);
      }

      // 날짜 정렬
      final sortedDates = recordDates.toList()..sort();
      
      int maxStreak = 0;
      int currentStreak = 1;
      
      for (int i = 1; i < sortedDates.length; i++) {
        final prevDate = DateTime.parse(sortedDates[i - 1]);
        final currentDate = DateTime.parse(sortedDates[i]);
        
        if (currentDate.difference(prevDate).inDays == 1) {
          currentStreak++;
        } else {
          maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
          currentStreak = 1;
        }
      }
      
      return maxStreak > currentStreak ? maxStreak : currentStreak;
    } catch (e) {
      if (kDebugMode) {
        print('최장 연속 기록 일수 조회 실패: $e');
      }
      return 0;
    }
  }

  /// 가장 활발했던 감정 조회 (기간별)
  static Future<MoodType?> getMostFrequentMood(String userId, {int? days}) async {
    try {
      final moodStats = await getMoodStatistics(userId, days: days);
      if (moodStats.isEmpty) return null;

      final mostFrequent = moodStats.entries.reduce((a, b) => a.value > b.value ? a : b);
      return mostFrequent.value > 0 ? mostFrequent.key : null;
    } catch (e) {
      if (kDebugMode) {
        print('가장 활발했던 감정 조회 실패: $e');
      }
      return null;
    }
  }

  /// 감정 변화율 계산 - 이전 기간 대비 감정 변화
  static Future<Map<MoodType, double>> getMoodChangeRate(String userId, int days) async {
    try {
      final now = DateTime.now();
      final currentPeriodStart = now.subtract(Duration(days: days));
      final previousPeriodStart = now.subtract(Duration(days: days * 2));

      final currentPeriodStats = await getMoodStatistics(userId, days: days);
      
      // 이전 기간 통계 계산
      final previousEntries = await getMoodEntriesByDateRange(userId, previousPeriodStart, currentPeriodStart);
      final Map<MoodType, int> previousPeriodStats = {};
      for (final mood in MoodType.values) {
        previousPeriodStats[mood] = 0;
      }
      for (final entry in previousEntries) {
        previousPeriodStats[entry.mood] = (previousPeriodStats[entry.mood] ?? 0) + 1;
      }

      // 변화율 계산
      final Map<MoodType, double> changeRates = {};
      for (final mood in MoodType.values) {
        final currentCount = currentPeriodStats[mood] ?? 0;
        final previousCount = previousPeriodStats[mood] ?? 0;
        
        if (previousCount > 0) {
          changeRates[mood] = ((currentCount - previousCount) / previousCount) * 100;
        } else if (currentCount > 0) {
          changeRates[mood] = 100.0; // 이전에 없었던 감정이 나타남
        } else {
          changeRates[mood] = 0.0;
        }
      }

      return changeRates;
    } catch (e) {
      if (kDebugMode) {
        print('감정 변화율 계산 실패: $e');
      }
      return {};
    }
  }

  /// 즐겨찾기 토글
  static Future<bool> toggleFavorite(String entryId) async {
    try {
      if (kDebugMode) {
        print('즐겨찾기 토글 시작 - entryId: $entryId');
      }

      final doc = await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('감정일기를 찾을 수 없습니다: $entryId');
        }
        return false;
      }

      final currentData = doc.data()!;
      final currentFavorite = currentData['isFavorite'] ?? false;
      final newFavorite = !currentFavorite;

      await _firestore
          .collection(_collectionName)
          .doc(entryId)
          .update({
            'isFavorite': newFavorite,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });

      if (kDebugMode) {
        print('즐겨찾기 토글 완료 - entryId: $entryId, 새 상태: $newFavorite');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 토글 실패: $e');
      }
      return false;
    }
  }

  /// 즐겨찾기한 감정일기만 조회
  static Future<List<MoodEntryModel>> getFavoriteEntries(String userId) async {
    try {
      if (kDebugMode) {
        print('즐겨찾기 감정일기 조회 시작 - userId: $userId');
      }

      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .get();

      final entries = query.docs
          .map((doc) => MoodEntryModel.fromFirestore(doc.id, doc.data()))
          .toList();
      
      // 클라이언트에서 정렬 (최신순)
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (kDebugMode) {
        print('즐겨찾기 감정일기 조회 완료 - 총 ${entries.length}개');
      }
      
      return entries;
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 감정일기 조회 실패: $e');
      }
      return [];
    }
  }

  /// 즐겨찾기 개수 조회
  static Future<int> getFavoriteCount(String userId) async {
    try {
      final favorites = await getFavoriteEntries(userId);
      return favorites.length;
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 개수 조회 실패: $e');
      }
      return 0;
    }
  }

  /// 월별 즐겨찾기 감정일기 조회
  static Future<Map<String, List<MoodEntryModel>>> getGroupedFavoriteEntriesByMonth(
    String userId, 
    int year, 
    int month
  ) async {
    try {
      final favorites = await getFavoriteEntries(userId);
      final Map<String, List<MoodEntryModel>> groupedEntries = {};

      // 해당 월의 즐겨찾기만 필터링
      final monthStart = DateTime(year, month, 1);
      final monthEnd = DateTime(year, month + 1, 1);

      for (final entry in favorites) {
        if (entry.createdAt.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
            entry.createdAt.isBefore(monthEnd)) {
          final dateKey = '${entry.createdAt.year}-${entry.createdAt.month.toString().padLeft(2, '0')}-${entry.createdAt.day.toString().padLeft(2, '0')}';
          groupedEntries[dateKey] = groupedEntries[dateKey] ?? [];
          groupedEntries[dateKey]!.add(entry);
        }
      }

      // 각 날짜 내에서 시간순 정렬
      for (final dateEntries in groupedEntries.values) {
        dateEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      return groupedEntries;
    } catch (e) {
      if (kDebugMode) {
        print('월별 즐겨찾기 감정일기 조회 실패: $e');
      }
      return {};
    }
  }
}
