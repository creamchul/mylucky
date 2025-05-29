# MyLucky

매일의 작은 행운을 발견하고, 긍정적인 습관을 만들어가는 Flutter 앱입니다! 🍀

## 주요 기능

- 🎲 **랜덤 메시지 시스템**: 매일 새로운 격려 메시지와 긍정적인 문구를 제공합니다
- 🏆 **챌린지 시스템**: 기존 미션을 개선한 체계적인 도전 과제로 습관 형성을 도와줍니다
- 🐾 **동물 클릭커 게임**: 귀여운 동물들과 상호작용하며 성장시키는 재미있는 게임
- 🌳 **집중 모드 (포레스트)**: 포모도로 타이머로 집중하며 나무를 키우는 기능
- 🏷️ **카테고리 시스템**: 집중 활동을 분류하고 즐겨찾기로 관리
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
│   ├── focus_setup_page.dart # 집중 설정
│   ├── focusing_page.dart    # 집중 중 화면
│   ├── category_management_page.dart  # 카테고리 관리
│   └── more_menu_page.dart   # 더보기 메뉴
├── models/                   # 데이터 모델들
│   ├── focus_category_model.dart     # 카테고리 모델
│   └── focus_session_model.dart      # 집중 세션 모델
├── services/                 # 비즈니스 로직
│   ├── category_service.dart         # 카테고리 관리
│   └── focus_service.dart            # 집중 세션 관리
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

---

## 🚧 현재 개발 상태 (2025년 5월 30일)

### ✅ Phase 5 완료 (95%): 카테고리 시스템 통합
- 집중 설정에서 카테고리 선택 ✅
- 집중 중 카테고리 정보 표시 ✅
- 통계 페이지 카테고리 필터링 ✅
- 카테고리 관리 및 즐겨찾기 기능 🔧 (수정 중)

### 🔧 알려진 문제
- **즐겨찾기 동기화 문제**: Firebase 업데이트는 성공하지만 UI 반영 안됨
- **Firebase 인덱스 오류**: 복합 쿼리 인덱스 누락으로 카테고리 로딩 실패

### 📋 오늘 작업 (2025년 5월 30일)
- 즐겨찾기 기능 완전 수정 (최우선)
- 집중하기 기능 안정성 개선
- 타이머 정확도 및 백그라운드 처리 개선
- 사용자 경험 최적화

### 📝 개발 문서
- `DEVELOPMENT_LOG.md`: 상세한 개발 기록
- `TODO.md`: 구체적인 작업 계획

---

## 라이선스

이 프로젝트는 개인 학습 목적으로 만들어졌습니다.
