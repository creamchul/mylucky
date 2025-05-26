/// 날짜 관련 유틸리티 함수들
class DateUtils {
  DateUtils._(); // Private constructor

  /// 날짜 포맷팅 (YYYY-MM-DD)
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 시간 포맷팅 (HH:MM)
  static String formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 월/일 형식 (MM/DD)
  static String formatMonthDay(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  /// 오늘 날짜인지 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return today.isAtSameMomentAs(targetDate);
  }

  /// 며칠 전인지 계산
  static int daysAgo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return today.difference(targetDate).inDays;
  }

  /// 상대적 날짜 표시 (예: "오늘", "1일 전", "2일 전")
  static String getRelativeDateString(DateTime date) {
    final days = daysAgo(date);
    if (days == 0) return '오늘';
    if (days == 1) return '어제';
    return '$days일 전';
  }

  /// 한국어 요일 반환
  static String getWeekdayKorean(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// 오늘의 시작 시간 (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 오늘의 끝 시간 (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// 두 날짜가 연속인지 확인 (하루 차이)
  static bool isConsecutive(DateTime date1, DateTime date2) {
    final d1 = startOfDay(date1);
    final d2 = startOfDay(date2);
    return d1.difference(d2).inDays.abs() == 1;
  }

  /// 날짜 범위 생성 (startDate부터 endDate까지)
  static List<DateTime> getDateRange(DateTime startDate, DateTime endDate) {
    final dates = <DateTime>[];
    var current = startOfDay(startDate);
    final end = startOfDay(endDate);
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }
} 