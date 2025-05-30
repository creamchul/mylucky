import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/focus_category_model.dart';
import '../services/category_service.dart';
import '../constants/app_colors.dart';
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
  List<FocusCategoryModel> _filteredCategories = [];
  Map<String, int> _usageStats = {};
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterCategories();
    });
  }

  void _filterCategories() {
    if (_searchQuery.isEmpty) {
      _filteredCategories = List.from(_categories);
    } else {
      _filteredCategories = _categories.where((category) {
        return category.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               category.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
  }

  Future<void> _loadCategories() async {
    print('카테고리 로딩 시작...');
    setState(() => _isLoading = true);
    try {
      final categories = await CategoryService.getCategoriesOrderedByPosition(widget.currentUser.id);
      final stats = await CategoryService.getCategoryUsageStats(widget.currentUser.id);
      
      setState(() {
        _categories = categories;
        _filteredCategories = List.from(categories);
        _usageStats = stats;
        _isLoading = false;
      });
      _filterCategories();
      
      print('카테고리 로딩 완료 - 총 ${categories.length}개');
    } catch (e) {
      print('카테고리 로딩 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('카테고리 로딩 실패: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    // 필터된 리스트에서 실제 카테고리 찾기
    final categoryToMove = _filteredCategories[oldIndex];
    final originalIndex = _categories.indexOf(categoryToMove);
    
    setState(() {
      final item = _categories.removeAt(originalIndex);
      _categories.insert(newIndex, item);
    });
    
    final reorderedCategories = _categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return category.copyWith(order: index);
    }).toList();
    
    try {
      final success = await CategoryService.updateCategoryOrder(
        widget.currentUser.id, 
        reorderedCategories,
      );
      
      if (success) {
        print('카테고리 순서 업데이트 성공');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('카테고리 순서가 변경되었습니다'),
            backgroundColor: AppColors.focusMint,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
        _filterCategories(); // 검색 결과 업데이트
      } else {
        print('카테고리 순서 업데이트 실패');
        _loadCategories();
      }
    } catch (e) {
      print('카테고리 순서 업데이트 에러: $e');
      _loadCategories();
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
        SnackBar(
          content: const Text('기본 카테고리는 삭제할 수 없습니다'),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: Colors.red.shade500,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '카테고리 삭제',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          '${category.name} 카테고리를 삭제하시겠습니까?\n삭제된 카테고리는 복구할 수 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await CategoryService.deleteCategory(category.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('카테고리가 삭제되었습니다'),
            backgroundColor: AppColors.focusMint,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('카테고리 삭제에 실패했습니다'),
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
      
      await Future.delayed(const Duration(milliseconds: 1000));
      await _loadCategories();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('기본 카테고리가 다시 생성되었습니다'),
            backgroundColor: AppColors.focusMint,
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
            backgroundColor: Colors.red.shade400,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.grey.shade700,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          '🏷️ 집중 카테고리 선택',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.focusMint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.refresh,
                color: AppColors.focusMint,
                size: 20,
              ),
            ),
            onPressed: _loadCategories,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFDFD),
              Color(0xFFF8F9FA),
              Color(0xFFF0F8F5),
              Color(0xFFFFF8F3),
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.focusMint,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '카테고리를 불러오는 중...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildSearchBar(),
                  Expanded(
                    child: _buildCategoryList(),
                  ),
                ],
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.focusMint.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addCategory,
          backgroundColor: AppColors.focusMint,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: const Icon(Icons.add, size: 22),
          label: const Text(
            '새 카테고리',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.focusMint.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.focusMint.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '카테고리 검색',
                hintStyle: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppColors.focusMint,
            ),
            onPressed: () => _filterCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    if (_filteredCategories.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        // 검색 결과가 없는 경우
        return Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.focusMint.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.focusMint.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.focusMint,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '검색 결과가 없어요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '"$_searchQuery"와 일치하는\n카테고리를 찾을 수 없습니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      } else {
        // 카테고리가 아예 없는 경우
        return Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.focusMint.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.focusMint.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: AppColors.focusMint,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '아직 카테고리가 없어요',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '새 카테고리를 추가해서\n집중 활동을 분류해보세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppColors.focusMint,
      child: ReorderableListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        onReorder: _onReorder,
        children: [
          for (int index = 0; index < _filteredCategories.length; index++)
            _buildCategoryCard(_filteredCategories[index]),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(FocusCategoryModel category) {
    return ReorderableDragStartListener(
      index: _filteredCategories.indexOf(category),
      key: Key(category.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _editCategory(category),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: category.color == Colors.transparent
                      ? AppColors.focusMint.withOpacity(0.3)
                      : category.color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (category.color == Colors.transparent
                        ? AppColors.focusMint
                        : category.color).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: category.color == Colors.transparent
                          ? AppColors.focusMint.withOpacity(0.1)
                          : category.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: category.color == Colors.transparent
                            ? AppColors.focusMint.withOpacity(0.3)
                            : category.color.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      color: category.color == Colors.transparent
                          ? AppColors.focusMint
                          : category.color,
                      size: 26,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            if (category.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.focusMint.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.focusMint.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '기본',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.focusMint,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (category.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            category.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: category.isDefault
                              ? Colors.grey.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: category.isDefault ? null : () => _deleteCategory(category),
                          icon: Icon(
                            Icons.delete_outline,
                            color: category.isDefault 
                                ? Colors.grey.shade300 
                                : Colors.red.shade400,
                            size: 20,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          tooltip: category.isDefault 
                              ? '기본 카테고리는 삭제할 수 없습니다' 
                              : '카테고리 삭제',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 