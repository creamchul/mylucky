import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';
import 'category_edit_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryManagementPage extends StatefulWidget {
  final UserModel currentUser;

  const CategoryManagementPage({super.key, required this.currentUser});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  List<FocusCategoryModel> _categories = [];
  Map<String, int> _usageStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    print('카테고리 로딩 시작...');
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryService.getUserCategories(widget.currentUser.id);
      final stats = await CategoryService.getCategoryUsageStats(widget.currentUser.id);
      
      setState(() {
        _categories = categories;
        _usageStats = stats;
        _isLoading = false;
      });
      
      print('카테고리 로딩 완료 - 총 ${categories.length}개, 즐겨찾기 ${categories.where((c) => c.isFavorite).length}개');
    } catch (e) {
      print('카테고리 로딩 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 로딩 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addCategory() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditPage(
          userId: widget.currentUser.id,
        ),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _editCategory(FocusCategoryModel category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditPage(
          userId: widget.currentUser.id,
          category: category,
        ),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(FocusCategoryModel category) async {
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('기본 카테고리는 삭제할 수 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('${category.name} 카테고리를 삭제하시겠습니까?\n삭제된 카테고리는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CategoryService.deleteCategory(category.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카테고리가 삭제되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
        _loadCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카테고리 삭제에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(FocusCategoryModel category) async {
    try {
      // 현재 상태 저장 (토글 전)
      final wasLiked = category.isFavorite;
      
      final success = await CategoryService.toggleFavorite(category.id, widget.currentUser.id);
      if (success) {
        // Firebase 업데이트 완료를 위한 잠시 대기
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 카테고리 목록 새로고침
        await _loadCategories();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                wasLiked 
                    ? '${category.name} 즐겨찾기에서 제거됨'
                    : '${category.name} 즐겨찾기에 추가됨',
              ),
              backgroundColor: wasLiked 
                  ? Colors.grey.shade600
                  : Colors.pink.shade600,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('즐겨찾기 설정에 실패했습니다'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _forceInitializeCategories() async {
    setState(() => _isLoading = true);
    
    try {
      print('기본 카테고리 강제 초기화 시작...');
      
      // 기본 카테고리들을 Firebase에 강제로 생성
      final defaultCategories = FocusCategoryModel.getDefaultCategories();
      
      for (final category in defaultCategories) {
        final categoryData = category.toMap();
        categoryData['userId'] = widget.currentUser.id;
        
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(category.id)
            .set(categoryData, SetOptions(merge: false));
            
        print('강제 생성: ${category.name} (${category.id})');
      }
      
      // 완료 후 새로고침
      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('기본 카테고리가 다시 생성되었습니다'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('강제 초기화 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('초기화 실패: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🏷️ 카테고리 관리',
          style: TextStyle(
            color: Colors.brown,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Colors.brown),
            onPressed: _forceInitializeCategories,
            tooltip: '카테고리 강제 초기화',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.brown),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF0F8F0),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.brown),
              )
            : Column(
                children: [
                  // 통계 헤더
                  _buildStatsHeader(),
                  
                  // 카테고리 목록
                  Expanded(
                    child: _buildCategoryList(),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCategory,
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '카테고리 추가',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalCategories = _categories.length;
    final customCategories = _categories.where((c) => !c.isDefault).length;
    final favoriteCategories = _categories.where((c) => c.isFavorite).length;
    final totalUsage = _usageStats.values.fold(0, (sum, count) => sum + count);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: Colors.brown.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '카테고리 현황',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '전체 카테고리',
                  '$totalCategories개',
                  Icons.category,
                  Colors.blue.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '즐겨찾기',
                  '$favoriteCategories개',
                  Icons.favorite,
                  Colors.pink.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '사용자 정의',
                  '$customCategories개',
                  Icons.edit,
                  Colors.green.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  '총 사용 횟수',
                  '$totalUsage회',
                  Icons.trending_up,
                  Colors.orange.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '카테고리가 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 카테고리를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: Colors.brown,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final usageCount = _usageStats[category.id] ?? 0;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _buildCategoryCard(category, usageCount),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(FocusCategoryModel category, int usageCount) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _editCategory(category),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 카테고리 아이콘
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 카테고리 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (category.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '기본',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$usageCount회 사용',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 액션 버튼들
              Column(
                children: [
                  // 즐겨찾기 토글 버튼 추가
                  IconButton(
                    onPressed: () => _toggleFavorite(category),
                    icon: Icon(
                      category.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: category.isFavorite ? Colors.pink.shade600 : Colors.grey.shade500,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editCategory(category),
                    icon: Icon(
                      Icons.edit,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                  if (!category.isDefault)
                    IconButton(
                      onPressed: () => _deleteCategory(category),
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 