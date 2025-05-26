import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/utils.dart';

class UserModel {
  final String id;
  final String nickname;
  final int consecutiveDays;
  final int totalFortunes;
  final int totalMissions;
  final int completedMissions;
  final int score;
  final int rewardPoints;
  final DateTime lastActiveDate;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.nickname,
    required this.consecutiveDays,
    required this.totalFortunes,
    required this.totalMissions,
    required this.completedMissions,
    required this.score,
    required this.rewardPoints,
    required this.lastActiveDate,
    required this.createdAt,
  });

  // 기본 생성자 (새 사용자용)
  factory UserModel.createNew({
    required String id,
    required String nickname,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: id,
      nickname: nickname,
      consecutiveDays: 0,
      totalFortunes: 0,
      totalMissions: 0,
      completedMissions: 0,
      score: 0,
      rewardPoints: 100,
      lastActiveDate: now,
      createdAt: now,
    );
  }

  // Firebase 문서에서 UserModel 생성
  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      nickname: data['nickname'] as String? ?? '익명 사용자',
      consecutiveDays: data['consecutiveDays'] as int? ?? 0,
      totalFortunes: data['totalFortunes'] as int? ?? 0,
      totalMissions: data['totalMissions'] as int? ?? 0,
      completedMissions: data['completedMissions'] as int? ?? 0,
      score: data['score'] as int? ?? 0,
      rewardPoints: data['rewardPoints'] as int? ?? 100,
      lastActiveDate: (data['lastActiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firebase에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'consecutiveDays': consecutiveDays,
      'totalFortunes': totalFortunes,
      'totalMissions': totalMissions,
      'completedMissions': completedMissions,
      'score': score,
      'rewardPoints': rewardPoints,
      'lastActiveDate': Timestamp.fromDate(lastActiveDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // JSON에서 UserModel 생성 (웹용)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nickname: json['nickname'] as String? ?? '익명 사용자',
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      totalFortunes: json['totalFortunes'] as int? ?? 0,
      totalMissions: json['totalMissions'] as int? ?? 0,
      completedMissions: json['completedMissions'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      rewardPoints: json['rewardPoints'] as int? ?? 100,
      lastActiveDate: DateTime.parse(json['lastActiveDate'] as String? ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'consecutiveDays': consecutiveDays,
      'totalFortunes': totalFortunes,
      'totalMissions': totalMissions,
      'completedMissions': completedMissions,
      'score': score,
      'rewardPoints': rewardPoints,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // 사용자 정보 업데이트를 위한 copyWith 메서드
  UserModel copyWith({
    String? id,
    String? nickname,
    int? consecutiveDays,
    int? totalFortunes,
    int? totalMissions,
    int? completedMissions,
    int? score,
    int? rewardPoints,
    DateTime? lastActiveDate,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      totalFortunes: totalFortunes ?? this.totalFortunes,
      totalMissions: totalMissions ?? this.totalMissions,
      completedMissions: completedMissions ?? this.completedMissions,
      score: score ?? this.score,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // 미션 성공률 계산
  double get missionSuccessRate => ScoreUtils.calculateMissionSuccessPercentage(completedMissions, totalMissions);

  // 점수 재계산 (현재 로직과 동일)
  int calculateScore() {
    return ScoreUtils.calculateTotalScore(
      consecutiveDays: consecutiveDays,
      totalFortunes: totalFortunes,
      totalMissions: totalMissions,
      completedMissions: completedMissions,
    );
  }

  // 점수가 업데이트된 새 인스턴스 반환
  UserModel withUpdatedScore() {
    return copyWith(score: calculateScore());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, nickname: $nickname, score: $score, consecutiveDays: $consecutiveDays)';
  }

  // 가입일로부터 지난 일수
  int get daysSinceJoined {
    return DateTime.now().difference(createdAt).inDays;
  }

  // 마지막 활동일로부터 지난 일수
  int get daysSinceLastActive {
    return DateTime.now().difference(lastActiveDate).inDays;
  }

  // 미션 완료율 (백분율)
  double get missionCompletionRate {
    if (totalMissions == 0) return 0.0;
    return (completedMissions / totalMissions) * 100;
  }

  // 포맷된 가입일
  String get formattedJoinDate {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  // 포맷된 마지막 활동일
  String get formattedLastActiveDate {
    return '${lastActiveDate.year}-${lastActiveDate.month.toString().padLeft(2, '0')}-${lastActiveDate.day.toString().padLeft(2, '0')}';
  }

  // 활동 상태 (활성/비활성)
  bool get isActive {
    return daysSinceLastActive <= 7; // 7일 이내 활동시 활성 상태
  }

  // 레벨 계산 (점수 기반)
  int get level {
    if (score < 100) return 1;
    if (score < 300) return 2;
    if (score < 600) return 3;
    if (score < 1000) return 4;
    if (score < 1500) return 5;
    return 6; // 최대 레벨
  }

  // 다음 레벨까지 필요한 점수
  int get pointsToNextLevel {
    final currentLevel = level;
    switch (currentLevel) {
      case 1: return 100 - score;
      case 2: return 300 - score;
      case 3: return 600 - score;
      case 4: return 1000 - score;
      case 5: return 1500 - score;
      default: return 0; // 최고 레벨
    }
  }

  // 보상 포인트 포맷팅
  String get formattedRewardPoints {
    if (rewardPoints >= 1000) {
      return '${(rewardPoints / 1000).toStringAsFixed(1)}K';
    }
    return rewardPoints.toString();
  }
}
