import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoSlider 사용
import '../../models/user_model.dart'; // UserModel 필요
import '../../services/focus_service.dart';
import '../../models/focus_session_model.dart';
import '../models/focus_category_model.dart'; // 카테고리 모델 추가
import '../services/category_service.dart'; // 카테고리 서비스 추가
import '../constants/app_colors.dart'; // 앱 색상 시스템 추가
import './focusing_page.dart';
import './category_management_page.dart'; // 카테고리 관리 페이지 추가

class FocusSetupPage extends StatefulWidget {
  final UserModel currentUser; // 현재 사용자 정보

  const FocusSetupPage({super.key, required this.currentUser});

  @override
  State<FocusSetupPage> createState() => _FocusSetupPageState();
}

class _FocusSetupPageState extends State<FocusSetupPage> with TickerProviderStateMixin {
  double _selectedDurationMinutes = 25.0; // 기본 25분
  bool _isLoading = false;
  FocusMode _selectedMode = FocusMode.timer; // 기본값: 타이머 모드
  
  // 카테고리 관련 상태 변수 추가
  List<FocusCategoryModel> _categories = [];
  FocusCategoryModel? _selectedCategory;
  bool _isLoadingCategories = true;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _scaleController.forward();
    
    // 카테고리 로딩
    _loadCategories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // 카테고리 로딩 함수 추가
  Future<void> _loadCategories() async {
    try {
      // 순서대로 정렬된 카테고리 로드
      final categories = await CategoryService.getCategoriesOrderedByPosition(widget.currentUser.id);
      final now = DateTime.now();
      final recommendedCategories = await CategoryService.getMostUsedCategories(widget.currentUser.id);
      
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        
        // 자주 사용하는 카테고리를 기본 선택
        if (recommendedCategories.isNotEmpty) {
          _selectedCategory = recommendedCategories.first;
        } else if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      print('카테고리 로딩 실패: $e');
    }
  }

  // TODO: 나무 종류 선택 UI (MVP에서는 기본 나무만 사용)
  // TreeType _selectedTreeType = TreeType.basic;

  void _startFocusSession() async {
    setState(() => _isLoading = true);
    try {
      final newSession = await FocusService.createSession(
        userId: widget.currentUser.id,
        focusMode: _selectedMode,
        durationMinutes: _selectedMode == FocusMode.timer ? _selectedDurationMinutes.toInt() : 0,
        categoryId: _selectedCategory?.id, // 카테고리 ID 추가
        // treeType: _selectedTreeType, // 추후 나무 선택 기능 추가 시
      );
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FocusingPage(
              session: newSession,
              currentUser: widget.currentUser,
            ),
          ),
        );
      }
    } catch (e) {
      // 에러 처리
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('집중 세션 생성 실패: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMotivationalMessage() {
    if (_selectedMode == FocusMode.stopwatch) {
      return '얼마나 오래 집중할 수 있을까요? ⏱️';
    }
    
    final duration = _selectedDurationMinutes.toInt();
    if (duration <= 15) {
      return '짧고 집중적인 시간이에요! 🌱';
    } else if (duration <= 30) {
      return '완벽한 집중 시간이에요! 🌿';
    } else if (duration <= 60) {
      return '깊은 집중의 시간이에요! 🌳';
    } else {
      return '도전적인 긴 집중이에요! 🌲';
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '집중하기 설정',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 환영 메시지
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.focusMintLight.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.focusMint.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '깊은 집중의 시간을 시작해요',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.focusMint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '나무와 함께 성장하는 특별한 여정',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 모드 선택 섹션
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.focusMint.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.touch_app_outlined,
                                size: 22,
                                color: AppColors.focusMint,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 모드 선택',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildModeButton(
                                mode: FocusMode.timer,
                                icon: Icons.timer_outlined,
                                title: '타이머',
                                subtitle: '목표 시간 설정',
                                isSelected: _selectedMode == FocusMode.timer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildModeButton(
                                mode: FocusMode.stopwatch,
                                icon: Icons.timer,
                                title: '스톱워치',
                                subtitle: '자유 시간 측정',
                                isSelected: _selectedMode == FocusMode.stopwatch,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 시간 설정 섹션
                  if (_selectedMode == FocusMode.timer)
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.focusMint.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.timer_outlined,
                                  size: 22,
                                  color: AppColors.focusMint,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '집중 시간 설정',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.focusMint.withOpacity(0.1),
                                    AppColors.focusMint.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.focusMint.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_selectedDurationMinutes.toInt()}분',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.focusMint,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMotivationalMessage(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.focusMint,
                              inactiveTrackColor: AppColors.focusMint.withOpacity(0.2),
                              thumbColor: AppColors.focusMint,
                              overlayColor: AppColors.focusMint.withOpacity(0.2),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            ),
                            child: Slider(
                              min: 10.0,
                              max: 120.0,
                              divisions: 11,
                              value: _selectedDurationMinutes,
                              onChanged: (double value) {
                                setState(() {
                                  _selectedDurationMinutes = value.roundToDouble();
                                });
                              },
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '10분',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '120분',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 스톱워치 모드 설명
                  if (_selectedMode == FocusMode.stopwatch)
                    Container(
                      padding: const EdgeInsets.all(24),
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
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.focusMint.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.timer,
                              size: 40,
                              color: AppColors.focusMint,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '자유로운 집중 시간',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '시간 제한 없이 원하는 만큼\n집중해보세요 ⏱️',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // 카테고리 선택 섹션
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.focusMint.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                size: 22,
                                color: AppColors.focusMint,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 카테고리 선택',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        if (_isLoadingCategories)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (_selectedCategory != null)
                          GestureDetector(
                            onTap: () => _showCategorySelector(),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedCategory!.color == Colors.transparent 
                                    ? AppColors.focusMint.withOpacity(0.1)
                                    : _selectedCategory!.color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedCategory!.color == Colors.transparent 
                                      ? AppColors.focusMint.withOpacity(0.3)
                                      : _selectedCategory!.color.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: _selectedCategory!.color == Colors.transparent 
                                          ? AppColors.focusMint.withOpacity(0.2)
                                          : _selectedCategory!.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _selectedCategory!.icon,
                                      color: _selectedCategory!.color == Colors.transparent 
                                          ? AppColors.focusMint
                                          : _selectedCategory!.color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      _selectedCategory!.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _selectedCategory!.color == Colors.transparent 
                                            ? AppColors.focusMint
                                            : _selectedCategory!.color,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: _selectedCategory!.color == Colors.transparent 
                                        ? AppColors.focusMint
                                        : _selectedCategory!.color,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _navigateToCategoryManagement(),
                            icon: Icon(
                              Icons.settings,
                              color: AppColors.focusMint,
                              size: 20,
                            ),
                            label: Text(
                              '카테고리 관리',
                              style: TextStyle(
                                color: AppColors.focusMint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.focusMint, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 시작 버튼
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.focusMint.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startFocusSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.focusMint,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '나무가 준비 중이에요...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.eco,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '함께 성장하기 시작',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required FocusMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedMode = mode),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.focusMint : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: isSelected ? 6 : 2,
        shadowColor: isSelected ? AppColors.focusMint.withOpacity(0.4) : Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.focusMint : AppColors.focusMint.withOpacity(0.3),
            width: isSelected ? 0 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected ? Colors.white : AppColors.focusMint,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.focusMint.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.category,
                      color: AppColors.focusMint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '카테고리 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category.id == _selectedCategory?.id;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.focusMint.withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.focusMint
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: category.color == Colors.transparent
                                    ? AppColors.focusMint.withOpacity(0.2)
                                    : category.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color == Colors.transparent
                                    ? AppColors.focusMint
                                    : category.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (category.description.isNotEmpty)
                                    Text(
                                      category.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.focusMint,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCategoryManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagementPage(currentUser: widget.currentUser),
      ),
    );

    if (result == true) {
      _loadCategories();
    }
  }
} 