import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
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
  
  /// 새 동물 입양
  static Future<Map<String, dynamic>> adoptPet({
    required UserModel currentUser,
    required String name,
    required AnimalType animalType,
  }) async {
    if (kIsWeb) {
      // 웹에서는 데모 펫 생성
      final demoPet = PetModel.create(
        id: 'web_pet_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.id,
        name: name,
        animalType: animalType,
      );
      
      // 로컬에 저장
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      existingPets.insert(0, demoPet);
      await _savePetsToLocal(currentUser.id, existingPets);
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 동물 입양 - $name');
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
        animalType: animalType,
      );
      
      // 로컬에도 저장
      final existingPets = await _loadPetsFromLocal(currentUser.id);
      existingPets.insert(0, pet);
      await _savePetsToLocal(currentUser.id, existingPets);
      
      if (kDebugMode) {
        print('PetService: 동물 입양 완료 - $name (${animalType.toString().split('.').last})');
      }
      
      return {
        'pet': pet,
        'user': currentUser,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 동물 입양 실패 - $e');
      }
      rethrow;
    }
  }
  
  /// 동물 먹이주기
  static Future<Map<String, dynamic>> feedPet({
    required UserModel currentUser,
    required PetModel pet,
  }) async {
    const feedCost = 10; // 먹이주기 비용
    
    if (!RewardService.hasEnoughPoints(currentUser, feedCost)) {
      throw Exception('포인트가 부족합니다. (필요: $feedCost, 보유: ${currentUser.rewardPoints})');
    }

    // 시간 체크 (테스트용으로 비활성화)
    final now = DateTime.now();
    // final timeSinceLastFed = now.difference(pet.lastFedAt).inMinutes;
    // if (timeSinceLastFed < 60) {
    //   final remainingMinutes = 60 - timeSinceLastFed;
    //   throw Exception('${pet.name}은(는) 아직 배가 부릅니다. ${remainingMinutes}분 후에 다시 시도해주세요.');
    // }

    // 상태 업데이트 계산
    final newHunger = math.max(0, pet.hunger - 30);
    final newHappiness = math.min(100, pet.happiness + 15);
    final newMood = _calculateMood(newHappiness, newHunger, pet.energy);
    final newAction = AnimalAction.eating;

    final updatedPet = pet.copyWith(
      hunger: newHunger,
      happiness: newHappiness,
      lastFedAt: now,
      currentMood: newMood,
      currentAction: newAction,
      totalPointsInvested: pet.totalPointsInvested + feedCost,
    );

    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - feedCost,
      );
      
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 먹이주기 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': updatedUser,
        'pointsUsed': feedCost,
      };
    }

    try {
      // 포인트 사용
      final pointsResult = await RewardService.usePoints(
        currentUser: currentUser,
        pointsToUse: feedCost,
        petId: pet.id,
        description: '${pet.name}에게 먹이주기',
      );

      // Firebase 업데이트 시도
      try {
        await FirebaseService.updatePet(updatedPet);
        if (kDebugMode) {
          print('PetService: Firebase 먹이주기 업데이트 완료 - ${pet.name}');
        }
      } catch (firebaseError) {
        if (kDebugMode) {
          print('PetService: Firebase 업데이트 실패, 로컬 모드로 진행 - $firebaseError');
        }
      }
      
      // 로컬 업데이트 (항상 실행)
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 먹이주기 완료 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': pointsResult['user'],
        'pointsUsed': feedCost,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 먹이주기 실패 - $e');
      }
      
      // 포인트 사용 실패 시 로컬 모드로 처리
      if (e.toString().contains('포인트가 부족합니다')) {
        rethrow;
      }
      
      // 다른 오류의 경우 로컬 모드로 처리
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - feedCost,
      );
      
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 오류 발생으로 로컬 모드로 먹이주기 처리 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': updatedUser,
        'pointsUsed': feedCost,
      };
    }
  }
  
  /// 동물과 놀아주기
  static Future<Map<String, dynamic>> playWithPet({
    required UserModel currentUser,
    required PetModel pet,
  }) async {
    const playCost = 15; // 놀아주기 비용
    
    if (!RewardService.hasEnoughPoints(currentUser, playCost)) {
      throw Exception('포인트가 부족합니다. (필요: $playCost, 보유: ${currentUser.rewardPoints})');
    }

    // 시간 체크 (테스트용으로 비활성화)
    final now = DateTime.now();
    // final timeSinceLastPlayed = now.difference(pet.lastPlayedAt).inMinutes;
    // if (timeSinceLastPlayed < 120) {
    //   final remainingMinutes = 120 - timeSinceLastPlayed;
    //   throw Exception('${pet.name}은(는) 아직 피곤합니다. ${remainingMinutes}분 후에 다시 시도해주세요.');
    // }

    // 상태 업데이트 계산
    final newHappiness = math.min(100, pet.happiness + 25);
    final newEnergy = math.max(20, pet.energy - 20);
    final newMood = _calculateMood(newHappiness, pet.hunger, newEnergy);
    final newAction = AnimalAction.playing;

    final updatedPet = pet.copyWith(
      happiness: newHappiness,
      energy: newEnergy,
      lastPlayedAt: now,
      currentMood: newMood,
      currentAction: newAction,
      totalPointsInvested: pet.totalPointsInvested + playCost,
    );

    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - playCost,
      );
      
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 웹 환경에서 놀아주기 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': updatedUser,
        'pointsUsed': playCost,
      };
    }

    try {
      // 포인트 사용
      final pointsResult = await RewardService.usePoints(
        currentUser: currentUser,
        pointsToUse: playCost,
        petId: pet.id,
        description: '${pet.name}과(와) 놀아주기',
      );

      // Firebase 업데이트 시도
      try {
        await FirebaseService.updatePet(updatedPet);
        if (kDebugMode) {
          print('PetService: Firebase 놀아주기 업데이트 완료 - ${pet.name}');
        }
      } catch (firebaseError) {
        if (kDebugMode) {
          print('PetService: Firebase 업데이트 실패, 로컬 모드로 진행 - $firebaseError');
        }
      }
      
      // 로컬 업데이트 (항상 실행)
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 놀아주기 완료 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': pointsResult['user'],
        'pointsUsed': playCost,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 놀아주기 실패 - $e');
      }
      
      // 포인트 사용 실패 시 로컬 모드로 처리
      if (e.toString().contains('포인트가 부족합니다')) {
        rethrow;
      }
      
      // 다른 오류의 경우 로컬 모드로 처리
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - playCost,
      );
      
      await _updatePetInLocal(currentUser.id, updatedPet);
      
      if (kDebugMode) {
        print('PetService: 오류 발생으로 로컬 모드로 놀아주기 처리 - ${pet.name}');
      }
      
      return {
        'pet': updatedPet,
        'user': updatedUser,
        'pointsUsed': playCost,
      };
    }
  }
  
  /// 동물 성장시키기 (포인트 사용)
  static Future<Map<String, dynamic>> growPet({
    required UserModel currentUser,
    required PetModel pet,
  }) async {
    if (!pet.canGrow) {
      throw Exception('${pet.name}은(는) 이미 최고 단계이거나 성장 조건을 만족하지 않습니다.');
    }

    final requiredPoints = pet.growthRequiredPoints;
    if (!RewardService.hasEnoughPoints(currentUser, requiredPoints)) {
      throw Exception('포인트가 부족합니다. (필요: $requiredPoints, 보유: ${currentUser.rewardPoints})');
    }

    final nextStage = pet.nextStage!;
    final grownPet = pet.copyWith(
      stage: nextStage,
      level: pet.level + 1,
      totalPointsInvested: pet.totalPointsInvested + requiredPoints,
      happiness: math.min(100, pet.happiness + 20),
      currentMood: AnimalMood.excited,
    );

    if (kIsWeb) {
      // 웹에서는 로컬 처리만
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - requiredPoints,
      );
      
      await _updatePetInLocal(currentUser.id, grownPet);
      
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
        description: '${pet.name}을(를) ${grownPet.stageDisplayName} 단계로 성장',
      );

      // Firebase 업데이트 시도
      try {
        await FirebaseService.updatePet(grownPet);
        if (kDebugMode) {
          print('PetService: Firebase 성장 업데이트 완료 - ${pet.name}');
        }
      } catch (firebaseError) {
        if (kDebugMode) {
          print('PetService: Firebase 업데이트 실패, 로컬 모드로 진행 - $firebaseError');
        }
      }
      
      // 로컬 업데이트 (항상 실행)
      await _updatePetInLocal(currentUser.id, grownPet);
      
      if (kDebugMode) {
        print('PetService: 펫 성장 완료 - ${pet.name} → ${grownPet.stageDisplayName}');
      }
      
      return {
        'pet': grownPet,
        'user': pointsResult['user'],
        'pointsUsed': requiredPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('PetService: 펫 성장 실패 - $e');
      }
      
      // 포인트 사용 실패 시 로컬 모드로 처리
      if (e.toString().contains('포인트가 부족합니다')) {
        rethrow;
      }
      
      // 다른 오류의 경우 로컬 모드로 처리
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - requiredPoints,
      );
      
      await _updatePetInLocal(currentUser.id, grownPet);
      
      if (kDebugMode) {
        print('PetService: 오류 발생으로 로컬 모드로 성장 처리 - ${pet.name}');
      }
      
      return {
        'pet': grownPet,
        'user': updatedUser,
        'pointsUsed': requiredPoints,
      };
    }
  }
  
  /// 사용자의 펫 목록 가져오기
  static Future<List<PetModel>> getUserPets(String userId) async {
    if (kIsWeb) {
      // 웹에서는 로컬 데이터만 사용
      final pets = await _loadPetsFromLocal(userId);
      return _updatePetsStatus(pets);
    }

    try {
      // Firebase에서 펫 목록 가져오기
      final pets = await FirebaseService.getUserPets(userId);
      
      // 로컬에도 저장
      await _savePetsToLocal(userId, pets);
      
      // 상태 업데이트
      final updatedPets = _updatePetsStatus(pets);
      
      if (kDebugMode) {
        print('PetService: 펫 목록 로드 완료 (${updatedPets.length}개)');
      }
      
      return updatedPets;
    } catch (e) {
      if (kDebugMode) {
        print('PetService: Firebase 펫 목록 로드 실패, 로컬 데이터 사용 - $e');
      }
      
      // Firebase 실패 시 로컬 데이터 사용
      final pets = await _loadPetsFromLocal(userId);
      return _updatePetsStatus(pets);
    }
  }
  
  /// 로컬에서 특정 펫 업데이트
  static Future<void> _updatePetInLocal(String userId, PetModel updatedPet) async {
    final pets = await _loadPetsFromLocal(userId);
    final index = pets.indexWhere((p) => p.id == updatedPet.id);
    
    if (index != -1) {
      pets[index] = updatedPet;
      await _savePetsToLocal(userId, pets);
    }
  }
  
  /// 펫들의 상태를 시간에 따라 업데이트
  static List<PetModel> _updatePetsStatus(List<PetModel> pets) {
    final now = DateTime.now();
    
    return pets.map((pet) {
      if (!pet.needsStatusUpdate) return pet;
      
      // 시간 경과에 따른 상태 변화
      final hoursSinceLastFed = now.difference(pet.lastFedAt).inHours;
      final hoursSinceLastPlayed = now.difference(pet.lastPlayedAt).inHours;
      
      int newHunger = pet.hunger;
      int newHappiness = pet.happiness;
      int newEnergy = pet.energy;
      
      // 배고픔 증가 (4시간마다 +20)
      if (hoursSinceLastFed >= 4) {
        newHunger = math.min(100, pet.hunger + (hoursSinceLastFed ~/ 4) * 20);
      }
      
      // 행복도 감소 (6시간마다 -10)
      if (hoursSinceLastPlayed >= 6) {
        newHappiness = math.max(0, pet.happiness - (hoursSinceLastPlayed ~/ 6) * 10);
      }
      
      // 에너지 회복 (2시간마다 +15)
      newEnergy = math.min(100, pet.energy + (hoursSinceLastPlayed ~/ 2) * 15);
      
      final newMood = _calculateMood(newHappiness, newHunger, newEnergy);
      final newAction = _calculateAction(newMood, newHunger, newEnergy);
      
      return pet.copyWith(
        hunger: newHunger,
        happiness: newHappiness,
        energy: newEnergy,
        currentMood: newMood,
        currentAction: newAction,
      );
    }).toList();
  }
  
  /// 상태에 따른 기분 계산
  static AnimalMood _calculateMood(int happiness, int hunger, int energy) {
    if (hunger > 80) return AnimalMood.hungry;
    if (energy < 20) return AnimalMood.sleepy;
    if (happiness > 80 && energy > 60) return AnimalMood.excited;
    if (happiness > 60) return AnimalMood.playful;
    return AnimalMood.happy;
  }
  
  /// 상태에 따른 행동 계산
  static AnimalAction _calculateAction(AnimalMood mood, int hunger, int energy) {
    switch (mood) {
      case AnimalMood.hungry:
        return AnimalAction.idle;
      case AnimalMood.sleepy:
        return AnimalAction.sleeping;
      case AnimalMood.excited:
        return AnimalAction.playing;
      case AnimalMood.playful:
        return AnimalAction.walking;
      case AnimalMood.happy:
        return AnimalAction.idle;
    }
  }
  
  /// 입양 가능한 동물 목록
  static List<Map<String, dynamic>> getAvailableAnimalsForAdoption() {
    return [
      {
        'type': AnimalType.cat,
        'name': '고양이',
        'emoji': '🐱',
        'description': '귀엽고 독립적인 성격의 고양이',
      },
      {
        'type': AnimalType.dog,
        'name': '강아지',
        'emoji': '🐶',
        'description': '충성스럽고 활발한 성격의 강아지',
      },
      {
        'type': AnimalType.rabbit,
        'name': '토끼',
        'emoji': '🐰',
        'description': '온순하고 사랑스러운 토끼',
      },
      {
        'type': AnimalType.hamster,
        'name': '햄스터',
        'emoji': '🐹',
        'description': '작고 귀여운 햄스터',
      },
      {
        'type': AnimalType.bird,
        'name': '새',
        'emoji': '🐦',
        'description': '아름다운 노래를 부르는 새',
      },
    ];
  }
} 