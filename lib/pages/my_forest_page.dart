import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/focus_session_model.dart';
import '../models/focus_category_model.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';
import 'tree_gallery_page.dart';
import 'category_management_page.dart';
import '../services/analytics_service.dart';
import '../widgets/analytics_charts.dart';
import '../services/category_service.dart';

// 기간 선택 enum 추가
enum AnalyticsPeriod {
  day,
  week,
  month,
  year;

  String get displayName {
    switch (this) {
      case AnalyticsPeriod.day: return '일';
      case AnalyticsPeriod.week: return '주';
      case AnalyticsPeriod.month: return '월';
      case AnalyticsPeriod.year: return '년';
    }
  }
}

class MyForestPage extends StatefulWidget {
  final UserModel currentUser;

  const MyForestPage({super.key, required this.currentUser});

  @override
  State<MyForestPage> createState() => _MyForestPageState();
}

class _MyForestPageState extends State<MyForestPage> with TickerProviderStateMixin {
  List<FocusSessionModel> _completedSessions = [];
  List<FocusSessionModel> _abandonedSessions = [];
  bool _isLoading = true;
  
  // 카테고리 필터링 관련 상태 변수 추가
  List<FocusCategoryModel> _categories = [];
  FocusCategoryModel? _selectedCategoryFilter;
  bool _isLoadingCategories = false;
  
  // 통계 관련 상태 변수 추가
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.day;
  DateTime _selectedDate = DateTime.now();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  late Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutBack,
    ));
    
    _loadForestData();
    _loadCategories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await CategoryService.getUserCategories(widget.currentUser.id);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      print('카테고리 로딩 실패: $e');
    }
  }

  Future<void> _loadForestData() async {
    setState(() => _isLoading = true);
    try {
      final allSessions = await FocusService.getUserSessions(widget.currentUser.id);
      setState(() {
        _completedSessions = allSessions.where((s) => s.status == FocusSessionStatus.completed).toList();
        _abandonedSessions = allSessions.where((s) => s.status == FocusSessionStatus.abandoned).toList();
        _isLoading = false;
      });
      
      // 데이터 로딩 완료 후 애니메이션 시작
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _staggerController.forward();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('숲 정보 로딩 실패: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getThemeColor() {
    return Colors.brown.shade600;
  }

  // 필터링된 세션 데이터 반환
  List<FocusSessionModel> _getFilteredSessions() {
    List<FocusSessionModel> allSessions = [..._completedSessions, ..._abandonedSessions];
    
    if (_selectedCategoryFilter != null) {
      allSessions = allSessions.where((session) => 
          session.categoryId == _selectedCategoryFilter!.id).toList();
    }
    
    return allSessions;
  }

  List<FocusSessionModel> _getFilteredCompletedSessions() {
    List<FocusSessionModel> sessions = _completedSessions;
    
    if (_selectedCategoryFilter != null) {
      sessions = sessions.where((session) => 
          session.categoryId == _selectedCategoryFilter!.id).toList();
    }
    
    return sessions;
  }

  List<FocusSessionModel> _getFilteredAbandonedSessions() {
    List<FocusSessionModel> sessions = _abandonedSessions;
    
    if (_selectedCategoryFilter != null) {
      sessions = sessions.where((session) => 
          session.categoryId == _selectedCategoryFilter!.id).toList();
    }
    
    return sessions;
  }

  int _getTotalFocusTime() {
    return _getFilteredCompletedSessions().fold(0, (sum, session) {
      // 실제 집중한 시간을 분 단위로 계산
      final focusMinutes = (session.elapsedSeconds / 60).round();
      return sum + focusMinutes;
    });
  }

  String _getSessionTimeText(FocusSessionModel session) {
    if (session.isStopwatchMode) {
      // 스톱워치 모드: 실제 경과 시간 표시
      final minutes = session.elapsedSeconds ~/ 60;
      final seconds = session.elapsedSeconds % 60;
      if (minutes > 0) {
        return seconds > 0 ? '${minutes}분 ${seconds}초 집중' : '${minutes}분 집중';
      } else {
        return '${seconds}초 집중';
      }
    } else {
      // 타이머 모드: 설정된 시간 표시
      return '${session.durationMinutesSet}분 집중';
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
          icon: Icon(
            Icons.arrow_back_ios,
            color: _getThemeColor(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '📊 집중 통계',
          style: TextStyle(
            color: _getThemeColor(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _getThemeColor(),
            ),
            onPressed: _loadForestData,
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
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '숲을 불러오는 중...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildForestContent(),
              ),
      ),
    );
  }

  Widget _buildForestContent() {
    if (_completedSessions.isEmpty && _abandonedSessions.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 60,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '아직 집중 기록이 없어요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '집중하기를 통해 첫 번째 기록을 만들어보세요!\n매일 조금씩 집중하면 아름다운 통계가 만들어집니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('집중하러 가기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getThemeColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadForestData,
      color: _getThemeColor(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 통계 헤더
            _buildStatsHeader(),
            const SizedBox(height: 24),
            
            // 집중 패턴 분석 차트
            _buildPatternAnalysis(),
            const SizedBox(height: 24),
            
            // 비교 분석
            _buildComparisonAnalysis(),
            const SizedBox(height: 24),
            
            // 집중 트렌드 (최근 7일)
            _buildFocusTrend(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final filteredSessions = _getFilteredSessions();
    final filteredCompleted = _getFilteredCompletedSessions();
    final filteredAbandoned = _getFilteredAbandonedSessions();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor().withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 카테고리 필터 추가
          if (!_isLoadingCategories && _categories.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '카테고리 필터:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FocusCategoryModel?>(
                        value: _selectedCategoryFilter,
                        isExpanded: true,
                        hint: Text(
                          '전체',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        items: [
                          DropdownMenuItem<FocusCategoryModel?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.all_inclusive,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '전체',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ..._categories.map((category) => DropdownMenuItem<FocusCategoryModel?>(
                            value: category,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: category.color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    category.icon,
                                    size: 10,
                                    color: category.color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: category.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedCategoryFilter = value);
                        },
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // 기간 선택 탭 추가
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: AnalyticsPeriod.values.map((period) {
                final isSelected = _selectedPeriod == period;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = period),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _getThemeColor() : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        period.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 날짜 선택기 추가
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: _getThemeColor(),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _getThemeColor(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 헤더 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getThemeColor().withValues(alpha: 0.1),
                      _getThemeColor().withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics,
                  size: 24,
                  color: _getThemeColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.currentUser.nickname}님의 집중 통계',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCategoryFilter != null 
                          ? '${_selectedCategoryFilter!.name} 카테고리 분석'
                          : '${_selectedPeriod.displayName}별 집중 기록 분석',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 통계 카드들 (필터링된 데이터 사용)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 나무',
                  '${filteredSessions.length}그루',
                  Icons.park,
                  Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '성공률',
                  filteredSessions.isEmpty
                      ? '0%'
                      : '${((filteredCompleted.length / filteredSessions.length) * 100).round()}%',
                  Icons.trending_up,
                  Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '총 집중시간',
                  '${_getTotalFocusTime()}분',
                  Icons.timer,
                  Colors.orange.shade400,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 나무 갤러리 버튼 추가
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TreeGalleryPage(currentUser: widget.currentUser),
                  ),
                );
              },
              icon: const Icon(Icons.forest, size: 20),
              label: Text(
                '🌳 나무 갤러리 보기 (${filteredSessions.length}그루)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: Colors.green.shade200,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // 카테고리 관리 버튼 추가
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryManagementPage(currentUser: widget.currentUser),
                  ),
                );
              },
              icon: const Icon(Icons.category, size: 20),
              label: const Text(
                '🏷️ 카테고리 관리',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade50,
                foregroundColor: Colors.orange.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: Colors.orange.shade200,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPatternAnalysis() {
    final allSessions = _getFilteredSessions();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: _getThemeColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '집중 패턴 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_selectedCategoryFilter != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCategoryFilter!.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategoryFilter!.icon,
                        size: 12,
                        color: _selectedCategoryFilter!.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCategoryFilter!.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: _selectedCategoryFilter!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // 선택된 기간에 따른 차트 표시
          _buildPeriodChart(allSessions),
          
          const SizedBox(height: 16),
          
          // 패턴 요약 정보
          _buildPatternSummary(allSessions),
        ],
      ),
    );
  }

  Widget _buildPeriodChart(List<FocusSessionModel> sessions) {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.day:
        final data = AnalyticsService.getHourlyPattern(sessions, _selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시간대별 집중 패턴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AnalyticsCharts.buildHourlyChart(data, Colors.blue.shade500),
          ],
        );
        
      case AnalyticsPeriod.week:
        final data = AnalyticsService.getWeeklyPattern(sessions, _selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '요일별 집중 패턴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AnalyticsCharts.buildWeeklyChart(data, Colors.green.shade500),
          ],
        );
        
      case AnalyticsPeriod.month:
        final data = AnalyticsService.getMonthlyPattern(sessions, _selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '일별 집중 패턴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AnalyticsCharts.buildMonthlyChart(data, Colors.orange.shade500, 'month'),
          ],
        );
        
      case AnalyticsPeriod.year:
        final data = AnalyticsService.getYearlyPattern(sessions, _selectedDate);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '월별 집중 패턴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            AnalyticsCharts.buildMonthlyChart(data, Colors.purple.shade500, 'year'),
          ],
        );
    }
  }

  Widget _buildPatternSummary(List<FocusSessionModel> sessions) {
    final peakTime = AnalyticsService.getPeakFocusTime(sessions);
    final successRate = AnalyticsService.getSuccessRateAnalysis(
      sessions, 
      _selectedDate, 
      _selectedPeriod.name,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '최고 집중 시간',
                  peakTime['timeString'] ?? '데이터 없음',
                  '${peakTime['period']}',
                  Icons.access_time,
                  Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  '성공률',
                  '${successRate['successRate'].toInt()}%',
                  '${successRate['totalSessions']}회 시도',
                  Icons.trending_up,
                  Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, String subtitle, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildComparisonAnalysis() {
    final allSessions = _getFilteredSessions();
    final comparison = AnalyticsService.getComparisonAnalysis(
      allSessions,
      _selectedDate,
      _selectedPeriod.name,
    );
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: _getThemeColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '기간 비교 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_selectedCategoryFilter != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCategoryFilter!.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategoryFilter!.icon,
                        size: 12,
                        color: _selectedCategoryFilter!.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCategoryFilter!.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: _selectedCategoryFilter!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          // 비교 통계
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: comparison['isImproved'] ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: comparison['isImproved'] ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  comparison['isImproved'] ? Icons.trending_up : Icons.trending_down,
                  color: comparison['isImproved'] ? Colors.green.shade600 : Colors.red.shade600,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이전 기간 대비 ${comparison['changePercent'].abs().toInt()}% ${comparison['isImproved'] ? '증가' : '감소'}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: comparison['isImproved'] ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '현재: ${comparison['currentTotal'].toInt()}분 | 이전: ${comparison['previousTotal'].toInt()}분',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 비교 차트
          Text(
            '패턴 비교',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          AnalyticsCharts.buildComparisonChart(
            comparison['current'],
            comparison['previous'],
            Colors.blue.shade500,
            Colors.grey.shade400,
            _selectedPeriod == AnalyticsPeriod.week ? 'bar' : 'line',
          ),
          
          // 범례
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('현재 기간', Colors.blue.shade500),
              const SizedBox(width: 20),
              _buildLegendItem('이전 기간', Colors.grey.shade400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFocusTrend() {
    final allSessions = _getFilteredSessions();
    final trendData = AnalyticsService.getFocusTrend(allSessions, 7);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: _getThemeColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '최근 7일 집중 트렌드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_selectedCategoryFilter != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _selectedCategoryFilter!.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedCategoryFilter!.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCategoryFilter!.icon,
                        size: 12,
                        color: _selectedCategoryFilter!.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedCategoryFilter!.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: _selectedCategoryFilter!.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          
          AnalyticsCharts.buildTrendChart(trendData, Colors.purple.shade500),
          
          const SizedBox(height: 16),
          
          // 트렌드 요약
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '평균 집중시간',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(trendData.fold(0.0, (sum, data) => sum + data['totalMinutes']) / trendData.length).toInt()}분',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '총 세션수',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trendData.fold(0, (sum, data) => sum + (data['sessionCount'] as int))}회',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '활성 일수',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${trendData.where((data) => data['sessionCount'] > 0).length}일',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 