import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/utils.dart';

class AttendanceModel {
  final String id;
  final DateTime date;
  final DateTime timestamp;

  const AttendanceModel({
    required this.id,
    required this.date,
    required this.timestamp,
  });

  // 새 출석 생성용 생성자
  factory AttendanceModel.create({
    required String id,
  }) {
    final now = DateTime.now();
    final today = DateUtils.startOfDay(now);
    return AttendanceModel(
      id: id,
      date: today,
      timestamp: now,
    );
  }

  // Firebase 문서에서 AttendanceModel 생성
  factory AttendanceModel.fromFirestore(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firebase에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // JSON에서 AttendanceModel 생성 (웹용)
  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String? ?? DateTime.now().toIso8601String()),
      timestamp: DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // 오늘 날짜의 출석인지 확인
  bool get isToday => DateUtils.isToday(date);

  // 날짜 포맷팅 (YYYY-MM-DD)
  String get formattedDate => DateUtils.formatDate(date);

  // 시간 포맷팅 (HH:MM)
  String get formattedTime => DateUtils.formatTime(timestamp);

  // 몇 일 전인지 계산
  int get daysAgo => DateUtils.daysAgo(date);

  // 요일 반환 (한국어)
  String get weekdayKorean => DateUtils.getWeekdayKorean(date);

  // 월/일 형식 (MM/DD)
  String get monthDay => DateUtils.formatMonthDay(date);

  // 연속 출석 계산을 위한 날짜 비교
  bool isConsecutive(AttendanceModel other) {
    return DateUtils.isConsecutive(date, other.date);
  }

  // copyWith 메서드
  AttendanceModel copyWith({
    String? id,
    DateTime? date,
    DateTime? timestamp,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AttendanceModel(id: $id, date: $formattedDate, time: $formattedTime)';
  }
}
