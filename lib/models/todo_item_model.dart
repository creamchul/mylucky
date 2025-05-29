import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 투두 아이템 타입
enum TodoType {
  oneTime,    // 🎯 일회성 할일
  repeat,     // 🔄 반복 할일 (세부 유형은 RepeatType으로 구분)
  habit,      // 💪 습관
}

/// TodoType 확장
extension TodoTypeExtension on TodoType {
  /// 타입 이모지
  String get emoji {
    switch (this) {
      case TodoType.oneTime:
        return '🎯';
      case TodoType.repeat:
        return '🔄';
      case TodoType.habit:
        return '💪';
    }
  }

  /// 타입 이름
  String get displayName {
    switch (this) {
      case TodoType.oneTime:
        return '일회성';
      case TodoType.repeat:
        return '반복';
      case TodoType.habit:
        return '습관';
    }
  }
}

/// 반복 유형
enum RepeatType {
  daily,      // 📅 매일 반복
  weekly,     // 📆 주간 반복 (요일 선택)
  monthly,    // 🗓️ 월간 반복 (일자 선택)
  yearly,     // 📊 연간 반복 (월, 일 선택)
  custom,     // ⚙️ 사용자 정의 (N일마다)
}

/// RepeatType 확장
extension RepeatTypeExtension on RepeatType {
  /// 반복 타입 이모지
  String get emoji {
    switch (this) {
      case RepeatType.daily:
        return '📅';
      case RepeatType.weekly:
        return '📆';
      case RepeatType.monthly:
        return '🗓️';
      case RepeatType.yearly:
        return '📊';
      case RepeatType.custom:
        return '⚙️';
    }
  }

  /// 반복 타입 이름
  String get displayName {
    switch (this) {
      case RepeatType.daily:
        return '매일';
      case RepeatType.weekly:
        return '주간';
      case RepeatType.monthly:
        return '월간';
      case RepeatType.yearly:
        return '연간';
      case RepeatType.custom:
        return '사용자 정의';
    }
  }

  /// 반복 타입 설명
  String get description {
    switch (this) {
      case RepeatType.daily:
        return '매일 반복되는 할일';
      case RepeatType.weekly:
        return '선택한 요일에 반복';
      case RepeatType.monthly:
        return '선택한 날짜에 매월 반복';
      case RepeatType.yearly:
        return '선택한 날짜에 매년 반복';
      case RepeatType.custom:
        return 'N일마다 반복';
    }
  }
}

/// 투두 카테고리
enum TodoCategory {
  personal,     // 🏠 개인
  work,         // 💼 업무/학업
  health,       // 💪 건강/운동
  learning,     // 📚 자기계발
  hobby,        // 🎨 취미/여가
  social,       // 👥 인간관계
}

/// TodoCategory 확장
extension TodoCategoryExtension on TodoCategory {
  /// 카테고리 이모지
  String get emoji {
    switch (this) {
      case TodoCategory.personal:
        return '🏠';
      case TodoCategory.work:
        return '💼';
      case TodoCategory.health:
        return '💪';
      case TodoCategory.learning:
        return '📚';
      case TodoCategory.hobby:
        return '🎨';
      case TodoCategory.social:
        return '👥';
    }
  }

  /// 카테고리 이름
  String get displayName {
    switch (this) {
      case TodoCategory.personal:
        return '개인';
      case TodoCategory.work:
        return '업무/학업';
      case TodoCategory.health:
        return '건강/운동';
      case TodoCategory.learning:
        return '자기계발';
      case TodoCategory.hobby:
        return '취미/여가';
      case TodoCategory.social:
        return '인간관계';
    }
  }
}

/// 우선순위
enum Priority {
  low,      // 낮음
  medium,   // 보통
  high      // 높음
}

/// Priority 확장
extension PriorityExtension on Priority {
  /// 우선순위 이모지
  String get emoji {
    switch (this) {
      case Priority.low:
        return '🟢';
      case Priority.medium:
        return '🟡';
      case Priority.high:
        return '🔴';
    }
  }

  /// 우선순위 이름
  String get displayName {
    switch (this) {
      case Priority.low:
        return '낮음';
      case Priority.medium:
        return '보통';
      case Priority.high:
        return '높음';
    }
  }
}

/// 난이도 (보상 차등을 위함)
enum Difficulty {
  easy,     // 쉬움 (1-2 포인트)
  medium,   // 보통 (3-5 포인트)
  hard      // 어려움 (6-10 포인트)
}

/// Difficulty 확장
extension DifficultyExtension on Difficulty {
  /// 난이도 이모지
  String get emoji {
    switch (this) {
      case Difficulty.easy:
        return '⭐';
      case Difficulty.medium:
        return '⭐⭐';
      case Difficulty.hard:
        return '⭐⭐⭐';
    }
  }

  /// 난이도 이름
  String get displayName {
    switch (this) {
      case Difficulty.easy:
        return '쉬움';
      case Difficulty.medium:
        return '보통';
      case Difficulty.hard:
        return '어려움';
    }
  }

  /// 난이도별 포인트
  int get points {
    switch (this) {
      case Difficulty.easy:
        return 2;
      case Difficulty.medium:
        return 5;
      case Difficulty.hard:
        return 10;
    }
  }
}

/// 반복 패턴
class RepeatPattern {
  final RepeatType repeatType;
  final List<int>? weekdays; // 주간 반복 시 요일 (1=월요일, 7=일요일)
  final List<int>? monthDays; // 월간 반복 시 날짜 (1~31, 99=마지막날)
  final List<int>? yearMonths; // 연간 반복 시 월 (1~12)
  final List<int>? yearDays; // 연간 반복 시 날짜 (1~31)
  final int? customInterval; // 사용자 정의 반복 시 간격 (N일마다)
  
  const RepeatPattern({
    required this.repeatType,
    this.weekdays,
    this.monthDays,
    this.yearMonths,
    this.yearDays,
    this.customInterval,
  });

  Map<String, dynamic> toMap() {
    return {
      'repeatType': repeatType.name,
      'weekdays': weekdays,
      'monthDays': monthDays,
      'yearMonths': yearMonths,
      'yearDays': yearDays,
      'customInterval': customInterval,
    };
  }

  factory RepeatPattern.fromMap(Map<String, dynamic> map) {
    return RepeatPattern(
      repeatType: RepeatType.values.firstWhere((e) => e.name == map['repeatType']),
      weekdays: map['weekdays']?.cast<int>(),
      monthDays: map['monthDays']?.cast<int>(),
      yearMonths: map['yearMonths']?.cast<int>(),
      yearDays: map['yearDays']?.cast<int>(),
      customInterval: map['customInterval'],
    );
  }
}

/// 투두 아이템 모델
class TodoItemModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TodoType type;
  final TodoCategory category;
  final Priority priority;
  final Difficulty difficulty;
  final DateTime? startDate;
  final DateTime? dueDate;
  final Duration? estimatedTime;
  final RepeatPattern? repeatPattern;
  final bool isCompleted;
  final DateTime? completedAt;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 습관 관련 필드
  final int? targetCount; // 목표 횟수 (습관용)
  final int currentCount; // 현재 횟수
  final int streak; // 연속 달성 일수
  final int bestStreak; // 최고 연속 달성 일수
  
  // 알림 설정
  final bool hasReminder;
  final DateTime? reminderTime;
  final int? reminderMinutesBefore;
  
  // 일회성 할일 표시 옵션
  final bool showUntilCompleted; // 완료할 때까지 표시하기 (기본값: true)

  const TodoItemModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.type,
    this.category = TodoCategory.personal,
    this.priority = Priority.medium,
    this.difficulty = Difficulty.medium,
    this.startDate,
    this.dueDate,
    this.estimatedTime,
    this.repeatPattern,
    this.isCompleted = false,
    this.completedAt,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.targetCount,
    this.currentCount = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.hasReminder = false,
    this.reminderTime,
    this.reminderMinutesBefore,
    this.showUntilCompleted = true,
  });

  /// 새 투두 아이템 생성
  factory TodoItemModel.create({
    required String userId,
    required String title,
    String description = '',
    TodoType type = TodoType.oneTime,
    TodoCategory category = TodoCategory.personal,
    Priority priority = Priority.medium,
    Difficulty difficulty = Difficulty.medium,
    DateTime? startDate,
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    List<String> tags = const [],
    int? targetCount,
    bool hasReminder = false,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
    bool showUntilCompleted = true,
  }) {
    final now = DateTime.now();
    
    // 습관 타입의 경우 targetCount가 null이면 1로 설정
    int? finalTargetCount = targetCount;
    if (type == TodoType.habit && targetCount == null) {
      finalTargetCount = 1;
    }
    
    return TodoItemModel(
      id: 'todo_${now.millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      description: description,
      type: type,
      category: category,
      priority: priority,
      difficulty: difficulty,
      startDate: startDate,
      dueDate: dueDate,
      estimatedTime: estimatedTime,
      repeatPattern: repeatPattern,
      tags: tags,
      createdAt: now,
      updatedAt: now,
      targetCount: finalTargetCount,
      hasReminder: hasReminder,
      reminderTime: reminderTime,
      reminderMinutesBefore: reminderMinutesBefore,
      showUntilCompleted: showUntilCompleted,
    );
  }

  /// 복사본 생성 (불변성 유지)
  TodoItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TodoType? type,
    TodoCategory? category,
    Priority? priority,
    Difficulty? difficulty,
    DateTime? startDate,
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    bool? isCompleted,
    DateTime? completedAt,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? targetCount,
    int? currentCount,
    int? streak,
    int? bestStreak,
    bool? hasReminder,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
    bool? showUntilCompleted,
    bool clearStartDate = false,
    bool clearDueDate = false,
    bool clearCompletedAt = false,
    bool clearReminderTime = false,
  }) {
    return TodoItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      difficulty: difficulty ?? this.difficulty,
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      estimatedTime: estimatedTime ?? this.estimatedTime,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      streak: streak ?? this.streak,
      bestStreak: bestStreak ?? this.bestStreak,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: clearReminderTime ? null : (reminderTime ?? this.reminderTime),
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      showUntilCompleted: showUntilCompleted ?? this.showUntilCompleted,
    );
  }

  /// JSON 변환
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'category': category.name,
      'priority': priority.name,
      'difficulty': difficulty.name,
      'startDate': startDate?.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'estimatedTime': estimatedTime?.inMinutes,
      'repeatPattern': repeatPattern?.toMap(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'streak': streak,
      'bestStreak': bestStreak,
      'hasReminder': hasReminder,
      'reminderTime': reminderTime?.millisecondsSinceEpoch,
      'reminderMinutesBefore': reminderMinutesBefore,
      'showUntilCompleted': showUntilCompleted,
    };
  }

  factory TodoItemModel.fromMap(Map<String, dynamic> map) {
    return TodoItemModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'] ?? '',
      type: TodoType.values.firstWhere((e) => e.name == map['type']),
      category: TodoCategory.values.firstWhere((e) => e.name == map['category']),
      priority: Priority.values.firstWhere((e) => e.name == map['priority']),
      difficulty: Difficulty.values.firstWhere((e) => e.name == map['difficulty']),
      startDate: map['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startDate']) : null,
      dueDate: map['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['dueDate']) : null,
      estimatedTime: map['estimatedTime'] != null ? Duration(minutes: map['estimatedTime']) : null,
      repeatPattern: map['repeatPattern'] != null ? RepeatPattern.fromMap(map['repeatPattern']) : null,
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['completedAt']) : null,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      targetCount: map['targetCount'],
      currentCount: map['currentCount'] ?? 0,
      streak: map['streak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
      hasReminder: map['hasReminder'] ?? false,
      reminderTime: map['reminderTime'] != null ? DateTime.fromMillisecondsSinceEpoch(map['reminderTime']) : null,
      reminderMinutesBefore: map['reminderMinutesBefore'],
      showUntilCompleted: map['showUntilCompleted'] ?? true,
    );
  }

  /// JSON 문자열 변환
  String toJson() => jsonEncode(toMap());
  factory TodoItemModel.fromJson(String source) => TodoItemModel.fromMap(jsonDecode(source));

  /// Firebase 호환 변환
  Map<String, dynamic> toFirestore() => toMap();
  factory TodoItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return TodoItemModel.fromMap({...data, 'id': id});
  }

  /// 유틸리티 메서드들
  
  /// 카테고리 이모지
  String get categoryEmoji {
    return category.emoji;
  }

  /// 카테고리 이름
  String get categoryName {
    return category.displayName;
  }

  /// 우선순위 이모지
  String get priorityEmoji {
    switch (priority) {
      case Priority.low:
        return '🟢';
      case Priority.medium:
        return '🟡';
      case Priority.high:
        return '🔴';
    }
  }

  /// 난이도 포인트
  int get difficultyPoints {
    switch (difficulty) {
      case Difficulty.easy:
        return 2;
      case Difficulty.medium:
        return 5;
      case Difficulty.hard:
        return 10;
    }
  }

  /// 오늘 할일인지 확인
  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    final due = dueDate!;
    return due.year == today.year && due.month == today.month && due.day == today.day;
  }

  /// 기한 지났는지 확인
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// 시작일이 오늘인지 확인
  bool get isStartToday {
    if (startDate == null) return true; // 시작일이 없으면 항상 시작 가능
    final today = DateTime.now();
    final start = startDate!;
    return start.year == today.year && start.month == today.month && start.day == today.day;
  }

  /// 시작일이 지났는지 확인 (시작 가능한지)
  bool get isStarted {
    if (startDate == null) return true; // 시작일이 없으면 항상 시작됨
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startOnlyDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
    
    return startOnlyDate.isBefore(todayDate) || startOnlyDate.isAtSameMomentAs(todayDate);
  }

  /// 시작 전인지 확인 (아직 시작하지 않음)
  bool get isBeforeStart {
    if (startDate == null) return false; // 시작일이 없으면 항상 시작됨
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final startOnlyDate = DateTime(startDate!.year, startDate!.month, startDate!.day);
    
    return startOnlyDate.isAfter(todayDate);
  }

  /// 습관인지 확인
  bool get isHabit {
    return type == TodoType.habit;
  }

  /// 반복 할일인지 확인
  bool get isRepeating {
    return type == TodoType.repeat || isHabit;
  }

  /// 습관의 목표 횟수 (기본값 1)
  int get effectiveTargetCount {
    if (!isHabit) return 1;
    return targetCount ?? 1;
  }

  /// 습관의 진행률 (0.0 ~ 1.0)
  double get habitProgress {
    if (!isHabit) return 0.0;
    final target = effectiveTargetCount;
    if (target <= 0) return 0.0;
    return (currentCount / target).clamp(0.0, 1.0);
  }

  /// 습관이 목표 달성했는지 확인
  bool get isHabitCompleted {
    if (!isHabit) return false;
    return currentCount >= effectiveTargetCount;
  }

  /// 습관 진행 상태 텍스트
  String get habitProgressText {
    if (!isHabit) return '';
    return '$currentCount / $effectiveTargetCount';
  }

  /// 미래 날짜 할일인지 확인 (오늘보다 나중에 처리해야 하는 할일)
  bool get isFutureTodo {
    if (dueDate == null) return false;
    
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueOnlyDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    return dueOnlyDate.isAfter(todayDate);
  }

  /// 오늘 또는 과거 날짜 할일인지 확인 (체크 가능한 할일)
  bool get isCheckableToday {
    // 이미 완료된 할일은 항상 체크 가능 (완료 취소를 위해)
    if (isCompleted) return true;
    
    // 마감일이 없는 할일은 항상 체크 가능
    if (dueDate == null) return true;
    
    // 미래 날짜 할일은 체크 불가
    return !isFutureTodo;
  }

  @override
  String toString() {
    return 'TodoItemModel(id: $id, title: $title, type: $type, category: $category, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TodoItemModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 