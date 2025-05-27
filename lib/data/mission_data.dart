// 챌린지 데이터
// 이 파일에서 큐레이션된 챌린지와 개인 목표를 관리합니다.
// 새로운 챌린지를 추가하거나 기존 챌린지를 수정할 때 이 파일만 편집하세요.

import 'dart:math';

enum ChallengeCategory {
  health('건강한 하루', '💪', '몸과 마음의 건강을 위한 챌린지'),
  growth('자기계발', '📚', '성장과 학습을 위한 챌린지'),
  mindfulness('마음 챙김', '🧘', '평온과 집중을 위한 챌린지'),
  productivity('생산성 향상', '🎯', '효율적인 하루를 위한 챌린지'),
  social('인간관계', '💝', '소중한 사람들과의 연결을 위한 챌린지'),
  creativity('창의성', '🎨', '창의력과 표현력을 기르는 챌린지');

  const ChallengeCategory(this.displayName, this.emoji, this.description);
  final String displayName;
  final String emoji;
  final String description;
}

enum ChallengeDifficulty {
  easy('쉬움', 1, '누구나 쉽게 시작할 수 있어요'),
  medium('보통', 2, '조금의 노력이 필요해요'),
  hard('어려움', 3, '의지력이 필요한 도전이에요');

  const ChallengeDifficulty(this.displayName, this.level, this.description);
  final String displayName;
  final int level;
  final String description;
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final int durationDays;
  final int pointsReward;
  final List<String> tips;
  final String emoji;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationDays,
    required this.pointsReward,
    required this.tips,
    required this.emoji,
  });
}

class ChallengeData {
  // 큐레이션된 챌린지 목록
  static const List<Challenge> curatedChallenges = [
    // 🌅 건강한 하루 시작하기 챌린지
    Challenge(
      id: 'early_bird',
      title: '일찍 일어나기',
      description: '매일 7시 전에 일어나서 하루를 활기차게 시작해보세요',
      category: ChallengeCategory.health,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 21,
      pointsReward: 50,
      tips: ['전날 일찍 잠자리에 들기', '알람을 침실 밖에 두기', '일어나자마자 커튼 열기'],
      emoji: '🌅',
    ),
    Challenge(
      id: 'morning_water',
      title: '기상 후 물 마시기',
      description: '일어나자마자 물 한 잔으로 몸을 깨워보세요',
      category: ChallengeCategory.health,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 7,
      pointsReward: 20,
      tips: ['침대 옆에 물병 준비하기', '미지근한 물이 좋아요', '레몬 한 조각 넣어보기'],
      emoji: '💧',
    ),
    Challenge(
      id: 'morning_stretch',
      title: '아침 스트레칭',
      description: '5분간 간단한 스트레칭으로 몸을 풀어보세요',
      category: ChallengeCategory.health,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 14,
      pointsReward: 35,
      tips: ['목, 어깨, 허리 중심으로', '천천히 부드럽게', '유튜브 영상 활용하기'],
      emoji: '🤸',
    ),

    // 📚 자기계발 챌린지
    Challenge(
      id: 'daily_reading',
      title: '매일 독서하기',
      description: '하루 10페이지씩 책을 읽으며 지식을 쌓아보세요',
      category: ChallengeCategory.growth,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 30,
      pointsReward: 80,
      tips: ['관심 있는 분야부터 시작', '독서 노트 작성하기', '작은 목표부터 달성'],
      emoji: '📖',
    ),
    Challenge(
      id: 'new_word',
      title: '새로운 단어 배우기',
      description: '매일 새로운 단어 3개를 배우고 사용해보세요',
      category: ChallengeCategory.growth,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 21,
      pointsReward: 45,
      tips: ['단어장 앱 활용하기', '문장으로 만들어보기', '일상 대화에서 사용하기'],
      emoji: '📝',
    ),
    Challenge(
      id: 'skill_practice',
      title: '새로운 기술 연습',
      description: '관심 있는 기술을 매일 30분씩 연습해보세요',
      category: ChallengeCategory.growth,
      difficulty: ChallengeDifficulty.hard,
      durationDays: 66,
      pointsReward: 150,
      tips: ['온라인 강의 활용', '작은 프로젝트 만들기', '꾸준함이 핵심'],
      emoji: '💻',
    ),

    // 🧘 마음 챙김 챌린지
    Challenge(
      id: 'meditation',
      title: '명상하기',
      description: '하루 5분간 조용히 명상하며 마음을 정리해보세요',
      category: ChallengeCategory.mindfulness,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 21,
      pointsReward: 60,
      tips: ['조용한 공간 찾기', '호흡에 집중하기', '명상 앱 활용하기'],
      emoji: '🧘',
    ),
    Challenge(
      id: 'gratitude_journal',
      title: '감사 일기 쓰기',
      description: '매일 감사한 일 3가지를 기록해보세요',
      category: ChallengeCategory.mindfulness,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 14,
      pointsReward: 40,
      tips: ['작은 것부터 감사하기', '구체적으로 적기', '잠들기 전 작성'],
      emoji: '🙏',
    ),
    Challenge(
      id: 'digital_detox',
      title: '디지털 디톡스',
      description: '하루 1시간 동안 모든 디지털 기기를 끄고 휴식해보세요',
      category: ChallengeCategory.mindfulness,
      difficulty: ChallengeDifficulty.hard,
      durationDays: 14,
      pointsReward: 70,
      tips: ['특정 시간대 정하기', '대체 활동 준비하기', '가족과 함께 하기'],
      emoji: '📵',
    ),

    // 🎯 생산성 향상 챌린지
    Challenge(
      id: 'todo_completion',
      title: '투두리스트 완성',
      description: '매일 계획한 할 일 3개를 모두 완료해보세요',
      category: ChallengeCategory.productivity,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 21,
      pointsReward: 55,
      tips: ['현실적인 목표 설정', '우선순위 정하기', '완료 시 체크하기'],
      emoji: '✅',
    ),
    Challenge(
      id: 'focus_time',
      title: '집중 시간 갖기',
      description: '핸드폰 없이 1시간 동안 집중해서 일해보세요',
      category: ChallengeCategory.productivity,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 14,
      pointsReward: 45,
      tips: ['핸드폰 다른 방에 두기', '타이머 설정하기', '집중 음악 활용'],
      emoji: '🎯',
    ),
    Challenge(
      id: 'organize_space',
      title: '공간 정리하기',
      description: '매일 10분씩 주변을 정리하며 깔끔한 환경 만들기',
      category: ChallengeCategory.productivity,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 7,
      pointsReward: 25,
      tips: ['작은 공간부터 시작', '필요 없는 물건 버리기', '정리 후 사진 찍기'],
      emoji: '🧹',
    ),

    // 💝 인간관계 챌린지
    Challenge(
      id: 'daily_contact',
      title: '소중한 사람에게 연락하기',
      description: '매일 가족이나 친구에게 안부 인사를 전해보세요',
      category: ChallengeCategory.social,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 14,
      pointsReward: 35,
      tips: ['간단한 메시지라도 좋아요', '안부 묻기', '고마움 표현하기'],
      emoji: '💌',
    ),
    Challenge(
      id: 'compliment_others',
      title: '타인에게 칭찬하기',
      description: '매일 누군가에게 진심어린 칭찬을 해보세요',
      category: ChallengeCategory.social,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 21,
      pointsReward: 50,
      tips: ['구체적으로 칭찬하기', '진심을 담아서', '작은 것도 인정하기'],
      emoji: '👏',
    ),
    Challenge(
      id: 'help_others',
      title: '작은 도움 주기',
      description: '매일 누군가에게 작은 도움이나 친절을 베풀어보세요',
      category: ChallengeCategory.social,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 14,
      pointsReward: 40,
      tips: ['문 열어주기', '짐 들어주기', '미소 짓기'],
      emoji: '🤝',
    ),

    // 🎨 창의성 챌린지
    Challenge(
      id: 'daily_photo',
      title: '일상 사진 찍기',
      description: '매일 아름다운 순간을 사진으로 기록해보세요',
      category: ChallengeCategory.creativity,
      difficulty: ChallengeDifficulty.easy,
      durationDays: 14,
      pointsReward: 30,
      tips: ['다양한 각도로 촬영', '자연광 활용하기', '감정 담아 찍기'],
      emoji: '📸',
    ),
    Challenge(
      id: 'creative_writing',
      title: '창작 글쓰기',
      description: '매일 짧은 글이나 시를 써보며 창의력을 기르세요',
      category: ChallengeCategory.creativity,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 21,
      pointsReward: 55,
      tips: ['일상에서 영감 찾기', '감정 솔직하게 표현', '완벽하지 않아도 괜찮아요'],
      emoji: '✍️',
    ),
    Challenge(
      id: 'sketch_daily',
      title: '매일 스케치하기',
      description: '간단한 그림이나 스케치로 관찰력을 기르세요',
      category: ChallengeCategory.creativity,
      difficulty: ChallengeDifficulty.medium,
      durationDays: 30,
      pointsReward: 65,
      tips: ['주변 사물 관찰하기', '선 연습부터 시작', '실수도 작품의 일부'],
      emoji: '🎨',
    ),
  ];

  // 간단한 일일 미션 (기존 호환성 유지)
  static const List<String> simpleMissions = [
    '☕ 좋아하는 음료 한 잔과 함께 잠시 여유를 가져보세요',
    '🌱 새로운 것을 하나 배워보거나 시도해보세요',
    '💌 소중한 사람에게 안부 인사를 전해보세요',
    '📖 책 한 페이지라도 읽어보세요',
    '🚶‍♀️ 10분 이상 산책하며 신선한 공기를 마셔보세요',
    '🎵 좋아하는 음악을 들으며 기분을 전환해보세요',
    '🌅 창밖을 보며 깊게 숨을 3번 쉬어보세요',
    '😊 거울을 보며 자신에게 격려의 말을 해주세요',
    '🧹 주변 정리를 하며 마음도 깔끔하게 정돈해보세요',
    '🍎 건강한 간식이나 과일을 드셔보세요',
  ];

  /// 카테고리별 챌린지 가져오기
  static List<Challenge> getChallengesByCategory(ChallengeCategory category) {
    return curatedChallenges.where((challenge) => challenge.category == category).toList();
  }

  /// 난이도별 챌린지 가져오기
  static List<Challenge> getChallengesByDifficulty(ChallengeDifficulty difficulty) {
    return curatedChallenges.where((challenge) => challenge.difficulty == difficulty).toList();
  }

  /// 인기 챌린지 가져오기 (쉬운 것부터 추천)
  static List<Challenge> getPopularChallenges() {
    final popular = curatedChallenges.where((challenge) => 
      challenge.difficulty == ChallengeDifficulty.easy || 
      challenge.difficulty == ChallengeDifficulty.medium
    ).toList();
    popular.shuffle();
    return popular.take(6).toList();
  }

  /// 초보자 추천 챌린지
  static List<Challenge> getBeginnerChallenges() {
    return curatedChallenges.where((challenge) => 
      challenge.difficulty == ChallengeDifficulty.easy &&
      challenge.durationDays <= 14
    ).toList();
  }

  /// 특정 챌린지 찾기
  static Challenge? getChallengeById(String id) {
    try {
      return curatedChallenges.firstWhere((challenge) => challenge.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 날짜 기반 오늘의 간단한 미션 가져오기 (기존 호환성)
  static String getTodaySimpleMission(DateTime date) {
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final seed = dateString.hashCode;
    final index = seed % simpleMissions.length;
    return simpleMissions[index.abs()];
  }

  /// 날짜 기반 오늘의 추천 챌린지 가져오기
  static Challenge getTodayRecommendedChallenge(DateTime date) {
    final dateString = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final seed = dateString.hashCode;
    final index = seed % curatedChallenges.length;
    return curatedChallenges[index.abs()];
  }

  /// 랜덤 챌린지 가져오기
  static Challenge getRandomChallenge() {
    final random = Random();
    return curatedChallenges[random.nextInt(curatedChallenges.length)];
  }

  /// 랜덤 간단한 미션 가져오기 (기존 호환성)
  static String getRandomSimpleMission() {
    final random = Random();
    return simpleMissions[random.nextInt(simpleMissions.length)];
  }

  /// 전체 챌린지 개수
  static int get totalChallenges => curatedChallenges.length;

  /// 카테고리 목록
  static List<ChallengeCategory> get allCategories => ChallengeCategory.values;

  /// 난이도 목록
  static List<ChallengeDifficulty> get allDifficulties => ChallengeDifficulty.values;
}