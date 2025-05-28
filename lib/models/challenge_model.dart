import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'todo_item_model.dart';

/// 챌린지 타입
enum ChallengeType {
  daily,      // 일일 챌린지
  weekly,     // 주간 챌린지
  monthly,    // 월간 챌린지
  custom,     // 커스텀 챌린지
}

/// 챌린지 상태
enum ChallengeStatus {
  notStarted, // 시작 전
  active,     // 진행 중
  completed,  // 완료
  failed,     // 실패
  paused,     // 일시정지
}

/// 챌린지 난이도
enum ChallengeDifficulty {
  beginner,   // 초급 (1-7일)
  intermediate, // 중급 (8-21일)
  advanced,   // 고급 (22-66일)
  expert,     // 전문가 (67일 이상)
}

/// 챌린지 보상 정보
class ChallengeReward {
  final int points;
  final int experience;
  final String? badgeId;
  final String? title;
  final Map<String, dynamic>? specialReward;

  const ChallengeReward({
    required this.points,
    required this.experience,
    this.badgeId,
    this.title,
    this.specialReward,
  });

  Map<String, dynamic> toMap() {
    return {
      'points': points,
      'experience': experience,
      'badgeId': badgeId,
      'title': title,
      'specialReward': specialReward,
    };
  }

  factory ChallengeReward.fromMap(Map<String, dynamic> map) {
    return ChallengeReward(
      points: map['points'] ?? 0,
      experience: map['experience'] ?? 0,
      badgeId: map['badgeId'],
      title: map['title'],
      specialReward: map['specialReward'],
    );
  }
}

/// 챌린지 진행 상황
class ChallengeProgress {
  final int currentDay;
  final int totalDays;
  final int completedTasks;
  final int totalTasks;
  final double completionRate;
  final List<DateTime> completedDates;
  final int currentStreak;
  final int bestStreak;

  const ChallengeProgress({
    required this.currentDay,
    required this.totalDays,
    required this.completedTasks,
    required this.totalTasks,
    required this.completionRate,
    required this.completedDates,
    required this.currentStreak,
    required this.bestStreak,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentDay': currentDay,
      'totalDays': totalDays,
      'completedTasks': completedTasks,
      'totalTasks': totalTasks,
      'completionRate': completionRate,
      'completedDates': completedDates.map((d) => d.millisecondsSinceEpoch).toList(),
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
    };
  }

  factory ChallengeProgress.fromMap(Map<String, dynamic> map) {
    return ChallengeProgress(
      currentDay: map['currentDay'] ?? 0,
      totalDays: map['totalDays'] ?? 0,
      completedTasks: map['completedTasks'] ?? 0,
      totalTasks: map['totalTasks'] ?? 0,
      completionRate: map['completionRate']?.toDouble() ?? 0.0,
      completedDates: (map['completedDates'] as List<dynamic>?)
          ?.map((timestamp) => DateTime.fromMillisecondsSinceEpoch(timestamp))
          .toList() ?? [],
      currentStreak: map['currentStreak'] ?? 0,
      bestStreak: map['bestStreak'] ?? 0,
    );
  }

  factory ChallengeProgress.empty() {
    return const ChallengeProgress(
      currentDay: 0,
      totalDays: 0,
      completedTasks: 0,
      totalTasks: 0,
      completionRate: 0.0,
      completedDates: [],
      currentStreak: 0,
      bestStreak: 0,
    );
  }
}

/// 챌린지 모델
class ChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> todoIds; // 연결된 투두 아이템들
  final ChallengeReward reward;
  final ChallengeProgress progress;
  final Map<String, dynamic> settings; // 챌린지별 설정
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.todoIds,
    required this.reward,
    required this.progress,
    required this.settings,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 새 챌린지 생성
  factory ChallengeModel.create({
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
  }) {
    final now = DateTime.now();
    final id = 'challenge_${now.millisecondsSinceEpoch}_${userId.hashCode}';
    
    // 난이도에 따른 기본 보상 계산
    final basePoints = _calculateBasePoints(difficulty, endDate.difference(startDate).inDays);
    final baseExperience = _calculateBaseExperience(difficulty, todoIds.length);
    
    return ChallengeModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      type: type,
      difficulty: difficulty,
      status: ChallengeStatus.notStarted,
      startDate: startDate,
      endDate: endDate,
      todoIds: todoIds,
      reward: ChallengeReward(
        points: basePoints,
        experience: baseExperience,
        badgeId: _getBadgeId(difficulty),
        title: _getCompletionTitle(difficulty),
      ),
      progress: ChallengeProgress.empty(),
      settings: settings,
      tags: tags,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 챌린지 시작
  ChallengeModel start() {
    if (status != ChallengeStatus.notStarted) {
      throw Exception('이미 시작된 챌린지입니다.');
    }
    
    return copyWith(
      status: ChallengeStatus.active,
      updatedAt: DateTime.now(),
    );
  }

  /// 챌린지 완료
  ChallengeModel complete() {
    return copyWith(
      status: ChallengeStatus.completed,
      updatedAt: DateTime.now(),
    );
  }

  /// 챌린지 실패
  ChallengeModel fail() {
    return copyWith(
      status: ChallengeStatus.failed,
      updatedAt: DateTime.now(),
    );
  }

  /// 진행 상황 업데이트
  ChallengeModel updateProgress(ChallengeProgress newProgress) {
    return copyWith(
      progress: newProgress,
      updatedAt: DateTime.now(),
    );
  }

  /// 복사본 생성
  ChallengeModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? todoIds,
    ChallengeReward? reward,
    ChallengeProgress? progress,
    Map<String, dynamic>? settings,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      todoIds: todoIds ?? this.todoIds,
      reward: reward ?? this.reward,
      progress: progress ?? this.progress,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 챌린지가 활성 상태인지 확인
  bool get isActive => status == ChallengeStatus.active;

  /// 챌린지가 완료되었는지 확인
  bool get isCompleted => status == ChallengeStatus.completed;

  /// 챌린지가 실패했는지 확인
  bool get isFailed => status == ChallengeStatus.failed;

  /// 챌린지가 진행 중인지 확인
  bool get isInProgress => status == ChallengeStatus.active || status == ChallengeStatus.paused;

  /// 남은 일수 계산
  int get remainingDays {
    if (!isActive) return 0;
    final now = DateTime.now();
    final remaining = endDate.difference(now).inDays;
    return remaining > 0 ? remaining : 0;
  }

  /// 전체 기간 계산
  int get totalDuration => endDate.difference(startDate).inDays + 1;

  /// 진행률 계산 (0.0 ~ 1.0)
  double get progressPercentage {
    if (totalDuration <= 0) return 0.0;
    return (progress.currentDay / totalDuration).clamp(0.0, 1.0);
  }

  /// 성공 가능성 계산
  double get successProbability {
    if (progress.totalTasks == 0) return 0.0;
    return progress.completionRate;
  }

  /// 챌린지 타입 이모지
  String get typeEmoji {
    switch (type) {
      case ChallengeType.daily:
        return '📅';
      case ChallengeType.weekly:
        return '📆';
      case ChallengeType.monthly:
        return '🗓️';
      case ChallengeType.custom:
        return '⚡';
    }
  }

  /// 난이도 이모지
  String get difficultyEmoji {
    switch (difficulty) {
      case ChallengeDifficulty.beginner:
        return '🌱';
      case ChallengeDifficulty.intermediate:
        return '🌿';
      case ChallengeDifficulty.advanced:
        return '🌳';
      case ChallengeDifficulty.expert:
        return '🏆';
    }
  }

  /// 상태 이모지
  String get statusEmoji {
    switch (status) {
      case ChallengeStatus.notStarted:
        return '⏳';
      case ChallengeStatus.active:
        return '🔥';
      case ChallengeStatus.completed:
        return '✅';
      case ChallengeStatus.failed:
        return '❌';
      case ChallengeStatus.paused:
        return '⏸️';
    }
  }

  // ========================================
  // JSON 변환
  // ========================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'status': status.name,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'todoIds': todoIds,
      'reward': reward.toMap(),
      'progress': progress.toMap(),
      'settings': settings,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      type: ChallengeType.values.firstWhere((e) => e.name == map['type']),
      difficulty: ChallengeDifficulty.values.firstWhere((e) => e.name == map['difficulty']),
      status: ChallengeStatus.values.firstWhere((e) => e.name == map['status']),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      todoIds: List<String>.from(map['todoIds']),
      reward: ChallengeReward.fromMap(map['reward']),
      progress: ChallengeProgress.fromMap(map['progress']),
      settings: Map<String, dynamic>.from(map['settings']),
      tags: List<String>.from(map['tags']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ChallengeModel.fromJson(String source) => 
      ChallengeModel.fromMap(jsonDecode(source));

  // ========================================
  // 정적 메서드
  // ========================================

  /// 난이도별 기본 포인트 계산
  static int _calculateBasePoints(ChallengeDifficulty difficulty, int days) {
    final baseMultiplier = switch (difficulty) {
      ChallengeDifficulty.beginner => 10,
      ChallengeDifficulty.intermediate => 20,
      ChallengeDifficulty.advanced => 35,
      ChallengeDifficulty.expert => 50,
    };
    
    return baseMultiplier * days;
  }

  /// 난이도별 기본 경험치 계산
  static int _calculateBaseExperience(ChallengeDifficulty difficulty, int todoCount) {
    final baseMultiplier = switch (difficulty) {
      ChallengeDifficulty.beginner => 5,
      ChallengeDifficulty.intermediate => 10,
      ChallengeDifficulty.advanced => 20,
      ChallengeDifficulty.expert => 30,
    };
    
    return baseMultiplier * todoCount;
  }

  /// 난이도별 배지 ID
  static String? _getBadgeId(ChallengeDifficulty difficulty) {
    return switch (difficulty) {
      ChallengeDifficulty.beginner => 'badge_beginner_challenger',
      ChallengeDifficulty.intermediate => 'badge_intermediate_challenger',
      ChallengeDifficulty.advanced => 'badge_advanced_challenger',
      ChallengeDifficulty.expert => 'badge_expert_challenger',
    };
  }

  /// 난이도별 완료 타이틀
  static String? _getCompletionTitle(ChallengeDifficulty difficulty) {
    return switch (difficulty) {
      ChallengeDifficulty.beginner => '새싹 도전자',
      ChallengeDifficulty.intermediate => '성장하는 도전자',
      ChallengeDifficulty.advanced => '숙련된 도전자',
      ChallengeDifficulty.expert => '전설의 도전자',
    };
  }

  @override
  String toString() {
    return 'ChallengeModel(id: $id, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 