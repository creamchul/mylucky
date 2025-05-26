/// 점수 계산 관련 유틸리티 함수들
class ScoreUtils {
  ScoreUtils._(); // Private constructor

  // 점수 계산 가중치 상수
  static const int attendancePoints = 10;  // 연속 출석일 당 점수
  static const int fortunePoints = 1;      // 운세 1개당 점수
  static const int missionSuccessMultiplier = 100; // 미션 성공률 배수 (100% = 100점)

  /// 총 점수 계산
  /// 공식: (연속 출석일 × 10점) + (미션 성공률 × 100점) + (총 운세 × 1점)
  static int calculateTotalScore({
    required int consecutiveDays,
    required int totalFortunes,
    required int totalMissions,
    required int completedMissions,
  }) {
    final attendanceScore = consecutiveDays * attendancePoints;
    final fortuneScore = totalFortunes * fortunePoints;
    final missionSuccessRate = calculateMissionSuccessRate(completedMissions, totalMissions);
    final missionScore = (missionSuccessRate * missionSuccessMultiplier).round();
    
    return attendanceScore + fortuneScore + missionScore;
  }

  /// 미션 성공률 계산 (0.0 ~ 1.0)
  static double calculateMissionSuccessRate(int completed, int total) {
    if (total == 0) return 0.0;
    return completed / total;
  }

  /// 미션 성공률을 퍼센트로 계산 (0 ~ 100)
  static double calculateMissionSuccessPercentage(int completed, int total) {
    return calculateMissionSuccessRate(completed, total) * 100;
  }

  /// 출석 점수만 계산
  static int calculateAttendanceScore(int consecutiveDays) {
    return consecutiveDays * attendancePoints;
  }

  /// 운세 점수만 계산
  static int calculateFortuneScore(int totalFortunes) {
    return totalFortunes * fortunePoints;
  }

  /// 미션 점수만 계산
  static int calculateMissionScore(int completed, int total) {
    final successRate = calculateMissionSuccessRate(completed, total);
    return (successRate * missionSuccessMultiplier).round();
  }

  /// 점수 상세 분석 (각 영역별 점수와 비율)
  static Map<String, dynamic> getScoreBreakdown({
    required int consecutiveDays,
    required int totalFortunes,
    required int totalMissions,
    required int completedMissions,
  }) {
    final attendanceScore = calculateAttendanceScore(consecutiveDays);
    final fortuneScore = calculateFortuneScore(totalFortunes);
    final missionScore = calculateMissionScore(completedMissions, totalMissions);
    final totalScore = attendanceScore + fortuneScore + missionScore;

    return {
      'attendanceScore': attendanceScore,
      'fortuneScore': fortuneScore,
      'missionScore': missionScore,
      'totalScore': totalScore,
      'attendanceRatio': totalScore > 0 ? (attendanceScore / totalScore) * 100 : 0.0,
      'fortuneRatio': totalScore > 0 ? (fortuneScore / totalScore) * 100 : 0.0,
      'missionRatio': totalScore > 0 ? (missionScore / totalScore) * 100 : 0.0,
      'missionSuccessRate': calculateMissionSuccessPercentage(completedMissions, totalMissions),
    };
  }

  /// 레벨 계산 (점수 기반)
  static int calculateLevel(int score) {
    if (score < 100) return 1;
    if (score < 300) return 2;
    if (score < 600) return 3;
    if (score < 1000) return 4;
    if (score < 1500) return 5;
    if (score < 2500) return 6;
    if (score < 4000) return 7;
    if (score < 6000) return 8;
    if (score < 9000) return 9;
    return 10; // 최대 레벨
  }

  /// 레벨명 반환
  static String getLevelName(int level) {
    switch (level) {
      case 1:
        return '새싹';
      case 2:
        return '모험가';
      case 3:
        return '탐험가';
      case 4:
        return '수행자';
      case 5:
        return '달인';
      case 6:
        return '고수';
      case 7:
        return '전문가';
      case 8:
        return '마스터';
      case 9:
        return '그랜드마스터';
      case 10:
        return '전설';
      default:
        return '새싹';
    }
  }

  /// 다음 레벨까지 필요한 점수
  static int getScoreToNextLevel(int currentScore) {
    final currentLevel = calculateLevel(currentScore);
    if (currentLevel >= 10) return 0; // 최대 레벨
    
    const levelThresholds = [100, 300, 600, 1000, 1500, 2500, 4000, 6000, 9000];
    return levelThresholds[currentLevel] - currentScore;
  }

  /// 점수 달성률 계산 (다음 레벨까지의 진행률)
  static double getProgressToNextLevel(int currentScore) {
    final currentLevel = calculateLevel(currentScore);
    if (currentLevel >= 10) return 1.0; // 최대 레벨
    
    const levelThresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 9000];
    final currentThreshold = levelThresholds[currentLevel - 1];
    final nextThreshold = levelThresholds[currentLevel];
    
    if (nextThreshold == currentThreshold) return 1.0;
    
    return (currentScore - currentThreshold) / (nextThreshold - currentThreshold);
  }

  /// 축하할 만한 점수인지 확인 (특정 마일스톤)
  static bool isScoreMilestone(int score) {
    const milestones = [100, 300, 500, 1000, 1500, 2000, 3000, 5000, 7500, 10000];
    return milestones.contains(score);
  }

  /// 점수 순위 예측 (간단한 구간별 분류)
  static String getScoreRank(int score) {
    if (score >= 5000) return '최상위';
    if (score >= 2000) return '상위';
    if (score >= 1000) return '중상위';
    if (score >= 500) return '중위';
    if (score >= 200) return '중하위';
    return '하위';
  }
} 