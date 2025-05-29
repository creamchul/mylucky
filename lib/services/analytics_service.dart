import '../../models/focus_session_model.dart';

class AnalyticsService {
  
  /// 시간대별 집중 패턴 분석 (24시간)
  static Map<int, double> getHourlyPattern(List<FocusSessionModel> sessions, DateTime targetDate) {
    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final filteredSessions = sessions.where((session) {
      final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
      return sessionDate.isAtSameMomentAs(targetDateOnly) && session.status == FocusSessionStatus.completed;
    }).toList();
    
    Map<int, double> hourlyData = {};
    for (int hour = 0; hour < 24; hour++) {
      hourlyData[hour] = 0.0;
    }
    
    for (final session in filteredSessions) {
      final hour = session.createdAt.hour;
      final focusMinutes = session.elapsedSeconds / 60.0;
      hourlyData[hour] = (hourlyData[hour] ?? 0.0) + focusMinutes;
    }
    
    return hourlyData;
  }
  
  /// 요일별 집중 패턴 분석 (주간)
  static Map<int, double> getWeeklyPattern(List<FocusSessionModel> sessions, DateTime targetWeek) {
    final startOfWeek = _getStartOfWeek(targetWeek);
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final filteredSessions = sessions.where((session) {
      final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
      return sessionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             sessionDate.isBefore(endOfWeek.add(const Duration(days: 1))) &&
             session.status == FocusSessionStatus.completed;
    }).toList();
    
    Map<int, double> weeklyData = {};
    for (int day = 1; day <= 7; day++) {
      weeklyData[day] = 0.0;
    }
    
    for (final session in filteredSessions) {
      final weekday = session.createdAt.weekday;
      final focusMinutes = session.elapsedSeconds / 60.0;
      weeklyData[weekday] = (weeklyData[weekday] ?? 0.0) + focusMinutes;
    }
    
    return weeklyData;
  }
  
  /// 월별 집중 패턴 분석 (한 달)
  static Map<int, double> getMonthlyPattern(List<FocusSessionModel> sessions, DateTime targetMonth) {
    final startOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
    
    final filteredSessions = sessions.where((session) {
      final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
      return sessionDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             sessionDate.isBefore(endOfMonth.add(const Duration(days: 1))) &&
             session.status == FocusSessionStatus.completed;
    }).toList();
    
    Map<int, double> monthlyData = {};
    for (int day = 1; day <= endOfMonth.day; day++) {
      monthlyData[day] = 0.0;
    }
    
    for (final session in filteredSessions) {
      final day = session.createdAt.day;
      final focusMinutes = session.elapsedSeconds / 60.0;
      monthlyData[day] = (monthlyData[day] ?? 0.0) + focusMinutes;
    }
    
    return monthlyData;
  }
  
  /// 연간 집중 패턴 분석 (12개월)
  static Map<int, double> getYearlyPattern(List<FocusSessionModel> sessions, DateTime targetYear) {
    final startOfYear = DateTime(targetYear.year, 1, 1);
    final endOfYear = DateTime(targetYear.year, 12, 31);
    
    final filteredSessions = sessions.where((session) {
      return session.createdAt.isAfter(startOfYear.subtract(const Duration(days: 1))) &&
             session.createdAt.isBefore(endOfYear.add(const Duration(days: 1))) &&
             session.status == FocusSessionStatus.completed;
    }).toList();
    
    Map<int, double> yearlyData = {};
    for (int month = 1; month <= 12; month++) {
      yearlyData[month] = 0.0;
    }
    
    for (final session in filteredSessions) {
      final month = session.createdAt.month;
      final focusMinutes = session.elapsedSeconds / 60.0;
      yearlyData[month] = (yearlyData[month] ?? 0.0) + focusMinutes;
    }
    
    return yearlyData;
  }
  
  /// 비교 분석 (현재 vs 이전 기간)
  static Map<String, dynamic> getComparisonAnalysis(
    List<FocusSessionModel> sessions,
    DateTime currentPeriod,
    String periodType, // 'day', 'week', 'month', 'year'
  ) {
    Map<int, double> currentData;
    Map<int, double> previousData;
    DateTime previousPeriod;
    
    switch (periodType) {
      case 'day':
        previousPeriod = currentPeriod.subtract(const Duration(days: 1));
        currentData = getHourlyPattern(sessions, currentPeriod);
        previousData = getHourlyPattern(sessions, previousPeriod);
        break;
      case 'week':
        previousPeriod = currentPeriod.subtract(const Duration(days: 7));
        currentData = getWeeklyPattern(sessions, currentPeriod);
        previousData = getWeeklyPattern(sessions, previousPeriod);
        break;
      case 'month':
        previousPeriod = DateTime(currentPeriod.year, currentPeriod.month - 1, currentPeriod.day);
        currentData = getMonthlyPattern(sessions, currentPeriod);
        previousData = getMonthlyPattern(sessions, previousPeriod);
        break;
      case 'year':
        previousPeriod = DateTime(currentPeriod.year - 1, currentPeriod.month, currentPeriod.day);
        currentData = getYearlyPattern(sessions, currentPeriod);
        previousData = getYearlyPattern(sessions, previousPeriod);
        break;
      default:
        throw ArgumentError('Invalid period type: $periodType');
    }
    
    final currentTotal = currentData.values.fold(0.0, (sum, value) => sum + value);
    final previousTotal = previousData.values.fold(0.0, (sum, value) => sum + value);
    final changePercent = previousTotal > 0 ? ((currentTotal - previousTotal) / previousTotal * 100) : 0.0;
    
    return {
      'current': currentData,
      'previous': previousData,
      'currentTotal': currentTotal,
      'previousTotal': previousTotal,
      'changePercent': changePercent,
      'isImproved': changePercent > 0,
    };
  }
  
  /// 성공률 분석
  static Map<String, dynamic> getSuccessRateAnalysis(
    List<FocusSessionModel> sessions,
    DateTime targetPeriod,
    String periodType,
  ) {
    List<FocusSessionModel> filteredSessions;
    
    switch (periodType) {
      case 'day':
        final targetDate = DateTime(targetPeriod.year, targetPeriod.month, targetPeriod.day);
        filteredSessions = sessions.where((session) {
          final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
          return sessionDate.isAtSameMomentAs(targetDate);
        }).toList();
        break;
      case 'week':
        final startOfWeek = _getStartOfWeek(targetPeriod);
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        filteredSessions = sessions.where((session) {
          final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
          return sessionDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                 sessionDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;
      case 'month':
        filteredSessions = sessions.where((session) {
          return session.createdAt.year == targetPeriod.year &&
                 session.createdAt.month == targetPeriod.month;
        }).toList();
        break;
      case 'year':
        filteredSessions = sessions.where((session) {
          return session.createdAt.year == targetPeriod.year;
        }).toList();
        break;
      default:
        filteredSessions = sessions;
    }
    
    final totalSessions = filteredSessions.length;
    final completedSessions = filteredSessions.where((s) => s.status == FocusSessionStatus.completed).length;
    final abandonedSessions = filteredSessions.where((s) => s.status == FocusSessionStatus.abandoned).length;
    final successRate = totalSessions > 0 ? (completedSessions / totalSessions * 100) : 0.0;
    
    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'abandonedSessions': abandonedSessions,
      'successRate': successRate,
    };
  }
  
  /// 주의 시작일 계산 (월요일 기준)
  static DateTime _getStartOfWeek(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
  
  /// 집중 시간 트렌드 분석 (최근 N일)
  static List<Map<String, dynamic>> getFocusTrend(List<FocusSessionModel> sessions, int days) {
    final now = DateTime.now();
    final trendData = <Map<String, dynamic>>[];
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      final daysSessions = sessions.where((session) {
        final sessionDate = DateTime(session.createdAt.year, session.createdAt.month, session.createdAt.day);
        return sessionDate.isAtSameMomentAs(dateOnly) && session.status == FocusSessionStatus.completed;
      }).toList();
      
      final totalMinutes = daysSessions.fold(0.0, (sum, session) => sum + (session.elapsedSeconds / 60.0));
      final sessionCount = daysSessions.length;
      
      trendData.add({
        'date': dateOnly,
        'totalMinutes': totalMinutes,
        'sessionCount': sessionCount,
        'dayOfWeek': date.weekday,
      });
    }
    
    return trendData;
  }
  
  /// 최고 집중 시간대 찾기
  static Map<String, dynamic> getPeakFocusTime(List<FocusSessionModel> sessions) {
    final hourlyTotal = <int, double>{};
    
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed) {
        final hour = session.createdAt.hour;
        final minutes = session.elapsedSeconds / 60.0;
        hourlyTotal[hour] = (hourlyTotal[hour] ?? 0.0) + minutes;
      }
    }
    
    if (hourlyTotal.isEmpty) {
      return {'hour': 0, 'totalMinutes': 0.0, 'period': '데이터 없음'};
    }
    
    final peakHour = hourlyTotal.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    String getPeriodName(int hour) {
      if (hour >= 6 && hour < 12) return '오전';
      if (hour >= 12 && hour < 18) return '오후';
      if (hour >= 18 && hour < 22) return '저녁';
      return '밤';
    }
    
    return {
      'hour': peakHour.key,
      'totalMinutes': peakHour.value,
      'period': getPeriodName(peakHour.key),
      'timeString': '${peakHour.key}:00 - ${peakHour.key + 1}:00',
    };
  }

  /// 카테고리별 집중 시간 분석
  static Map<String, double> getCategoryAnalysis(List<FocusSessionModel> sessions) {
    final categoryTimes = <String, double>{};
    
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed && session.categoryId != null) {
        final minutes = session.elapsedSeconds / 60.0;
        categoryTimes[session.categoryId!] = (categoryTimes[session.categoryId!] ?? 0.0) + minutes;
      }
    }
    
    return categoryTimes;
  }

  /// 카테고리별 세션 수 분석
  static Map<String, int> getCategorySessionCount(List<FocusSessionModel> sessions) {
    final categoryCount = <String, int>{};
    
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed && session.categoryId != null) {
        categoryCount[session.categoryId!] = (categoryCount[session.categoryId!] ?? 0) + 1;
      }
    }
    
    return categoryCount;
  }

  /// 카테고리별 성공률 분석
  static Map<String, Map<String, dynamic>> getCategorySuccessRate(List<FocusSessionModel> sessions) {
    final categoryStats = <String, Map<String, dynamic>>{};
    
    for (final session in sessions) {
      if (session.categoryId != null) {
        final categoryId = session.categoryId!;
        
        if (!categoryStats.containsKey(categoryId)) {
          categoryStats[categoryId] = {
            'total': 0,
            'completed': 0,
            'abandoned': 0,
          };
        }
        
        categoryStats[categoryId]!['total'] = (categoryStats[categoryId]!['total'] as int) + 1;
        
        if (session.status == FocusSessionStatus.completed) {
          categoryStats[categoryId]!['completed'] = (categoryStats[categoryId]!['completed'] as int) + 1;
        } else if (session.status == FocusSessionStatus.abandoned) {
          categoryStats[categoryId]!['abandoned'] = (categoryStats[categoryId]!['abandoned'] as int) + 1;
        }
      }
    }
    
    // 성공률 계산
    for (final entry in categoryStats.entries) {
      final stats = entry.value;
      final total = stats['total'] as int;
      final completed = stats['completed'] as int;
      stats['successRate'] = total > 0 ? (completed / total * 100) : 0.0;
    }
    
    return categoryStats;
  }

  /// 최고 성능 카테고리 찾기
  static Map<String, dynamic> getTopPerformanceCategory(
    List<FocusSessionModel> sessions,
    Map<String, String> categoryNames,
  ) {
    final categoryTimes = getCategoryAnalysis(sessions);
    final categorySuccessRates = getCategorySuccessRate(sessions);
    
    if (categoryTimes.isEmpty) {
      return {
        'categoryId': null,
        'categoryName': '데이터 없음',
        'totalMinutes': 0.0,
        'successRate': 0.0,
        'sessionCount': 0,
      };
    }
    
    // 총 집중 시간 기준으로 최고 성능 카테고리 선택
    final topCategory = categoryTimes.entries.reduce((a, b) => a.value > b.value ? a : b);
    final categoryStats = categorySuccessRates[topCategory.key];
    
    return {
      'categoryId': topCategory.key,
      'categoryName': categoryNames[topCategory.key] ?? '알 수 없음',
      'totalMinutes': topCategory.value,
      'successRate': categoryStats?['successRate'] ?? 0.0,
      'sessionCount': categoryStats?['completed'] ?? 0,
    };
  }

  /// 기간별 카테고리 사용 패턴
  static Map<String, List<Map<String, dynamic>>> getCategoryUsagePattern(
    List<FocusSessionModel> sessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final categoryPattern = <String, List<Map<String, dynamic>>>{};
    
    // 날짜별로 세션들을 그룹화
    final sessionsByDate = <String, List<FocusSessionModel>>{};
    
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed && 
          session.categoryId != null &&
          session.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
          session.createdAt.isBefore(endDate.add(const Duration(days: 1)))) {
        
        final dateKey = '${session.createdAt.year}-${session.createdAt.month}-${session.createdAt.day}';
        
        if (!sessionsByDate.containsKey(dateKey)) {
          sessionsByDate[dateKey] = [];
        }
        sessionsByDate[dateKey]!.add(session);
      }
    }
    
    // 각 날짜별로 카테고리별 집중 시간 계산
    for (final entry in sessionsByDate.entries) {
      final dateKey = entry.key;
      final dateSessions = entry.value;
      
      final dailyCategoryTimes = <String, double>{};
      
      for (final session in dateSessions) {
        final categoryId = session.categoryId!;
        final minutes = session.elapsedSeconds / 60.0;
        dailyCategoryTimes[categoryId] = (dailyCategoryTimes[categoryId] ?? 0.0) + minutes;
      }
      
      // 각 카테고리별 패턴에 추가
      for (final categoryEntry in dailyCategoryTimes.entries) {
        final categoryId = categoryEntry.key;
        
        if (!categoryPattern.containsKey(categoryId)) {
          categoryPattern[categoryId] = [];
        }
        
        categoryPattern[categoryId]!.add({
          'date': dateKey,
          'minutes': categoryEntry.value,
        });
      }
    }
    
    return categoryPattern;
  }

  /// 카테고리별 시간대 선호도 분석
  static Map<String, Map<int, double>> getCategoryTimePreference(List<FocusSessionModel> sessions) {
    final categoryTimePreference = <String, Map<int, double>>{};
    
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed && session.categoryId != null) {
        final categoryId = session.categoryId!;
        final hour = session.createdAt.hour;
        final minutes = session.elapsedSeconds / 60.0;
        
        if (!categoryTimePreference.containsKey(categoryId)) {
          categoryTimePreference[categoryId] = {};
        }
        
        categoryTimePreference[categoryId]![hour] = 
            (categoryTimePreference[categoryId]![hour] ?? 0.0) + minutes;
      }
    }
    
    return categoryTimePreference;
  }

  /// 카테고리 추천 (사용 패턴 기반)
  static List<String> getRecommendedCategories(
    List<FocusSessionModel> sessions,
    int currentHour,
    int currentWeekday,
  ) {
    final categoryHourUsage = <String, Map<int, int>>{};
    final categoryWeekdayUsage = <String, Map<int, int>>{};
    
    // 카테고리별 시간대/요일별 사용 패턴 수집
    for (final session in sessions) {
      if (session.status == FocusSessionStatus.completed && session.categoryId != null) {
        final categoryId = session.categoryId!;
        final hour = session.createdAt.hour;
        final weekday = session.createdAt.weekday;
        
        // 시간대별 사용 패턴
        if (!categoryHourUsage.containsKey(categoryId)) {
          categoryHourUsage[categoryId] = {};
        }
        categoryHourUsage[categoryId]![hour] = (categoryHourUsage[categoryId]![hour] ?? 0) + 1;
        
        // 요일별 사용 패턴
        if (!categoryWeekdayUsage.containsKey(categoryId)) {
          categoryWeekdayUsage[categoryId] = {};
        }
        categoryWeekdayUsage[categoryId]![weekday] = (categoryWeekdayUsage[categoryId]![weekday] ?? 0) + 1;
      }
    }
    
    // 현재 시간대와 요일에 맞는 카테고리 점수 계산
    final categoryScores = <String, double>{};
    
    for (final categoryId in categoryHourUsage.keys) {
      final hourUsage = categoryHourUsage[categoryId]!;
      final weekdayUsage = categoryWeekdayUsage[categoryId]!;
      
      final hourScore = hourUsage[currentHour] ?? 0;
      final weekdayScore = weekdayUsage[currentWeekday] ?? 0;
      
      categoryScores[categoryId] = hourScore.toDouble() + (weekdayScore * 0.5);
    }
    
    // 점수순으로 정렬하여 상위 카테고리 반환
    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories.take(3).map((e) => e.key).toList();
  }
} 