/// 텍스트 관련 유틸리티 함수들
class TextUtils {
  TextUtils._(); // Private constructor

  /// 닉네임 표시 (길이 제한)
  static String formatNickname(String nickname, {int maxLength = 8}) {
    if (nickname.trim().isEmpty) {
      return '익명 사용자';
    }
    
    final trimmed = nickname.trim();
    if (trimmed.length > maxLength) {
      return '${trimmed.substring(0, maxLength)}...';
    }
    return trimmed;
  }

  /// 점수 포맷팅 (1,000점 형식)
  static String formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K점';
    }
    return '$score점';
  }

  /// 연속 출석일 포맷팅
  static String formatConsecutiveDays(int days) {
    if (days == 0) return '0일';
    if (days >= 100) {
      return '${days}일 🔥';
    }
    if (days >= 30) {
      return '${days}일 ⭐';
    }
    if (days >= 7) {
      return '${days}일 ✨';
    }
    return '${days}일';
  }

  /// 순위 표시 (1위, 2위, 3위)
  static String formatRank(int rank) {
    switch (rank) {
      case 1:
        return '🥇 1위';
      case 2:
        return '🥈 2위';
      case 3:
        return '🥉 3위';
      default:
        return '$rank위';
    }
  }

  /// 텍스트 줄임 처리
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  /// 숫자를 한국어 형식으로 포맷팅 (예: 1,234)
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// 퍼센트 포맷팅
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// 미션 성공률 표시
  static String formatMissionSuccessRate(int completed, int total) {
    if (total == 0) return '0%';
    final rate = (completed / total) * 100;
    return formatPercentage(rate);
  }

  /// 안전한 문자열 비교 (null 체크 포함)
  static bool safeEquals(String? str1, String? str2) {
    if (str1 == null && str2 == null) return true;
    if (str1 == null || str2 == null) return false;
    return str1 == str2;
  }

  /// 첫 글자 대문자로 변환
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// 랭킹 변화 아이콘
  static String getRankChangeIcon(int currentRank, int? previousRank) {
    if (previousRank == null) return '';
    
    if (currentRank < previousRank) {
      return '📈'; // 순위 상승
    } else if (currentRank > previousRank) {
      return '📉'; // 순위 하락
    } else {
      return '➖'; // 순위 유지
    }
  }

  /// 축하 메시지 생성
  static String getCelebrationMessage(int days) {
    switch (days) {
      case 3:
        return '3일 연속 출석! 좋은 습관을 만들어가고 있어요!';
      case 7:
        return '일주일 연속 출석! 정말 대단해요!';
      case 14:
        return '2주 연속 출석! 꾸준함이 빛나는 순간이에요!';
      case 30:
        return '한 달 연속 출석! 놀라운 의지력이네요!';
      case 50:
        return '50일 연속 출석! 진정한 MyLucky 마스터예요!';
      case 100:
        return '100일 연속 출석! 전설적인 기록을 세우셨네요!';
      default:
        if (days >= 100 && days % 100 == 0) {
          return '$days일 연속 출석! 경이로운 기록입니다!';
        }
        return '연속 출석 달성! 계속해서 행운을 쌓아가세요!';
    }
  }
} 