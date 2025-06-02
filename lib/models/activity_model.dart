import 'package:cloud_firestore/cloud_firestore.dart';

/// 활동 모델 - 감정일기의 활동 태그용
class ActivityModel {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final bool isDefault; // 기본 제공 활동인지 여부

  const ActivityModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.isDefault = false,
  });

  /// 새 활동 생성
  factory ActivityModel.create({
    required String userId,
    required String name,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    final id = 'activity_${userId}_${now.millisecondsSinceEpoch}';
    
    return ActivityModel(
      id: id,
      userId: userId,
      name: name,
      createdAt: now,
      isDefault: isDefault,
    );
  }

  /// 기본 활동 생성 (앱에서 제공하는 기본 활동들)
  factory ActivityModel.defaultActivity({
    required String userId,
    required String name,
  }) {
    final now = DateTime.now();
    final id = 'default_activity_${name.toLowerCase()}_$userId';
    
    return ActivityModel(
      id: id,
      userId: userId,
      name: name,
      createdAt: now,
      isDefault: true,
    );
  }

  /// Firestore에서 생성
  factory ActivityModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ActivityModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDefault: data['isDefault'] ?? false,
    );
  }

  /// Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDefault': isDefault,
    };
  }

  /// 로컬 DB 저장용 맵 변환
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  /// 로컬 DB에서 생성
  factory ActivityModel.fromLocalMap(Map<String, dynamic> map) {
    return ActivityModel(
      id: map['id'],
      userId: map['userId'],
      name: map['name'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      isDefault: map['isDefault'] == 1,
    );
  }

  /// 복사 생성자
  ActivityModel copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    bool? isDefault,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityModel(id: $id, name: $name)';
  }
}

/// 기본 제공 활동들
class DefaultActivities {
  static const List<String> defaultList = [
    '운동',
    '독서', 
    '영화',
    '게임',
    '휴식',
    '요리',
    '청소',
    '쇼핑',
    '여행',
    '공부',
    '미팅',
    '카페',
    '산책',
    '음악',
    '그림',
    '사진',
    '일',
    '가족',
    '친구',
    '반려동물',
  ];

  /// 사용자용 기본 활동들 생성
  static List<ActivityModel> createForUser(String userId) {
    return defaultList.map((name) => 
      ActivityModel.defaultActivity(
        userId: userId,
        name: name,
      )
    ).toList();
  }
} 