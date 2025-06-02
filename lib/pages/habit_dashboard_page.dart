import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/habit_service.dart';
import '../services/todo_service.dart';

// Utils imports
import '../utils/snackbar_utils.dart';

class HabitDashboardPage extends StatefulWidget {
  final UserModel currentUser;
  
  const HabitDashboardPage({super.key, required this.currentUser});

  @override
  State<HabitDashboardPage> createState() => _HabitDashboardPageState();
}

class _HabitDashboardPageState extends State<HabitDashboardPage>
    with TickerProviderStateMixin {
  
  late UserModel _currentUser;
  List<HabitTrackerModel> _habits = [];
  List<TodoItemModel> _habitTodos = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  
  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // 선택된 월 (달력용)
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    
    _currentUser = widget.currentUser;
    
    // 애니메이션 초기화
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadHabitData();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ========================================
  // 데이터 로딩
  // ========================================

  /// 습관 데이터 로드
  Future<void> _loadHabitData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 습관 타입 투두 목록 로드
      final allTodos = await TodoService.getTodos(_currentUser.id);
      final habitTodos = allTodos.where((todo) => todo.isHabit).toList();
      
      // 습관 통계 계산
      final stats = _calculateHabitStats(habitTodos);

      if (mounted) {
        setState(() {
          _habits = []; // HabitService 사용하지 않음
          _habitTodos = habitTodos;
          _stats = stats;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('습관 데이터 로드 완료: ${habitTodos.length}개 습관 투두');
      }
    } catch (e) {
      if (kDebugMode) {
        print('습관 데이터 로드 실패: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        _showErrorSnackBar('습관 데이터를 불러오는데 실패했습니다.');
      }
    }
  }

  /// 습관 통계 계산
  Map<String, dynamic> _calculateHabitStats(List<TodoItemModel> habitTodos) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    // 오늘 처리 가능한 습관만 필터링
    final todayAvailableHabits = habitTodos.where((todo) => todo.isCheckableToday).toList();
    
    // 오늘 완료된 습관 수 (오늘 처리 가능한 습관 중에서)
    final habitsCompletedToday = todayAvailableHabits.where((todo) {
      if (!todo.isCompleted || todo.completedAt == null) return false;
      final completedAt = todo.completedAt!;
      return completedAt.isAfter(todayStart) && completedAt.isBefore(todayEnd);
    }).length;
    
    // 최장 연속 달성 일수 (전체 습관 중에서)
    final longestStreak = habitTodos.isEmpty ? 0 : habitTodos.map((todo) => todo.bestStreak).reduce((a, b) => a > b ? a : b);
    
    // 평균 완료율 계산 (오늘 처리 가능한 습관만 고려)
    final totalTodayHabits = todayAvailableHabits.length;
    final completedTodayHabits = todayAvailableHabits.where((todo) => todo.isCompleted).length;
    final averageCompletionRate = totalTodayHabits == 0 ? 0.0 : completedTodayHabits / totalTodayHabits;
    
    return {
      'totalHabits': habitTodos.length, // 전체 습관 수는 유지
      'todayAvailableHabits': totalTodayHabits, // 오늘 처리 가능한 습관 수 추가
      'habitsCompletedToday': habitsCompletedToday,
      'longestStreak': longestStreak,
      'averageCompletionRate': averageCompletionRate,
    };
  }

  /// 데이터 새로고침
  Future<void> _refreshData() async {
    await _loadHabitData();
  }

  // ========================================
  // UI 빌더
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  /// 앱바 빌드
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.track_changes,
            color: AppColors.purple600,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            '습관 추적',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.purple700,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: AppColors.purple600,
          ),
          onPressed: _refreshData,
        ),
      ],
    );
  }

  /// 메인 바디 빌드
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 통계 요약
              _buildStatsOverview(),
              const SizedBox(height: 24),
              
              // 오늘의 습관
              _buildTodayHabits(),
              const SizedBox(height: 24),
              
              // 습관 목록
              _buildHabitsList(),
            ],
          ),
        ),
      ),
    );
  }

  /// 통계 요약 빌드
  Widget _buildStatsOverview() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppColors.purple600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '습관 통계',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 통계 그리드
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: [
                _buildStatCard(
                  '오늘 습관',
                  '${_stats['todayAvailableHabits'] ?? 0}개',
                  Icons.today,
                  AppColors.blue600,
                ),
                _buildStatCard(
                  '오늘 완료',
                  '${_stats['habitsCompletedToday'] ?? 0}개',
                  Icons.check_circle,
                  AppColors.green600,
                ),
                _buildStatCard(
                  '최장 연속',
                  '${_stats['longestStreak'] ?? 0}일',
                  Icons.local_fire_department,
                  AppColors.orange600,
                ),
                _buildStatCard(
                  '완료율',
                  '${((_stats['averageCompletionRate'] ?? 0.0) * 100).round()}%',
                  Icons.trending_up,
                  AppColors.purple600,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 통계 카드 빌드
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.grey600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// 오늘의 습관 빌드
  Widget _buildTodayHabits() {
    // isCheckableToday 속성을 사용하여 오늘 처리 가능한 습관만 필터링
    final todayHabits = _habitTodos.where((todo) {
      if (!todo.isHabit) return false;
      if (todo.isCompleted) return false;
      return todo.isCheckableToday; // 오늘 처리 가능한 습관만
    }).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.today,
                  color: AppColors.green600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '오늘의 습관',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green700,
                  ),
                ),
                const Spacer(),
                Text(
                  '${todayHabits.length}개 남음',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (todayHabits.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 48,
                      color: AppColors.green400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '오늘의 모든 습관을 완료했습니다!',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.green600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...todayHabits.map((todo) => _buildTodayHabitItem(todo)),
          ],
        ),
      ),
    );
  }

  /// 오늘의 습관 아이템 빌드
  Widget _buildTodayHabitItem(TodoItemModel todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            color: AppColors.grey400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (todo.streak > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🔥 ${todo.streak}일',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.orange600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getDifficultyColor(todo.difficulty).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              todo.difficulty.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _getDifficultyColor(todo.difficulty),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 습관 목록 빌드
  Widget _buildHabitsList() {
    if (_habitTodos.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.track_changes,
                  size: 64,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: 16),
                Text(
                  '아직 습관이 없습니다',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '오늘의 루틴에서 습관을 추가해보세요!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list,
                  color: AppColors.purple600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '모든 습관',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.purple700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ..._habitTodos.map((todo) => _buildHabitItem(todo)),
          ],
        ),
      ),
    );
  }

  /// 습관 아이템 빌드
  Widget _buildHabitItem(TodoItemModel todo) {
    // TodoItemModel에서 직접 통계 계산
    final currentStreak = todo.streak;
    final bestStreak = todo.bestStreak;
    final currentCount = todo.currentCount;
    final targetCount = todo.effectiveTargetCount;
    final habitProgress = todo.habitProgress; // 0.0 이상
    final completionRate = habitProgress; // 오늘의 완료율
    
    // 전체 성취도 계산을 단순화 - 목표 달성 시 100%
    final achievement = habitProgress >= 1.0 ? 100 : (habitProgress * 100).round();

    // 오늘 처리 가능한지 확인
    final isCheckableToday = todo.isCheckableToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCheckableToday ? AppColors.grey50 : AppColors.grey200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCheckableToday ? AppColors.grey200 : AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 카테고리
          Row(
            children: [
              Text(
                todo.categoryEmoji,
                style: TextStyle(
                  fontSize: 20,
                  color: isCheckableToday ? null : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCheckableToday ? AppColors.grey800 : AppColors.grey500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAchievementColor(achievement).withOpacity(isCheckableToday ? 0.1 : 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$achievement%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isCheckableToday ? _getAchievementColor(achievement) : AppColors.grey400,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 습관 상태 정보
          Row(
            children: [
              Icon(
                todo.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: todo.isCompleted 
                    ? (isCheckableToday ? AppColors.green600 : AppColors.grey400)
                    : AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                todo.isCompleted 
                    ? '완료됨' 
                    : (isCheckableToday ? '미완료' : '처리 불가'),
                style: TextStyle(
                  fontSize: 12,
                  color: todo.isCompleted 
                      ? (isCheckableToday ? AppColors.green600 : AppColors.grey500)
                      : (isCheckableToday ? AppColors.grey600 : AppColors.grey500),
                ),
              ),
              const Spacer(),
              Text(
                '목표: ${todo.habitProgressText}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCheckableToday ? AppColors.grey600 : AppColors.grey500,
                ),
              ),
            ],
          ),
          
          // 처리 불가 상태 표시
          if (!isCheckableToday && !todo.isCompleted) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getDisabledReason(todo),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 12),
          
          // 통계 정보
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildHabitStatChip(
                '🔥$currentStreak일',
                Icons.local_fire_department,
                AppColors.orange600,
              ),
              _buildHabitStatChip(
                '${achievement}%',
                Icons.trending_up,
                AppColors.green600,
              ),
              _buildHabitStatChip(
                '최고${bestStreak}일',
                Icons.emoji_events,
                AppColors.purple600,
              ),
              _buildHabitStatChip(
                todo.difficulty.displayName,
                Icons.star,
                _getDifficultyColor(todo.difficulty),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 진행 바 (오늘의 목표 달성률)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '오늘의 진행률',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    habitProgress >= 1.0 
                        ? '목표 달성! 100%'
                        : '${(habitProgress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: habitProgress >= 1.0 
                          ? AppColors.green600 
                          : _getProgressColor(habitProgress),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: habitProgress.clamp(0.0, 1.0), // 진행바는 최대 100%까지만 표시
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  habitProgress >= 1.0 ? AppColors.green600 : _getProgressColor(habitProgress)
                ),
                minHeight: 6,
              ),
            ],
          ),
          
          // 시작일/마감일 정보
          if (todo.startDate != null || todo.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (todo.startDate != null) ...[
                  Icon(
                    Icons.play_arrow,
                    size: 12,
                    color: AppColors.green600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${todo.startDate!.month}/${todo.startDate!.day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.green600,
                    ),
                  ),
                ],
                if (todo.startDate != null && todo.dueDate != null)
                  const SizedBox(width: 8),
                if (todo.dueDate != null) ...[
                  Icon(
                    Icons.flag,
                    size: 12,
                    color: AppColors.red600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${todo.dueDate!.month}/${todo.dueDate!.day}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.red600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 습관 통계 칩 빌드
  Widget _buildHabitStatChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 성취도에 따른 색상 반환
  Color _getAchievementColor(int achievement) {
    if (achievement >= 80) return AppColors.green600;
    if (achievement >= 60) return AppColors.orange600;
    if (achievement >= 40) return AppColors.yellow600;
    return AppColors.red600;
  }

  /// 난이도에 따른 색상 반환
  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.green600;
      case Difficulty.medium:
        return AppColors.orange600;
      case Difficulty.hard:
        return AppColors.red600;
    }
  }

  /// 진행률에 따른 색상 반환
  Color _getProgressColor(double progress) {
    if (progress >= 0.8) return AppColors.green600;
    if (progress >= 0.5) return AppColors.orange600;
    if (progress >= 0.3) return AppColors.yellow600;
    return AppColors.red600;
  }

  // ========================================
  // 스낵바 메서드
  // ========================================

  void _showErrorSnackBar(String message) {
    if (mounted) {
      SnackBarUtils.showError(context, message);
    }
  }

  String _getDisabledReason(TodoItemModel todo) {
    final today = DateTime.now();
    
    // 시작일이 미래인 경우
    if (todo.isBeforeStart) {
      final startDate = todo.startDate!;
      return '${startDate.month}/${startDate.day}부터 시작 가능';
    }
    
    // 마감일이 지난 경우
    if (todo.isOverdue) {
      return '마감일이 지났습니다';
    }
    
    // 반복 패턴에 따른 처리 불가
    if (todo.repeatPattern != null) {
      final pattern = todo.repeatPattern!;
      
      switch (pattern.repeatType) {
        case RepeatType.weekly:
          if (pattern.weekdays != null && pattern.weekdays!.isNotEmpty) {
            final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
            final availableWeekdays = pattern.weekdays!.map((w) => weekdayNames[w - 1]);
            if (availableWeekdays.length <= 3) {
              return '${availableWeekdays.join(', ')} 요일에만 처리 가능';
            } else {
              final excludedCount = 7 - availableWeekdays.length;
              final firstThree = availableWeekdays.take(3).join(', ');
              return '$firstThree 외 ${excludedCount}개 요일에만 처리 가능';
            }
          }
          break;
          
        case RepeatType.monthly:
          if (pattern.monthDays != null && pattern.monthDays!.isNotEmpty) {
            final days = pattern.monthDays!;
            if (days.length <= 3) {
              final dayTexts = days.map((d) => d == 99 ? '말일' : '${d}일');
              return '매월 ${dayTexts.join(', ')}에만 처리 가능';
            } else {
              final remainingCount = days.length - 3;
              final firstThree = days.take(3).map((d) => d == 99 ? '말일' : '${d}일');
              return '매월 ${firstThree.join(', ')} 외 ${remainingCount}개 날짜에만 처리 가능';
            }
          }
          break;
          
        case RepeatType.custom:
          if (pattern.customInterval != null) {
            return '${pattern.customInterval}일마다 반복';
          }
          break;
          
        case RepeatType.daily:
        case RepeatType.yearly:
          break;
      }
    }
    
    return '오늘은 처리할 수 없습니다';
  }
} 