import '../models/animal_species.dart';
import 'dart:math';

// 모든 동물 종족 데이터 (클릭커 게임용 단순화)
class AnimalData {
  static const List<AnimalSpecies> allSpecies = [
    // 일반 등급 (⭐) - 70%
    AnimalSpecies(
      id: 'cat',
      name: '고양이',
      baseEmoji: '🐱',
      rarity: AnimalRarity.common,
      description: '귀여운 고양이입니다. 클릭하면 기분 좋게 울어요.',
      flavorText: '냥~ 관심 없는 척하지만 사실 주인을 좋아해요',
      specialAbility: '클릭 시 가끔 특별한 소리를 내요',
    ),
    
    AnimalSpecies(
      id: 'dog',
      name: '강아지',
      baseEmoji: '🐶',
      rarity: AnimalRarity.common,
      description: '충성스러운 강아지입니다. 클릭하면 꼬리를 흔들어요.',
      flavorText: '멍멍! 주인만 보면 신나서 어쩔 줄 몰라요',
      specialAbility: '클릭 시 행복도가 더 많이 올라요',
    ),
    
    AnimalSpecies(
      id: 'rabbit',
      name: '토끼',
      baseEmoji: '🐰',
      rarity: AnimalRarity.common,
      description: '깡총깡총 뛰어다니는 토끼입니다.',
      flavorText: '당근을 좋아하고 점프를 잘해요',
      specialAbility: '클릭 시 가끔 점프해요',
    ),
    
    AnimalSpecies(
      id: 'hamster',
      name: '햄스터',
      baseEmoji: '🐹',
      rarity: AnimalRarity.common,
      description: '작고 귀여운 햄스터입니다.',
      flavorText: '볼에 음식을 가득 넣고 다녀요',
      specialAbility: '클릭 속도가 빨라요',
    ),
    
    AnimalSpecies(
      id: 'bird',
      name: '새',
      baseEmoji: '🐦',
      rarity: AnimalRarity.common,
      description: '예쁜 소리로 노래하는 새입니다.',
      flavorText: '아침마다 아름다운 노래를 불러줘요',
      specialAbility: '클릭 시 노래를 불러요',
    ),
    
    AnimalSpecies(
      id: 'fish',
      name: '물고기',
      baseEmoji: '🐠',
      rarity: AnimalRarity.common,
      description: '형형색색 아름다운 물고기입니다.',
      flavorText: '물속에서 우아하게 헤엄쳐요',
      specialAbility: '클릭 시 물방울 효과',
    ),
    
    AnimalSpecies(
      id: 'turtle',
      name: '거북이',
      baseEmoji: '🐢',
      rarity: AnimalRarity.common,
      description: '느리지만 꾸준한 거북이입니다.',
      flavorText: '천천히 하지만 끝까지 해내요',
      specialAbility: '시간이 지날수록 더 빨라져요',
    ),
    
    AnimalSpecies(
      id: 'frog',
      name: '개구리',
      baseEmoji: '🐸',
      rarity: AnimalRarity.common,
      description: '연못에서 개굴개굴 우는 개구리입니다.',
      flavorText: '비 오는 날을 제일 좋아해요',
      specialAbility: '클릭 시 개굴개굴 소리',
    ),
    
    // 희귀 등급 (⭐⭐) - 25%
    AnimalSpecies(
      id: 'fox',
      name: '여우',
      baseEmoji: '🦊',
      rarity: AnimalRarity.rare,
      description: '영리하고 교활한 여우입니다.',
      flavorText: '똑똑해서 주인의 마음을 잘 알아요',
      specialAbility: '클릭 효과가 2배로 증가',
    ),
    
    AnimalSpecies(
      id: 'panda',
      name: '판다',
      baseEmoji: '🐼',
      rarity: AnimalRarity.rare,
      description: '귀여운 판다입니다. 대나무를 좋아해요.',
      flavorText: '하루 종일 대나무만 먹어도 행복해요',
      specialAbility: '클릭 시 대나무 효과',
    ),
    
    AnimalSpecies(
      id: 'koala',
      name: '코알라',
      baseEmoji: '🐨',
      rarity: AnimalRarity.rare,
      description: '나무에서 자는 것을 좋아하는 코알라입니다.',
      flavorText: '유칼립투스 잎만 먹고 살아요',
      specialAbility: '자동 성장 속도 증가',
    ),
    
    AnimalSpecies(
      id: 'penguin',
      name: '펭귄',
      baseEmoji: '🐧',
      rarity: AnimalRarity.rare,
      description: '남극에서 온 귀여운 펭귄입니다.',
      flavorText: '추운 곳을 좋아하고 물고기를 잘 잡아요',
      specialAbility: '클릭 시 얼음 효과',
    ),
    
    AnimalSpecies(
      id: 'owl',
      name: '부엉이',
      baseEmoji: '🦉',
      rarity: AnimalRarity.rare,
      description: '밤에 활동하는 지혜로운 부엉이입니다.',
      flavorText: '밤하늘을 날아다니며 지혜를 나눠줘요',
      specialAbility: '밤에 클릭 효과 증가',
    ),
    
    // 전설 등급 (⭐⭐⭐) - 5%
    AnimalSpecies(
      id: 'dragon',
      name: '드래곤',
      baseEmoji: '🐉',
      rarity: AnimalRarity.legendary,
      description: '전설 속의 용입니다. 매우 강력한 힘을 가지고 있어요.',
      flavorText: '하늘을 날아다니며 불을 뿜는 전설의 존재',
      specialAbility: '클릭 효과가 10배로 증가!',
    ),
    
    AnimalSpecies(
      id: 'unicorn',
      name: '유니콘',
      baseEmoji: '🦄',
      rarity: AnimalRarity.legendary,
      description: '신화 속의 유니콘입니다. 순수한 마음을 가진 자만 만날 수 있어요.',
      flavorText: '무지개를 타고 다니는 마법의 존재',
      specialAbility: '모든 업그레이드 효과 2배!',
    ),
  ];

  // ID로 동물 종족 찾기
  static AnimalSpecies? getSpeciesById(String id) {
    try {
      return allSpecies.firstWhere((species) => species.id == id);
    } catch (e) {
      return null;
    }
  }

  // 확률에 따른 랜덤 동물 뽑기
  static AnimalSpecies getRandomSpeciesByProbability() {
    final random = Random();
    final randomValue = random.nextDouble();
    
    // 등급별로 먼저 선택
    AnimalRarity selectedRarity;
    if (randomValue <= 0.05) {
      selectedRarity = AnimalRarity.legendary; // 5%
    } else if (randomValue <= 0.30) {
      selectedRarity = AnimalRarity.rare; // 25%
    } else {
      selectedRarity = AnimalRarity.common; // 70%
    }
    
    // 선택된 등급의 동물들 중에서 랜덤 선택
    final speciesOfRarity = getSpeciesByRarity(selectedRarity);
    if (speciesOfRarity.isEmpty) {
      return allSpecies.first; // 혹시 모를 경우
    }
    
    final randomIndex = random.nextInt(speciesOfRarity.length);
    return speciesOfRarity[randomIndex];
  }

  // 등급별 동물 목록
  static List<AnimalSpecies> getSpeciesByRarity(AnimalRarity rarity) {
    return allSpecies.where((species) => species.rarity == rarity).toList();
  }

  // 전체 동물 수
  static int get totalSpeciesCount => allSpecies.length;

  // 등급별 동물 수
  static Map<AnimalRarity, int> get speciesCountByRarity {
    final Map<AnimalRarity, int> counts = {};
    for (final rarity in AnimalRarity.values) {
      counts[rarity] = getSpeciesByRarity(rarity).length;
    }
    return counts;
  }
} 