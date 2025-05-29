import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // CupertinoSlider 사용
import '../../models/user_model.dart'; // UserModel 필요
import '../../services/focus_service.dart';
import '../../models/focus_session_model.dart';
import '../models/focus_category_model.dart'; // 카테고리 모델 추가
import '../services/category_service.dart'; // 카테고리 서비스 추가
import './focusing_page.dart';

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
      final categories = await CategoryService.getUserCategories(widget.currentUser.id);
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
      return '짧고 집중적인 시간이에요! 🚀';
    } else if (duration <= 30) {
      return '완벽한 집중 시간이에요! ⭐';
    } else if (duration <= 60) {
      return '깊은 집중의 시간이에요! 🎯';
    } else {
      return '도전적인 긴 집중이에요! 💪';
    }
  }

  Color _getThemeColor() {
    return Colors.teal.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _getThemeColor(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '집중하기 설정',
          style: TextStyle(
            color: _getThemeColor(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF0F9FF),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 헤더 섹션
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _getThemeColor().withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 나무 아이콘과 제목
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getThemeColor().withOpacity(0.1),
                                  _getThemeColor().withOpacity(0.2),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.park_outlined,
                              size: 60,
                              color: _getThemeColor(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '나무와 함께 집중해요',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '설정한 시간 동안 집중하면\n아름다운 나무가 자라납니다',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 모드 선택 섹션
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
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
                                color: _getThemeColor().withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.touch_app_outlined,
                                size: 20,
                                color: _getThemeColor(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 모드 선택',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 모드 선택 버튼들
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
                  
                  const SizedBox(height: 32),
                  
                  // 시간 설정 섹션 (타이머 모드에서만 표시)
                  if (_selectedMode == FocusMode.timer)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
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
                                  color: _getThemeColor().withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timer_outlined,
                                  size: 20,
                                  color: _getThemeColor(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '집중 시간 설정',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // 시간 표시
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getThemeColor().withOpacity(0.1),
                                    _getThemeColor().withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _getThemeColor().withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_selectedDurationMinutes.toInt()}분',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: _getThemeColor(),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMotivationalMessage(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // 슬라이더
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _getThemeColor(),
                              inactiveTrackColor: _getThemeColor().withOpacity(0.2),
                              thumbColor: _getThemeColor(),
                              overlayColor: _getThemeColor().withOpacity(0.2),
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
                          
                          // 슬라이더 라벨
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
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '120분',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 스톱워치 모드 설명 섹션 (스톱워치 모드에서만 표시)
                  if (_selectedMode == FocusMode.stopwatch)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
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
                                  color: _getThemeColor().withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.timeline,
                                  size: 20,
                                  color: _getThemeColor(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '스톱워치 모드',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // 나무 성장 설명 (간소화)
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getThemeColor().withOpacity(0.05),
                                  _getThemeColor().withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '15분마다 나무가 성장해요\n90분 이상 집중하면 특별한 대나무를 얻을 수 있어요!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // 카테고리 선택 섹션 추가
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
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
                                color: _getThemeColor().withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.category_outlined,
                                size: 20,
                                color: _getThemeColor(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '집중 카테고리 선택',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const Spacer(),
                            if (!_isLoadingCategories && _selectedCategory != null)
                              Text(
                                '선택함',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getThemeColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        if (_isLoadingCategories)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(
                                color: _getThemeColor(),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (_categories.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.grey.shade500,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '카테고리가 없습니다. 먼저 카테고리를 생성해주세요.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: [
                              // 선택된 카테고리 표시
                              if (_selectedCategory != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _selectedCategory!.color.withValues(alpha: 0.1),
                                        _selectedCategory!.color.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedCategory!.color.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: _selectedCategory!.color.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _selectedCategory!.icon,
                                          color: _selectedCategory!.color,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _selectedCategory!.name,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: _selectedCategory!.color,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _selectedCategory!.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        color: _selectedCategory!.color,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 16),
                              
                              // 카테고리 변경 버튼
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCategorySelector(),
                                  icon: Icon(
                                    Icons.swap_horiz,
                                    color: _getThemeColor(),
                                    size: 20,
                                  ),
                                  label: Text(
                                    '카테고리 변경',
                                    style: TextStyle(
                                      color: _getThemeColor(),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: _getThemeColor()),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 시작 버튼
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getThemeColor().withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _startFocusSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getThemeColor(),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
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
                                  '준비 중...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '집중 시작하기',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 팁 섹션
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.amber.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '집중 팁',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '• 휴대폰을 멀리 두고 시작하세요\n• 조용하고 편안한 환경을 만드세요\n• 집중 중에는 앱을 종료하지 마세요\n• 완료하면 포인트를 받을 수 있어요!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
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
        backgroundColor: isSelected ? _getThemeColor() : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        elevation: isSelected ? 8 : 2,
        shadowColor: isSelected ? _getThemeColor().withOpacity(0.3) : Colors.grey.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? _getThemeColor() : Colors.grey.shade200,
            width: isSelected ? 0 : 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: isSelected ? Colors.white : _getThemeColor(),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 카테고리 선택 다이얼로그 표시
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // 핸들 바
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    '카테고리 선택',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // 추천 카테고리 섹션
            _buildRecommendedSection(),
            
            // 모든 카테고리 목록
            Expanded(
              child: _buildAllCategoriesSection(),
            ),
          ],
        ),
      ),
    );
  }

  // 추천 카테고리 섹션
  Widget _buildRecommendedSection() {
    // 즐겨찾기 카테고리 필터링
    List<FocusCategoryModel> favoriteCategories = _categories
        .where((category) => category.isFavorite)
        .toList();
    
    // 즐겨찾기가 없으면 자주 사용하는 상위 3개
    if (favoriteCategories.isEmpty) {
      favoriteCategories = _categories.take(3).toList();
    }
    
    if (favoriteCategories.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.pink.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '즐겨찾기 카테고리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favoriteCategories.length,
            itemBuilder: (context, index) {
              final category = favoriteCategories[index];
              final isSelected = _selectedCategory?.id == category.id;
              
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _buildRecommendedCategoryCard(category, isSelected),
              );
            },
          ),
        ),
        
        const SizedBox(height: 20),
        
        Divider(color: Colors.grey.shade200),
      ],
    );
  }

  // 추천 카테고리 카드
  Widget _buildRecommendedCategoryCard(FocusCategoryModel category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        Navigator.pop(context);
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected 
                ? [category.color.withValues(alpha: 0.2), category.color.withValues(alpha: 0.1)]
                : [Colors.grey.shade50, Colors.white],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? category.color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? category.color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: category.color,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 모든 카테고리 섹션
  Widget _buildAllCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '모든 카테고리',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory?.id == category.id;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _buildCategoryListItem(category, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  // 카테고리 리스트 아이템
  Widget _buildCategoryListItem(FocusCategoryModel category, bool isSelected) {
    return ListTile(
      onTap: () {
        setState(() => _selectedCategory = category);
        Navigator.pop(context);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: isSelected ? category.color.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? category.color : Colors.transparent,
          width: 1,
        ),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          category.icon,
          color: category.color,
          size: 20,
        ),
      ),
      title: Text(
        category.name,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isSelected ? category.color : Colors.grey.shade800,
        ),
      ),
      subtitle: Text(
        category.description,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: category.color,
              size: 24,
            )
          : null,
    );
  }
} 