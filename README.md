# MyLucky

매일의 작은 행운을 발견하고, 긍정적인 습관을 만들어가는 Flutter 앱입니다! 🍀

## 주요 기능

- 🎲 **랜덤 메시지 시스템**: 매일 새로운 격려 메시지와 긍정적인 문구를 제공합니다
- 🏆 **챌린지 시스템**: 기존 미션을 개선한 체계적인 도전 과제로 습관 형성을 도와줍니다
- 🐾 **동물 클릭커 게임**: 귀여운 동물들과 상호작용하며 성장시키는 재미있는 게임
- 🌳 **집중 모드 (포레스트)**: 포모도로 타이머로 집중하며 나무를 키우는 기능
- 📊 **랭킹 시스템**: 다른 사용자들과 포인트를 경쟁하는 소셜 기능
- ✨ **출석 체크**: 연속 출석으로 보상을 받는 시스템
- 💫 **아름다운 UI**: Material Design 3을 활용한 현대적이고 직관적인 인터페이스

## 시작하기

이 프로젝트는 Flutter로 개발된 앱입니다.

### 실행 방법

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run

# 테스트 실행
flutter test
```

### 지원 플랫폼

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## 앱 구조

```
lib/
├── main.dart                 # 앱 진입점
├── pages/                    # 화면들
│   ├── home_page.dart        # 메인 홈 화면
│   ├── fortune_result_page.dart  # 랜덤 메시지 결과
│   ├── mission_page.dart     # 챌린지 화면
│   ├── animal_clicker_page.dart  # 동물 클릭커 게임
│   ├── my_forest_page.dart   # 집중 모드
│   └── more_menu_page.dart   # 더보기 메뉴
├── models/                   # 데이터 모델들
├── services/                 # 비즈니스 로직
├── data/                     # 정적 데이터
├── constants/                # 상수들 (색상, 문자열)
└── utils/                    # 유틸리티 함수들
```

## 기술 스택

- **Flutter**: 멀티플랫폼 앱 개발
- **Firebase**: 백엔드 서비스 (Firestore, Authentication)
- **애니메이션**: Lottie, Rive, Flutter Animate
- **로컬 저장소**: SharedPreferences
- **공유 기능**: Share Plus

## 개발 환경

- Flutter SDK: 3.3.2+
- Dart: 3.3.2+

## 라이선스

이 프로젝트는 개인 학습 목적으로 만들어졌습니다.
