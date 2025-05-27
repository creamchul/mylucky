import 'lib/models/current_pet.dart';
import 'lib/models/animal_species.dart';
import 'lib/models/collected_animal.dart';
import 'lib/data/animal_data.dart';

void main() {
  print('🎮 성격 시스템 테스트 시작!\n');
  
  // 1. 고양이 생성
  final cat = CurrentPet.create(
    speciesId: 'cat',
    nickname: '냥이',
  );
  
  print('📝 초기 상태:');
  print('- 동물: ${cat.nickname}');
  print('- 성격: ${cat.personalityDescription} ${cat.personalityEmoji}');
  print('- 친밀도: ${cat.growth}%');
  print('- 행동 횟수: ${cat.actionCounts}');
  print('');
  
  // 2. 먹이 위주로 키우기
  var updatedCat = cat;
  for (int i = 0; i < 10; i++) {
    updatedCat = updatedCat.copyWith(
      actionCounts: {
        ...updatedCat.actionCounts,
        'feed': (updatedCat.actionCounts['feed'] ?? 0) + 1,
      },
      growth: (updatedCat.growth + 10).clamp(0, 100),
    );
  }
  
  print('🍎 먹이 10번 준 후:');
  print('- 성격: ${updatedCat.personalityDescription} ${updatedCat.personalityEmoji}');
  print('- 계산된 성격: ${updatedCat.calculatedPersonality}');
  print('- 친밀도: ${updatedCat.growth}%');
  print('- 행동 횟수: ${updatedCat.actionCounts}');
  print('- 도감 등록 가능: ${updatedCat.canComplete}');
  print('');
  
  // 3. 친밀도 100% 달성
  updatedCat = updatedCat.copyWith(
    growth: 100.0,
    personality: updatedCat.calculatedPersonality,
  );
  
  print('💖 친밀도 100% 달성:');
  print('- 성격: ${updatedCat.personalityDescription} ${updatedCat.personalityEmoji}');
  print('- 도감 등록 가능: ${updatedCat.canComplete}');
  print('');
  
  // 4. 도감 등록
  final collectedAnimal = CollectedAnimal.completed(
    speciesId: updatedCat.speciesId,
    nickname: updatedCat.nickname,
    personality: updatedCat.personality.toString().split('.').last,
  );
  
  print('📖 도감 등록 완료:');
  print('- 이름: ${collectedAnimal.nickname}');
  print('- 성격: ${collectedAnimal.personalityDisplayName}');
  print('- 완료 여부: ${collectedAnimal.isCompleted}');
  print('- 상태: ${collectedAnimal.statusDescription}');
  print('');
  
  // 5. 동물 종족 정보 확인
  final catSpecies = AnimalData.getSpeciesById('cat');
  if (catSpecies != null) {
    print('🐱 고양이 종족 정보:');
    print('- 이름: ${catSpecies.name}');
    print('- 등급: ${catSpecies.rarityStars}');
    print('- 기본 이모지: ${catSpecies.baseEmoji}');
    print('- 식탐쟁이 이모지: ${catSpecies.getPersonalityEmoji('foodie')}');
    print('- 설명: ${catSpecies.flavorText}');
    print('');
  }
  
  // 6. 다른 성격으로 키우기 테스트
  print('🏃 운동선수 성격으로 키우기:');
  var athleteCat = cat;
  for (int i = 0; i < 15; i++) {
    athleteCat = athleteCat.copyWith(
      actionCounts: {
        ...athleteCat.actionCounts,
        'train': (athleteCat.actionCounts['train'] ?? 0) + 1,
      },
      growth: (athleteCat.growth + 7).clamp(0, 100),
    );
  }
  
  athleteCat = athleteCat.copyWith(
    growth: 100.0,
    personality: athleteCat.calculatedPersonality,
  );
  
  print('- 성격: ${athleteCat.personalityDescription} ${athleteCat.personalityEmoji}');
  print('- 계산된 성격: ${athleteCat.calculatedPersonality}');
  print('- 행동 횟수: ${athleteCat.actionCounts}');
  
  if (catSpecies != null) {
    print('- 운동선수 이모지: ${catSpecies.getPersonalityEmoji('athlete')}');
  }
  
  print('\n✅ 성격 시스템 테스트 완료!');
  print('🎉 진화 시스템이 성격 시스템으로 성공적으로 변경되었습니다!');
} 