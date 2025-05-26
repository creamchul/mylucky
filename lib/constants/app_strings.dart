/// 앱에서 사용하는 문자열 상수들
class AppStrings {
  AppStrings._(); // Private constructor

  // App Info
  static const String appName = 'MyLucky';
  static const String appVersion = '1.0.0';
  
  // Home Page
  static const String homeGreeting = '안녕하세요, {name}님!';
  static const String homeSubtitle = '오늘은 어떤 행운이 기다리고 있을까요?';
  static const String homeBottomText = '✨ 매일 새로운 운세와 미션으로 행운을 만나보세요 ✨';
  static const String welcomeNewUser = 'MyLucky에 오신 것을 환영합니다!';
  static const String nicknamePrompt = '랭킹에 표시될 닉네임을 입력해주세요.';
  static const String nicknameHint = '닉네임 (최대 10자)';
  static const String startButton = '시작하기';
  
  // Attendance
  static const String consecutiveAttendance = '연속 출석';
  static const String congratulations = '🎉 축하합니다! 🎉';
  static const String attendanceAchieved = '{days}일 연속 출석 달성!';
  static const String thankYou = '고마워요!';
  
  // Fortune
  static const String fortuneTitle = '오늘의 운세';
  static const String fortuneSubtitle = '당신만을 위한 특별한 메시지';
  static const String fortuneResult = '운세 결과';
  static const String todaysFortune = '오늘 뽑으신 운세';
  static const String shareFortune = '운세 공유하기';
  static const String drawAgain = '다시 뽑기';
  static const String drawTomorrow = '내일 다시 뽑기';
  static const String backToHome = '홈으로 돌아가기';
  
  // Mission
  static const String missionTitle = '오늘의 미션';
  static const String missionSubtitle = '작은 실천으로 만드는 변화';
  static const String missionComplete = '미션 완료하기';
  static const String missionCompleted = '미션 완료됨';
  static const String missionCompletedTitle = '🎉 미션 완료!';
  static const String missionCompletedMessage = '오늘의 미션을 성공적으로 완료했습니다!\n작은 실천이 큰 변화를 만들어요.';
  
  // Ranking
  static const String rankingTitle = 'TOP10 랭킹';
  static const String scoreCalculation = '점수 계산 방식';
  static const String scoreFormula = '연속 출석일 × 10점 + 미션 성공률 × 100점 + 총 운세 × 1점';
  static const String currentUser = '나';
  static const String loadingRanking = '랭킹을 불러오는 중...';
  static const String noRankingData = '아직 랭킹 데이터가 없어요';
  static const String rankingDescription = '활동하시는 분들이 늘어나면 랭킹이 표시됩니다!';
  
  // History
  static const String historyTitle = '내 운세 기록';
  static const String loadingHistory = '기록을 불러오는 중...';
  static const String noHistoryData = '아직 운세 기록이 없어요';
  static const String firstFortunePrompt = '첫 번째 운세를 뽑아보세요!';
  static const String goToFortune = '운세 뽑으러 가기';
  
  // More Menu
  static const String moreMenu = '더보기';
  static const String myHistory = '내 기록 보기';
  static const String myHistorySubtitle = '지금까지의 운세 기록을 확인하세요';
  static const String rankingSubtitle = '다른 사용자들과 점수를 비교해보세요';
  static const String themeSettings = '테마 설정';
  static const String themeSubtitle = '앱의 색상과 테마를 변경하세요';
  static const String feedback = '피드백 보내기';
  static const String feedbackSubtitle = '의견이나 제안사항을 알려주세요';
  static const String appInfo = '앱 정보';
  static const String appInfoSubtitle = 'MyLucky 버전 및 개발자 정보';
  static const String bottomMessage = 'MyLucky와 함께하는\n특별한 하루를 만들어보세요!';
  
  // Common
  static const String confirm = '확인';
  static const String cancel = '취소';
  static const String back = '돌아가기';
  static const String loading = '불러오는 중...';
  static const String error = '오류가 발생했습니다';
  static const String anonymous = '익명 사용자';
  static const String webUser = '웹 사용자';
  
  // Error Messages
  static const String firebaseInitError = 'Firebase 초기화 실패';
  static const String userCreateError = '사용자 생성 실패';
  static const String attendanceCheckError = '출석 체크 실패';
  static const String missionSaveError = '미션 완료 저장 실패';
  static const String shareError = '공유 실패';
  static const String loadError = '불러오는 중 오류가 발생했습니다';
  
  // Features in Development
  static const String themeInDevelopment = '테마 설정 기능은 준비 중입니다';
  static const String feedbackInDevelopment = '피드백 기능은 준비 중입니다';
  
  // App Description
  static const String appDescription = '당신의 일상에 작은 행운과 변화를 가져다주는 운세 앱입니다.';
  static const String appFeatures = '✨ 매일 새로운 운세\n🎯 일일 미션 도전\n🏆 친구들과 랭킹 경쟁\n📱 간편한 공유';
}