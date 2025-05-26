import 'package:cloud_firestore/cloud_firestore.dart';

enum PetType { animal, plant }
enum GrowthStage { egg, baby, teen, adult, master }

class PetModel {
  final String id;
  final String userId;
  final String name;
  final PetType type;
  final String species; // 종류 (고양이, 강아지, 장미, 선인장 등)
  final GrowthStage stage;
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
    return PetModel(
      id: id,
      userId: userId,
      name: name,
      type: type,
      species: species,
      stage: GrowthStage.egg,
      level: 1,
      totalPointsInvested: 0,
      adoptedAt: now,
      lastFedAt: now,
      imageAsset: _getImageAsset(type, species, GrowthStage.egg),
    );
  }

  // Firestore에서 생성
  factory PetModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PetModel(
      id: id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      type: PetType.values.firstWhere(
        (e) => e.toString() == 'PetType.${data['type']}',
        orElse: () => PetType.animal,
      ),
      species: data['species'] ?? '',
      stage: GrowthStage.values.firstWhere(
        (e) => e.toString() == 'GrowthStage.${data['stage']}',
        orElse: () => GrowthStage.egg,
      ),
      level: data['level'] ?? 1,
      totalPointsInvested: data['totalPointsInvested'] ?? 0,
      adoptedAt: (data['adoptedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastFedAt: (data['lastFedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageAsset: data['imageAsset'],
    );
  }

  // Firestore 저장용 맵 변환
  Map<String, dynamic> toFirestore() {
    return {
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
  }

  // 복사본 생성 (업데이트용)
  PetModel copyWith({
    String? name,
    GrowthStage? stage,
    int? level,
    int? totalPointsInvested,
    DateTime? lastFedAt,
    String? imageAsset,
  }) {
    final newStage = stage ?? this.stage;
    final newSpecies = species;
    
    return PetModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      type: type,
      species: species,
      stage: newStage,
      level: level ?? this.level,
      totalPointsInvested: totalPointsInvested ?? this.totalPointsInvested,
      adoptedAt: adoptedAt,
      lastFedAt: lastFedAt ?? this.lastFedAt,
      imageAsset: imageAsset ?? _getImageAsset(type, newSpecies, newStage),
    );
  }

  // 유틸리티 메서드들
  
  // 성장 단계 한글명
  String get stageDisplayName {
    switch (stage) {
      case GrowthStage.egg:
        return '알';
      case GrowthStage.baby:
        return '새끼';
      case GrowthStage.teen:
        return '청소년기';
      case GrowthStage.adult:
        return '성체';
      case GrowthStage.master:
        return '마스터';
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
    switch (stage) {
      case GrowthStage.egg:
        return 50;
      case GrowthStage.baby:
        return 100;
      case GrowthStage.teen:
        return 200;
      case GrowthStage.adult:
        return 300;
      case GrowthStage.master:
        return 0; // 최고 단계
    }
  }

  // 다음 성장 단계
  GrowthStage? get nextStage {
    switch (stage) {
      case GrowthStage.egg:
        return GrowthStage.baby;
      case GrowthStage.baby:
        return GrowthStage.teen;
      case GrowthStage.teen:
        return GrowthStage.adult;
      case GrowthStage.adult:
        return GrowthStage.master;
      case GrowthStage.master:
        return null; // 최고 단계
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
  static String _getImageAsset(PetType type, String species, GrowthStage stage) {
    final typeStr = type == PetType.animal ? 'animal' : 'plant';
    final stageStr = stage.toString().split('.').last;
    return 'assets/images/pets/${typeStr}_${species}_$stageStr.png';
  }

  // 사용 가능한 동물 종류
  static List<String> get availableAnimals => [
    'cat', 'dog', 'rabbit', 'hamster', 'bird'
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
      'bird': '새',
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
} 