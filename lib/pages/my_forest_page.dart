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
import '../constants/app_colors.dart';

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
  Set<String> _selectedCategoryIds = {}; // 복수 선택을 위해 Set으로 변경
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
    return AppColors.focusMint;
  }

  // 날짜 기간별 필터링 함수 추가
  bool _isSessionInSelectedPeriod(FocusSessionModel session) {
    final sessionDate = session.createdAt;
    
    switch (_selectedPeriod) {
      case AnalyticsPeriod.day:
        // 선택된 날짜와 같은 날
        return sessionDate.year == _selectedDate.year &&
               sessionDate.month == _selectedDate.month &&
               sessionDate.day == _selectedDate.day;
               
      case AnalyticsPeriod.week:
        // 선택된 날짜가 포함된 주
        final weekStart = _getStartOfWeek(_selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return sessionDate.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
               sessionDate.isBefore(weekEnd.add(const Duration(days: 1)));
               
      case AnalyticsPeriod.month:
        // 선택된 날짜와 같은 월
        return sessionDate.year == _selectedDate.year &&
               sessionDate.month == _selectedDate.month;
               
      case AnalyticsPeriod.year:
        // 선택된 날짜와 같은 년
        return sessionDate.year == _selectedDate.year;
    }
  }

  // 필터링된 세션 데이터 반환 (날짜 기간 + 카테고리 필터링)
  List<FocusSessionModel> _getFilteredSessions() {
    List<FocusSessionModel> allSessions = [..._completedSessions, ..._abandonedSessions];
    
    // 날짜 기간별 필터링
    allSessions = allSessions.where(_isSessionInSelectedPeriod).toList();
    
    // 카테고리 필터링
    if (_selectedCategoryIds.isNotEmpty) {
      allSessions = allSessions.where((session) => 
          _selectedCategoryIds.contains(session.categoryId)).toList();
    }
    
    return allSessions;
  }

  List<FocusSessionModel> _getFilteredCompletedSessions() {
    List<FocusSessionModel> sessions = _completedSessions;
    
    // 날짜 기간별 필터링
    sessions = sessions.where(_isSessionInSelectedPeriod).toList();
    
    // 카테고리 필터링
    if (_selectedCategoryIds.isNotEmpty) {
      sessions = sessions.where((session) => 
          _selectedCategoryIds.contains(session.categoryId)).toList();
    }
    
    return sessions;
  }

  List<FocusSessionModel> _getFilteredAbandonedSessions() {
    List<FocusSessionModel> sessions = _abandonedSessions;
    
    // 날짜 기간별 필터링
    sessions = sessions.where(_isSessionInSelectedPeriod).toList();
    
    // 카테고리 필터링
    if (_selectedCategoryIds.isNotEmpty) {
      sessions = sessions.where((session) => 
          _selectedCategoryIds.contains(session.categoryId)).toList();
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
      backgroundColor: Colors.transparent,
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
            
            // 카테고리 분석
            _buildCategoryAnalysis(),
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
            color: _getThemeColor().withOpacity(0.1),
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
                    child: InkWell(
                      onTap: _showCategoryFilterDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                                  ? Icons.all_inclusive 
                                  : Icons.checklist,
                              size: 16,
                              color: _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                                  ? Colors.grey.shade600 
                                  : _getThemeColor(),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                                    ? '전체' 
                                    : '${_selectedCategoryIds.length}개 카테고리',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                                      ? Colors.grey.shade600 
                                      : _getThemeColor(),
                                  fontWeight: _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                                      ? FontWeight.normal 
                                      : FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ],
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
            onTap: _showPeriodPicker,
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
                        _getDateDisplayText(),
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
                      _getThemeColor().withOpacity(0.1),
                      _getThemeColor().withOpacity(0.2),
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
                      _selectedCategoryIds.isEmpty || _selectedCategoryIds.length == _categories.length
                          ? '${_selectedPeriod.displayName}별 전체 집중 기록 분석'
                          : '${_selectedCategoryIds.length}개 카테고리 집중 기록 분석',
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
                    builder: (context) => TreeGalleryPage(
                      currentUser: widget.currentUser,
                      filteredSessions: filteredSessions,
                      periodDescription: _getDateDisplayText(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.forest, size: 20),
              label: Text(
                '나무 갤러리 보기 (${filteredSessions.length}그루)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.focusMint.withOpacity(0.1),
                foregroundColor: AppColors.focusMint,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(
                  color: AppColors.focusMint.withOpacity(0.3),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
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
            color: Colors.grey.withOpacity(0.1),
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
            AnalyticsCharts.buildBarChart(
              data, 
              Colors.green.shade500,
              (index) => '${index}시', // 툴팁용으로 모든 시간 표시
              '분',
              barWidth: 10,
            ),
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
            AnalyticsCharts.buildBarChart(
              data, 
              Colors.green.shade500,
              (index) => '${index}일', // 툴팁용으로 모든 일자 표시
              '분',
              barWidth: 8,
            ),
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
            AnalyticsCharts.buildBarChart(
              data, 
              Colors.green.shade500,
              (index) => '${index}월', // 툴팁용으로 모든 월 표시
              '분',
              barWidth: 15,
            ),
          ],
        );
    }
  }

  Widget _buildPatternSummary(List<FocusSessionModel> sessions) {
    final peakTime = AnalyticsService.getPeakFocusAnalysis(sessions, _selectedPeriod.name);
    final successRate = AnalyticsService.getSuccessRateAnalysis(
      sessions, 
      _selectedDate, 
      _selectedPeriod.name,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  '패턴 요약',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    '최고 집중 시간',
                    peakTime['timeString'] ?? '데이터 없음',
                    '${peakTime['subtitle']}',
                    Icons.access_time,
                    Colors.green.shade600,
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
    final comparison = AnalyticsService.getSimplePeriodComparison(
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
            color: Colors.grey.withOpacity(0.1),
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
            ],
          ),
          const SizedBox(height: 16),
          
          // 현재 vs 이전 기간 비교
          _buildDetailedComparisonCard(
            comparison['currentLabel'],
            comparison['previousLabel'],
            comparison['currentTotal'],
            comparison['previousTotal'],
            true, // 첫 번째 비교
          ),
          
          const SizedBox(height: 12),
          
          // 현재 vs 전전 기간 비교
          _buildDetailedComparisonCard(
            comparison['currentLabel'],
            comparison['beforePreviousLabel'],
            comparison['currentTotal'],
            comparison['beforePreviousTotal'],
            false, // 두 번째 비교
          ),
          
          const SizedBox(height: 20),
          
          // 간단한 막대 비교 차트
          Text(
            '기간별 총 집중시간',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          
          AnalyticsCharts.buildSimpleComparisonChart(
            comparison['currentTotal'],
            comparison['previousTotal'],
            comparison['beforePreviousTotal'],
            comparison['currentLabel'],
            comparison['previousLabel'],
            comparison['beforePreviousLabel'],
            Colors.green.shade500,
            Colors.green.shade400,
            Colors.green.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedComparisonCard(
    String currentLabel,
    String compareLabel,
    double currentTotal,
    double compareTotal,
    bool isPrimaryComparison,
  ) {
    final difference = currentTotal - compareTotal;
    final isImproved = difference > 0;
    final changePercent = compareTotal > 0 ? ((difference / compareTotal) * 100) : 0.0;
    
    final backgroundColor = isImproved 
        ? Colors.green.shade50
        : Colors.orange.shade50;
    
    final borderColor = isImproved 
        ? Colors.green.shade200
        : Colors.orange.shade200;
    
    final iconColor = isImproved 
        ? Colors.green.shade600
        : Colors.orange.shade600;
    
    final textColor = isImproved 
        ? Colors.green.shade700
        : Colors.orange.shade700;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isImproved ? Icons.trending_up : Icons.trending_down,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$compareLabel 대비 ${difference.abs().toInt()}분 ${isImproved ? '증가' : '감소'}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${changePercent.abs().toInt()}% ${isImproved ? '상승' : '하락'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$currentLabel: ${currentTotal.toInt()}분 vs $compareLabel: ${compareTotal.toInt()}분',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAnalysis() {
    final allSessions = _getFilteredSessions();
    
    // 카테고리 정보 맵 구성
    final categoryInfo = <String, Map<String, dynamic>>{};
    for (final category in _categories) {
      categoryInfo[category.id] = {
        'name': category.name,
        'color': category.color,
        'icon': category.icon,
      };
    }
    
    final categoryAnalysis = AnalyticsService.getCategoryTimeAnalysis(allSessions, categoryInfo);
    final totalMinutes = categoryAnalysis.values.fold(0.0, (sum, data) => sum + (data['minutes'] as double));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                Icons.pie_chart,
                color: _getThemeColor(),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '카테고리 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 원형 차트
          AnalyticsCharts.buildCategoryPieChart(categoryAnalysis, totalMinutes),
          
          const SizedBox(height: 16),
          
          // 카테고리 요약 정보
          if (categoryAnalysis.isNotEmpty) ...[
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
                          '총 카테고리',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryAnalysis.length}개',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getThemeColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '가장 많이 한 카테고리',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryAnalysis.keys.first,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getThemeColor(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '집중 시간',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(categoryAnalysis.values.first['minutes'] as double).toInt()}분',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getThemeColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDFDFD),
                  Color(0xFFF8F9FA),
                  Color(0xFFF0F8F5),
                  Color(0xFFFFF8F3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: AppColors.focusMint.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.focusMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          color: AppColors.focusMint,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '카테고리 필터',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 컨텐츠
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 전체 선택/해제 버튼
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    setState(() {
                                      _selectedCategoryIds.clear();
                                      _selectedCategoryIds.addAll(_categories.map((c) => c.id));
                                    });
                                  });
                                },
                                icon: const Icon(Icons.select_all, size: 16),
                                label: const Text('전체 선택'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.focusMint.withOpacity(0.1),
                                  foregroundColor: AppColors.focusMint,
                                  elevation: 0,
                                  side: BorderSide(color: AppColors.focusMint.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setDialogState(() {
                                    setState(() => _selectedCategoryIds.clear());
                                  });
                                },
                                icon: const Icon(Icons.clear_all, size: 16),
                                label: const Text('전체 해제'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade100,
                                  foregroundColor: Colors.grey.shade600,
                                  elevation: 0,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.focusMint.withOpacity(0.1),
                                AppColors.focusMint.withOpacity(0.3),
                                AppColors.focusMint.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 카테고리 목록
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              children: _categories.map((category) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: _selectedCategoryIds.contains(category.id)
                                      ? AppColors.focusMint.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _selectedCategoryIds.contains(category.id)
                                        ? AppColors.focusMint.withOpacity(0.3)
                                        : Colors.grey.shade200,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  title: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: category.color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          category.icon,
                                          size: 18,
                                          color: category.color,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            color: category.color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: _selectedCategoryIds.contains(category.id),
                                  activeColor: AppColors.focusMint,
                                  checkColor: Colors.white,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      setState(() {
                                        if (value == true) {
                                          _selectedCategoryIds.add(category.id);
                                        } else {
                                          _selectedCategoryIds.remove(category.id);
                                        }
                                      });
                                    });
                                  },
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 하단 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.focusMint,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: AppColors.focusMint.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.day:
        _showDayPicker();
        break;
      case AnalyticsPeriod.week:
        _showWeekPicker();
        break;
      case AnalyticsPeriod.month:
        _showMonthPicker();
        break;
      case AnalyticsPeriod.year:
        _showYearPicker();
        break;
    }
  }

  Future<void> _showDayPicker() async {
    try {
      final picked = await showDatePicker(
        context: context,
        locale: const Locale('en', 'US'),
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _getThemeColor(),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.grey.shade800,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() => _selectedDate = picked);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('날짜 선택 기능은 모바일 앱에서 사용 가능합니다.'),
            backgroundColor: Colors.grey.shade300,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showWeekPicker() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: 500,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDFDFD),
                  Color(0xFFF8F9FA),
                  Color(0xFFF0F8F5),
                  Color(0xFFFFF8F3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: AppColors.focusMint.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.focusMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_view_week,
                          color: AppColors.focusMint,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '주 선택',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 컨텐츠
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 월 네비게이션
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  final prevMonth = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
                                  _selectedDate = prevMonth;
                                });
                              },
                              icon: Icon(Icons.chevron_left, color: AppColors.focusMint),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.focusMint.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${_selectedDate.year}년 ${_selectedDate.month}월',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  '주를 선택하세요',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  final nextMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
                                  _selectedDate = nextMonth;
                                });
                              },
                              icon: Icon(Icons.chevron_right, color: AppColors.focusMint),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.focusMint.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // 요일 헤더
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.focusMint.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.focusMint.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: ['월', '화', '수', '목', '금', '토', '일'].map((day) => 
                              Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.focusMint,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 달력 격자
                        Expanded(
                          child: _buildWeekCalendar(setDialogState),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 선택된 주 정보 표시
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.focusMint.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.focusMint.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.focusMint, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getSelectedWeekInfo(),
                                  style: TextStyle(
                                    color: AppColors.focusMint,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 하단 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '취소',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.focusMint,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppColors.focusMint.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            '확인',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
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
    );
  }

  Widget _buildWeekCalendar(StateSetter setDialogState) {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    
    // 달력 시작일 (월요일부터 시작하도록 조정)
    final startDate = firstDayOfMonth.subtract(Duration(days: firstDayOfMonth.weekday - 1));
    
    // 주별로 그룹화
    List<List<DateTime>> weeks = [];
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(lastDayOfMonth) || currentDate.month == _selectedDate.month) {
      List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(week);
      
      // 마지막 주가 완전히 다음 달로 넘어가면 중단
      if (week.every((day) => day.month != _selectedDate.month)) {
        break;
      }
    }
    
    final selectedWeekStart = _getStartOfWeek(_selectedDate);
    
    return Column(
      children: weeks.map((week) {
        final isSelectedWeek = week.any((day) => 
          _getStartOfWeek(day).isAtSameMomentAs(selectedWeekStart));
        final weekStart = _getStartOfWeek(week[0]);
        final now = DateTime.now();
        final currentWeekStart = _getStartOfWeek(now);
        final isFutureWeek = weekStart.isAfter(currentWeekStart);
        
        return Expanded(
          child: GestureDetector(
            onTap: !isFutureWeek ? () {
              setDialogState(() {
                setState(() {
                  _selectedDate = _getStartOfWeek(week[0]);
                });
              });
            } : null,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 1),
              decoration: BoxDecoration(
                color: isFutureWeek
                    ? Colors.grey.shade100
                    : isSelectedWeek 
                        ? _getThemeColor().withOpacity(0.2)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isFutureWeek
                    ? null
                    : isSelectedWeek 
                        ? Border.all(color: _getThemeColor(), width: 2)
                        : null,
              ),
              child: Row(
                children: week.map((day) {
                  final isCurrentMonth = day.month == _selectedDate.month;
                  final isToday = day.day == DateTime.now().day && 
                                  day.month == DateTime.now().month &&
                                  day.year == DateTime.now().year;
                  
                  return Expanded(
                    child: Container(
                      height: double.infinity,
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isToday 
                                ? _getThemeColor()
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isFutureWeek
                                    ? Colors.grey.shade400
                                    : isToday 
                                        ? Colors.white
                                        : isCurrentMonth 
                                            ? (isSelectedWeek ? _getThemeColor() : Colors.black87)
                                            : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getSelectedWeekInfo() {
    final weekStart = _getStartOfWeek(_selectedDate);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final weekNumber = _getWeekNumber(_selectedDate);
    
    return '선택된 주: ${weekStart.year}년 ${weekNumber}주차 (${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day})';
  }

  void _showMonthPicker() {
    DateTime tempSelectedDate = _selectedDate; // 임시 선택 날짜
    final now = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 450,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDFDFD),
                  Color(0xFFF8F9FA),
                  Color(0xFFF0F8F5),
                  Color(0xFFFFF8F3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    border: Border.all(
                      color: AppColors.focusMint.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.focusMint.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.calendar_view_month,
                          color: AppColors.focusMint,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '월 선택',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 컨텐츠
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // 년도 선택
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: tempSelectedDate.year > 2020 ? () {
                                setDialogState(() {
                                  tempSelectedDate = DateTime(tempSelectedDate.year - 1, tempSelectedDate.month, 1);
                                });
                              } : null,
                              icon: Icon(
                                Icons.chevron_left,
                                color: tempSelectedDate.year > 2020 ? AppColors.focusMint : Colors.grey.shade400,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: tempSelectedDate.year > 2020 
                                    ? AppColors.focusMint.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.focusMint.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.focusMint.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${tempSelectedDate.year}년',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.focusMint,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: tempSelectedDate.year < now.year ? () {
                                setDialogState(() {
                                  tempSelectedDate = DateTime(tempSelectedDate.year + 1, tempSelectedDate.month, 1);
                                });
                              } : null,
                              icon: Icon(
                                Icons.chevron_right,
                                color: tempSelectedDate.year < now.year ? AppColors.focusMint : Colors.grey.shade400,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: tempSelectedDate.year < now.year 
                                    ? AppColors.focusMint.withOpacity(0.1)
                                    : Colors.grey.shade100,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.focusMint.withOpacity(0.1),
                                AppColors.focusMint.withOpacity(0.3),
                                AppColors.focusMint.withOpacity(0.1),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        Expanded(
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                            itemCount: 12,
                            itemBuilder: (context, index) {
                              final month = index + 1;
                              final isSelected = month == tempSelectedDate.month && tempSelectedDate.year == _selectedDate.year;
                              final isPastMonth = tempSelectedDate.year < now.year || 
                                                 (tempSelectedDate.year == now.year && month <= now.month);
                              
                              return GestureDetector(
                                onTap: isPastMonth ? () {
                                  setDialogState(() {
                                    tempSelectedDate = DateTime(tempSelectedDate.year, month, 1);
                                  });
                                  setState(() {
                                    _selectedDate = tempSelectedDate;
                                  });
                                  Navigator.pop(context);
                                } : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !isPastMonth 
                                        ? Colors.grey.shade100
                                        : isSelected 
                                            ? AppColors.focusMint 
                                            : Colors.white.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: !isPastMonth
                                          ? Colors.grey.shade300
                                          : isSelected 
                                              ? AppColors.focusMint 
                                              : AppColors.focusMint.withOpacity(0.2),
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      if (isPastMonth)
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${month}월',
                                      style: TextStyle(
                                        color: !isPastMonth
                                            ? Colors.grey.shade400
                                            : isSelected 
                                                ? Colors.white 
                                                : AppColors.focusMint,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 14,
                                      ),
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
                ),
                
                // 하단 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.focusMint.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: AppColors.focusMint,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showYearPicker() {
    final now = DateTime.now();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: 450,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFDFDFD),
                Color(0xFFF8F9FA),
                Color(0xFFF0F8F5),
                Color(0xFFFFF8F3),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              // 헤더
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  border: Border.all(
                    color: AppColors.focusMint.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.focusMint.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: AppColors.focusMint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '년도 선택',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 컨텐츠
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: now.year - 2020 + 1,
                    itemBuilder: (context, index) {
                      final year = 2020 + index;
                      final isSelected = year == _selectedDate.year;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = DateTime(year, 1, 1);
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.focusMint 
                                : Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.focusMint 
                                  : AppColors.focusMint.withOpacity(0.2),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$year년',
                              style: TextStyle(
                                color: isSelected 
                                    ? Colors.white 
                                    : AppColors.focusMint,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // 하단 버튼
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.focusMint.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: AppColors.focusMint,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateDisplayText() {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.day:
        return '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일';
      case AnalyticsPeriod.week:
        final weekNumber = _getWeekNumber(_selectedDate);
        final weekStart = _getStartOfWeek(_selectedDate);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_selectedDate.year}년 ${weekNumber}주차 (${weekStart.month}/${weekStart.day} - ${weekEnd.month}/${weekEnd.day})';
      case AnalyticsPeriod.month:
        return '${_selectedDate.year}년 ${_selectedDate.month}월';
      case AnalyticsPeriod.year:
        return '${_selectedDate.year}년';
    }
  }

  // 주 번호를 계산하는 헬퍼 함수
  int _getWeekNumber(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final days = date.difference(jan1).inDays + 1;
    return ((days - jan1.weekday + 10) / 7).floor();
  }

  // 특정 년도의 특정 주차의 시작일을 구하는 함수
  DateTime _getDateOfWeek(int year, int weekNumber) {
    final jan1 = DateTime(year, 1, 1);
    final firstMonday = jan1.add(Duration(days: (8 - jan1.weekday) % 7));
    return firstMonday.add(Duration(days: (weekNumber - 1) * 7));
  }

  // 주의 시작일(월요일)을 구하는 함수
  DateTime _getStartOfWeek(DateTime date) {
    final difference = date.weekday - 1;
    return date.subtract(Duration(days: difference));
  }
} 