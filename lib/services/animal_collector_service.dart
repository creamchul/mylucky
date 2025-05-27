import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../data/animal_data.dart';

class AnimalCollectorService {
  static const String _currentPetKey = 'current_pet';
  static const String _collectionKey = 'animal_collection';
  static const String _lastFreeGachaKey = 'last_free_gacha';
  static const String _upgradesKey = 'upgrades';

  // ========================================
  // 현재 키우는 동물 관리
  // ========================================

  /// 현재 키우는 동물 가져오기
  static Future<CurrentPet?> getCurrentPet(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petJson = prefs.getString('${_currentPetKey}_$userId');
      
      if (petJson != null) {
        final petData = json.decode(petJson);
        return CurrentPet.fromJson(petData);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 현재 펫 로드 실패 - $e');
      }
      return null;
    }
  }

  /// 현재 키우는 동물 저장
  static Future<void> saveCurrentPet(String userId, CurrentPet pet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('${_currentPetKey}_$userId', json.encode(pet.toJson()));
      
      if (kDebugMode) {
        print('AnimalCollectorService: 현재 펫 저장 완료 - ${pet.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 현재 펫 저장 실패 - $e');
      }
      rethrow;
    }
  }

  /// 현재 키우는 동물 제거 (완료 또는 포기 시)
  static Future<void> removeCurrentPet(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_currentPetKey}_$userId');
      
      if (kDebugMode) {
        print('AnimalCollectorService: 현재 펫 제거 완료');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 현재 펫 제거 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 뽑기 시스템
  // ========================================

  /// 무료 뽑기 가능 여부 확인
  static Future<bool> canUseFreeGacha(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFreeGachaTime = prefs.getInt('${_lastFreeGachaKey}_$userId');
      
      if (lastFreeGachaTime == null) return true;
      
      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastFreeGachaTime);
      final now = DateTime.now();
      final difference = now.difference(lastTime);
      
      return difference.inHours >= 24;
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 무료 뽑기 확인 실패 - $e');
      }
      return false;
    }
  }

  /// 무료 뽑기 시간 업데이트
  static Future<void> updateFreeGachaTime(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${_lastFreeGachaKey}_$userId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 무료 뽑기 시간 업데이트 실패 - $e');
      }
    }
  }

  /// 동물 뽑기 (가챠)
  static Future<Map<String, dynamic>> performGacha({
    required String userId,
    required UserModel currentUser,
    bool isFree = false,
  }) async {
    try {
      // 현재 키우는 동물이 있는지 확인
      final currentPet = await getCurrentPet(userId);
      if (currentPet != null) {
        throw Exception('이미 키우는 동물이 있습니다. 먼저 완료하거나 포기해주세요.');
      }

      // 무료 뽑기 확인
      if (isFree) {
        final canFree = await canUseFreeGacha(userId);
        if (!canFree) {
          throw Exception('무료 뽑기는 24시간마다 1회만 가능합니다.');
        }
      } else {
        // 포인트 뽑기 (500P 필요)
        if (currentUser.rewardPoints < 500) {
          throw Exception('포인트가 부족합니다. (필요: 500P)');
        }
      }

      // 랜덤 동물 뽑기
      final randomSpecies = AnimalData.getRandomSpeciesByProbability();
      
      // 새로운 펫 생성
      final newPet = CurrentPet.create(
        speciesId: randomSpecies.id,
        nickname: randomSpecies.name, // 기본 이름, 나중에 변경 가능
      );

      // 펫 저장
      await saveCurrentPet(userId, newPet);

      // 무료 뽑기 시간 업데이트 또는 포인트 차감
      UserModel updatedUser = currentUser;
      if (isFree) {
        await updateFreeGachaTime(userId);
      } else {
        updatedUser = currentUser.copyWith(
          rewardPoints: currentUser.rewardPoints - 500,
        );
      }

      if (kDebugMode) {
        print('AnimalCollectorService: 뽑기 성공 - ${randomSpecies.name} (${randomSpecies.rarityStars})');
      }

      return {
        'success': true,
        'species': randomSpecies,
        'pet': newPet,
        'user': updatedUser,
        'isLegendary': randomSpecies.rarity == AnimalRarity.legendary,
        'isRare': randomSpecies.rarity == AnimalRarity.rare,
      };
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 뽑기 실패 - $e');
      }
      return {
        'success': false,
        'error': e.toString(),
        'user': currentUser,
      };
    }
  }

  // ========================================
  // 클릭커 시스템
  // ========================================

  /// 동물 클릭 (클릭커 게임의 핵심)
  static Future<CurrentPet?> clickPet(String userId) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) return null;

      // 클릭 파워에 따른 성장량 계산
      double growthBonus = currentPet.clickPower;
      int newCombo = currentPet.comboCount + 1;
      
      // 콤보 보너스 (연속 클릭 시 보너스)
      if (newCombo >= 50) {
        growthBonus *= 3.0; // 🔥🔥🔥 환상적!
      } else if (newCombo >= 20) {
        growthBonus *= 2.0; // 🔥🔥 대박!
      } else if (newCombo >= 10) {
        growthBonus *= 1.5; // 🔥 콤보!
      }

      // 특별 이벤트 (랜덤)
      final random = Random().nextDouble();
      if (random < 0.01) { // 1% 크리티컬
        growthBonus *= 10.0;
      } else if (random < 0.05) { // 5% 럭키
        growthBonus *= 5.0;
      }

      // 기분 결정
      AnimalMood newMood = AnimalMood.happy;
      if (currentPet.growth + growthBonus >= 90) {
        newMood = AnimalMood.love;
      } else if (newCombo >= 10) {
        newMood = AnimalMood.excited;
      }

      // 상태 업데이트
      final updatedPet = currentPet.copyWith(
        growth: (currentPet.growth + growthBonus).clamp(0, 100),
        totalClicks: currentPet.totalClicks + 1,
        comboCount: newCombo,
        mood: newMood,
        lastInteraction: DateTime.now(),
      );

      await saveCurrentPet(userId, updatedPet);
      return updatedPet;
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 클릭 처리 실패 - $e');
      }
      return null;
    }
  }

  /// 자동 성장 처리 (백그라운드에서 실행)
  static Future<CurrentPet?> processAutoGrowth(String userId) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) return null;

      final now = DateTime.now();
      final timeDiff = now.difference(currentPet.lastInteraction).inSeconds;
      
      if (timeDiff > 0 && currentPet.autoGrowthPerSecond > 0) {
        final autoGrowth = currentPet.autoGrowthPerSecond * timeDiff;
        
        final updatedPet = currentPet.copyWith(
          growth: (currentPet.growth + autoGrowth).clamp(0, 100),
          lastInteraction: now,
          comboCount: 0, // 자동 성장 시 콤보 리셋
        );

        await saveCurrentPet(userId, updatedPet);
        return updatedPet;
      }

      return currentPet;
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 자동 성장 처리 실패 - $e');
      }
      return null;
    }
  }

  /// 업그레이드 구매
  static Future<Map<String, dynamic>> purchaseUpgrade({
    required String userId,
    required UserModel currentUser,
    required String upgradeType,
  }) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) {
        throw Exception('키우는 동물이 없습니다.');
      }

      int cost = 0;
      Map<String, dynamic> newStats = Map.from(currentPet.stats);

      switch (upgradeType) {
        case 'clickPower':
          final currentLevel = (newStats['clickPower'] as double? ?? 1.0);
          cost = (currentLevel * 100).round();
          if (currentUser.rewardPoints < cost) {
            throw Exception('포인트가 부족합니다. (필요: ${cost}P)');
          }
          newStats['clickPower'] = currentLevel + 0.5;
          break;

        case 'autoClick':
          final currentLevel = (newStats['autoClickLevel'] as int? ?? 0);
          cost = (currentLevel + 1) * 200;
          if (currentUser.rewardPoints < cost) {
            throw Exception('포인트가 부족합니다. (필요: ${cost}P)');
          }
          newStats['autoClickLevel'] = currentLevel + 1;
          break;

        case 'speedBoost':
          final currentLevel = (newStats['speedBoostLevel'] as int? ?? 0);
          cost = (currentLevel + 1) * 150;
          if (currentUser.rewardPoints < cost) {
            throw Exception('포인트가 부족합니다. (필요: ${cost}P)');
          }
          newStats['speedBoostLevel'] = currentLevel + 1;
          break;

        default:
          throw Exception('알 수 없는 업그레이드 타입입니다.');
      }

      // 펫 업데이트
      final updatedPet = currentPet.copyWith(stats: newStats);
      await saveCurrentPet(userId, updatedPet);

      // 유저 포인트 차감
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints - cost,
      );

      return {
        'success': true,
        'pet': updatedPet,
        'user': updatedUser,
        'cost': cost,
        'upgradeType': upgradeType,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'user': currentUser,
      };
    }
  }

  /// 도감 등록하기 (성장도 100% 달성 시)
  static Future<Map<String, dynamic>> completePet({
    required String userId,
    required UserModel currentUser,
  }) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) {
        throw Exception('키우는 동물이 없습니다.');
      }

      if (!currentPet.canComplete) {
        throw Exception('도감 등록 조건을 만족하지 않습니다. (성장도 100% 필요)');
      }

      // 도감에 등록
      final collectedAnimal = await _addToCollection(userId, currentPet);
      
      // 완료 보상 (클릭 수에 따라)
      final rewardPoints = (currentPet.totalClicks * 0.1).round() + 100; // 기본 100P + 클릭당 0.1P
      
      // 현재 펫 제거
      await removeCurrentPet(userId);

      // 유저 포인트 추가
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + rewardPoints,
      );

      return {
        'success': true,
        'user': updatedUser,
        'collectedAnimal': collectedAnimal,
        'rewardPoints': rewardPoints,
        'message': '🎉 ${currentPet.nickname}이(가) 도감에 등록되었어요! (+${rewardPoints}P)',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'user': currentUser,
      };
    }
  }

  /// 키우기 포기
  static Future<Map<String, dynamic>> abandonPet({
    required String userId,
    required UserModel currentUser,
  }) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) {
        throw Exception('키우는 동물이 없습니다.');
      }

      // 도감에 현재 상태로 등록
      await _addToCollection(userId, currentPet);
      
      // 현재 펫 제거
      await removeCurrentPet(userId);

      return {
        'success': true,
        'user': currentUser,
        'message': '${currentPet.nickname}이(가) 도감에 등록되었어요.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'user': currentUser,
      };
    }
  }

  // ========================================
  // 도감 관리
  // ========================================

  /// 도감에 동물 추가
  static Future<CollectedAnimal> _addToCollection(String userId, CurrentPet pet) async {
    try {
      final collection = await getCollection(userId);
      
      // 새로운 동물 추가
      final newEntry = CollectedAnimal.completed(
        speciesId: pet.speciesId,
        nickname: pet.nickname,
        totalClicks: pet.totalClicks,
      );
      collection.add(newEntry);

      await _saveCollection(userId, collection);
      
      if (kDebugMode) {
        print('AnimalCollectorService: 도감에 추가 완료 - ${pet.nickname}');
      }
      
      return newEntry;
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 도감 추가 실패 - $e');
      }
      rethrow;
    }
  }

  /// 도감 가져오기
  static Future<List<CollectedAnimal>> getCollection(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionJson = prefs.getString('${_collectionKey}_$userId');
      
      if (collectionJson != null) {
        final collectionData = json.decode(collectionJson) as List;
        return collectionData.map((data) => CollectedAnimal.fromJson(data)).toList();
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 도감 로드 실패 - $e');
      }
      return [];
    }
  }

  /// 도감 저장
  static Future<void> _saveCollection(String userId, List<CollectedAnimal> collection) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collectionData = collection.map((animal) => animal.toJson()).toList();
      await prefs.setString('${_collectionKey}_$userId', json.encode(collectionData));
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 도감 저장 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 유틸리티
  // ========================================

  /// 콤보 리셋 (일정 시간 후)
  static Future<void> resetComboIfNeeded(String userId) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) return;

      final timeSinceLastInteraction = DateTime.now().difference(currentPet.lastInteraction);
      if (timeSinceLastInteraction.inSeconds > 3) { // 3초 후 콤보 리셋
        final updatedPet = currentPet.copyWith(comboCount: 0);
        await saveCurrentPet(userId, updatedPet);
      }
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 콤보 리셋 실패 - $e');
      }
    }
  }
} 