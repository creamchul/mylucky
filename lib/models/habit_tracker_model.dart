import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 습관 추적 기록
class HabitRecord {
  final DateTime date;
  final bool completed;
  final int? value; // 수치형 습관의 경우 (예: 물 8잔, 운동 30분)
  final String? note; // 메모
  final DateTime recordedAt;

  const HabitRecord({
    required this.date,
    required this.completed,
    this.value,
    this.note,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'completed': completed,
      'value': value,
      'note': note,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
    };
  }

  factory HabitRecord.fromMap(Map<String, dynamic> map) {
    return HabitRecord(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      completed: map['completed'] ?? false,
      value: map['value'],
      note: map['note'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
    );
  }
}

/// 습관 통계
class HabitStats {
  final int totalDays; // 총 추적 일수
  final int completedDays; // 완료한 일수
  final int currentStreak; // 현재 연속 달성
  final int bestStreak; // 최고 연속 달성
  final double completionRate; // 완료율
  final Map<String, int> weeklyPattern; // 요일별 완료 패턴
  final List<int> monthlyData; // 월별 완료 데이터 (최근 12개월)

  const HabitStats({
    required this.totalDays,
    required this.completedDays,
    required this.currentStreak,
    required this.bestStreak,
    required this.completionRate,
    required this.weeklyPattern,
    required this.monthlyData,
  });

  factory HabitStats.empty() {
    return const HabitStats(
      totalDays: 0,
      completedDays: 0,
      currentStreak: 0,
      bestStreak: 0,
      completionRate: 0.0,
      weeklyPattern: {},
      monthlyData: [],
    );
  }
}

/// 습관 추적 모델
class HabitTrackerModel {
  final String habitId; // 연결된 투두 아이템 ID
  final String userId;
  final List<HabitRecord> records; // 기록들
  final DateTime createdAt;
  final DateTime updatedAt;

  const HabitTrackerModel({
    required this.habitId,
    required this.userId,
    required this.records,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 새 습관 추적기 생성
  factory HabitTrackerModel.create({
    required String habitId,
    required String userId,
  }) {
    final now = DateTime.now();
    return HabitTrackerModel(
      habitId: habitId,
      userId: userId,
      records: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 기록 추가
  HabitTrackerModel addRecord(HabitRecord record) {
    final updatedRecords = List<HabitRecord>.from(records);
    
    // 같은 날짜의 기록이 있으면 교체, 없으면 추가
    final existingIndex = updatedRecords.indexWhere(
      (r) => _isSameDay(r.date, record.date),
    );
    
    if (existingIndex != -1) {
      updatedRecords[existingIndex] = record;
    } else {
      updatedRecords.add(record);
    }
    
    // 날짜순 정렬
    updatedRecords.sort((a, b) => a.date.compareTo(b.date));
    
    return copyWith(
      records: updatedRecords,
      updatedAt: DateTime.now(),
    );
  }

  /// 특정 날짜의 기록 조회
  HabitRecord? getRecordForDate(DateTime date) {
    try {
      return records.firstWhere((record) => _isSameDay(record.date, date));
    } catch (e) {
      return null;
    }
  }

  /// 오늘 완료했는지 확인
  bool get isCompletedToday {
    final today = DateTime.now();
    final todayRecord = getRecordForDate(today);
    return todayRecord?.completed ?? false;
  }

  /// 습관 통계 계산
  HabitStats calculateStats() {
    if (records.isEmpty) {
      return HabitStats.empty();
    }

    final completedRecords = records.where((r) => r.completed).toList();
    final totalDays = records.length;
    final completedDays = completedRecords.length;
    final completionRate = totalDays > 0 ? (completedDays / totalDays) : 0.0;

    // 현재 연속 달성 계산
    int currentStreak = 0;
    final today = DateTime.now();
    DateTime checkDate = today;
    
    while (true) {
      final record = getRecordForDate(checkDate);
      if (record?.completed == true) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // 최고 연속 달성 계산
    int bestStreak = 0;
    int tempStreak = 0;
    
    for (final record in records) {
      if (record.completed) {
        tempStreak++;
        if (tempStreak > bestStreak) {
          bestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }

    // 요일별 패턴 계산
    final weeklyPattern = <String, int>{};
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    
    for (int i = 0; i < 7; i++) {
      weeklyPattern[weekdays[i]] = 0;
    }
    
    for (final record in completedRecords) {
      final weekday = weekdays[record.date.weekday - 1];
      weeklyPattern[weekday] = (weeklyPattern[weekday] ?? 0) + 1;
    }

    // 월별 데이터 (최근 12개월)
    final monthlyData = <int>[];
    final now = DateTime.now();
    
    for (int i = 11; i >= 0; i--) {
      final targetMonth = DateTime(now.year, now.month - i, 1);
      final monthRecords = completedRecords.where((record) {
        return record.date.year == targetMonth.year && 
               record.date.month == targetMonth.month;
      }).length;
      monthlyData.add(monthRecords);
    }

    return HabitStats(
      totalDays: totalDays,
      completedDays: completedDays,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      completionRate: completionRate,
      weeklyPattern: weeklyPattern,
      monthlyData: monthlyData,
    );
  }

  /// 복사본 생성
  HabitTrackerModel copyWith({
    String? habitId,
    String? userId,
    List<HabitRecord>? records,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HabitTrackerModel(
      habitId: habitId ?? this.habitId,
      userId: userId ?? this.userId,
      records: records ?? this.records,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toMap() {
    return {
      'habitId': habitId,
      'userId': userId,
      'records': records.map((r) => r.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory HabitTrackerModel.fromMap(Map<String, dynamic> map) {
    return HabitTrackerModel(
      habitId: map['habitId'],
      userId: map['userId'],
      records: (map['records'] as List<dynamic>)
          .map((r) => HabitRecord.fromMap(r))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory HabitTrackerModel.fromJson(String source) => 
      HabitTrackerModel.fromMap(jsonDecode(source));

  /// 유틸리티: 같은 날인지 확인
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  @override
  String toString() {
    return 'HabitTrackerModel(habitId: $habitId, records: ${records.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitTrackerModel && other.habitId == habitId;
  }

  @override
  int get hashCode => habitId.hashCode;
} 