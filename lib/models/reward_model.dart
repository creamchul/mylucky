import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardType { attendance, fortune, mission, bonus }

class RewardModel {
  final String id;
  final String userId;
  final RewardType type;
  final int points;
  final String description;
  final DateTime earnedAt;

  const RewardModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    required this.earnedAt,
  });

  // 팩토리 생성자 - 새 보상 생성
  factory RewardModel.create({
    required String id,
    required String userId,
    required RewardType type,
    required int points,
    String? description,
  }) {
    return RewardModel(
      id: id,
      userId: userId,
      type: type,
      points: points,
      description: description ?? _getDefaultDescription(type, points),
      earnedAt: DateTime.now(),
    );
  }

  // Firestore에서 생성
  factory RewardModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RewardModel(
      id: id,
      userId: data['userId'] ?? '',
      type: RewardType.values.firstWhere(
        (e) => e.toString() == 'RewardType.${data['type']}',
        orElse: () => RewardType.bonus,
      ),
      points: data['points'] ?? 0,
      description: data['description'] ?? '',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'points': points,
      'description': description,
      'earnedAt': Timestamp.fromDate(earnedAt),
    };
  }

  // 유틸리티 메서드들

  // 보상 타입 한글명
  String get typeDisplayName {
    switch (type) {
      case RewardType.attendance:
        return '출석';
      case RewardType.fortune:
        return '운세';
      case RewardType.mission:
        return '미션';
      case RewardType.bonus:
        return '보너스';
    }
  }

  // 보상 타입 아이콘
  String get typeIcon {
    switch (type) {
      case RewardType.attendance:
        return '📅';
      case RewardType.fortune:
        return '🔮';
      case RewardType.mission:
        return '🎯';
      case RewardType.bonus:
        return '🎁';
    }
  }

  // 포맷된 날짜
  String get formattedDate {
    return '${earnedAt.year}-${earnedAt.month.toString().padLeft(2, '0')}-${earnedAt.day.toString().padLeft(2, '0')}';
  }

  // 포맷된 시간
  String get formattedTime {
    return '${earnedAt.hour.toString().padLeft(2, '0')}:${earnedAt.minute.toString().padLeft(2, '0')}';
  }

  // 상대적 시간
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(earnedAt);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return formattedDate;
    }
  }

  // 기본 설명 생성
  static String _getDefaultDescription(RewardType type, int points) {
    switch (type) {
      case RewardType.attendance:
        return '출석으로 $points 포인트 획득';
      case RewardType.fortune:
        return '운세 확인으로 $points 포인트 획득';
      case RewardType.mission:
        return '미션 완료로 $points 포인트 획득';
      case RewardType.bonus:
        return '보너스로 $points 포인트 획득';
    }
  }

  // 기본 포인트 값들
  static const int attendancePoints = 10;
  static const int fortunePoints = 15;
  static const int missionPoints = 20;
  static const int bonusPoints = 50;
}

// 포인트 사용 내역 모델
class PointsUsageModel {
  final String id;
  final String userId;
  final String petId;
  final int pointsUsed;
  final String description;
  final DateTime usedAt;

  const PointsUsageModel({
    required this.id,
    required this.userId,
    required this.petId,
    required this.pointsUsed,
    required this.description,
    required this.usedAt,
  });

  // 팩토리 생성자
  factory PointsUsageModel.create({
    required String id,
    required String userId,
    required String petId,
    required int pointsUsed,
    required String description,
  }) {
    return PointsUsageModel(
      id: id,
      userId: userId,
      petId: petId,
      pointsUsed: pointsUsed,
      description: description,
      usedAt: DateTime.now(),
    );
  }

  // Firestore에서 생성
  factory PointsUsageModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PointsUsageModel(
      id: id,
      userId: data['userId'] ?? '',
      petId: data['petId'] ?? '',
      pointsUsed: data['pointsUsed'] ?? 0,
      description: data['description'] ?? '',
      usedAt: (data['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'petId': petId,
      'pointsUsed': pointsUsed,
      'description': description,
      'usedAt': Timestamp.fromDate(usedAt),
    };
  }

  // 포맷된 날짜
  String get formattedDate {
    return '${usedAt.year}-${usedAt.month.toString().padLeft(2, '0')}-${usedAt.day.toString().padLeft(2, '0')}';
  }
} 