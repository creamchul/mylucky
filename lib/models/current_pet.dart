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
  final double growth;        // 호환성을 위해 유지 (experience와 동일)
  final int level;            // 현재 레벨 (1부터 시작)
  final double experience;    // 현재 경험치
  final AnimalMood mood;
  final DateTime createdAt;
  final DateTime lastInteraction;
  final int totalClicks;      // 총 클릭 수
  final int comboCount;       // 현재 콤보 수
  final Map<String, dynamic> stats; // 추가 스탯 (업그레이드 등)
  final List<String> titles;  // 획득한 타이틀들

  const CurrentPet({
    required this.id,
    required this.speciesId,
    required this.nickname,
    required this.growth,
    this.level = 1,
    this.experience = 0.0,
    required this.mood,
    required this.createdAt,
    required this.lastInteraction,
    this.totalClicks = 0,
    this.comboCount = 0,
    this.stats = const {},
    this.titles = const [],
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
      level: 1,
      experience: 0.0,
      mood: AnimalMood.happy,
      createdAt: now,
      lastInteraction: now,
      totalClicks: 0,
      comboCount: 0,
      stats: {
        'clickPower': 1.0,      // 클릭당 경험치 증가량
      },
      titles: ['🐣 새싹 키우미'], // 시작 타이틀
    );
  }

  // 다음 레벨 요구 경험치 계산
  double get requiredExp {
    if (level >= 99) return 99 * 100.0 + (99 - 1) * 50.0; // 레벨 99 요구 경험치 고정
    return (level + 1) * 100.0 + level * 50.0; // 다음 레벨 요구 경험치
  }

  // 경험치 진행률 (0.0 ~ 1.0)
  double get expProgress {
    if (level >= 99) return 1.0; // 최대 레벨에서는 100%
    final required = requiredExp;
    if (required <= 0) return 1.0; // 안전장치
    return (experience / required).clamp(0.0, 1.0);
  }

  // 도감 등록 가능 여부 확인 (레벨 2 이상)
  bool get canComplete => level >= 2;

  // 클릭 파워 (업그레이드 가능)
  double get clickPower => (stats['clickPower'] as double?) ?? 1.0;

  // 현재 타이틀 (가장 최근 획득)
  String get currentTitle => titles.isNotEmpty ? titles.last : '🐣 새싹 키우미';

  // 레벨별 기본 타이틀 가져오기
  String getLevelTitle(int targetLevel) {
    if (targetLevel >= 90) return '♾️ 영원한 수호자';
    if (targetLevel >= 80) return '🌟 클릭의 신';
    if (targetLevel >= 70) return '🚀 우주 클리커';
    if (targetLevel >= 60) return '🌈 무지개 터치';
    if (targetLevel >= 50) return '⚡ 번개손';
    if (targetLevel >= 40) return '🔥 클릭 황제';
    if (targetLevel >= 30) return '💎 동물원장';
    if (targetLevel >= 20) return '🎯 클릭 전설';
    if (targetLevel >= 15) return '👑 펫 마에스트로';
    if (targetLevel >= 10) return '🏆 케어마스터';
    if (targetLevel >= 5) return '🌟 돌봄이';
    if (targetLevel >= 2) return '🐾 동물 친구';
    return '🐣 새싹 키우미';
  }

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
    int? level,
    double? experience,
    AnimalMood? mood,
    DateTime? createdAt,
    DateTime? lastInteraction,
    int? totalClicks,
    int? comboCount,
    Map<String, dynamic>? stats,
    List<String>? titles,
  }) {
    return CurrentPet(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      nickname: nickname ?? this.nickname,
      growth: growth ?? this.growth,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      totalClicks: totalClicks ?? this.totalClicks,
      comboCount: comboCount ?? this.comboCount,
      stats: stats ?? this.stats,
      titles: titles ?? this.titles,
    );
  }

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'nickname': nickname,
      'growth': growth,
      'level': level,
      'experience': experience,
      'mood': mood.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastInteraction': lastInteraction.millisecondsSinceEpoch,
      'totalClicks': totalClicks,
      'comboCount': comboCount,
      'stats': stats,
      'titles': titles,
    };
  }

  // JSON 역직렬화
  factory CurrentPet.fromJson(Map<String, dynamic> json) {
    return CurrentPet(
      id: json['id'] as String,
      speciesId: json['speciesId'] as String,
      nickname: json['nickname'] as String,
      growth: (json['growth'] as num).toDouble(),
      level: json['level'] as int? ?? 1,
      experience: (json['experience'] as num?)?.toDouble() ?? 0.0,
      mood: AnimalMood.values.firstWhere(
        (e) => e.toString() == json['mood'],
        orElse: () => AnimalMood.happy,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      lastInteraction: DateTime.fromMillisecondsSinceEpoch(json['lastInteraction'] as int),
      totalClicks: json['totalClicks'] as int? ?? 0,
      comboCount: json['comboCount'] as int? ?? 0,
      stats: Map<String, dynamic>.from(json['stats'] as Map? ?? {}),
      titles: List<String>.from(json['titles'] as List? ?? []),
    );
  }

  @override
  String toString() {
    return 'CurrentPet(id: $id, nickname: $nickname, level: $level, exp: ${experience.toInt()}/${requiredExp.toInt()}, clicks: $totalClicks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CurrentPet && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 