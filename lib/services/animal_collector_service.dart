import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../data/animal_data.dart';
import 'user_service.dart';

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
  static Future<Map<String, dynamic>> clickPet(String userId, {UserModel? currentUser}) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) return {'success': false, 'pet': null, 'user': currentUser};

      // 클릭 파워에 따른 경험치 계산
      double expGain = currentPet.clickPower;
      int newCombo = currentPet.comboCount + 1;
      
      // 콤보 보너스 (연속 클릭 시 보너스)
      if (newCombo >= 50) {
        expGain *= 3.0; // 🔥🔥🔥 환상적!
      } else if (newCombo >= 20) {
        expGain *= 2.0; // 🔥🔥 대박!
      } else if (newCombo >= 10) {
        expGain *= 1.5; // 🔥 콤보!
      }

      // 특별 이벤트 (랜덤)
      final random = Random().nextDouble();
      String? specialMessage;
      if (random < 0.01) { // 1% 크리티컬
        expGain *= 10.0;
        specialMessage = '🌟 크리티컬 터치! (10배 경험치)';
      } else if (random < 0.05) { // 5% 럭키
        expGain *= 5.0;
        specialMessage = '✨ 럭키 클릭! (5배 경험치)';
      }

      // 현재 경험치와 레벨 계산
      double newExp = currentPet.experience + expGain;
      int newLevel = currentPet.level;
      List<String> newTitles = List.from(currentPet.titles);
      bool leveledUp = false;
      List<String> levelUpMessages = [];
      int totalRewardPoints = 0; // 레벨업으로 얻은 총 포인트

      // 레벨업 처리 (여러 레벨 동시 가능, 레벨 99까지)
      while (newLevel < 99 && newExp >= _getRequiredExp(newLevel + 1)) {
        newLevel++;
        newExp -= _getRequiredExp(newLevel);
        leveledUp = true;
        
        // 레벨업 보상 (포인트)
        final rewardPoints = newLevel * 100;
        totalRewardPoints += rewardPoints;
        levelUpMessages.add('🎉 레벨 $newLevel 달성! (+${rewardPoints}P)');
        
        // 레벨별 타이틀 획득
        final levelTitle = _getLevelTitle(newLevel);
        if (!newTitles.contains(levelTitle)) {
          newTitles.add(levelTitle);
          levelUpMessages.add('🏆 새 타이틀 획득: $levelTitle');
        }
      }

      // 레벨 99에서는 경험치 무제한 누적 (클릭 수만 증가)
      if (newLevel >= 99) {
        newLevel = 99;
        // 경험치는 계속 누적됨 (표시용)
      }

      // 기분 결정
      AnimalMood newMood = AnimalMood.happy;
      if (newLevel >= 10) {
        newMood = AnimalMood.love;
      } else if (newCombo >= 10 || leveledUp) {
        newMood = AnimalMood.excited;
      }

      // 상태 업데이트
      final updatedPet = currentPet.copyWith(
        growth: newLevel >= 99 ? 100.0 : (newExp / _getRequiredExp(newLevel) * 100), // 호환성
        level: newLevel,
        experience: newExp,
        totalClicks: currentPet.totalClicks + 1,
        comboCount: newCombo,
        mood: newMood,
        lastInteraction: DateTime.now(),
        titles: newTitles,
      );

      await saveCurrentPet(userId, updatedPet);

      // 유저 포인트 업데이트 (레벨업 보상 적용)
      UserModel? updatedUser = currentUser;
      if (leveledUp && totalRewardPoints > 0 && currentUser != null) {
        updatedUser = currentUser.copyWith(
          rewardPoints: currentUser.rewardPoints + totalRewardPoints,
        );
        // 유저 정보 저장
        await UserService.updateUser(updatedUser);
      }
      
      return {
        'success': true,
        'pet': updatedPet,
        'user': updatedUser,
        'leveledUp': leveledUp,
        'expGain': expGain,
        'totalRewardPoints': totalRewardPoints,
        'specialMessage': specialMessage,
        'levelUpMessages': levelUpMessages,
      };
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 클릭 처리 실패 - $e');
      }
      return {'success': false, 'pet': null, 'user': currentUser};
    }
  }

  // 레벨별 요구 경험치 계산 (정적 메서드)
  static double _getRequiredExp(int level) {
    if (level >= 99) return 99 * 100.0 + (99 - 1) * 50.0; // 레벨 99 요구 경험치 고정
    return level * 100.0 + (level - 1) * 50.0;
  }

  // 레벨별 타이틀 가져오기 (정적 메서드)
  static String _getLevelTitle(int level) {
    if (level >= 90) return '♾️ 영원한 수호자';
    if (level >= 80) return '🌟 클릭의 신';
    if (level >= 70) return '🚀 우주 클리커';
    if (level >= 60) return '🌈 무지개 터치';
    if (level >= 50) return '⚡ 번개손';
    if (level >= 40) return '🔥 클릭 황제';
    if (level >= 30) return '💎 동물원장';
    if (level >= 20) return '🎯 클릭 전설';
    if (level >= 15) return '👑 펫 마에스트로';
    if (level >= 10) return '🏆 케어마스터';
    if (level >= 5) return '🌟 돌봄이';
    if (level >= 2) return '🐾 동물 친구';
    return '🐣 새싹 키우미';
  }

  /// 자동 성장 처리 (오프라인 시간 계산)
  static Future<CurrentPet?> processOfflineGrowth(CurrentPet currentPet) async {
    try {
      // 자동 성장 기능은 현재 비활성화됨 (클릭 전용 게임)
      // 단순히 현재 펫을 반환
      return currentPet;
    } catch (e) {
      if (kDebugMode) {
        print('오프라인 성장 처리 실패: $e');
      }
      return currentPet;
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

  /// 도감 등록하기 (레벨 2 이상 달성 시)
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
        throw Exception('도감 등록 조건을 만족하지 않습니다. (레벨 2 이상 필요)');
      }

      // 도감에 등록 (레벨 정보 포함)
      final collectedAnimal = await _addToCollection(userId, currentPet);
      
      // 완료 보상 (레벨과 클릭 수에 따라)
      final levelBonus = currentPet.level * 50; // 레벨당 50P
      final clickBonus = (currentPet.totalClicks * 0.1).round(); // 클릭당 0.1P
      final rewardPoints = 100 + levelBonus + clickBonus; // 기본 100P + 보너스
      
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
        'message': '🎉 ${currentPet.nickname} (Lv.${currentPet.level})이(가) 도감에 등록되었어요! (+${rewardPoints}P)',
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
      
      // 새로운 동물 추가 (레벨 정보 포함)
      final newEntry = CollectedAnimal.completed(
        speciesId: pet.speciesId,
        nickname: pet.nickname,
        totalClicks: pet.totalClicks,
        completedLevel: pet.level,
      );
      collection.add(newEntry);

      await _saveCollection(userId, collection);
      
      if (kDebugMode) {
        print('AnimalCollectorService: 도감에 추가 완료 - ${pet.nickname} (Lv.${pet.level})');
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

  // 테스트용 레벨업 메서드 (개발용)
  static Future<Map<String, dynamic>> levelUpPet(String userId, {UserModel? currentUser}) async {
    try {
      final currentPet = await getCurrentPet(userId);
      if (currentPet == null) return {'success': false, 'pet': null, 'user': currentUser};

      if (currentPet.level >= 99) {
        return {
          'success': false, 
          'error': '이미 최대 레벨입니다!',
          'pet': currentPet, 
          'user': currentUser
        };
      }

      // 현재 레벨에서 다음 레벨로 가는데 필요한 경험치 계산
      final requiredExp = _getRequiredExp(currentPet.level + 1);
      final expToAdd = requiredExp - currentPet.experience;

      // 레벨업 처리
      double newExp = currentPet.experience + expToAdd;
      int newLevel = currentPet.level;
      List<String> newTitles = List.from(currentPet.titles);
      bool leveledUp = false;
      int totalRewardPoints = 0;

      // 레벨업 처리
      if (newLevel < 99 && newExp >= _getRequiredExp(newLevel + 1)) {
        newLevel++;
        newExp -= _getRequiredExp(newLevel);
        leveledUp = true;
        
        // 레벨업 보상 (포인트)
        final rewardPoints = newLevel * 100;
        totalRewardPoints += rewardPoints;
        
        // 레벨별 타이틀 획득
        final levelTitle = _getLevelTitle(newLevel);
        if (!newTitles.contains(levelTitle)) {
          newTitles.add(levelTitle);
        }
      }

      // 레벨 99에서는 경험치 무제한 누적
      if (newLevel >= 99) {
        newLevel = 99;
        // 경험치는 계속 누적됨
      }

      // 기분 결정
      AnimalMood newMood = AnimalMood.happy;
      if (newLevel >= 10) {
        newMood = AnimalMood.love;
      } else if (leveledUp) {
        newMood = AnimalMood.excited;
      }

      // 상태 업데이트
      final updatedPet = currentPet.copyWith(
        growth: newLevel >= 99 ? 100.0 : (newExp / _getRequiredExp(newLevel + 1) * 100),
        level: newLevel,
        experience: newExp,
        mood: newMood,
        lastInteraction: DateTime.now(),
        titles: newTitles,
      );

      await saveCurrentPet(userId, updatedPet);

      // 유저 포인트 업데이트 (레벨업 보상 적용)
      UserModel? updatedUser = currentUser;
      if (leveledUp && totalRewardPoints > 0 && currentUser != null) {
        updatedUser = currentUser.copyWith(
          rewardPoints: currentUser.rewardPoints + totalRewardPoints,
        );
        // 유저 정보 저장
        await UserService.updateUser(updatedUser);
      }
      
      return {
        'success': true,
        'pet': updatedPet,
        'user': updatedUser,
        'leveledUp': leveledUp,
        'totalRewardPoints': totalRewardPoints,
      };
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 테스트 레벨업 실패 - $e');
      }
      return {'success': false, 'pet': null, 'user': currentUser};
    }
  }

  // 테스트용 포인트 충전 메서드 (개발용)
  static Future<Map<String, dynamic>> addTestPoints(String userId, {UserModel? currentUser}) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'error': '사용자 정보가 없습니다.', 'user': null};
      }

      // 10000 포인트 추가
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + 10000,
      );

      // 유저 정보 저장
      await UserService.updateUser(updatedUser);
      
      return {
        'success': true,
        'user': updatedUser,
        'pointsAdded': 10000,
      };
    } catch (e) {
      if (kDebugMode) {
        print('AnimalCollectorService: 테스트 포인트 충전 실패 - $e');
      }
      return {'success': false, 'error': e.toString(), 'user': currentUser};
    }
  }
} 