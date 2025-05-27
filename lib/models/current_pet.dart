// import 'animal_species.dart'; // 더 이상 필요 없음

// 동물 기분 (단순화)
enum AnimalMood {
  happy,    // 😊 행복
  excited,  // 🤩 신남
  love      // 💖 사랑 (100% 달성 시)
}

// 현재 키우는 동물 (클릭커 게임용)
class CurrentPet {
  final String id;
  final String speciesId;
  final String nickname;
  final double growth;        // 0-100 성장도 (클릭으로만 증가)
  final AnimalMood mood;
  final DateTime createdAt;
  final DateTime lastInteraction;
  final int totalClicks;      // 총 클릭 수
  final int comboCount;       // 현재 콤보 수
  final Map<String, dynamic> stats; // 추가 스탯 (업그레이드 등)

  const CurrentPet({
    required this.id,
    required this.speciesId,
    required this.nickname,
    required this.growth,
    required this.mood,
    required this.createdAt,
    required this.lastInteraction,
    this.totalClicks = 0,
    this.comboCount = 0,
    this.stats = const {},
  });

  // 팩토리 생성자 - 새로운 펫 생성
  factory CurrentPet.create({
    required String speciesId,
    required String nickname,
  }) {
    final now = DateTime.now();
    return CurrentPet(
      id: 'pet_${now.millisecondsSinceEpoch}',
      speciesId: speciesId,
      nickname: nickname,
      growth: 0.0,
      mood: AnimalMood.happy,
      createdAt: now,
      lastInteraction: now,
      totalClicks: 0,
      comboCount: 0,
      stats: {
        'clickPower': 1.0,      // 클릭당 성장량만 유지
      },
    );
  }

  // 도감 등록 가능 여부 확인 (성장도 100%)
  bool get canComplete => growth >= 100;

  // 클릭 파워 (업그레이드 가능)
  double get clickPower => (stats['clickPower'] as double?) ?? 1.0;

  // 기분 이모지
  String get moodEmoji {
    switch (mood) {
      case AnimalMood.happy:
        return '😊';
      case AnimalMood.excited:
        return '🤩';
      case AnimalMood.love:
        return '💖';
    }
  }

  // 기분 설명
  String get moodDescription {
    switch (mood) {
      case AnimalMood.happy:
        return '행복해요';
      case AnimalMood.excited:
        return '신나해요';
      case AnimalMood.love:
        return '완성이 가까워요!';
    }
  }

  // 상태 업데이트
  CurrentPet copyWith({
    String? id,
    String? speciesId,
    String? nickname,
    double? growth,
    AnimalMood? mood,
    DateTime? createdAt,
    DateTime? lastInteraction,
    int? totalClicks,
    int? comboCount,
    Map<String, dynamic>? stats,
  }) {
    return CurrentPet(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      nickname: nickname ?? this.nickname,
      growth: growth ?? this.growth,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalClicks: totalClicks ?? this.totalClicks,
      comboCount: comboCount ?? this.comboCount,
      stats: stats ?? this.stats,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'nickname': nickname,
      'growth': growth,
      'mood': mood.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastInteraction': lastInteraction.millisecondsSinceEpoch,
      'totalClicks': totalClicks,
      'comboCount': comboCount,
      'stats': stats,
    };
  }

  // JSON 역직렬화
  factory CurrentPet.fromJson(Map<String, dynamic> json) {
    return CurrentPet(
      id: json['id'] as String,
      speciesId: json['speciesId'] as String,
      nickname: json['nickname'] as String,
      growth: (json['growth'] as num).toDouble(),
      mood: AnimalMood.values.firstWhere(
        (e) => e.toString() == json['mood'],
        orElse: () => AnimalMood.happy,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastInteraction: DateTime.fromMillisecondsSinceEpoch(json['lastInteraction'] as int),
      totalClicks: json['totalClicks'] as int? ?? 0,
      comboCount: json['comboCount'] as int? ?? 0,
      stats: Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'CurrentPet(id: $id, nickname: $nickname, growth: $growth%, clicks: $totalClicks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentPet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 