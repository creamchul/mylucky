import 'package:cloud_firestore/cloud_firestore.dart';

enum AnimalType { cat, dog, rabbit, hamster, bird }
enum GrowthStage { baby, teen, adult, master }
enum AnimalMood { happy, sleepy, hungry, playful, excited }
enum AnimalAction { idle, walking, eating, sleeping, playing }

class PetModel {
  final String id;
  final String userId;
  final String name;
  final AnimalType animalType;
  final GrowthStage stage;
  final int level;
  final int happiness; // 행복도 (0-100)
  final int hunger; // 배고픔 (0-100, 높을수록 배고픔)
  final int energy; // 에너지 (0-100)
  final int totalPointsInvested; // 투자한 총 포인트
  final DateTime adoptedAt;
  final DateTime lastFedAt;
  final DateTime lastPlayedAt;
  final AnimalMood currentMood;
  final AnimalAction currentAction;
  final String? imageAsset; // 이미지 에셋 경로
  final String? animationAsset; // 애니메이션 에셋 경로

  const PetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.animalType,
    required this.stage,
    required this.level,
    required this.happiness,
    required this.hunger,
    required this.energy,
    required this.totalPointsInvested,
    required this.adoptedAt,
    required this.lastFedAt,
    required this.lastPlayedAt,
    required this.currentMood,
    required this.currentAction,
    this.imageAsset,
    this.animationAsset,
  });

  // 팩토리 생성자 - 새 펫 생성
  factory PetModel.create({
    required String id,
    required String userId,
    required String name,
    required AnimalType animalType,
  }) {
    final now = DateTime.now();
    
    return PetModel(
      id: id,
      userId: userId,
      name: name,
      animalType: animalType,
      stage: GrowthStage.baby,
      level: 1,
      happiness: 80,
      hunger: 30,
      energy: 100,
      totalPointsInvested: 0,
      adoptedAt: now,
      lastFedAt: now,
      lastPlayedAt: now,
      currentMood: AnimalMood.happy,
      currentAction: AnimalAction.idle,
      imageAsset: _getImageAsset(animalType, GrowthStage.baby),
      animationAsset: _getAnimationAsset(animalType),
    );
  }

  // Firestore에서 생성
  factory PetModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PetModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      animalType: AnimalType.values.firstWhere(
        (e) => e.toString() == 'AnimalType.${data['animalType']}',
        orElse: () => AnimalType.cat,
      ),
      stage: GrowthStage.values.firstWhere(
        (e) => e.toString() == 'GrowthStage.${data['stage']}',
        orElse: () => GrowthStage.baby,
      ),
      level: data['level'] ?? 1,
      happiness: data['happiness'] ?? 80,
      hunger: data['hunger'] ?? 30,
      energy: data['energy'] ?? 100,
      totalPointsInvested: data['totalPointsInvested'] ?? 0,
      adoptedAt: (data['adoptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastFedAt: (data['lastFedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPlayedAt: (data['lastPlayedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentMood: AnimalMood.values.firstWhere(
        (e) => e.toString() == 'AnimalMood.${data['currentMood']}',
        orElse: () => AnimalMood.happy,
      ),
      currentAction: AnimalAction.values.firstWhere(
        (e) => e.toString() == 'AnimalAction.${data['currentAction']}',
        orElse: () => AnimalAction.idle,
      ),
      imageAsset: data['imageAsset'],
      animationAsset: data['animationAsset'],
    );
  }

  // Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'animalType': animalType.toString().split('.').last,
      'stage': stage.toString().split('.').last,
      'level': level,
      'happiness': happiness,
      'hunger': hunger,
      'energy': energy,
      'totalPointsInvested': totalPointsInvested,
      'adoptedAt': Timestamp.fromDate(adoptedAt),
      'lastFedAt': Timestamp.fromDate(lastFedAt),
      'lastPlayedAt': Timestamp.fromDate(lastPlayedAt),
      'currentMood': currentMood.toString().split('.').last,
      'currentAction': currentAction.toString().split('.').last,
      'imageAsset': imageAsset,
      'animationAsset': animationAsset,
    };
  }

  // JSON 직렬화 (SharedPreferences용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'animalType': animalType.toString().split('.').last,
      'stage': stage.toString().split('.').last,
      'level': level,
      'happiness': happiness,
      'hunger': hunger,
      'energy': energy,
      'totalPointsInvested': totalPointsInvested,
      'adoptedAt': adoptedAt.millisecondsSinceEpoch,
      'lastFedAt': lastFedAt.millisecondsSinceEpoch,
      'lastPlayedAt': lastPlayedAt.millisecondsSinceEpoch,
      'currentMood': currentMood.toString().split('.').last,
      'currentAction': currentAction.toString().split('.').last,
      'imageAsset': imageAsset,
      'animationAsset': animationAsset,
    };
  }

  // JSON에서 생성 (SharedPreferences용)
  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      animalType: AnimalType.values.firstWhere(
        (e) => e.toString() == 'AnimalType.${json['animalType']}',
        orElse: () => AnimalType.cat,
      ),
      stage: GrowthStage.values.firstWhere(
        (e) => e.toString() == 'GrowthStage.${json['stage']}',
        orElse: () => GrowthStage.baby,
      ),
      level: json['level'] ?? 1,
      happiness: json['happiness'] ?? 80,
      hunger: json['hunger'] ?? 30,
      energy: json['energy'] ?? 100,
      totalPointsInvested: json['totalPointsInvested'] ?? 0,
      adoptedAt: DateTime.fromMillisecondsSinceEpoch(json['adoptedAt'] ?? 0),
      lastFedAt: DateTime.fromMillisecondsSinceEpoch(json['lastFedAt'] ?? 0),
      lastPlayedAt: DateTime.fromMillisecondsSinceEpoch(json['lastPlayedAt'] ?? 0),
      currentMood: AnimalMood.values.firstWhere(
        (e) => e.toString() == 'AnimalMood.${json['currentMood']}',
        orElse: () => AnimalMood.happy,
      ),
      currentAction: AnimalAction.values.firstWhere(
        (e) => e.toString() == 'AnimalAction.${json['currentAction']}',
        orElse: () => AnimalAction.idle,
      ),
      imageAsset: json['imageAsset'],
      animationAsset: json['animationAsset'],
    );
  }

  // 복사본 생성 (업데이트용)
  PetModel copyWith({
    String? name,
    GrowthStage? stage,
    int? level,
    int? happiness,
    int? hunger,
    int? energy,
    int? totalPointsInvested,
    DateTime? lastFedAt,
    DateTime? lastPlayedAt,
    AnimalMood? currentMood,
    AnimalAction? currentAction,
    String? imageAsset,
    String? animationAsset,
  }) {
    final newStage = stage ?? this.stage;
    
    return PetModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      animalType: animalType,
      stage: newStage,
      level: level ?? this.level,
      happiness: happiness ?? this.happiness,
      hunger: hunger ?? this.hunger,
      energy: energy ?? this.energy,
      totalPointsInvested: totalPointsInvested ?? this.totalPointsInvested,
      adoptedAt: adoptedAt,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      currentMood: currentMood ?? this.currentMood,
      currentAction: currentAction ?? this.currentAction,
      imageAsset: imageAsset ?? _getImageAsset(animalType, newStage),
      animationAsset: animationAsset ?? this.animationAsset,
    );
  }

  // 이미지 에셋 경로 생성
  static String _getImageAsset(AnimalType animalType, GrowthStage stage) {
    final typeStr = animalType.toString().split('.').last;
    final stageStr = stage.toString().split('.').last;
    return 'assets/images/pets/${typeStr}_$stageStr.png';
  }

  // 애니메이션 에셋 경로 생성
  static String _getAnimationAsset(AnimalType animalType) {
    final typeStr = animalType.toString().split('.').last;
    return 'assets/animations/${typeStr}_animation.json';
  }

  // 동물 타입 표시명
  String get animalTypeDisplayName {
    switch (animalType) {
      case AnimalType.cat:
        return '고양이';
      case AnimalType.dog:
        return '강아지';
      case AnimalType.rabbit:
        return '토끼';
      case AnimalType.hamster:
        return '햄스터';
      case AnimalType.bird:
        return '새';
    }
  }

  // 성장 단계 표시명
  String get stageDisplayName {
    switch (stage) {
      case GrowthStage.baby:
        return '아기';
      case GrowthStage.teen:
        return '청소년';
      case GrowthStage.adult:
        return '성인';
      case GrowthStage.master:
        return '마스터';
    }
  }

  // 기분 표시명
  String get moodDisplayName {
    switch (currentMood) {
      case AnimalMood.happy:
        return '행복함';
      case AnimalMood.sleepy:
        return '졸림';
      case AnimalMood.hungry:
        return '배고픔';
      case AnimalMood.playful:
        return '장난기';
      case AnimalMood.excited:
        return '흥분';
    }
  }

  // 행동 표시명
  String get actionDisplayName {
    switch (currentAction) {
      case AnimalAction.idle:
        return '휴식';
      case AnimalAction.walking:
        return '걷기';
      case AnimalAction.eating:
        return '먹기';
      case AnimalAction.sleeping:
        return '잠자기';
      case AnimalAction.playing:
        return '놀기';
    }
  }

  // 기분 이모지
  String get moodEmoji {
    switch (currentMood) {
      case AnimalMood.happy:
        return '😊';
      case AnimalMood.sleepy:
        return '😴';
      case AnimalMood.hungry:
        return '🍽️';
      case AnimalMood.playful:
        return '🎾';
      case AnimalMood.excited:
        return '🤩';
    }
  }

  // 성장 가능 여부
  bool get canGrow {
    return stage != GrowthStage.master && totalPointsInvested >= growthRequiredPoints;
  }

  // 성장에 필요한 포인트 (테스트용으로 낮춤)
  int get growthRequiredPoints {
    switch (stage) {
      case GrowthStage.baby:
        return 50; // 100 -> 50
      case GrowthStage.teen:
        return 150; // 300 -> 150  
      case GrowthStage.adult:
        return 300; // 600 -> 300
      case GrowthStage.master:
        return 0; // 더 이상 성장 불가
    }
  }

  // 다음 성장 단계
  GrowthStage? get nextStage {
    switch (stage) {
      case GrowthStage.baby:
        return GrowthStage.teen;
      case GrowthStage.teen:
        return GrowthStage.adult;
      case GrowthStage.adult:
        return GrowthStage.master;
      case GrowthStage.master:
        return null;
    }
  }

  // 전체 상태 점수 (0-100)
  int get overallHealth {
    return ((happiness + (100 - hunger) + energy) / 3).round();
  }

  // 배고픔 상태인지
  bool get isHungry => hunger > 70;

  // 피곤한 상태인지
  bool get isTired => energy < 30;

  // 행복한 상태인지
  bool get isHappy => happiness > 70;

  // 시간 경과에 따른 상태 업데이트가 필요한지
  bool get needsStatusUpdate {
    final now = DateTime.now();
    final hoursSinceLastFed = now.difference(lastFedAt).inHours;
    final hoursSinceLastPlayed = now.difference(lastPlayedAt).inHours;
    
    return hoursSinceLastFed > 4 || hoursSinceLastPlayed > 6;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PetModel(id: $id, name: $name, type: ${animalTypeDisplayName}, stage: ${stageDisplayName})';
  }
} 