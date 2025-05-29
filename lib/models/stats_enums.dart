/// 통계 기간 enum
enum StatsPeriod {
  daily('일일', '오늘'),
  weekly('주간', '이번 주'),
  monthly('월간', '이번 달'),
  all('전체', '전체 기간');

  const StatsPeriod(this.displayName, this.description);
  final String displayName;
  final String description;
} 