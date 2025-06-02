import 'package:cloud_firestore/cloud_firestore.dart';

/// 감정 유형 - 일상 중심
enum MoodType {
  amazing,  // ✨ 최고
  good,     // 😊 좋음
  normal,   // 😐 그저그래
  bad,      // 😕 별로
  terrible, // 😓 최악
}

/// MoodType 확장
extension MoodTypeExtension on MoodType {
  /// 감정 이모지
  String get emoji {
    switch (this) {
      case MoodType.amazing:
        return '✨';
      case MoodType.good:
        return '😊';
      case MoodType.normal:
        return '😐';
      case MoodType.bad:
        return '😕';
      case MoodType.terrible:
        return '😓';
    }
  }

  /// 감정 이름
  String get displayName {
    switch (this) {
      case MoodType.amazing:
        return '최고';
      case MoodType.good:
        return '좋음';
      case MoodType.normal:
        return '그저그래';
      case MoodType.bad:
        return '별로';
      case MoodType.terrible:
        return '최악';
    }
  }

  /// 감정 설명
  String get description {
    switch (this) {
      case MoodType.amazing:
        return '정말 좋은 하루';
      case MoodType.good:
        return '괜찮은 하루';
      case MoodType.normal:
        return '평범한 하루';
      case MoodType.bad:
        return '아쉬운 하루';
      case MoodType.terrible:
        return '힘든 하루';
    }
  }

  /// 감정별 테마 컬러 (16진수)
  String get colorHex {
    switch (this) {
      case MoodType.amazing:
        return '#FFE5B4'; // 밝은 골드
      case MoodType.good:
        return '#B8F5B8'; // 밝은 초록색
      case MoodType.normal:
        return '#F0F0F0'; // 연한 회색
      case MoodType.bad:
        return '#FFD4B8'; // 연한 주황색
      case MoodType.terrible:
        return '#E8D5FF'; // 연한 보라색
    }
  }
}

/// 감정일기 모델 - 새로운 버전
class MoodEntryModel {
  final String id;
  final String userId;
  final MoodType mood;
  final String content; // 일기 내용
  final List<String> activities; // 활동 태그 (이전 tags)
  final List<String> imageUrls; // 첨부 이미지 URL 목록
  final bool isFavorite; // 즐겨찾기 여부
  final DateTime createdAt; // 작성 시간 (정확한 시간)
  final DateTime updatedAt;

  const MoodEntryModel({
    required this.id,
    required this.userId,
    required this.mood,
    required this.content,
    this.activities = const [],
    this.imageUrls = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 새 감정일기 생성 - 하루 여러 번 작성 가능, 사용자 지정 날짜 지원
  factory MoodEntryModel.create({
    required String userId,
    required MoodType mood,
    required String content,
    List<String> activities = const [],
    List<String> imageUrls = const [],
    bool isFavorite = false,
    DateTime? customDate, // 사용자가 선택한 날짜
  }) {
    final now = DateTime.now();
    final targetDate = customDate ?? now;
    
    // 사용자 지정 날짜가 있으면 해당 날짜로, 없으면 현재 시간으로
    final createdAt = customDate != null 
        ? DateTime(targetDate.year, targetDate.month, targetDate.day, now.hour, now.minute, now.second, now.millisecond)
        : now;
    
    // 밀리초 단위로 고유 ID 생성하여 하루 여러 번 작성 가능
    final id = 'mood_${userId}_${createdAt.millisecondsSinceEpoch}';
    
    return MoodEntryModel(
      id: id,
      userId: userId,
      mood: mood,
      content: content,
      activities: activities,
      imageUrls: imageUrls,
      isFavorite: isFavorite,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Firestore에서 생성
  factory MoodEntryModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MoodEntryModel(
      id: id,
      userId: data['userId'] ?? '',
      mood: MoodType.values.firstWhere(
        (e) => e.name == data['mood'],
        orElse: () => MoodType.normal,
      ),
      content: data['content'] ?? '',
      activities: List<String>.from(data['activities'] ?? data['tags'] ?? []), // 하위 호환성
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mood': mood.name,
      'content': content,
      'activities': activities,
      'imageUrls': imageUrls,
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// 로컬 DB 저장용 맵 변환
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'userId': userId,
      'mood': mood.name,
      'content': content,
      'activities': activities.join(','), // CSV 형태로 저장
      'imageUrls': imageUrls.join(','), // CSV 형태로 저장
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 로컬 DB에서 생성
  factory MoodEntryModel.fromLocalMap(Map<String, dynamic> map) {
    return MoodEntryModel(
      id: map['id'],
      userId: map['userId'],
      mood: MoodType.values.firstWhere(
        (e) => e.name == map['mood'],
        orElse: () => MoodType.normal,
      ),
      content: map['content'],
      activities: map['activities']?.isNotEmpty == true 
          ? map['activities'].split(',').cast<String>()
          : <String>[],
      imageUrls: map['imageUrls']?.isNotEmpty == true 
          ? map['imageUrls'].split(',').cast<String>()
          : <String>[],
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  /// 복사 생성자
  MoodEntryModel copyWith({
    String? id,
    String? userId,
    MoodType? mood,
    String? content,
    List<String>? activities,
    List<String>? imageUrls,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mood: mood ?? this.mood,
      content: content ?? this.content,
      activities: activities ?? this.activities,
      imageUrls: imageUrls ?? this.imageUrls,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// 날짜 포맷 (yyyy년 MM월 dd일)
  String get formattedDate {
    return '${createdAt.year}년 ${createdAt.month.toString().padLeft(2, '0')}월 ${createdAt.day.toString().padLeft(2, '0')}일';
  }

  /// 간단한 날짜 포맷 (MM/dd)
  String get shortDate {
    return '${createdAt.month.toString().padLeft(2, '0')}/${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// 시간 포맷 (HH:mm)
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// 요일 포맷 (월, 화, 수...)
  String get dayOfWeek {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    return weekdays[createdAt.weekday % 7];
  }

  /// 날짜만 추출 (yyyy-MM-dd 형태의 DateTime)
  DateTime get dateOnly {
    return DateTime(createdAt.year, createdAt.month, createdAt.day);
  }

  /// 월 표시용 (yyyy년 M월)
  String get monthYear {
    return '${createdAt.year}년 ${createdAt.month}월';
  }
}
