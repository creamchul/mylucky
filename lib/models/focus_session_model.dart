import 'package:cloud_firestore/cloud_firestore.dart';

enum FocusSessionStatus {
  running, // 집중 진행 중
  paused, // 일시정지 (MVP에서는 미사용 고려)
  completed, // 집중 성공
  abandoned, // 집중 포기
}

enum FocusMode {
  timer,     // 타이머 모드 (기존) - 목표 시간 설정
  stopwatch, // 스톱워치 모드 (신규) - 무제한 시간 측정
}

enum TreeType {
  basic, // 기본 나무 (추후 확장 가능)
  // oak,
  // cherryBlossom,
}

class FocusSessionModel {
  final String id;
  final String userId;
  final String? categoryId; // 카테고리 ID 추가
  final FocusMode focusMode; // 새로운 필드: 집중 모드
  final int durationMinutesSet; // 타이머 모드: 사용자가 설정한 집중 시간 (분)
  final int elapsedSeconds; // 실제 집중한 시간 (초) - 초 단위로 관리하는 것이 더 정밀
  final FocusSessionStatus status;
  final TreeType treeType; // 선택한 나무 종류
  final DateTime createdAt;
  final DateTime? endedAt; // 완료 또는 포기 시간
  final String? treeAssetPath; // 현재 나무 이미지 에셋 경로 (성장 단계에 따라 변경)

  FocusSessionModel({
    required this.id,
    required this.userId,
    this.categoryId, // 카테고리 ID 생성자 파라미터 추가
    this.focusMode = FocusMode.timer, // 기본값: 타이머 모드
    required this.durationMinutesSet,
    this.elapsedSeconds = 0,
    this.status = FocusSessionStatus.running,
    this.treeType = TreeType.basic, // 기본값
    DateTime? createdAt,
    this.endedAt,
    this.treeAssetPath, 
  }) : createdAt = createdAt ?? DateTime.now();

  // 스톱워치 모드 여부 확인
  bool get isStopwatchMode => focusMode == FocusMode.stopwatch;

  // 분을 초로 변환 (타이머 모드에서만 사용)
  int get durationSecondsSet => durationMinutesSet * 60;

  // 남은 시간 (초) - 타이머 모드에서만 의미있음
  int get remainingSeconds {
    if (isStopwatchMode) return 0; // 스톱워치 모드에서는 남은 시간 개념 없음
    final remaining = durationSecondsSet - elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  // 진행률 (0.0 ~ 1.0)
  double get progress {
    if (isStopwatchMode) {
      // 스톱워치 모드: 시간 기반 성장 단계
      return _getStopwatchProgress();
    }
    
    // 타이머 모드: 기존 로직
    if (durationSecondsSet == 0) return 0.0;
    final calculated = elapsedSeconds / durationSecondsSet;
    return calculated.clamp(0.0, 1.0); // 안전한 범위로 제한
  }

  // 스톱워치 모드 진행률 계산
  double _getStopwatchProgress() {
    final minutes = elapsedSeconds / 60;
    if (minutes < 15) return minutes / 15 * 0.25; // 0-15분: 0-25%
    if (minutes < 30) return 0.25 + (minutes - 15) / 15 * 0.25; // 15-30분: 25-50%
    if (minutes < 60) return 0.50 + (minutes - 30) / 30 * 0.25; // 30-60분: 50-75%
    if (minutes < 90) return 0.75 + (minutes - 60) / 30 * 0.20; // 60-90분: 75-95%
    return 0.95 + ((minutes - 90) / 60 * 0.05).clamp(0.0, 0.05); // 90분+: 95-100%
  }

  // 성장 단계
  int get growthStage {
    if (isStopwatchMode) {
      // 스톱워치 모드: 시간 기반 성장 (기존 로직 유지)
      final minutes = elapsedSeconds / 60;
      if (minutes < 15) return 1; // 🌱 씨앗
      if (minutes < 30) return 2; // 🌿 새싹
      if (minutes < 60) return 3; // 🌳 작은 나무
      if (minutes < 90) return 4; // 🌲 큰 나무
      return 5; // 🎋 거대한 나무 (보너스)
    }
    
    // 타이머 모드: 완료 시에만 최종 단계, 진행 중에는 단계별 성장
    if (status == FocusSessionStatus.completed) {
      return 5; // 완료 시 최고 단계 (🎋)
    }
    
    // 진행 중일 때는 진행률에 따른 4단계 성장
    if (progress < 0.25) return 1; // 🌱 씨앗
    if (progress < 0.50) return 2; // 🌿 새싹  
    if (progress < 0.75) return 3; // 🌳 작은 나무
    return 4; // 🌲 큰 나무
  }

  // 경과 시간 포맷 (스톱워치 모드용)
  String get formattedElapsedTime {
    final hours = elapsedSeconds ~/ 3600;
    final minutes = (elapsedSeconds % 3600) ~/ 60;
    final seconds = elapsedSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 스톱워치 모드 보상 계산
  int get stopwatchRewardPoints {
    if (!isStopwatchMode) return 0;
    
    final minutes = elapsedSeconds ~/ 60;
    int basePoints = minutes; // 기본: 1분 = 1P
    int bonusPoints = 0;
    
    // 보너스 계산
    if (minutes >= 120) bonusPoints += 100; // 2시간 이상
    else if (minutes >= 90) bonusPoints += 60; // 1.5시간 이상
    else if (minutes >= 60) bonusPoints += 30; // 1시간 이상
    else if (minutes >= 30) bonusPoints += 10; // 30분 이상
    
    return basePoints + bonusPoints;
  }

  String get statusDisplayName {
    switch (status) {
      case FocusSessionStatus.running:
        return '집중 중';
      case FocusSessionStatus.paused:
        return '일시정지';
      case FocusSessionStatus.completed:
        return '집중 완료';
      case FocusSessionStatus.abandoned:
        return '집중 포기';
    }
  }

  // TreeType에 따른 기본 에셋 경로 또는 초기 이미지 반환 로직
  // 이 부분은 tree_widget.dart 또는 FocusService에서 관리될 수 있음
  // 예: static String getInitialTreeAsset(TreeType type) { ... }


  FocusSessionModel copyWith({
    String? id,
    String? userId,
    String? categoryId, // 카테고리 ID 추가
    FocusMode? focusMode,
    int? durationMinutesSet,
    int? elapsedSeconds,
    FocusSessionStatus? status,
    TreeType? treeType,
    DateTime? createdAt,
    DateTime? endedAt,
    bool markEndedAtAsNull = false, // endedAt을 명시적으로 null로 설정하기 위한 플래그
    String? treeAssetPath,
    bool markTreeAssetPathAsNull = false, 
    bool markCategoryIdAsNull = false, // 카테고리 ID null 설정 플래그 추가
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: markCategoryIdAsNull ? null : (categoryId ?? this.categoryId),
      focusMode: focusMode ?? this.focusMode,
      durationMinutesSet: durationMinutesSet ?? this.durationMinutesSet,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      treeType: treeType ?? this.treeType,
      createdAt: createdAt ?? this.createdAt,
      endedAt: markEndedAtAsNull ? null : (endedAt ?? this.endedAt),
      treeAssetPath: markTreeAssetPathAsNull ? null : (treeAssetPath ?? this.treeAssetPath),
    );
  }

  factory FocusSessionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FocusSessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      categoryId: data['categoryId'], // 카테고리 ID 추가
      focusMode: FocusMode.values.firstWhere(
            (e) => e.toString() == data['focusMode'],
            orElse: () => FocusMode.timer, // 기본값 또는 오류 처리
          ),
      durationMinutesSet: data['durationMinutesSet'] ?? 10,
      elapsedSeconds: data['elapsedSeconds'] ?? 0,
      status: FocusSessionStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
            orElse: () => FocusSessionStatus.abandoned, // 기본값 또는 오류 처리
          ),
      treeType: TreeType.values.firstWhere(
            (e) => e.toString() == data['treeType'],
            orElse: () => TreeType.basic, // 기본값
          ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
      treeAssetPath: data['treeAssetPath'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (categoryId != null) 'categoryId': categoryId, // 카테고리 ID 추가
      'focusMode': focusMode.toString(),
      'durationMinutesSet': durationMinutesSet,
      'elapsedSeconds': elapsedSeconds,
      'status': status.toString(),
      'treeType': treeType.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (endedAt != null) 'endedAt': Timestamp.fromDate(endedAt!),
      if (treeAssetPath != null) 'treeAssetPath': treeAssetPath,
    };
  }

  // SharedPreferences용 Map 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      if (categoryId != null) 'categoryId': categoryId, // 카테고리 ID 추가
      'focusMode': focusMode.toString(),
      'durationMinutesSet': durationMinutesSet,
      'elapsedSeconds': elapsedSeconds,
      'status': status.toString(),
      'treeType': treeType.toString(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      if (endedAt != null) 'endedAt': endedAt!.millisecondsSinceEpoch,
      if (treeAssetPath != null) 'treeAssetPath': treeAssetPath,
    };
  }

  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'], // 카테고리 ID 추가
      focusMode: FocusMode.values.firstWhere(
        (e) => e.toString() == map['focusMode'],
        orElse: () => FocusMode.timer,
      ),
      durationMinutesSet: map['durationMinutesSet'] ?? 10,
      elapsedSeconds: map['elapsedSeconds'] ?? 0,
      status: FocusSessionStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => FocusSessionStatus.abandoned,
      ),
      treeType: TreeType.values.firstWhere(
        (e) => e.toString() == map['treeType'],
        orElse: () => TreeType.basic,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      endedAt: map['endedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endedAt']) : null,
      treeAssetPath: map['treeAssetPath'],
    );
  }
} 