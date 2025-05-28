import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 투두 아이템 타입
enum TodoType {
  oneTime,    // 🎯 일회성 할일
  daily,      // 📅 매일 반복
  weekly,     // 📆 주간 반복  
  habit,      // 💪 습관
}

/// TodoType 확장
extension TodoTypeExtension on TodoType {
  /// 타입 이모지
  String get emoji {
    switch (this) {
      case TodoType.oneTime:
        return '🎯';
      case TodoType.daily:
        return '📅';
      case TodoType.weekly:
        return '📆';
      case TodoType.habit:
        return '💪';
    }
  }

  /// 타입 이름
  String get displayName {
    switch (this) {
      case TodoType.oneTime:
        return '일회성';
      case TodoType.daily:
        return '매일 반복';
      case TodoType.weekly:
        return '주간 반복';
      case TodoType.habit:
        return '습관';
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
  final TodoType type;
  final List<int>? weekdays; // 주간 반복 시 요일 (1=월요일, 7=일요일)
  final int? interval; // 간격 (예: 2일마다, 3주마다)
  
  const RepeatPattern({
    required this.type,
    this.weekdays,
    this.interval,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'weekdays': weekdays,
      'interval': interval,
    };
  }

  factory RepeatPattern.fromMap(Map<String, dynamic> map) {
    return RepeatPattern(
      type: TodoType.values.firstWhere((e) => e.name == map['type']),
      weekdays: map['weekdays']?.cast<int>(),
      interval: map['interval'],
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

  const TodoItemModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.type,
    this.category = TodoCategory.personal,
    this.priority = Priority.medium,
    this.difficulty = Difficulty.medium,
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
    DateTime? dueDate,
    Duration? estimatedTime,
    RepeatPattern? repeatPattern,
    List<String> tags = const [],
    int? targetCount,
    bool hasReminder = false,
    DateTime? reminderTime,
    int? reminderMinutesBefore,
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

  /// 습관인지 확인
  bool get isHabit {
    return type == TodoType.habit;
  }

  /// 반복 할일인지 확인
  bool get isRepeating {
    return type == TodoType.daily || type == TodoType.weekly || isHabit;
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