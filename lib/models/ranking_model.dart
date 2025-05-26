import '../utils/utils.dart';

class RankingModel {
  final String userId;
  final String nickname;
  final int score;
  final int consecutiveDays;
  final int rank;

  const RankingModel({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.consecutiveDays,
    required this.rank,
  });

  // Firebase 문서에서 RankingModel 생성
  factory RankingModel.fromFirestore(String userId, Map<String, dynamic> data, int rank) {
    return RankingModel(
      userId: userId,
      nickname: data['nickname'] as String? ?? '익명',
      score: data['score'] as int? ?? 0,
      consecutiveDays: data['consecutiveDays'] as int? ?? 0,
      rank: rank,
    );
  }

  // UserModel에서 RankingModel 생성
  factory RankingModel.fromUser(String userId, Map<String, dynamic> userData, int rank) {
    return RankingModel(
      userId: userId,
      nickname: userData['nickname'] as String? ?? '익명',
      score: userData['score'] as int? ?? 0,
      consecutiveDays: userData['consecutiveDays'] as int? ?? 0,
      rank: rank,
    );
  }

  // JSON에서 RankingModel 생성 (웹용)
  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      userId: json['userId'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '익명',
      score: json['score'] as int? ?? 0,
      consecutiveDays: json['consecutiveDays'] as int? ?? 0,
      rank: json['rank'] as int? ?? 0,
    );
  }

  // JSON으로 변환 (웹용)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'score': score,
      'consecutiveDays': consecutiveDays,
      'rank': rank,
    };
  }

  // 순위 표시 (1위, 2위, 3위)
  String get rankDisplay => TextUtils.formatRank(rank);

  // 상위 3위인지 확인
  bool get isTopThree => rank <= 3;

  // 점수 포맷팅 (1,000점 형식)
  String get formattedScore => TextUtils.formatScore(score);

  // 연속 출석일 포맷팅
  String get formattedConsecutiveDays => TextUtils.formatConsecutiveDays(consecutiveDays);

  // 닉네임 표시 (길이 제한)
  String get displayNickname => TextUtils.formatNickname(nickname);

  // 랭킹 변화 표시를 위한 이전 순위와 비교
  String getRankChangeIcon(int? previousRank) {
    return TextUtils.getRankChangeIcon(rank, previousRank);
  }

  // copyWith 메서드
  RankingModel copyWith({
    String? userId,
    String? nickname,
    int? score,
    int? consecutiveDays,
    int? rank,
  }) {
    return RankingModel(
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      score: score ?? this.score,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      rank: rank ?? this.rank,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RankingModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'RankingModel(userId: $userId, nickname: $nickname, rank: $rank, score: $score)';
  }
}
