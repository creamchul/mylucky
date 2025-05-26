import 'package:cloud_firestore/cloud_firestore.dart';

enum FocusSessionStatus {
  running, // 집중 진행 중
  paused, // 일시정지 (MVP에서는 미사용 고려)
  completed, // 집중 성공
  abandoned, // 집중 포기
}

enum TreeType {
  basic, // 기본 나무 (추후 확장 가능)
  // oak,
  // cherryBlossom,
}

class FocusSessionModel {
  final String id;
  final String userId;
  final int durationMinutesSet; // 사용자가 설정한 집중 시간 (분)
  final int elapsedSeconds; // 실제 집중한 시간 (초) - 초 단위로 관리하는 것이 더 정밀
  final FocusSessionStatus status;
  final TreeType treeType; // 선택한 나무 종류
  final DateTime createdAt;
  final DateTime? endedAt; // 완료 또는 포기 시간
  final String? treeAssetPath; // 현재 나무 이미지 에셋 경로 (성장 단계에 따라 변경)

  FocusSessionModel({
    required this.id,
    required this.userId,
    required this.durationMinutesSet,
    this.elapsedSeconds = 0,
    this.status = FocusSessionStatus.running,
    this.treeType = TreeType.basic, // 기본값
    DateTime? createdAt,
    this.endedAt,
    this.treeAssetPath, 
  }) : createdAt = createdAt ?? DateTime.now();

  // 분을 초로 변환
  int get durationSecondsSet => durationMinutesSet * 60;

  // 남은 시간 (초)
  int get remainingSeconds {
    final remaining = durationSecondsSet - elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  // 진행률 (0.0 ~ 1.0)
  double get progress {
    if (durationSecondsSet == 0) return 0.0;
    return elapsedSeconds / durationSecondsSet;
  }

  // 성장 단계 (예시: 4단계)
  int get growthStage {
    if (progress < 0.25) return 1; // 씨앗
    if (progress < 0.50) return 2; // 새싹
    if (progress < 0.75) return 3; // 작은 나무
    return 4; // 큰 나무
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
    int? durationMinutesSet,
    int? elapsedSeconds,
    FocusSessionStatus? status,
    TreeType? treeType,
    DateTime? createdAt,
    DateTime? endedAt,
    bool markEndedAtAsNull = false, // endedAt을 명시적으로 null로 설정하기 위한 플래그
    String? treeAssetPath,
    bool markTreeAssetPathAsNull = false, 
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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