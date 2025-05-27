import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../data/mission_data.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========================================
  // 사용자 관련 기능
  // ========================================

  /// 현재 사용자 ID 생성/반환 (기기별 고유 ID)
  static Future<String> getCurrentUserId() async {
    // 간단한 사용자 ID 생성 (실제 앱에서는 Firebase Auth 사용)
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// 사용자 생성
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());

      if (kDebugMode) {
        print('Firebase: 새 사용자 생성 완료 - ${user.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 사용자 생성 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자 정보 조회
  static Future<UserModel?> getUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        if (kDebugMode) {
          print('Firebase: 사용자 정보 조회 완료');
        }
        return UserModel.fromFirestore(userId, userDoc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 사용자 정보 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자 정보 업데이트
  static Future<UserModel> updateUser({
    required UserModel currentUser,
    int? consecutiveDays,
    bool? addFortune,
    bool? addMission,
    bool? completeMission,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(currentUser.id);
      
      // 새로운 값들 계산
      final newConsecutiveDays = consecutiveDays ?? currentUser.consecutiveDays;
      final newTotalFortunes = currentUser.totalFortunes + (addFortune == true ? 1 : 0);
      final newTotalMissions = currentUser.totalMissions + (addMission == true ? 1 : 0);
      final newCompletedMissions = currentUser.completedMissions + (completeMission == true ? 1 : 0);
      
      // 업데이트된 사용자 모델 생성
      final updatedUser = currentUser.copyWith(
        consecutiveDays: newConsecutiveDays,
        totalFortunes: newTotalFortunes,
        totalMissions: newTotalMissions,
        completedMissions: newCompletedMissions,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore(); // 점수 자동 재계산

      // Firebase 업데이트
      await userRef.update(updatedUser.toFirestore());

      if (kDebugMode) {
        print('Firebase: 사용자 정보 업데이트 완료');
      }
      
      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 사용자 정보 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자 정보 업데이트 (간단한 업데이트용)
  static Future<UserModel> updateUserSimple({
    required String userId,
    required Map<String, dynamic> updates,
    required UserModel currentUser,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      // 업데이트된 사용자 모델 생성
      final updatedUser = currentUser.copyWith(
        consecutiveDays: updates['consecutiveDays'],
        lastActiveDate: updates['lastActiveDate'],
      ).withUpdatedScore();

      // Firebase 업데이트
      await userRef.update(updatedUser.toFirestore());

      if (kDebugMode) {
        print('Firebase: 사용자 정보 간단 업데이트 완료');
      }
      
      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 사용자 정보 간단 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 출석 관련 기능
  // ========================================

  /// 오늘 출석 기록 확인
  static Future<Map<String, dynamic>> checkTodayAttendance({
    required String userId,
    required DateTime today,
  }) async {
    try {
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayTimestamp = Timestamp.fromDate(todayStart);

      final query = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: todayTimestamp)
          .limit(1)
          .get();

      final hasAttendanceToday = query.docs.isNotEmpty;
      
      if (hasAttendanceToday) {
        // 이미 출석함 - 연속 출석일수 계산
        final consecutiveDays = await calculateConsecutiveDays();
        
        if (kDebugMode) {
          print('Firebase: 오늘 이미 출석함 - 연속 $consecutiveDays일');
        }
        
        return {
          'isFirstTime': false,
          'consecutiveDays': consecutiveDays,
        };
      }
      
      // 첫 출석 - 출석 기록 추가 후 연속 출석일수 계산
      await addAttendance();
      final consecutiveDays = await calculateConsecutiveDays();
      
      if (kDebugMode) {
        print('Firebase: 오늘 첫 출석 완료 - 연속 $consecutiveDays일');
      }
      
      return {
        'isFirstTime': true,
        'consecutiveDays': consecutiveDays,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 출석 확인 실패 - $e');
      }
      rethrow;
    }
  }

  /// 출석 기록 추가
  static Future<AttendanceModel> addAttendance() async {
    try {
      final attendanceRef = await _firestore.collection('attendance').add({});
      final attendance = AttendanceModel.create(id: attendanceRef.id);
      
      await attendanceRef.set(attendance.toFirestore());

      if (kDebugMode) {
        print('Firebase: 출석 기록 추가 완료');
      }
      
      return attendance;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 출석 기록 추가 실패 - $e');
      }
      rethrow;
    }
  }

  /// 연속 출석일수 계산
  static Future<int> calculateConsecutiveDays() async {
    try {
      final attendanceQuery = await _firestore
          .collection('attendance')
          .orderBy('date', descending: true)
          .get();

      if (attendanceQuery.docs.isEmpty) {
        return 0;
      }

      int consecutiveDays = 0;
      DateTime? lastDate;

      for (var doc in attendanceQuery.docs) {
        final attendance = AttendanceModel.fromFirestore(doc.id, doc.data());
        final dateOnly = DateTime(attendance.date.year, attendance.date.month, attendance.date.day);

        if (lastDate == null) {
          lastDate = dateOnly;
          consecutiveDays = 1;
        } else {
          final expectedPreviousDate = lastDate.subtract(const Duration(days: 1));
          if (dateOnly.year == expectedPreviousDate.year &&
              dateOnly.month == expectedPreviousDate.month &&
              dateOnly.day == expectedPreviousDate.day) {
            consecutiveDays++;
            lastDate = dateOnly;
          } else {
            break;
          }
        }
      }

      if (kDebugMode) {
        print('Firebase: 연속 출석일수 계산 완료 - $consecutiveDays일');
      }

      return consecutiveDays;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 연속 출석일수 계산 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 운세 관련 기능
  // ========================================

  /// 오늘의 운세 기록 확인
  static Future<FortuneModel?> getTodayFortune() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final query = await _firestore
          .collection('draws')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        if (kDebugMode) {
          print('Firebase: 오늘의 운세 기록 발견');
        }
        return FortuneModel.fromFirestore(doc.id, doc.data());
      }

      if (kDebugMode) {
        print('Firebase: 오늘의 운세 기록 없음');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 오늘의 운세 확인 실패 - $e');
      }
      rethrow;
    }
  }

  /// 운세 기록 저장
  static Future<FortuneModel> saveFortune({
    required String message,
    required String mission,
  }) async {
    try {
      final fortuneRef = await _firestore.collection('draws').add({});
      final fortune = FortuneModel.create(
        id: fortuneRef.id,
        message: message,
        mission: mission,
      );
      
      await fortuneRef.set(fortune.toFirestore());

      if (kDebugMode) {
        print('Firebase: 운세 기록 저장 완료');
      }
      
      return fortune;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 운세 기록 저장 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 미션 관련 기능
  // ========================================

  /// 오늘의 미션 완료 상태 확인
  static Future<bool> checkTodayMissionStatus(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final query = await _firestore
          .collection('missions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      final isCompleted = query.docs.isNotEmpty;
      
      if (kDebugMode) {
        print('Firebase: 오늘의 미션 상태 - ${isCompleted ? "완료" : "미완료"}');
      }

      return isCompleted;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 미션 상태 확인 실패 - $e');
      }
      rethrow;
    }
  }

  /// 미션 완료 기록
  static Future<MissionModel> completeMission({
    required String userId,
    required String mission,
  }) async {
    try {
      final missionRef = await _firestore.collection('missions').add({});
      final missionModel = MissionModel.create(
        id: missionRef.id,
        userId: userId,
        mission: mission,
      );
      
      await missionRef.set(missionModel.toFirestore());

      if (kDebugMode) {
        print('Firebase: 미션 완료 기록 저장 완료');
      }
      
      return missionModel;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 미션 완료 기록 저장 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 미션 이력 조회
  static Future<List<MissionModel>> getUserMissionHistory(String userId, {int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('missions')
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      final history = query.docs.map((doc) {
        return MissionModel.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 미션 이력 조회 완료 - ${history.length}개');
      }

      return history;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 미션 이력 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 운세 이력 조회
  static Future<List<FortuneModel>> getUserFortuneHistory(String userId, {int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('draws')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final history = query.docs.map((doc) {
        return FortuneModel.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 운세 이력 조회 완료 - ${history.length}개');
      }

      return history;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 운세 이력 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 랭킹 관련 기능
  // ========================================

  /// 랭킹 조회
  static Future<List<RankingModel>> getRankings({int limit = 10}) async {
    try {
      final query = await _firestore
          .collection('users')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      final rankings = <RankingModel>[];
      for (int i = 0; i < query.docs.length; i++) {
        final doc = query.docs[i];
        final ranking = RankingModel.fromFirestore(doc.id, doc.data(), i + 1);
        rankings.add(ranking);
      }

      if (kDebugMode) {
        print('Firebase: 랭킹 조회 완료 - ${rankings.length}명');
      }

      return rankings;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 랭킹 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 보상 관련 기능
  // ========================================

  /// 보상 기록 추가
  static Future<RewardModel> addReward({
    required String userId,
    required RewardType type,
    required int points,
    String? description,
  }) async {
    try {
      final rewardRef = await _firestore.collection('rewards').add({});
      final reward = RewardModel.create(
        id: rewardRef.id,
        userId: userId,
        type: type,
        points: points,
        description: description,
      );
      
      await rewardRef.set(reward.toFirestore());

      if (kDebugMode) {
        print('Firebase: 보상 기록 추가 완료 - $points 포인트');
      }
      
      return reward;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 보상 기록 추가 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자 포인트 업데이트
  static Future<UserModel> updateUserPoints({
    required String userId,
    required int pointsToAdd,
    required UserModel currentUser,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      final updatedUser = currentUser.copyWith(
        rewardPoints: currentUser.rewardPoints + pointsToAdd,
        lastActiveDate: DateTime.now(),
      ).withUpdatedScore();

      await userRef.update(updatedUser.toFirestore());

      if (kDebugMode) {
        print('Firebase: 사용자 포인트 업데이트 완료 - ${pointsToAdd > 0 ? '+' : ''}$pointsToAdd 포인트');
      }
      
      return updatedUser;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 사용자 포인트 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  /// 포인트 사용 내역 추가
  static Future<PointsUsageModel> addPointsUsage({
    required String userId,
    required String petId,
    required int pointsUsed,
    required String description,
  }) async {
    try {
      final usageRef = await _firestore.collection('pointsUsage').add({});
      final usage = PointsUsageModel.create(
        id: usageRef.id,
        userId: userId,
        petId: petId,
        pointsUsed: pointsUsed,
        description: description,
      );
      
      await usageRef.set(usage.toFirestore());

      if (kDebugMode) {
        print('Firebase: 포인트 사용 내역 추가 완료 - $pointsUsed 포인트');
      }
      
      return usage;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 포인트 사용 내역 추가 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 보상 내역 조회
  static Future<List<RewardModel>> getUserRewards(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('rewards')
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .limit(limit)
          .get();

      final rewards = query.docs.map((doc) {
        return RewardModel.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 보상 내역 조회 완료 - ${rewards.length}개');
      }

      return rewards;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 보상 내역 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 포인트 사용 내역 조회
  static Future<List<PointsUsageModel>> getUserPointsUsage(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('pointsUsage')
          .where('userId', isEqualTo: userId)
          .orderBy('usedAt', descending: true)
          .limit(limit)
          .get();

      final usage = query.docs.map((doc) {
        return PointsUsageModel.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 포인트 사용 내역 조회 완료 - ${usage.length}개');
      }

      return usage;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 포인트 사용 내역 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 챌린지 관련 기능
  // ========================================

  /// 새로운 챌린지 시작
  static Future<UserChallenge> startChallenge({
    required String userId,
    required Challenge challenge,
  }) async {
    try {
      final challengeRef = await _firestore.collection('userChallenges').add({});
      final userChallenge = UserChallenge.start(
        id: challengeRef.id,
        userId: userId,
        challenge: challenge,
      );
      
      await challengeRef.set(userChallenge.toFirestore());

      if (kDebugMode) {
        print('Firebase: 챌린지 시작 완료 - ${challenge.title}');
      }
      
      return userChallenge;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 챌린지 시작 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자 챌린지 업데이트
  static Future<void> updateUserChallenge(UserChallenge userChallenge) async {
    try {
      final challengeRef = _firestore.collection('userChallenges').doc(userChallenge.id);
      await challengeRef.update(userChallenge.toFirestore());

      if (kDebugMode) {
        print('Firebase: 챌린지 업데이트 완료 - ${userChallenge.challenge.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 챌린지 업데이트 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 활성 챌린지 목록 조회
  static Future<List<UserChallenge>> getUserActiveChallenges(String userId) async {
    try {
      final query = await _firestore
          .collection('userChallenges')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'inProgress')
          .orderBy('startDate', descending: true)
          .get();

      final challenges = query.docs.map((doc) {
        return UserChallenge.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 활성 챌린지 조회 완료 - ${challenges.length}개');
      }

      return challenges;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 활성 챌린지 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 모든 챌린지 이력 조회
  static Future<List<UserChallenge>> getUserChallengeHistory(String userId, {int limit = 20}) async {
    try {
      final query = await _firestore
          .collection('userChallenges')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final challenges = query.docs.map((doc) {
        return UserChallenge.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 챌린지 이력 조회 완료 - ${challenges.length}개');
      }

      return challenges;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 챌린지 이력 조회 실패 - $e');
      }
      rethrow;
    }
  }

  /// 사용자의 완료된 챌린지 목록 조회
  static Future<List<UserChallenge>> getUserCompletedChallenges(String userId) async {
    try {
      final query = await _firestore
          .collection('userChallenges')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .orderBy('endDate', descending: true)
          .get();

      final challenges = query.docs.map((doc) {
        return UserChallenge.fromFirestore(doc.id, doc.data());
      }).toList();

      if (kDebugMode) {
        print('Firebase: 완료된 챌린지 조회 완료 - ${challenges.length}개');
      }

      return challenges;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 완료된 챌린지 조회 실패 - $e');
      }
      rethrow;
    }
  }

  // ========================================
  // 동물 콜렉터 관련 기능 (새로운 시스템)
  // ========================================
  
  // TODO: 새로운 동물 콜렉터 시스템의 Firebase 연동 기능 추가 예정

  // ========================================
  // 유틸리티 기능
  // ========================================

  /// Firestore 연결 상태 확인
  static Future<bool> checkConnection() async {
    try {
      await _firestore.collection('test').limit(1).get();
      if (kDebugMode) {
        print('Firebase: 연결 상태 양호');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 연결 실패 - $e');
      }
      return false;
    }
  }

  /// 컬렉션 데이터 수 조회
  static Future<int> getCollectionCount(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      final count = snapshot.docs.length;
      
      if (kDebugMode) {
        print('Firebase: $collection 컬렉션 데이터 수 - $count개');
      }
      
      return count;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase: 컬렉션 데이터 수 조회 실패 - $e');
      }
      rethrow;
    }
  }
}
