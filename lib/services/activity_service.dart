import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';

class ActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'activities';

  /// 사용자의 모든 활동 조회
  static Future<List<ActivityModel>> getUserActivities(String userId) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final activities = query.docs
          .map((doc) => ActivityModel.fromFirestore(doc.id, doc.data()))
          .toList();
      
      // 기본 활동이 위로 오도록 정렬
      activities.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.name.compareTo(b.name);
      });
      
      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('활동 목록 조회 실패: $e');
      }
      return [];
    }
  }

  /// 사용자용 기본 활동들 초기화
  static Future<bool> initializeDefaultActivities(String userId) async {
    try {
      // 이미 기본 활동이 있는지 확인
      final existingActivities = await getUserActivities(userId);
      final hasDefaultActivities = existingActivities.any((activity) => activity.isDefault);
      
      if (hasDefaultActivities) {
        if (kDebugMode) {
          print('기본 활동이 이미 존재합니다.');
        }
        return true;
      }

      // 기본 활동들 생성
      final defaultActivities = DefaultActivities.createForUser(userId);
      
      // Firestore에 배치로 저장
      final batch = _firestore.batch();
      for (final activity in defaultActivities) {
        final docRef = _firestore.collection(_collectionName).doc(activity.id);
        batch.set(docRef, activity.toFirestore());
      }
      
      await batch.commit();
      
      if (kDebugMode) {
        print('기본 활동 ${defaultActivities.length}개가 생성되었습니다.');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('기본 활동 초기화 실패: $e');
      }
      return false;
    }
  }

  /// 새 활동 저장
  static Future<bool> saveActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(activity.id)
          .set(activity.toFirestore());

      if (kDebugMode) {
        print('활동 저장 완료: ${activity.name}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('활동 저장 실패: $e');
      }
      return false;
    }
  }

  /// 활동 수정
  static Future<bool> updateActivity(ActivityModel activity) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(activity.id)
          .update(activity.toFirestore());

      if (kDebugMode) {
        print('활동 수정 완료: ${activity.name}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('활동 수정 실패: $e');
      }
      return false;
    }
  }

  /// 활동 삭제 (기본 활동도 삭제 가능)
  static Future<bool> deleteActivity(String activityId, bool isDefault) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(activityId)
          .delete();

      if (kDebugMode) {
        print('활동 삭제 완료: $activityId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('활동 삭제 실패: $e');
      }
      return false;
    }
  }

  /// 활동 이름 중복 확인
  static Future<bool> isActivityNameExists(String userId, String name, {String? excludeId}) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('name', isEqualTo: name)
          .get();

      // 수정 시 자기 자신은 제외
      final existingActivities = query.docs
          .where((doc) => excludeId == null || doc.id != excludeId)
          .toList();

      return existingActivities.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('활동 이름 중복 확인 실패: $e');
      }
      return false;
    }
  }

  /// 특정 활동 조회
  static Future<ActivityModel?> getActivity(String activityId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(activityId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ActivityModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('활동 조회 실패: $e');
      }
      return null;
    }
  }

  /// 사용자 정의 활동만 조회 (기본 활동 제외)
  static Future<List<ActivityModel>> getCustomActivities(String userId) async {
    try {
      final query = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('isDefault', isEqualTo: false)
          .get();

      final activities = query.docs
          .map((doc) => ActivityModel.fromFirestore(doc.id, doc.data()))
          .toList();
      
      // 이름순 정렬
      activities.sort((a, b) => a.name.compareTo(b.name));
      
      return activities;
    } catch (e) {
      if (kDebugMode) {
        print('사용자 정의 활동 조회 실패: $e');
      }
      return [];
    }
  }

  /// 활동 통계 조회 (감정일기에서 가장 많이 사용된 활동들)
  static Future<Map<String, int>> getActivityUsageStats(String userId, {int? days}) async {
    try {
      // TODO: MoodService에서 활동 통계를 가져와야 함
      // 현재는 임시로 빈 맵 반환
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('활동 사용 통계 조회 실패: $e');
      }
      return {};
    }
  }
} 