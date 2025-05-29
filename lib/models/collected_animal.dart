// import 'animal_species.dart'; // 더 이상 필요 없음

// 수집된 동물 (도감용)
class CollectedAnimal {
  final String speciesId;
  final String nickname;
  final DateTime discoveredDate;
  final DateTime? completedDate;
  final int totalClicks;
  final int daysSpent;
  final int completedLevel;  // 도감 등록 시 레벨

  const CollectedAnimal({
    required this.speciesId,
    required this.nickname,
    required this.discoveredDate,
    this.completedDate,
    this.totalClicks = 0,
    this.daysSpent = 0,
    this.completedLevel = 1,
  });

  // 팩토리 생성자 - 완료된 동물
  factory CollectedAnimal.completed({
    required String speciesId,
    required String nickname,
    int totalClicks = 0,
    int completedLevel = 1,
  }) {
    final now = DateTime.now();
    return CollectedAnimal(
      speciesId: speciesId,
      nickname: nickname,
      discoveredDate: now,
      completedDate: now,
      totalClicks: totalClicks,
      daysSpent: 1, // 최소 1일
      completedLevel: completedLevel,
    );
  }

  // 완료 여부
  bool get isCompleted => completedDate != null;

  // 상태 설명
  String get statusDescription {
    if (isCompleted) {
      return 'Lv.$completedLevel에서 키우기 완료! ✨';
    } else {
      return '키우는 중...';
    }
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'speciesId': speciesId,
      'nickname': nickname,
      'discoveredDate': discoveredDate.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'totalClicks': totalClicks,
      'daysSpent': daysSpent,
      'completedLevel': completedLevel,
    };
  }

  // JSON 역직렬화
  factory CollectedAnimal.fromJson(Map<String, dynamic> json) {
    return CollectedAnimal(
      speciesId: json['speciesId'] as String,
      nickname: json['nickname'] as String,
      discoveredDate: DateTime.fromMillisecondsSinceEpoch(json['discoveredDate'] as int),
      completedDate: json['completedDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['completedDate'] as int)
          : null,
      totalClicks: json['totalClicks'] as int? ?? 0,
      daysSpent: json['daysSpent'] as int? ?? 0,
      completedLevel: json['completedLevel'] as int? ?? 1,
    );
  }

  @override
  String toString() {
    return 'CollectedAnimal(speciesId: $speciesId, nickname: $nickname, completed: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectedAnimal && 
           other.speciesId == speciesId && 
           other.nickname == nickname;
  }

  @override
  int get hashCode => Object.hash(speciesId, nickname);
} 