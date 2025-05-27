import 'lib/models/current_pet.dart';
import 'lib/models/animal_species.dart';
import 'lib/models/collected_animal.dart';
import 'lib/data/animal_data.dart';

void main() {
  print('🎮 클릭커 시스템 테스트 시작!\\n');
  
  // 1. 랜덤 동물 뽑기 테스트
  print('📦 뽑기 테스트:');
  for (int i = 0; i < 10; i++) {
    final species = AnimalData.getRandomSpeciesByProbability();
    print('${i + 1}. ${species.rarityStars} ${species.name} (${species.rarity})');
  }
  print('');
  
  // 2. 클릭커 게임 시뮬레이션
  print('🖱️ 클릭커 게임 시뮬레이션:');
  
  // 고양이 생성
  var cat = CurrentPet.create(
    speciesId: 'cat',
    nickname: '냥이',
  );
  
  print('📝 초기 상태:');
  print('- 동물: ${cat.nickname}');
  print('- 성장도: ${cat.growth.toStringAsFixed(1)}%');
  print('- 클릭 파워: ${cat.clickPower}');
  print('- 총 클릭: ${cat.totalClicks}');
  print('- 콤보: ${cat.comboCount}');
  print('');
  
  // 3. 클릭 시뮬레이션
  print('🖱️ 클릭 10번:');
  for (int i = 0; i < 10; i++) {
    // 클릭 파워에 따른 성장량 계산
    double growthBonus = cat.clickPower;
    int newCombo = cat.comboCount + 1;
    
    // 콤보 보너스
    if (newCombo >= 50) {
      growthBonus *= 3.0; // 🔥🔥🔥 환상적!
    } else if (newCombo >= 20) {
      growthBonus *= 2.0; // 🔥🔥 대박!
    } else if (newCombo >= 10) {
      growthBonus *= 1.5; // 🔥 콤보!
    }
    
    // 기분 결정
    AnimalMood newMood = AnimalMood.happy;
    if (cat.growth + growthBonus >= 90) {
      newMood = AnimalMood.love;
    } else if (newCombo >= 10) {
      newMood = AnimalMood.excited;
    }
    
    // 상태 업데이트
    cat = cat.copyWith(
      growth: (cat.growth + growthBonus).clamp(0, 100),
      totalClicks: cat.totalClicks + 1,
      comboCount: newCombo,
      mood: newMood,
      lastInteraction: DateTime.now(),
    );
    
    String comboText = '';
    if (newCombo >= 10) {
      comboText = newCombo >= 20 ? ' 🔥🔥 대박!' : ' 🔥 콤보!';
    }
    
    print('클릭 ${i + 1}: +${growthBonus.toStringAsFixed(1)}% → ${cat.growth.toStringAsFixed(1)}% ${cat.moodEmoji}$comboText');
  }
  print('');
  
  // 4. 업그레이드 테스트
  print('⬆️ 업그레이드 테스트:');
  print('업그레이드 전 클릭 파워: ${cat.clickPower}');
  
  // 클릭 파워 업그레이드
  var newStats = Map<String, dynamic>.from(cat.stats);
  newStats['clickPower'] = cat.clickPower + 0.5;
  cat = cat.copyWith(stats: newStats);
  
  print('업그레이드 후 클릭 파워: ${cat.clickPower}');
  print('');
  
  // 5. 자동 성장 테스트
  print('🤖 자동 성장 테스트:');
  print('자동 성장 레벨: ${cat.autoClickLevel}');
  print('초당 자동 성장량: ${cat.autoGrowthPerSecond}%');
  
  // 자동 클릭 업그레이드
  newStats['autoClickLevel'] = 5;
  cat = cat.copyWith(stats: newStats);
  
  print('업그레이드 후 자동 성장 레벨: ${cat.autoClickLevel}');
  print('업그레이드 후 초당 자동 성장량: ${cat.autoGrowthPerSecond}%');
  print('');
  
  // 6. 완료 조건 확인
  print('📖 완료 조건 확인:');
  print('현재 성장도: ${cat.growth.toStringAsFixed(1)}%');
  print('완료 가능: ${cat.canComplete ? "✅ 가능" : "❌ 불가능"}');
  
  if (cat.canComplete) {
    // 도감 등록
    final collectedAnimal = CollectedAnimal.completed(
      speciesId: cat.speciesId,
      nickname: cat.nickname,
      totalClicks: cat.totalClicks,
    );
    
    print('🎉 도감 등록 완료!');
    print('- 종족: ${collectedAnimal.speciesId}');
    print('- 닉네임: ${collectedAnimal.nickname}');
    print('- 총 클릭: ${collectedAnimal.totalClicks}');
    print('- 완료 여부: ${collectedAnimal.isCompleted}');
  }
  print('');
  
  // 7. 희귀도별 확률 검증
  print('🎲 희귀도별 확률 검증 (1000회):');
  Map<AnimalRarity, int> counts = {
    AnimalRarity.common: 0,
    AnimalRarity.rare: 0,
    AnimalRarity.legendary: 0,
  };
  
  for (int i = 0; i < 1000; i++) {
    final species = AnimalData.getRandomSpeciesByProbability();
    counts[species.rarity] = (counts[species.rarity] ?? 0) + 1;
  }
  
  print('일반 (⭐): ${counts[AnimalRarity.common]}회 (${(counts[AnimalRarity.common]! / 10).toStringAsFixed(1)}%)');
  print('희귀 (⭐⭐): ${counts[AnimalRarity.rare]}회 (${(counts[AnimalRarity.rare]! / 10).toStringAsFixed(1)}%)');
  print('전설 (⭐⭐⭐): ${counts[AnimalRarity.legendary]}회 (${(counts[AnimalRarity.legendary]! / 10).toStringAsFixed(1)}%)');
  print('');
  
  print('🎮 클릭커 시스템 테스트 완료! ✨');
} 