import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/focus_category_model.dart';
import 'package:flutter/foundation.dart';

class CategoryService {
  static const String _categoriesKey = 'user_categories';

  /// 사용자의 모든 카테고리 가져오기
  static Future<List<FocusCategoryModel>> getUserCategories(String userId) async {
    try {
      print('카테고리 로딩 시작 - userId: $userId');
      
      // Firebase에서 카테고리 가져오기 (단순 쿼리)
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      print('Firebase에서 가져온 카테고리 수: ${snapshot.docs.length}');

      List<FocusCategoryModel> categories = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        final category = FocusCategoryModel.fromMap(data);
        print('카테고리 로드됨: ${category.name} (즐겨찾기: ${category.isFavorite})');
        return category;
      }).toList();

      // 클라이언트 사이드에서 정렬 (기본 카테고리 우선, 그 다음 생성일순)
      categories.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      // 카테고리가 없거나 기본 카테고리가 부족하면 기본 카테고리 생성
      final defaultCategoryIds = FocusCategoryModel.getDefaultCategories().map((c) => c.id).toSet();
      final existingDefaultIds = categories.where((c) => c.isDefault).map((c) => c.id).toSet();
      final missingDefaultIds = defaultCategoryIds.difference(existingDefaultIds);

      if (categories.isEmpty || missingDefaultIds.isNotEmpty) {
        print('기본 카테고리 초기화 필요: missing = $missingDefaultIds');
        await _initializeDefaultCategories(userId);
        
        // 다시 카테고리 가져오기 (단순 쿼리)
        final newSnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .get();

        categories = newSnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data();
          data['id'] = doc.id;
          return FocusCategoryModel.fromMap(data);
        }).toList();
        
        // 다시 정렬
        categories.sort((a, b) {
          if (a.isDefault && !b.isDefault) return -1;
          if (!a.isDefault && b.isDefault) return 1;
          return a.createdAt.compareTo(b.createdAt);
        });
        
        print('기본 카테고리 초기화 후 카테고리 수: ${categories.length}');
      }

      print('최종 카테고리 로딩 완료 - 총 ${categories.length}개');
      return categories;
    } catch (e) {
      print('카테고리 로딩 실패: $e');
      // Firebase 실패 시 기본 카테고리만 반환
      return FocusCategoryModel.getDefaultCategories();
    }
  }

  /// 기본 카테고리 초기화
  static Future<List<FocusCategoryModel>> _initializeDefaultCategories(String userId) async {
    try {
      print('기본 카테고리 초기화 시작 - userId: $userId');
      final defaultCategories = FocusCategoryModel.getDefaultCategories();
      
      // 각 카테고리를 개별적으로 저장 (배치보다 안정적)
      for (final category in defaultCategories) {
        try {
          final categoryData = category.toMap();
          categoryData['userId'] = userId;
          
          // 기본 카테고리 ID로 문서 생성 (강제 덮어쓰기)
          await FirebaseFirestore.instance
              .collection('categories')
              .doc(category.id)
              .set(categoryData, SetOptions(merge: false)); // merge: false로 완전 덮어쓰기
              
          print('기본 카테고리 생성됨: ${category.name} (${category.id}) - userId: $userId');
        } catch (e) {
          print('카테고리 생성 실패: ${category.name} - $e');
        }
      }

      // Firebase 동기화를 위한 대기 시간 증가
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('기본 카테고리 초기화 완료');
      return defaultCategories;
    } catch (e) {
      print('기본 카테고리 초기화 실패: $e');
      return FocusCategoryModel.getDefaultCategories();
    }
  }

  /// 새 카테고리 생성
  static Future<bool> createCategory(String userId, FocusCategoryModel category) async {
    try {
      final categoryData = category.toMap();
      categoryData['userId'] = userId;
      
      final docRef = await FirebaseFirestore.instance
          .collection('categories')
          .add(categoryData);

      // 로컬 저장소에도 저장
      await _saveToLocal(category.copyWith(id: docRef.id));
      return true;
    } catch (e) {
      print('카테고리 생성 실패: $e');
      return false;
    }
  }

  /// 카테고리 수정
  static Future<bool> updateCategory(FocusCategoryModel category) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());

      // 로컬 저장소도 업데이트
      await _saveToLocal(category);
      return true;
    } catch (e) {
      print('카테고리 수정 실패: $e');
      return false;
    }
  }

  /// 카테고리 삭제 (비활성화)
  static Future<bool> deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(categoryId)
          .update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('카테고리 삭제 실패: $e');
      return false;
    }
  }

  /// 카테고리 ID로 특정 카테고리 조회
  static Future<FocusCategoryModel?> getCategoryById(String categoryId) async {
    try {
      final categories = await _getStoredCategories();
      return categories.firstWhere(
        (category) => category.id == categoryId,
        orElse: () => _getDefaultCategories().firstWhere(
          (category) => category.id == categoryId,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('카테고리 조회 실패 (ID: $categoryId): $e');
      }
      return null;
    }
  }

  /// 저장된 카테고리 가져오기 (Firebase 우선, 실패시 로컬)
  static Future<List<FocusCategoryModel>> _getStoredCategories() async {
    try {
      // 일단 로컬 카테고리 반환 (임시)
      return await _getLocalCategories();
    } catch (e) {
      return _getDefaultCategories();
    }
  }

  /// 기본 카테고리 목록 반환
  static List<FocusCategoryModel> _getDefaultCategories() {
    return FocusCategoryModel.getDefaultCategories();
  }

  /// 로컬 저장소에 카테고리 저장
  static Future<void> _saveToLocal(FocusCategoryModel category) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categories = await _getLocalCategories();
      
      // 기존 카테고리 업데이트 또는 새 카테고리 추가
      final index = categories.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        categories[index] = category;
      } else {
        categories.add(category);
      }

      final categoriesData = categories.map((c) => c.toMap()).toList();
      await prefs.setString(_categoriesKey, categoriesData.toString());
    } catch (e) {
      print('로컬 카테고리 저장 실패: $e');
    }
  }

  /// 로컬 저장소에서 카테고리 가져오기
  static Future<List<FocusCategoryModel>> _getLocalCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesData = prefs.getString(_categoriesKey);
      
      if (categoriesData != null) {
        // 로컬 데이터 파싱 로직 (간단한 버전)
        // 실제로는 JSON 파싱이 필요할 수 있음
        return FocusCategoryModel.getDefaultCategories();
      }
      
      return FocusCategoryModel.getDefaultCategories();
    } catch (e) {
      print('로컬 카테고리 로딩 실패: $e');
      return FocusCategoryModel.getDefaultCategories();
    }
  }

  /// 카테고리 사용 통계 가져오기
  static Future<Map<String, int>> getCategoryUsageStats(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('focus_sessions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'FocusSessionStatus.completed')
          .get();

      Map<String, int> stats = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final categoryId = data['categoryId'] as String?;
        
        if (categoryId != null) {
          stats[categoryId] = (stats[categoryId] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('카테고리 통계 로딩 실패: $e');
      return {};
    }
  }

  /// 자주 사용하는 카테고리 순으로 정렬
  static Future<List<FocusCategoryModel>> getMostUsedCategories(String userId) async {
    try {
      final categories = await getUserCategories(userId);
      final stats = await getCategoryUsageStats(userId);

      // 사용 횟수로 정렬
      categories.sort((a, b) {
        final aCount = stats[a.id] ?? 0;
        final bCount = stats[b.id] ?? 0;
        return bCount.compareTo(aCount);
      });

      return categories;
    } catch (e) {
      print('자주 사용하는 카테고리 정렬 실패: $e');
      return await getUserCategories(userId);
    }
  }

  /// 즐겨찾기 토글
  static Future<bool> toggleFavorite(String categoryId, String userId) async {
    try {
      print('즐겨찾기 토글 시작 - categoryId: $categoryId, userId: $userId');
      
      // 현재 카테고리 목록에서 해당 카테고리 찾기
      final categories = await getUserCategories(userId);
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('카테고리를 찾을 수 없습니다'),
      );
      
      print('현재 즐겨찾기 상태: ${category.isFavorite} -> ${!category.isFavorite}');
      
      final updatedCategory = category.copyWith(
        isFavorite: !category.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      // Firebase에서 카테고리 문서 존재 여부 확인
      final docRef = FirebaseFirestore.instance.collection('categories').doc(categoryId);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
        // 문서가 존재하면 업데이트
        print('기존 문서 업데이트 시도...');
        await docRef.update({
          'isFavorite': updatedCategory.isFavorite,
          'updatedAt': updatedCategory.updatedAt.millisecondsSinceEpoch,
        });
        print('Firebase 업데이트 성공 - 새 상태: ${updatedCategory.isFavorite}');
      } else {
        // 문서가 존재하지 않으면 새로 생성
        print('문서가 존재하지 않음. 새로 생성...');
        final categoryData = updatedCategory.toMap();
        categoryData['userId'] = userId;
        
        await docRef.set(categoryData);
        print('새 카테고리 문서 생성 완료 - 상태: ${updatedCategory.isFavorite}');
      }
      
      return true;
    } catch (e) {
      print('즐겨찾기 토글 실패: $e');
      return false;
    }
  }

  /// 즐겨찾기 카테고리 조회
  static Future<List<FocusCategoryModel>> getFavoriteCategories(String userId) async {
    try {
      final categories = await getUserCategories(userId);
      return categories.where((category) => category.isFavorite).toList();
    } catch (e) {
      if (kDebugMode) {
        print('즐겨찾기 카테고리 조회 실패: $e');
      }
      return [];
    }
  }

  /// 카테고리 이름 중복 체크
  static Future<bool> isCategoryNameExists(String userId, String name, {String? excludeId}) async {
    try {
      final categories = await getUserCategories(userId);
      return categories.any((category) => 
          category.name.toLowerCase() == name.toLowerCase() && 
          category.id != excludeId
      );
    } catch (e) {
      print('카테고리 이름 중복 체크 실패: $e');
      return false;
    }
  }
} 