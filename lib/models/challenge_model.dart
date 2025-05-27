import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/mission_data.dart';
import '../utils/utils.dart';

// DateUtils 헬퍼 함수들
class _DateUtils {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}

enum ChallengeStatus {
  notStarted('시작 전'),
  inProgress('진행 중'),
  completed('완료'),
  failed('실패'),
  paused('일시정지');

  const ChallengeStatus(this.displayName);
  final String displayName;
}

class UserChallenge {
  final String id;
  final String userId;
  final String challengeId;
  final Challenge challenge;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final int currentDay;
  final int completedDays;
  final List<DateTime> completedDates;
  final int totalPointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata; // 추가 데이터 저장용

  const UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.challenge,
    required this.status,
    required this.startDate,
    this.endDate,
    required this.currentDay,
    required this.completedDays,
    required this.completedDates,
    required this.totalPointsEarned,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  // 새 챌린지 시작용 생성자
  factory UserChallenge.start({
    required String id,
    required String userId,
    required Challenge challenge,
  }) {
    final now = DateTime.now();
    final today = _DateUtils.startOfDay(now);
    
    return UserChallenge(
      id: id,
      userId: userId,
      challengeId: challenge.id,
      challenge: challenge,
      status: ChallengeStatus.inProgress,
      startDate: today,
      currentDay: 1,
      completedDays: 0,
      completedDates: [],
      totalPointsEarned: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Firebase 문서에서 UserChallenge 생성
  factory UserChallenge.fromFirestore(String id, Map<String, dynamic> data) {
    final challengeId = data['challengeId'] as String? ?? '';
    final challenge = ChallengeData.getChallengeById(challengeId);
    
    if (challenge == null) {
      throw Exception('Challenge not found: $challengeId');
    }

    return UserChallenge(
      id: id,
      userId: data['userId'] as String? ?? '',
      challengeId: challengeId,
      challenge: challenge,
      status: ChallengeStatus.values.firstWhere(
        (status) => status.name == (data['status'] as String? ?? 'notStarted'),
        orElse: () => ChallengeStatus.notStarted,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      currentDay: data['currentDay'] as int? ?? 1,
      completedDays: data['completedDays'] as int? ?? 0,
      completedDates: (data['completedDates'] as List<dynamic>?)
          ?.map((timestamp) => (timestamp as Timestamp).toDate())
          .toList() ?? [],
      totalPointsEarned: data['totalPointsEarned'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  // Firebase에 저장할 Map으로 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'currentDay': currentDay,
      'completedDays': completedDays,
      'completedDates': completedDates.map((date) => Timestamp.fromDate(date)).toList(),
      'totalPointsEarned': totalPointsEarned,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'metadata': metadata,
    };
  }

  // JSON에서 UserChallenge 생성 (웹용)
  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    final challengeId = json['challengeId'] as String? ?? '';
    final challenge = ChallengeData.getChallengeById(challengeId);
    
    if (challenge == null) {
      throw Exception('Challenge not found: $challengeId');
    }

    return UserChallenge(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      challengeId: challengeId,
      challenge: challenge,
      status: ChallengeStatus.values.firstWhere(
        (status) => status.name == (json['status'] as String? ?? 'notStarted'),
        orElse: () => ChallengeStatus.notStarted,
      ),
      startDate: DateTime.parse(json['startDate'] as String? ?? DateTime.now().toIso8601String()),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      currentDay: json['currentDay'] as int? ?? 1,
      completedDays: json['completedDays'] as int? ?? 0,
      completedDates: (json['completedDates'] as List<dynamic>?)
          ?.map((dateStr) => DateTime.parse(dateStr as String))
          .toList() ?? [],
      totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'challengeId': challengeId,
      'status': status.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'currentDay': currentDay,
      'completedDays': completedDays,
      'completedDates': completedDates.map((date) => date.toIso8601String()).toList(),
      'totalPointsEarned': totalPointsEarned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  // 계산된 속성들

  /// 진행률 (0.0 ~ 1.0)
  double get progressPercentage {
    if (challenge.durationDays == 0) return 0.0;
    return (completedDays / challenge.durationDays).clamp(0.0, 1.0);
  }

  /// 진행률 퍼센트 (0 ~ 100)
  int get progressPercent => (progressPercentage * 100).round();

  /// 남은 일수
  int get remainingDays {
    final remaining = challenge.durationDays - currentDay + 1;
    return remaining > 0 ? remaining : 0;
  }

  /// 성공률 (완료한 날 / 현재까지 진행된 날)
  double get successRate {
    if (currentDay <= 1) return 0.0;
    return (completedDays / (currentDay - 1)).clamp(0.0, 1.0);
  }

  /// 성공률 퍼센트
  int get successPercent => (successRate * 100).round();

  /// 오늘 완료했는지 확인
  bool get isTodayCompleted {
    final today = _DateUtils.startOfDay(DateTime.now());
    return completedDates.any((date) => _DateUtils.isSameDay(date, today));
  }

  /// 연속 완료 일수
  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort((a, b) => b.compareTo(a)); // 최신 날짜부터
    
    int streak = 0;
    final today = _DateUtils.startOfDay(DateTime.now());
    DateTime checkDate = today;
    
    for (final completedDate in sortedDates) {
      if (_DateUtils.isSameDay(completedDate, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// 최대 연속 완료 일수
  int get maxStreak {
    if (completedDates.isEmpty) return 0;
    
    final sortedDates = List<DateTime>.from(completedDates)
      ..sort();
    
    int maxStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < sortedDates.length; i++) {
      final prevDate = sortedDates[i - 1];
      final currentDate = sortedDates[i];
      
      if (currentDate.difference(prevDate).inDays == 1) {
        currentStreak++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }
    
    return maxStreak;
  }

  /// 챌린지가 완료되었는지 확인
  bool get isCompleted => status == ChallengeStatus.completed || completedDays >= challenge.durationDays;

  /// 챌린지가 실패했는지 확인 (기간 초과 등)
  bool get isFailed => status == ChallengeStatus.failed;

  /// 챌린지가 진행 중인지 확인
  bool get isActive => status == ChallengeStatus.inProgress;

  /// 예상 완료일
  DateTime get expectedEndDate => startDate.add(Duration(days: challenge.durationDays - 1));

  /// 실제 소요 일수 (완료된 경우)
  int? get actualDuration {
    if (endDate == null) return null;
    return endDate!.difference(startDate).inDays + 1;
  }

  /// 오늘 완료 가능한지 확인
  bool get canCompleteToday {
    if (!isActive) return false;
    if (isTodayCompleted) return false;
    
    final today = _DateUtils.startOfDay(DateTime.now());
    final daysSinceStart = today.difference(startDate).inDays + 1;
    
    return daysSinceStart <= challenge.durationDays;
  }

  /// 날짜별 완료 상태 확인
  bool isCompletedOnDate(DateTime date) {
    final targetDate = _DateUtils.startOfDay(date);
    return completedDates.any((completedDate) => _DateUtils.isSameDay(completedDate, targetDate));
  }

  /// 특정 날짜가 챌린지 기간 내인지 확인
  bool isDateInRange(DateTime date) {
    final targetDate = _DateUtils.startOfDay(date);
    final endDate = expectedEndDate;
    
    return !targetDate.isBefore(startDate) && !targetDate.isAfter(endDate);
  }

  /// 오늘 완료 처리
  UserChallenge completeToday() {
    if (!canCompleteToday) return this;
    
    final today = _DateUtils.startOfDay(DateTime.now());
    final newCompletedDates = List<DateTime>.from(completedDates);
    
    if (!isTodayCompleted) {
      newCompletedDates.add(today);
    }
    
    final newCompletedDays = newCompletedDates.length;
    final newCurrentDay = today.difference(startDate).inDays + 1;
    final newStatus = newCompletedDays >= challenge.durationDays 
        ? ChallengeStatus.completed 
        : ChallengeStatus.inProgress;
    
    final pointsForToday = challenge.pointsReward ~/ challenge.durationDays;
    final newTotalPoints = totalPointsEarned + (isTodayCompleted ? 0 : pointsForToday);
    
    return copyWith(
      status: newStatus,
      currentDay: newCurrentDay,
      completedDays: newCompletedDays,
      completedDates: newCompletedDates,
      totalPointsEarned: newTotalPoints,
      endDate: newStatus == ChallengeStatus.completed ? today : null,
      updatedAt: DateTime.now(),
    );
  }

  /// copyWith 메서드
  UserChallenge copyWith({
    String? id,
    String? userId,
    String? challengeId,
    Challenge? challenge,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? currentDay,
    int? completedDays,
    List<DateTime>? completedDates,
    int? totalPointsEarned,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return UserChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      challenge: challenge ?? this.challenge,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentDay: currentDay ?? this.currentDay,
      completedDays: completedDays ?? this.completedDays,
      completedDates: completedDates ?? this.completedDates,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserChallenge && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserChallenge(id: $id, challengeId: $challengeId, status: $status, progress: $progressPercent%)';
  }
} 