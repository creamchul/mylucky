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

      // 습관 추적기 목록 로드
      final habits = await HabitService.getAllHabitTrackers(_currentUser.id);
      
      // 습관 타입 투두 목록 로드
      final allTodos = await TodoService.getTodos(_currentUser.id);
      final habitTodos = allTodos.where((todo) => todo.isHabit).toList();
      
      // 습관 통계 로드
      final stats = await HabitService.getUserHabitStats(_currentUser.id);

      if (mounted) {
        setState(() {
          _habits = habits;
          _habitTodos = habitTodos;
          _stats = stats;
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print('습관 데이터 로드 완료: ${habits.length}개 습관, ${habitTodos.length}개 투두');
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
      backgroundColor: AppColors.scaffoldBackground,
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
                  '총 습관',
                  '${_stats['totalHabits'] ?? 0}개',
                  Icons.list_alt,
                  AppColors.blue600,
                ),
                _buildStatCard(
                  '오늘 완료',
                  '${_stats['habitsCompletedToday'] ?? 0}개',
                  Icons.today,
                  AppColors.green600,
                ),
                _buildStatCard(
                  '최장 연속',
                  '${_stats['longestStreak'] ?? 0}일',
                  Icons.local_fire_department,
                  AppColors.orange600,
                ),
                _buildStatCard(
                  '평균 완료율',
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
    final todayHabits = _habitTodos.where((todo) => 
      todo.isHabit && !todo.isCompleted
    ).toList();

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
    // 실제 습관 추적기 찾기 (없으면 null)
    HabitTrackerModel? actualHabit;
    try {
      actualHabit = _habits.firstWhere((h) => h.habitId == todo.id);
    } catch (e) {
      actualHabit = null;
    }
    
    // 습관 추적기가 없거나 기록이 없는 경우 기본값 사용
    HabitStats stats;
    int achievement;
    
    if (actualHabit == null || actualHabit.records.isEmpty) {
      stats = HabitStats.empty();
      achievement = 0;
    } else {
      stats = actualHabit.calculateStats();
      achievement = HabitService.calculateHabitAchievement(stats);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 카테고리
          Row(
            children: [
              Text(
                todo.categoryEmoji,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getAchievementColor(achievement).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$achievement%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getAchievementColor(achievement),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 통계 정보 (Wrap으로 변경하여 오버플로우 방지)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildHabitStatChip(
                '🔥${stats.currentStreak}',
                Icons.local_fire_department,
                AppColors.orange600,
              ),
              _buildHabitStatChip(
                '${(stats.completionRate * 100).round()}%',
                Icons.trending_up,
                AppColors.green600,
              ),
              _buildHabitStatChip(
                '최고${stats.bestStreak}',
                Icons.emoji_events,
                AppColors.purple600,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 진행 바
          LinearProgressIndicator(
            value: achievement / 100,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(_getAchievementColor(achievement)),
          ),
          
          // 기록이 없는 경우 안내 메시지
          if (actualHabit == null || actualHabit.records.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '아직 기록이 없습니다. 습관을 완료하면 통계가 표시됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey500,
                fontStyle: FontStyle.italic,
              ),
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
      default:
        return AppColors.grey600;
    }
  }

  // ========================================
  // 스낵바 메서드
  // ========================================

  void _showErrorSnackBar(String message) {
    if (mounted) {
      SnackBarUtils.showError(context, message);
    }
  }
} 