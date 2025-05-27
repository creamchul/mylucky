import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/utils.dart';

class FortuneModel {
  final String id;
  final String message;
  final String mission;
  final DateTime date;
  final DateTime timestamp;

  const FortuneModel({
    required this.id,
    required this.message,
    required this.mission,
    required this.date,
    required this.timestamp,
  });

  // 새 운세 생성용 생성자
  factory FortuneModel.create({
    required String id,
    required String message,
    required String mission,
  }) {
    final now = DateTime.now();
    return FortuneModel(
      id: id,
      message: message,
      mission: mission,
      date: now,
      timestamp: now,
    );
  }

  // Firebase 문서에서 FortuneModel 생성
  factory FortuneModel.fromFirestore(String id, Map<String, dynamic> data) {
    return FortuneModel(
      id: id,
      message: data['message'] as String? ?? '',
      mission: data['mission'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firebase에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'mission': mission,
      'date': Timestamp.fromDate(date),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // JSON에서 FortuneModel 생성 (웹용)
  factory FortuneModel.fromJson(Map<String, dynamic> json) {
    return FortuneModel(
      id: json['id'] as String,
      message: json['message'] as String? ?? '',
      mission: json['mission'] as String? ?? '',
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'mission': mission,
      'date': date.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // 오늘 날짜의 운세인지 확인
  bool get isToday => DateUtils.isToday(date);

  // 날짜 포맷팅 (YYYY-MM-DD)
  String get formattedDate => DateUtils.formatDate(date);

  // 시간 포맷팅 (HH:MM)
  String get formattedTime => DateUtils.formatTime(timestamp);

  // copyWith 메서드
  FortuneModel copyWith({
    String? id,
    String? message,
    String? mission,
    DateTime? date,
    DateTime? timestamp,
  }) {
    return FortuneModel(
      id: id ?? this.id,
      message: message ?? this.message,
      mission: mission ?? this.mission,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FortuneModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FortuneModel(id: $id, message: $message, date: $formattedDate)';
  }
}
