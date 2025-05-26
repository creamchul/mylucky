import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/utils.dart';

class MissionModel {
  final String id;
  final String userId;
  final String mission;
  final DateTime date;
  final DateTime completedAt;
  final bool isCompleted;

  const MissionModel({
    required this.id,
    required this.userId,
    required this.mission,
    required this.date,
    required this.completedAt,
    required this.isCompleted,
  });

  // 새 미션 생성용 생성자
  factory MissionModel.create({
    required String id,
    required String userId,
    required String mission,
  }) {
    final now = DateTime.now();
    final today = DateUtils.startOfDay(now);
    return MissionModel(
      id: id,
      userId: userId,
      mission: mission,
      date: today,
      completedAt: now,
      isCompleted: true,
    );
  }

  // Firebase 문서에서 MissionModel 생성
  factory MissionModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MissionModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      mission: data['mission'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: true, // Firestore에 있으면 완료된 것으로 간주
    );
  }

  // Firebase에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mission': mission,
      'date': Timestamp.fromDate(date),
      'completedAt': FieldValue.serverTimestamp(),
    };
  }

  // JSON에서 MissionModel 생성 (웹용)
  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      mission: json['mission'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      completedAt: DateTime.parse(json['completedAt'] as String? ?? DateTime.now().toIso8601String()),
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'mission': mission,
      'date': date.toIso8601String(),
      'completedAt': completedAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // 오늘 날짜의 미션인지 확인
  bool get isToday => DateUtils.isToday(date);

  // 날짜 포맷팅 (YYYY-MM-DD)
  String get formattedDate => DateUtils.formatDate(date);

  // 완료 시간 포맷팅 (HH:MM)
  String get formattedCompletedTime => DateUtils.formatTime(completedAt);

  // 몇 일 전인지 계산
  int get daysAgo => DateUtils.daysAgo(date);

  // 상대적 날짜 표시 (예: "오늘", "1일 전", "2일 전")
  String get relativeDateString => DateUtils.getRelativeDateString(date);

  // copyWith 메서드
  MissionModel copyWith({
    String? id,
    String? userId,
    String? mission,
    DateTime? date,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return MissionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mission: mission ?? this.mission,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MissionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MissionModel(id: $id, mission: $mission, date: $formattedDate, completed: $isCompleted)';
  }
}
