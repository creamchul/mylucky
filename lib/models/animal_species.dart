// 동물 희귀도
enum AnimalRarity {
  common,    // ⭐ 일반 (70%)
  rare,      // ⭐⭐ 희귀 (25%)
  legendary, // ⭐⭐⭐ 전설 (5%)
}

// 동물 종족 정보
class AnimalSpecies {
  final String id;
  final String name;
  final String baseEmoji;        // 기본 이모지 (클릭커 게임에서는 이것만 사용)
  final AnimalRarity rarity;
  final String description;
  final String flavorText;
  final String specialAbility;

  const AnimalSpecies({
    required this.id,
    required this.name,
    required this.baseEmoji,
    required this.rarity,
    required this.description,
    required this.flavorText,
    required this.specialAbility,
  });

  // 희귀도 별표
  String get rarityStars {
    switch (rarity) {
      case AnimalRarity.common:
        return '⭐';
      case AnimalRarity.rare:
        return '⭐⭐';
      case AnimalRarity.legendary:
        return '⭐⭐⭐';
    }
  }

  // 희귀도 확률
  double get probability {
    switch (rarity) {
      case AnimalRarity.common:
        return 0.70; // 70%
      case AnimalRarity.rare:
        return 0.25; // 25%
      case AnimalRarity.legendary:
        return 0.05; // 5%
    }
  }

  // 클릭커 게임에서는 항상 기본 이모지 사용
  String get displayEmoji => baseEmoji;

  @override
  String toString() {
    return 'AnimalSpecies(id: $id, name: $name, rarity: $rarityStars)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimalSpecies && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 