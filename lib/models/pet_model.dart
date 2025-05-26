import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { animal, plant }
enum GrowthStage { baby, teen, adult, master }
enum PlantStage { seed, sprout, growing, blooming, mature }

class PetModel {
  final String id;
  final String userId;
  final String name;
  final PetType type;
  final String species; // 종류 (고양이, 강아지, 장미, 선인장 등)
  final GrowthStage stage;
  final PlantStage? plantStage; // 식물 전용 성장 단계
  final int level;
  final int totalPointsInvested; // 투자한 총 포인트
  final DateTime adoptedAt;
  final DateTime lastFedAt;
  final String? imageAsset; // 이미지 에셋 경로

  const PetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.species,
    required this.stage,
    this.plantStage,
    required this.level,
    required this.totalPointsInvested,
    required this.adoptedAt,
    required this.lastFedAt,
    this.imageAsset,
  });

  // 팩토리 생성자 - 새 펫 생성
  factory PetModel.create({
    required String id,
    required String userId,
    required String name,
    required PetType type,
    required String species,
  }) {
    final now = DateTime.now();
    
    if (type == PetType.animal) {
      return PetModel(
        id: id,
        userId: userId,
        name: name,
        type: type,
        species: species,
        stage: GrowthStage.baby,
        plantStage: null,
        level: 1,
        totalPointsInvested: 0,
        adoptedAt: now,
        lastFedAt: now,
        imageAsset: _getImageAsset(type, species, GrowthStage.baby, null),
      );
    } else {
      return PetModel(
        id: id,
        userId: userId,
        name: name,
        type: type,
        species: species,
        stage: GrowthStage.baby, // 기본값 (사용하지 않음)
        plantStage: PlantStage.seed,
        level: 1,
        totalPointsInvested: 0,
        adoptedAt: now,
        lastFedAt: now,
        imageAsset: _getImageAsset(type, species, null, PlantStage.seed),
      );
    }
  }

  // Firestore에서 생성
  factory PetModel.fromFirestore(String id, Map<String, dynamic> data) {
    final type = PetType.values.firstWhere(
      (e) => e.toString() == 'PetType.${data['type']}',
      orElse: () => PetType.animal,
    );
    
    return PetModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: type,
      species: data['species'] ?? '',
      stage: GrowthStage.values.firstWhere(
        (e) => e.toString() == 'GrowthStage.${data['stage']}',
        orElse: () => GrowthStage.baby,
      ),
      plantStage: type == PetType.plant && data['plantStage'] != null
          ? PlantStage.values.firstWhere(
              (e) => e.toString() == 'PlantStage.${data['plantStage']}',
              orElse: () => PlantStage.seed,
            )
          : null,
      level: data['level'] ?? 1,
      totalPointsInvested: data['totalPointsInvested'] ?? 0,
      adoptedAt: (data['adoptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastFedAt: (data['lastFedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageAsset: data['imageAsset'],
    );
  }

  // Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    final result = {
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'species': species,
      'stage': stage.toString().split('.').last,
      'level': level,
      'totalPointsInvested': totalPointsInvested,
      'adoptedAt': Timestamp.fromDate(adoptedAt),
      'lastFedAt': Timestamp.fromDate(lastFedAt),
      'imageAsset': imageAsset,
    };
    
    if (plantStage != null) {
      result['plantStage'] = plantStage!.toString().split('.').last;
    }
    
    return result;
  }

  // JSON 직렬화 (SharedPreferences용)
  Map<String, dynamic> toJson() {
    final result = {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.toString().split('.').last,
      'species': species,
      'stage': stage.toString().split('.').last,
      'level': level,
      'totalPointsInvested': totalPointsInvested,
      'adoptedAt': adoptedAt.millisecondsSinceEpoch,
      'lastFedAt': lastFedAt.millisecondsSinceEpoch,
      'imageAsset': imageAsset,
    };
    
    if (plantStage != null) {
      result['plantStage'] = plantStage!.toString().split('.').last;
    }
    
    return result;
  }

  // JSON에서 생성 (SharedPreferences용)
  factory PetModel.fromJson(Map<String, dynamic> json) {
    final type = PetType.values.firstWhere(
      (e) => e.toString() == 'PetType.${json['type']}',
      orElse: () => PetType.animal,
    );
    
    return PetModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      type: type,
      species: json['species'] ?? '',
      stage: GrowthStage.values.firstWhere(
        (e) => e.toString() == 'GrowthStage.${json['stage']}',
        orElse: () => GrowthStage.baby,
      ),
      plantStage: type == PetType.plant && json['plantStage'] != null
          ? PlantStage.values.firstWhere(
              (e) => e.toString() == 'PlantStage.${json['plantStage']}',
              orElse: () => PlantStage.seed,
            )
          : null,
      level: json['level'] ?? 1,
      totalPointsInvested: json['totalPointsInvested'] ?? 0,
      adoptedAt: DateTime.fromMillisecondsSinceEpoch(json['adoptedAt'] ?? 0),
      lastFedAt: DateTime.fromMillisecondsSinceEpoch(json['lastFedAt'] ?? 0),
      imageAsset: json['imageAsset'],
    );
  }

  // 복사본 생성 (업데이트용)
  PetModel copyWith({
    String? name,
    GrowthStage? stage,
    PlantStage? plantStage,
    int? level,
    int? totalPointsInvested,
    DateTime? lastFedAt,
    String? imageAsset,
  }) {
    final newStage = stage ?? this.stage;
    final newPlantStage = plantStage ?? this.plantStage;
    final newSpecies = species;
    
    return PetModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type,
      species: species,
      stage: newStage,
      plantStage: newPlantStage,
      level: level ?? this.level,
      totalPointsInvested: totalPointsInvested ?? this.totalPointsInvested,
      adoptedAt: adoptedAt,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      imageAsset: imageAsset ?? _getImageAsset(type, newSpecies, 
        type == PetType.animal ? newStage : null, 
        type == PetType.plant ? newPlantStage : null),
    );
  }

  // 유틸리티 메서드들
  
  // 성장 단계 한글명
  String get stageDisplayName {
    if (type == PetType.animal) {
      switch (stage) {
        case GrowthStage.baby:
          return '새끼';
        case GrowthStage.teen:
          return '청소년기';
        case GrowthStage.adult:
          return '성체';
        case GrowthStage.master:
          return '마스터';
      }
    } else {
      switch (plantStage!) {
        case PlantStage.seed:
          return '씨앗';
        case PlantStage.sprout:
          return '새싹';
        case PlantStage.growing:
          return '성장기';
        case PlantStage.blooming:
          return '개화기';
        case PlantStage.mature:
          return '완숙기';
      }
    }
  }

  // 타입 한글명
  String get typeDisplayName {
    switch (type) {
      case PetType.animal:
        return '동물';
      case PetType.plant:
        return '식물';
    }
  }

  // 다음 성장 단계까지 필요한 포인트
  int get pointsToNextStage {
    if (type == PetType.animal) {
      switch (stage) {
        case GrowthStage.baby:
          return 100;
        case GrowthStage.teen:
          return 200;
        case GrowthStage.adult:
          return 300;
        case GrowthStage.master:
          return 0; // 최고 단계
      }
    } else {
      switch (plantStage!) {
        case PlantStage.seed:
          return 80;
        case PlantStage.sprout:
          return 150;
        case PlantStage.growing:
          return 250;
        case PlantStage.blooming:
          return 350;
        case PlantStage.mature:
          return 0; // 최고 단계
      }
    }
  }

  // 다음 성장 단계
  dynamic get nextStage {
    if (type == PetType.animal) {
      switch (stage) {
        case GrowthStage.baby:
          return GrowthStage.teen;
        case GrowthStage.teen:
          return GrowthStage.adult;
        case GrowthStage.adult:
          return GrowthStage.master;
        case GrowthStage.master:
          return null; // 최고 단계
      }
    } else {
      switch (plantStage!) {
        case PlantStage.seed:
          return PlantStage.sprout;
        case PlantStage.sprout:
          return PlantStage.growing;
        case PlantStage.growing:
          return PlantStage.blooming;
        case PlantStage.blooming:
          return PlantStage.mature;
        case PlantStage.mature:
          return null; // 최고 단계
      }
    }
  }

  // 성장 가능 여부
  bool get canGrow => nextStage != null;

  // 입양한 지 며칠
  int get daysAdopted {
    return DateTime.now().difference(adoptedAt).inDays;
  }

  // 포맷된 입양 날짜
  String get formattedAdoptedDate {
    return '${adoptedAt.year}-${adoptedAt.month.toString().padLeft(2, '0')}-${adoptedAt.day.toString().padLeft(2, '0')}';
  }

  // 마지막 먹이 준 시간 (상대적)
  String get lastFedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastFedAt);
    
    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  // 이미지 에셋 경로 생성
  static String _getImageAsset(PetType type, String species, GrowthStage? stage, PlantStage? plantStage) {
    final typeStr = type == PetType.animal ? 'animal' : 'plant';
    
    if (type == PetType.animal && stage != null) {
      final stageStr = stage.toString().split('.').last;
      return 'assets/images/pets/${typeStr}_${species}_$stageStr.png';
    } else if (type == PetType.plant && plantStage != null) {
      final stageStr = plantStage.toString().split('.').last;
      return 'assets/images/pets/${typeStr}_${species}_$stageStr.png';
    }
    
    return 'assets/images/pets/${typeStr}_${species}_default.png';
  }

  // 사용 가능한 동물 종류
  static List<String> get availableAnimals => [
    'cat', 'dog', 'rabbit', 'hamster',
  ];

  // 사용 가능한 식물 종류
  static List<String> get availablePlants => [
    'rose', 'cactus', 'sunflower', 'bamboo', 'cherry'
  ];

  // 종류 한글명
  String get speciesDisplayName {
    final animalNames = {
      'cat': '고양이',
      'dog': '강아지',
      'rabbit': '토끼',
      'hamster': '햄스터',
    };
    
    final plantNames = {
      'rose': '장미',
      'cactus': '선인장',
      'sunflower': '해바라기',
      'bamboo': '대나무',
      'cherry': '벚꽃',
    };
    
    if (type == PetType.animal) {
      return animalNames[species] ?? species;
    } else {
      return plantNames[species] ?? species;
    }
  }

  // 펫의 이모지 표현 (이미지 대신 사용)
  String get petEmoji {
    if (type == PetType.animal) {
      switch (species) {
        case 'cat':
          switch (stage) {
            case GrowthStage.baby: return '🐱';
            case GrowthStage.teen: return '😸';
            case GrowthStage.adult: return '😺';
            case GrowthStage.master: return '😻';
          }
        case 'dog':
          switch (stage) {
            case GrowthStage.baby: return '🐶';
            case GrowthStage.teen: return '🐕';
            case GrowthStage.adult: return '🦮';
            case GrowthStage.master: return '🐕‍🦺';
          }
        case 'rabbit':
          switch (stage) {
            case GrowthStage.baby: return '🐰';
            case GrowthStage.teen: return '🐇';
            case GrowthStage.adult: return '🐰';
            case GrowthStage.master: return '🐇';
          }
        case 'hamster':
          switch (stage) {
            case GrowthStage.baby: return '🐹';
            case GrowthStage.teen: return '🐹';
            case GrowthStage.adult: return '🐹';
            case GrowthStage.master: return '🐹';
          }
        default:
          return '🐾';
      }
    } else {
      switch (species) {
        case 'rose':
          switch (plantStage!) {
            case PlantStage.seed: return '🌰';
            case PlantStage.sprout: return '🌱';
            case PlantStage.growing: return '🌿';
            case PlantStage.blooming: return '🌹';
            case PlantStage.mature: return '🌺';
          }
        case 'cactus':
          switch (plantStage!) {
            case PlantStage.seed: return '🌰';
            case PlantStage.sprout: return '🌱';
            case PlantStage.growing: return '🌿';
            case PlantStage.blooming: return '🌵';
            case PlantStage.mature: return '🌵';
          }
        case 'sunflower':
          switch (plantStage!) {
            case PlantStage.seed: return '🌰';
            case PlantStage.sprout: return '🌱';
            case PlantStage.growing: return '🌿';
            case PlantStage.blooming: return '🌻';
            case PlantStage.mature: return '🌻';
          }
        case 'bamboo':
          switch (plantStage!) {
            case PlantStage.seed: return '🌰';
            case PlantStage.sprout: return '🌱';
            case PlantStage.growing: return '🌿';
            case PlantStage.blooming: return '🎋';
            case PlantStage.mature: return '🎋';
          }
        case 'cherry':
          switch (plantStage!) {
            case PlantStage.seed: return '🌰';
            case PlantStage.sprout: return '🌱';
            case PlantStage.growing: return '🌿';
            case PlantStage.blooming: return '🌸';
            case PlantStage.mature: return '🌸';
          }
        default:
          return '🌱';
      }
    }
  }
} 