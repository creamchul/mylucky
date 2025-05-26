import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/models.dart';
import 'firebase_service.dart';
import 'reward_service.dart';

class PetService {
  static const String _petsKey = 'user_pets';
  
  // ========================================
  // 로컬 저장 관리
  // ========================================
  
  /// 펫 목록을 로컬에 저장
  static Future<void> _savePetsToLocal(String userId, List<PetModel> pets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petsJson = pets.map((pet) => pet.toJson()).toList();
      await prefs.setString('${_petsKey}_$userId', json.encode(petsJson));
      
      if (kDebugMode) {
        print('PetService: 펫 목록 로컬 저장 완료 (${pets.length}개)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 목록 로컬 저장 실패 - $e');
      }
    }
  }
  
  /// 로컬에서 펫 목록 불러오기
  static Future<List<PetModel>> _loadPetsFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petsJson = prefs.getString('${_petsKey}_$userId');
      
      if (petsJson != null) {
        final List<dynamic> petsList = json.decode(petsJson);
        final pets = petsList.map((json) => PetModel.fromJson(json)).toList();
        
        if (kDebugMode) {
          print('PetService: 로컬에서 펫 목록 로드 완료 (${pets.length}개)');
        }
        
        return pets;
      }
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 로컬 펫 목록 로드 실패 - $e');
      }
    }
    
    return [];
  }
  
  // ========================================
  // 펫 생성 및 관리
  // ========================================
  
  /// 새 펫 입양
  static Future<Map<String, dynamic>> adoptPet({
    required UserModel currentUser,
    required String name,
    required PetType type,
    required String species,
  }) async {
    if (kIsWeb) {
      // 웹에서는 데모 펫 생성
      final demoPet = PetModel.create(
        id: 'web_pet_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        name: name,
        type: type,
        species: species,
      );
      
      // 로컬에 저장
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      existingPets.insert(0, demoPet);
      await _savePetsToLocal(currentUser.id, existingPets);
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 펫 입양 - $name');
      }
      
      return {
        'pet': demoPet,
        'user': currentUser,
      };
    }

    try {
      // 펫 생성
      final pet = await FirebaseService.createPet(
        userId: currentUser.id,
        name: name,
        type: type,
        species: species,
      );
      
      // 로컬에도 저장
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      existingPets.insert(0, pet);
      await _savePetsToLocal(currentUser.id, existingPets);
      
      if (kDebugMode) {
        print('PetService: 펫 입양 완료 - $name ($species)');
      }
      
      return {
        'pet': pet,
        'user': currentUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 입양 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 펫 성장시키기 (포인트 사용)
  static Future<Map<String, dynamic>> growPet({
    required UserModel currentUser,
    required PetModel pet,
  }) async {
    if (!pet.canGrow) {
      throw Exception('${pet.name}은(는) 이미 최고 단계입니다.');
    }

    final requiredPoints = pet.pointsToNextStage;
    if (!RewardService.hasEnoughPoints(currentUser, requiredPoints)) {
      throw Exception('포인트가 부족합니다. (필요: $requiredPoints, 보유: ${currentUser.rewardPoints})');
    }

    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      PetModel grownPet;
      
      if (pet.type == PetType.animal) {
        grownPet = pet.copyWith(
          stage: pet.nextStage as GrowthStage,
          level: pet.level + 1,
          totalPointsInvested: pet.totalPointsInvested + requiredPoints,
          lastFedAt: DateTime.now(),
        );
      } else {
        grownPet = pet.copyWith(
          plantStage: pet.nextStage as PlantStage,
          level: pet.level + 1,
          totalPointsInvested: pet.totalPointsInvested + requiredPoints,
          lastFedAt: DateTime.now(),
        );
      }

      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - requiredPoints,
      );
      
      // 로컬 펫 목록 업데이트
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      final petIndex = existingPets.indexWhere((p) => p.id == pet.id);
      if (petIndex != -1) {
        existingPets[petIndex] = grownPet;
        await _savePetsToLocal(currentUser.id, existingPets);
      }
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 펫 성장 - ${pet.name} → ${grownPet.stageDisplayName}');
      }
      
      return {
        'pet': grownPet,
        'user': updatedUser,
        'pointsUsed': requiredPoints,
      };
    }

    try {
      // 포인트 사용
      final pointsResult = await RewardService.usePoints(
        currentUser: currentUser,
        pointsToUse: requiredPoints,
        petId: pet.id,
        description: '${pet.name}을(를) ${pet.nextStage.toString().split('.').last} 단계로 성장',
      );

      // 펫 성장
      PetModel grownPet;
      
      if (pet.type == PetType.animal) {
        grownPet = pet.copyWith(
          stage: pet.nextStage as GrowthStage,
          level: pet.level + 1,
          totalPointsInvested: pet.totalPointsInvested + requiredPoints,
          lastFedAt: DateTime.now(),
        );
      } else {
        grownPet = pet.copyWith(
          plantStage: pet.nextStage as PlantStage,
          level: pet.level + 1,
          totalPointsInvested: pet.totalPointsInvested + requiredPoints,
          lastFedAt: DateTime.now(),
        );
      }

      // 펫 정보 업데이트
      final updatedPet = await FirebaseService.updatePet(grownPet);
      
      // 로컬 펫 목록도 업데이트
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      final petIndex = existingPets.indexWhere((p) => p.id == pet.id);
      if (petIndex != -1) {
        existingPets[petIndex] = updatedPet;
        await _savePetsToLocal(currentUser.id, existingPets);
      }
      
      if (kDebugMode) {
        print('PetService: 펫 성장 완료 - ${pet.name} → ${grownPet.stageDisplayName}');
      }
      
      return {
        'pet': updatedPet,
        'user': pointsResult['user'],
        'pointsUsed': requiredPoints,
        'usage': pointsResult['usage'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 성장 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 펫에게 먹이주기 (포인트 사용하지 않음)
  static Future<PetModel> feedPet(PetModel pet) async {
    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final fedPet = pet.copyWith(
        lastFedAt: DateTime.now(),
      );
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 펫 먹이주기 - ${pet.name}');
      }
      
      return fedPet;
    }

    try {
      final fedPet = pet.copyWith(
        lastFedAt: DateTime.now(),
      );

      final updatedPet = await FirebaseService.updatePet(fedPet);
      
      if (kDebugMode) {
        print('PetService: 펫 먹이주기 완료 - ${pet.name}');
      }
      
      return updatedPet;
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 먹이주기 실패 - $e');
      }
      rethrow;
    }
  }
  
  // ========================================
  // 조회 기능
  // ========================================
  
  /// 사용자의 펫 목록 조회
  static Future<List<PetModel>> getUserPets(String userId) async {
    // 먼저 로컬에서 펫 목록 로드
    final localPets = await _loadPetsFromLocal(userId);
    
    if (kIsWeb) {
      // 웹에서는 로컬 데이터가 있으면 그것을 사용, 없으면 데모 데이터
      if (localPets.isNotEmpty) {
        return localPets;
      }
      
      // 데모 펫 목록 (처음 실행 시에만)
      final demoPets = [
        PetModel.create(
          id: 'web_pet_1',
          userId: userId,
          name: '미미',
          type: PetType.animal,
          species: 'cat',
        ),
        PetModel.create(
          id: 'web_pet_2',
          userId: userId,
          name: '초록이',
          type: PetType.plant,
          species: 'rose',
        ),
      ];
      
      // 데모 펫을 로컬에 저장
      await _savePetsToLocal(userId, demoPets);
      return demoPets;
    }

    try {
      // 모바일에서는 Firebase에서 가져와서 로컬과 동기화
      final firebasePets = await FirebaseService.getUserPets(userId);
      
      // Firebase 데이터를 로컬에 저장
      if (firebasePets.isNotEmpty) {
        await _savePetsToLocal(userId, firebasePets);
        return firebasePets;
      }
      
      // Firebase에 데이터가 없으면 로컬 데이터 반환
      return localPets;
    } catch (e) {
      if (kDebugMode) {
        print('PetService: Firebase 펫 목록 조회 실패, 로컬 데이터 사용 - $e');
      }
      // Firebase 실패 시 로컬 데이터 반환
      return localPets;
    }
  }
  
  /// 펫 삭제
  static Future<void> deletePet(String petId) async {
    if (kIsWeb) {
      if (kDebugMode) {
        print('PetService: 웹 환경에서 펫 삭제 요청');
      }
      return;
    }

    try {
      await FirebaseService.deletePet(petId);
      
      if (kDebugMode) {
        print('PetService: 펫 삭제 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 삭제 실패 - $e');
      }
      rethrow;
    }
  }
  
  // ========================================
  // 유틸리티
  // ========================================
  
  /// 펫 이름 검증
  static bool isValidPetName(String name) {
    return name.trim().isNotEmpty && name.trim().length <= 10;
  }
  
  /// 무료 입양 가능한 펫 목록
  static List<Map<String, dynamic>> getAvailablePetsForAdoption() {
    final animals = PetModel.availableAnimals.map((species) => {
      'type': PetType.animal,
      'species': species,
      'displayName': _getSpeciesDisplayName(PetType.animal, species),
      'icon': _getSpeciesIcon(PetType.animal, species),
      'cost': 0, // 무료 입양
    }).toList();

    final plants = PetModel.availablePlants.map((species) => {
      'type': PetType.plant,
      'species': species,
      'displayName': _getSpeciesDisplayName(PetType.plant, species),
      'icon': _getSpeciesIcon(PetType.plant, species),
      'cost': 0, // 무료 입양
    }).toList();

    return [...animals, ...plants];
  }
  
  /// 펫 종류별 표시명
  static String _getSpeciesDisplayName(PetType type, String species) {
    if (type == PetType.animal) {
      const animalNames = {
        'cat': '고양이',
        'dog': '강아지',
        'rabbit': '토끼',
        'hamster': '햄스터',
      };
      return animalNames[species] ?? species;
    } else {
      const plantNames = {
        'rose': '장미',
        'cactus': '선인장',
        'sunflower': '해바라기',
        'bamboo': '대나무',
        'cherry': '벚꽃',
      };
      return plantNames[species] ?? species;
    }
  }
  
  /// 펫 종류별 아이콘
  static String _getSpeciesIcon(PetType type, String species) {
    if (type == PetType.animal) {
      const animalIcons = {
        'cat': '🐱',
        'dog': '🐶',
        'rabbit': '🐰',
        'hamster': '🐹',
      };
      return animalIcons[species] ?? '🐾';
    } else {
      const plantIcons = {
        'rose': '🌹',
        'cactus': '🌵',
        'sunflower': '🌻',
        'bamboo': '🎋',
        'cherry': '🌸',
      };
      return plantIcons[species] ?? '🌱';
    }
  }
  
  /// 성장 단계별 이모지
  static String getStageEmoji(PetModel pet) {
    if (pet.type == PetType.animal) {
      switch (pet.stage) {
        case GrowthStage.baby:
          return '🐣';
        case GrowthStage.teen:
          return '🐥';
        case GrowthStage.adult:
          return '🐦';
        case GrowthStage.master:
          return '🦅';
      }
    } else {
      switch (pet.plantStage!) {
        case PlantStage.seed:
          return '🌰';
        case PlantStage.sprout:
          return '🌱';
        case PlantStage.growing:
          return '🌿';
        case PlantStage.blooming:
          return '🌸';
        case PlantStage.mature:
          return '🌳';
      }
    }
  }
} 