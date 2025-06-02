import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';
import '../models/models.dart';
import '../models/mood_entry_model.dart';
import '../services/mood_service.dart';

class MoodStatisticsPage extends StatefulWidget {
  final UserModel currentUser;

  const MoodStatisticsPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<MoodStatisticsPage> createState() => _MoodStatisticsPageState();
}

class _MoodStatisticsPageState extends State<MoodStatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<MoodType, int> _moodStatistics = {};
  Map<String, int> _activityStatistics = {};
  List<MoodEntryModel> _recentEntries = [];
  Map<String, List<MoodEntryModel>> _monthlyEntries = {};
  Map<String, Map<MoodType, int>> _activityMoodAnalysis = {};
  int _consecutiveDays = 0;
  int _selectedPeriod = 30; // 기본 30일
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStatistics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final [moodStats, activityStats, recentEntries, consecutiveDays, monthlyEntries] = await Future.wait([
        MoodService.getMoodStatistics(widget.currentUser.id, days: _selectedPeriod),
        MoodService.getActivityStatistics(widget.currentUser.id, days: _selectedPeriod),
        MoodService.getAllMoodEntries(widget.currentUser.id),
        MoodService.getConsecutiveDays(widget.currentUser.id),
        MoodService.getGroupedMoodEntriesByMonth(widget.currentUser.id, _selectedYear, _selectedMonth),
      ]);

      // 활동별 감정 분석 계산
      final activityMoodAnalysis = await _calculateActivityMoodAnalysis();

      setState(() {
        _moodStatistics = moodStats as Map<MoodType, int>;
        _activityStatistics = activityStats as Map<String, int>;
        _recentEntries = (recentEntries as List<MoodEntryModel>).take(30).toList();
        _consecutiveDays = consecutiveDays as int;
        _monthlyEntries = monthlyEntries as Map<String, List<MoodEntryModel>>;
        _activityMoodAnalysis = activityMoodAnalysis;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('통계 로딩 실패: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, Map<MoodType, int>>> _calculateActivityMoodAnalysis() async {
    try {
      final allEntries = await MoodService.getAllMoodEntries(widget.currentUser.id);
      final Map<String, Map<MoodType, int>> analysis = {};

      for (final entry in allEntries) {
        for (final activity in entry.activities) {
          analysis[activity] = analysis[activity] ?? {};
          for (final mood in MoodType.values) {
            analysis[activity]![mood] = analysis[activity]![mood] ?? 0;
          }
          analysis[activity]![entry.mood] = analysis[activity]![entry.mood]! + 1;
        }
      }

      return analysis;
    } catch (e) {
      if (kDebugMode) {
        print('활동별 감정 분석 계산 실패: $e');
      }
      return {};
    }
  }

  void _changePeriod(int days) {
    setState(() => _selectedPeriod = days);
    _loadStatistics();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.analytics,
              color: const Color(0xFFEC407A),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '감정 통계',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFEC407A),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFFEC407A),
          tabs: const [
            Tab(text: '대시보드'),
            Tab(text: '달력'),
            Tab(text: '활동 분석'),
          ],
        ),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC407A)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildCalendarTab(),
                  _buildActivityAnalysisTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 16),
          _buildConsecutiveDaysCard(),
          const SizedBox(height: 16),
          _buildMoodChartCard(),
          const SizedBox(height: 16),
          _buildWeeklyTrendCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildMoodCalendar(),
        ],
      ),
    );
  }

  Widget _buildActivityAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTopActivitiesCard(),
          const SizedBox(height: 16),
          _buildActivityMoodAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'days': 7, 'label': '7일'},
      {'days': 30, 'label': '30일'},
      {'days': 90, 'label': '90일'},
      {'days': 0, 'label': '전체'},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.map((period) {
          final days = period['days'] as int;
          final isSelected = (days == 0 && _selectedPeriod == 0) || 
                           (days != 0 && _selectedPeriod == days);
          return Expanded(
            child: GestureDetector(
              onTap: () => _changePeriod(days),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEC407A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConsecutiveDaysCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC407A).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 48,
            color: Colors.orange.shade500,
          ),
          const SizedBox(height: 12),
          Text(
            '$_consecutiveDays일',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade500,
            ),
          ),
          Text(
            '연속 기록 중',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _consecutiveDays > 0 
                ? '대단해요! 꾸준한 기록을 이어가고 있어요 🔥'
                : '오늘부터 감정일기를 시작해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChartCard() {
    final totalCount = _moodStatistics.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '감정 분포',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          if (totalCount == 0) ...[
            _buildEmptyChart(),
          ] else ...[
            _buildMoodPieChart(),
            const SizedBox(height: 16),
            _buildMoodLegend(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_neutral,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              '아직 기록이 없어요',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodPieChart() {
    // 간단한 원형차트 (fl_chart 없이 구현)
    final totalCount = _moodStatistics.values.fold(0, (sum, count) => sum + count);
    
    return Container(
      height: 200,
      child: Center(
        child: Stack(
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: CustomPaint(
                painter: MoodPieChartPainter(_moodStatistics, totalCount),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalCount',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      '총 기록',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodLegend() {
    final sortedMoods = _moodStatistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMoods.map((entry) {
        final mood = entry.key;
        final count = entry.value;
        final totalCount = _moodStatistics.values.fold(0, (sum, c) => sum + c);
        final percentage = totalCount > 0 ? (count / totalCount * 100) : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mood.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                '${count}회 (${percentage.toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyTrendCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '요일별 감정 트렌드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeeklyTrendChart(),
        ],
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    // 요일별 감정 통계 계산
    final weeklyMoodCounts = <int, Map<MoodType, int>>{};
    
    for (final entry in _recentEntries) {
      final weekday = entry.createdAt.weekday % 7; // 0: 일요일, 1: 월요일 ... 6: 토요일
      weeklyMoodCounts[weekday] = weeklyMoodCounts[weekday] ?? {};
      weeklyMoodCounts[weekday]![entry.mood] = 
          (weeklyMoodCounts[weekday]![entry.mood] ?? 0) + 1;
    }

    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    
    return Column(
      children: List.generate(7, (index) {
        final moodCounts = weeklyMoodCounts[index] ?? {};
        final totalCount = moodCounts.values.fold(0, (sum, count) => sum + count);
        final dominantMood = moodCounts.isNotEmpty 
            ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  weekdays[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (dominantMood != null) ...[
                Text(
                  dominantMood.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dominantMood.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  '${totalCount}회',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Text(
                    '기록 없음',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEC407A).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: Icon(
              Icons.chevron_left,
              color: const Color(0xFFEC407A),
            ),
          ),
          Text(
            '${_selectedYear}년 ${_selectedMonth}월',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: Icon(
              Icons.chevron_right,
              color: const Color(0xFFEC407A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCalendar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '감정 달력',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDayOfMonth = DateTime(_selectedYear, _selectedMonth + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0: 일요일, 1: 월요일, ..., 6: 토요일
    final daysInMonth = lastDayOfMonth.day;

    const weekDays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        // 요일 헤더
        Row(
          children: weekDays.map((day) => Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        // 달력 그리드
        ...List.generate((daysInMonth + firstWeekday + 6) ~/ 7, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return Expanded(child: Container(height: 50));
              }

              final dateKey = '${_selectedYear}-${_selectedMonth.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final dayEntries = _monthlyEntries[dateKey] ?? [];
              
              return Expanded(
                child: _buildCalendarDay(dayNumber, dayEntries),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildCalendarDay(int day, List<MoodEntryModel> entries) {
    final isToday = DateTime.now().year == _selectedYear &&
        DateTime.now().month == _selectedMonth &&
        DateTime.now().day == day;

    // 주요 감정 계산 (가장 많이 나타난 감정)
    MoodType? dominantMood;
    if (entries.isNotEmpty) {
      final moodCounts = <MoodType, int>{};
      for (final entry in entries) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
      dominantMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      height: 50,
      decoration: BoxDecoration(
        color: isToday 
            ? const Color(0xFFEC407A).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isToday 
            ? Border.all(color: const Color(0xFFEC407A), width: 1)
            : null,
      ),
      child: Stack(
        children: [
          // 날짜 숫자
          Positioned(
            top: 4,
            left: 4,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday 
                    ? const Color(0xFFEC407A)
                    : Colors.grey.shade700,
              ),
            ),
          ),
          // 감정 스티커
          if (dominantMood != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getMoodStickerColor(dominantMood),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    dominantMood.emoji,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          // 다중 기록 표시
          if (entries.length > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFEC407A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    '${entries.length}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getMoodStickerColor(MoodType mood) {
    switch (mood) {
      case MoodType.amazing:
        return const Color(0xFFFFE5B4); // 밝은 골드
      case MoodType.good:
        return const Color(0xFFB8F5B8); // 밝은 초록
      case MoodType.normal:
        return const Color(0xFFF0F0F0); // 연한 회색
      case MoodType.bad:
        return const Color(0xFFFFD4B8); // 연한 주황
      case MoodType.terrible:
        return const Color(0xFFE8D5FF); // 연한 보라
    }
  }

  Widget _buildTopActivitiesCard() {
    final sortedActivities = _activityStatistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topActivities = sortedActivities.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP 5 활동',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          if (topActivities.isEmpty) ...[
            Center(
              child: Text(
                '아직 활동 기록이 없어요',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ] else ...[
            ...topActivities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value.key;
              final count = entry.value.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC407A).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEC407A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('🏃', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activity,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Text(
                      '${count}회',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityMoodAnalysis() {
    final sortedActivities = _activityMoodAnalysis.entries.toList()
      ..sort((a, b) {
        final aTotalCount = a.value.values.fold(0, (sum, count) => sum + count);
        final bTotalCount = b.value.values.fold(0, (sum, count) => sum + count);
        return bTotalCount.compareTo(aTotalCount);
      });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '활동별 감정 분석',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '각 활동을 할 때 어떤 감정을 주로 느끼는지 확인해보세요',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedActivities.isEmpty) ...[
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '아직 활동 기록이 없어요',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '감정일기를 작성할 때 활동을 추가해보세요',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ...sortedActivities.take(10).map((entry) {
              final activityName = entry.key;
              final moodCounts = entry.value;
              final totalCount = moodCounts.values.fold(0, (sum, count) => sum + count);
              
              // 가장 많은 감정 찾기
              final dominantMoodEntry = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
              final dominantMood = dominantMoodEntry.key;
              final dominantPercentage = (dominantMoodEntry.value / totalCount * 100).round();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🏃',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activityName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC407A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${totalCount}회',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFEC407A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '주요 감정: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          dominantMood.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${dominantMood.displayName} ${dominantPercentage}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 감정 분포 바
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: Colors.grey.shade200,
                            ),
                            child: Row(
                              children: MoodType.values.map((mood) {
                                final count = moodCounts[mood] ?? 0;
                                final percentage = count / totalCount;
                                return Expanded(
                                  flex: (percentage * 100).round(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getMoodStickerColor(mood),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 세부 감정 분포
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: moodCounts.entries.where((e) => e.value > 0).map((entry) {
                        final mood = entry.key;
                        final count = entry.value;
                        final percentage = (count / totalCount * 100).round();
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getMoodStickerColor(mood),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${mood.emoji} ${percentage}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// 간단한 원형차트 페인터
class MoodPieChartPainter extends CustomPainter {
  final Map<MoodType, int> moodStats;
  final int totalCount;

  MoodPieChartPainter(this.moodStats, this.totalCount);

  @override
  void paint(Canvas canvas, Size size) {
    if (totalCount == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    
    double startAngle = 0;
    
    for (final entry in moodStats.entries) {
      if (entry.value == 0) continue;
      
      final sweepAngle = (entry.value / totalCount) * 2 * 3.14159;
      final paint = Paint()
        ..color = _getMoodColor(entry.key)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.amazing:
        return const Color(0xFFFFD54F); // 밝은 골드
      case MoodType.good:
        return const Color(0xFF81C784); // 밝은 초록
      case MoodType.normal:
        return const Color(0xFF90A4AE); // 연한 회색
      case MoodType.bad:
        return const Color(0xFFFF8A65); // 연한 주황
      case MoodType.terrible:
        return const Color(0xFFBA68C8); // 연한 보라
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
} 