import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/todo_service.dart';
import '../services/user_service.dart';

// Widgets imports
import '../widgets/todo_add_dialog.dart';
import '../widgets/todo_edit_dialog.dart';
import '../widgets/todo_filter_dialog.dart';
import '../widgets/todo_stats_dialog.dart';

// Pages imports
import 'habit_dashboard_page.dart';

// Utils imports
import '../utils/snackbar_utils.dart';

class TodoListPage extends StatefulWidget {
  final UserModel currentUser;
  
  const TodoListPage({super.key, required this.currentUser});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  
  late UserModel _currentUser;
  List<TodoItemModel> _todos = [];
  List<TodoItemModel> _todayTodos = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // 필터링 상태
  TodoFilterState _currentFilter = const TodoFilterState();
  
  // 캐시된 필터링 결과
  List<TodoItemModel>? _cachedFilteredTodayTodos;
  List<TodoItemModel>? _cachedFilteredAllTodos;
  List<TodoItemModel>? _cachedFilteredCompletedTodos;
  TodoFilterState? _lastFilterForCache;
  List<TodoItemModel>? _lastTodosForCache;
  List<TodoItemModel>? _lastTodayTodosForCache;
  
  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // 탭 컨트롤러
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
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
    
    // 탭 컨트롤러 초기화
    _tabController = TabController(length: 3, vsync: this);
    
    _loadTodos();
    _fadeController.forward();
    
    // 어제 습관 결과 확인 (앱 시작 후 잠시 후에 표시)
    Future.delayed(const Duration(milliseconds: 1500), () {
      _checkYesterdayHabits();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshTodos();
    }
  }

  // ========================================
  // 데이터 로딩
  // ========================================

  /// 투두 목록 로드
  Future<void> _loadTodos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final todos = await TodoService.getTodos(_currentUser.id);
      final todayTodos = await TodoService.getTodayTodos(_currentUser.id);

      if (mounted) {
        setState(() {
          _todos = todos;
          _todayTodos = todayTodos;
          _isLoading = false;
          // 데이터가 변경되었으므로 캐시 무효화
          _invalidateCache();
        });
      }

      if (kDebugMode) {
        print('투두 목록 로드 완료: 전체 ${todos.length}개, 오늘 ${todayTodos.length}개');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 목록 로드 실패: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        SnackBarUtils.showError(context, '투두 목록을 불러오는데 실패했습니다.');
      }
    }
  }

  /// 투두 목록 새로고침
  Future<void> _refreshTodos() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    await _loadTodos();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  /// 캐시 무효화
  void _invalidateCache() {
    _cachedFilteredTodayTodos = null;
    _cachedFilteredAllTodos = null;
    _cachedFilteredCompletedTodos = null;
    _lastFilterForCache = null;
    _lastTodosForCache = null;
    _lastTodayTodosForCache = null;
  }

  /// 캐시가 유효한지 확인
  bool _isCacheValid() {
    return _lastFilterForCache == _currentFilter &&
           _lastTodosForCache == _todos &&
           _lastTodayTodosForCache == _todayTodos;
  }

  /// 오늘의 할일 필터링 (캐시 사용)
  List<TodoItemModel> _getFilteredTodayTodos() {
    if (_cachedFilteredTodayTodos != null && _isCacheValid()) {
      return _cachedFilteredTodayTodos!;
    }

    var filteredTodayTodos = List<TodoItemModel>.from(_todayTodos);
    
    // 할일 유형 필터
    if (_currentFilter.type != null) {
      filteredTodayTodos = filteredTodayTodos.where((todo) => todo.type == _currentFilter.type).toList();
    }
    
    // 카테고리 필터
    if (_currentFilter.category != null) {
      filteredTodayTodos = filteredTodayTodos.where((todo) => todo.category == _currentFilter.category).toList();
    }
    
    // 우선순위 필터
    if (_currentFilter.priority != null) {
      filteredTodayTodos = filteredTodayTodos.where((todo) => todo.priority == _currentFilter.priority).toList();
    }
    
    // 난이도 필터
    if (_currentFilter.difficulty != null) {
      filteredTodayTodos = filteredTodayTodos.where((todo) => todo.difficulty == _currentFilter.difficulty).toList();
    }
    
    // 완료 상태 필터
    if (_currentFilter.isCompleted != null) {
      filteredTodayTodos = filteredTodayTodos.where((todo) => todo.isCompleted == _currentFilter.isCompleted).toList();
    }
    
    // 태그 필터
    if (_currentFilter.tags.isNotEmpty) {
      filteredTodayTodos = filteredTodayTodos.where((todo) {
        return _currentFilter.tags.any((filterTag) => todo.tags.contains(filterTag));
      }).toList();
    }

    // 캐시 업데이트
    _cachedFilteredTodayTodos = filteredTodayTodos;
    _lastFilterForCache = _currentFilter;
    _lastTodosForCache = _todos;
    _lastTodayTodosForCache = _todayTodos;

    return filteredTodayTodos;
  }

  // ========================================
  // 투두 액션
  // ========================================

  /// 투두 완료 처리
  Future<void> _completeTodo(TodoItemModel todo) async {
    try {
      final result = await TodoService.completeTodo(
        userId: _currentUser.id,
        todoId: todo.id,
        currentUser: _currentUser,
      );

      // 사용자 정보 업데이트
      setState(() {
        _currentUser = result['user'] as UserModel;
      });

      // 반복 할일 다음 인스턴스 생성 비활성화 (일회성처럼 처리)
      // if (todo.isRepeating) {
      //   await TodoService.createNextRepeatInstance(result['todo'] as TodoItemModel);
      // }

      // 목록 새로고침
      await _refreshTodos();

      // 완료 알림 (포인트 알림 제거)
      SnackBarUtils.showSuccess(context, '할일을 완료했습니다! 🎉');

      if (kDebugMode) {
        print('투두 완료 처리 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 완료 처리 실패: $e');
      }
      SnackBarUtils.showError(context, '할일 완료 처리에 실패했습니다.');
    }
  }

  /// 투두 삭제
  Future<void> _deleteTodo(TodoItemModel todo) async {
    // 확인 다이얼로그
    final confirmed = await _showDeleteConfirmDialog(todo.title);
    if (!confirmed) return;

    try {
      await TodoService.deleteTodo(
        userId: _currentUser.id,
        todoId: todo.id,
      );

      await _refreshTodos();
      SnackBarUtils.showSuccess(context, '할일이 삭제되었습니다.');

      if (kDebugMode) {
        print('투두 삭제 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 삭제 실패: $e');
      }
      SnackBarUtils.showError(context, '할일 삭제에 실패했습니다.');
    }
  }

  /// 투두 완료 취소
  Future<void> _uncompleteTodo(TodoItemModel todo) async {
    try {
      final result = await TodoService.uncompleteTodo(
        userId: _currentUser.id,
        todoId: todo.id,
        currentUser: _currentUser,
      );

      // 사용자 정보 업데이트
      setState(() {
        _currentUser = result['user'] as UserModel;
      });

      // 목록 새로고침
      await _refreshTodos();
      
      SnackBarUtils.showSuccess(context, '할일 완료가 취소되었습니다.');

      if (kDebugMode) {
        print('투두 완료 취소 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 완료 취소 실패: $e');
      }
      SnackBarUtils.showError(context, '할일 완료 취소에 실패했습니다.');
    }
  }

  /// 습관 진행률 증가
  Future<void> _incrementHabitProgress(TodoItemModel todo) async {
    try {
      if (kDebugMode) {
        print('UI: 습관 진행률 증가 시작 - ${todo.title}');
      }
      
      final result = await TodoService.incrementHabitProgress(
        userId: _currentUser.id,
        todoId: todo.id,
        currentUser: _currentUser,
      );

      if (kDebugMode) {
        print('UI: TodoService.incrementHabitProgress 완료');
        print('UI: result keys: ${result.keys.toList()}');
        print('UI: isCompleted: ${result['isCompleted']}');
      }

      // 사용자 정보 업데이트
      if (result['user'] != null) {
        setState(() {
          _currentUser = result['user'] as UserModel;
        });
        if (kDebugMode) {
          print('UI: 사용자 정보 업데이트 완료');
        }
      }

      // 목록 새로고침
      if (kDebugMode) {
        print('UI: 목록 새로고침 시작');
      }
      await _refreshTodos();
      if (kDebugMode) {
        print('UI: 목록 새로고침 완료');
      }

      // 진행률 피드백 - 최적화된 스낵바 사용
      final updatedTodo = result['todo'] as TodoItemModel;
      final isCompleted = result['isCompleted'] as bool? ?? false;
      final progressText = result['progressText'] as String? ?? '';

      if (kDebugMode) {
        print('UI: 피드백 준비 - isCompleted: $isCompleted, progressText: $progressText');
      }

      if (isCompleted) {
        SnackBarUtils.showHabitProgress(
          context, 
          '${updatedTodo.title} 완료!',
          isCompleted: true,
        );
      } else {
        SnackBarUtils.showHabitProgress(
          context, 
          progressText,
          isCompleted: false,
        );
      }

      if (kDebugMode) {
        print('UI: 습관 진행률 증가 완료: ${todo.title} - $progressText');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('UI: 습관 진행률 증가 실패: $e');
        print('UI: 스택 트레이스: $stackTrace');
      }
      SnackBarUtils.showError(context, '습관 진행률 업데이트에 실패했습니다.');
    }
  }

  /// 어제 습관 결과 확인 및 표시
  Future<void> _checkYesterdayHabits() async {
    if (!mounted) return;
    
    try {
      final summary = await TodoService.getYesterdayHabitSummary(_currentUser.id);
      
      if (summary['hasResults'] == true && mounted) {
        _showYesterdayHabitSummary(summary);
      }
    } catch (e) {
      if (kDebugMode) {
        print('어제 습관 결과 확인 실패: $e');
      }
    }
  }

  /// 어제 습관 결과 요약 다이얼로그 표시
  void _showYesterdayHabitSummary(Map<String, dynamic> summary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.history,
              color: AppColors.purple600,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              '어제의 습관 결과',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary['summaryMessage'] ?? '',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (summary['results'] != null) ...[
              const Text(
                '상세 결과:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...((summary['results'] as List).map((result) {
                final completionRate = (result['completionRate'] as double) * 100;
                String statusEmoji = '';
                if (result['isCompleted'] == true) {
                  statusEmoji = '🎉';
                } else if (result['currentCount'] > 0) {
                  statusEmoji = '😊';
                } else {
                  statusEmoji = '😞';
                }
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(statusEmoji),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${result['title']}: ${result['currentCount']}/${result['targetCount']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${completionRate.toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: completionRate >= 100 ? AppColors.green600 : AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()),
            ],
            const SizedBox(height: 16),
            Text(
              '오늘도 화이팅! 💪',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.purple700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '확인',
              style: TextStyle(
                color: AppColors.purple600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// 앱바 빌드
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.purple600,
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            '오늘의 루틴',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        // 필터 버튼
        Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: AppColors.purple600,
              ),
              onPressed: _showFilterDialog,
            ),
            if (_currentFilter.hasAnyFilter)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        // 습관 대시보드 버튼
        IconButton(
          icon: Icon(
            Icons.track_changes,
            color: AppColors.purple600,
          ),
          onPressed: _showHabitDashboard,
          tooltip: '습관 추적',
        ),
        // 통계 버튼
        IconButton(
          icon: Icon(
            Icons.analytics_outlined,
            color: AppColors.purple600,
          ),
          onPressed: _showStatsDialog,
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.purple700,
        unselectedLabelColor: AppColors.grey600,
        indicatorColor: AppColors.purple600,
        tabs: const [
          Tab(text: '오늘', icon: Icon(Icons.today)),
          Tab(text: '전체', icon: Icon(Icons.list)),
          Tab(text: '완료', icon: Icon(Icons.done_all)),
        ],
      ),
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
        onRefresh: _refreshTodos,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTodayTab(),
            _buildAllTodosTab(),
            _buildCompletedTab(),
          ],
        ),
      ),
    );
  }

  /// 오늘 탭 빌드
  Widget _buildTodayTab() {
    final filteredTodayTodos = _getFilteredTodayTodos();

    if (filteredTodayTodos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.today,
        title: '오늘 할일이 없습니다',
        subtitle: '새로운 할일을 추가해보세요!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTodayTodos.length,
      itemBuilder: (context, index) {
        final todo = filteredTodayTodos[index];
        return _buildTodoItem(todo);
      },
    );
  }

  /// 전체 투두 탭 빌드
  Widget _buildAllTodosTab() {
    final filteredTodos = _getFilteredTodos();

    if (filteredTodos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment,
        title: '할일이 없습니다',
        subtitle: '첫 번째 할일을 추가해보세요!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTodos.length,
      itemBuilder: (context, index) {
        final todo = filteredTodos[index];
        return _buildTodoItem(todo);
      },
    );
  }

  /// 완료된 투두 탭 빌드
  Widget _buildCompletedTab() {
    var completedTodos = _todos.where((todo) => todo.isCompleted).toList();
    
    // 완료된 할일에도 필터 적용 (완료 상태 필터 제외)
    // 날짜 필터
    if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
      completedTodos = completedTodos.where((todo) {
        if (todo.createdAt.isAfter(_currentFilter.startDate!) && 
            todo.createdAt.isBefore(_currentFilter.endDate!)) {
          return true;
        }
        if (todo.dueDate != null) {
          return todo.dueDate!.isAfter(_currentFilter.startDate!) && 
                 todo.dueDate!.isBefore(_currentFilter.endDate!);
        }
        return false;
      }).toList();
    }
    
    // 할일 유형 필터
    if (_currentFilter.type != null) {
      completedTodos = completedTodos.where((todo) => todo.type == _currentFilter.type).toList();
    }
    
    // 카테고리 필터
    if (_currentFilter.category != null) {
      completedTodos = completedTodos.where((todo) => todo.category == _currentFilter.category).toList();
    }
    
    // 우선순위 필터
    if (_currentFilter.priority != null) {
      completedTodos = completedTodos.where((todo) => todo.priority == _currentFilter.priority).toList();
    }
    
    // 난이도 필터
    if (_currentFilter.difficulty != null) {
      completedTodos = completedTodos.where((todo) => todo.difficulty == _currentFilter.difficulty).toList();
    }
    
    // 태그 필터
    if (_currentFilter.tags.isNotEmpty) {
      completedTodos = completedTodos.where((todo) {
        // 선택된 태그 중 하나라도 포함하면 표시
        return _currentFilter.tags.any((filterTag) => todo.tags.contains(filterTag));
      }).toList();
    }

    if (completedTodos.isEmpty) {
      return _buildEmptyState(
        icon: Icons.done_all,
        title: '완료된 할일이 없습니다',
        subtitle: '할일을 완료하면 여기에 표시됩니다.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedTodos.length,
      itemBuilder: (context, index) {
        final todo = completedTodos[index];
        return _buildTodoItem(todo);
      },
    );
  }

  /// 투두 아이템 빌드
  Widget _buildTodoItem(TodoItemModel todo) {
    final isBeforeStart = todo.isBeforeStart;
    
    // 체크할 수 없는 할일인지 확인 (반복 패턴 때문에 오늘 해당하지 않는 경우 포함)
    final isCheckable = todo.isCheckableToday;
    final shouldShowAsDisabled = !isCheckable && !todo.isCompleted;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // 완료된 할일은 연한 녹색, 비활성화된 할일은 회색으로 표시
      color: todo.isCompleted 
          ? Colors.green.shade50
          : (shouldShowAsDisabled 
              ? AppColors.grey50.withOpacity(0.7)
              : null),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildTodoLeading(todo),
        title: Row(
          children: [
            Expanded(
              child: Text(
                todo.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  // 줄 긋기 제거
                  decoration: null,
                  color: todo.isCompleted 
                      ? AppColors.green700  // 완료된 할일은 진한 녹색 텍스트
                      : (shouldShowAsDisabled ? AppColors.grey500 : AppColors.grey800),
                ),
              ),
            ),
            // 비활성화된 할일 표시 아이콘
            if (shouldShowAsDisabled) ...[
              const SizedBox(width: 8),
              Icon(
                isBeforeStart ? Icons.pause_circle_outline : (todo.isRepeating && todo.repeatPattern != null ? Icons.event_busy : Icons.schedule),
                size: 16,
                color: AppColors.grey500,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description,
                style: TextStyle(
                  fontSize: 14,
                  color: shouldShowAsDisabled ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
            ],
            // 습관 진행률 표시
            if (todo.isHabit && !todo.isCompleted) ...[
              const SizedBox(height: 8),
              _buildHabitProgress(todo),
            ],
            // 시작일 표시
            if (todo.startDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: AppColors.green600),
                  const SizedBox(width: 4),
                  Text(
                    '시작: '
                    + '${todo.startDate!.year}.${todo.startDate!.month.toString().padLeft(2, '0')}.${todo.startDate!.day.toString().padLeft(2, '0')}'
                    + (todo.startDate!.hour != 0 || todo.startDate!.minute != 0 ? ' ${todo.startDate!.hour.toString().padLeft(2, '0')}:${todo.startDate!.minute.toString().padLeft(2, '0')}' : ''),
                    style: TextStyle(fontSize: 12, color: AppColors.green600),
                  ),
                ],
              ),
            ],
            // 마감일 표시
            if (todo.dueDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.blue600),
                  const SizedBox(width: 4),
                  Text(
                    '마감: '
                    + '${todo.dueDate!.year}.${todo.dueDate!.month.toString().padLeft(2, '0')}.${todo.dueDate!.day.toString().padLeft(2, '0')}'
                    + (todo.dueDate!.hour != 0 || todo.dueDate!.minute != 0 ? ' ${todo.dueDate!.hour.toString().padLeft(2, '0')}:${todo.dueDate!.minute.toString().padLeft(2, '0')}' : ''),
                    style: TextStyle(fontSize: 12, color: AppColors.blue600),
                  ),
                ],
              ),
            ],
            if (todo.isCompleted && todo.completedAt != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.green600),
                  const SizedBox(width: 4),
                  Text(
                    '완료: '
                    + '${todo.completedAt!.year}.${todo.completedAt!.month.toString().padLeft(2, '0')}.${todo.completedAt!.day.toString().padLeft(2, '0')}'
                    + ' ${todo.completedAt!.hour.toString().padLeft(2, '0')}:${todo.completedAt!.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: AppColors.green600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            // 모든 태그들을 한 줄에 표시 (Wrap 사용)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // 우선순위
                _buildCompactTag(
                  '${todo.priorityEmoji} ${todo.priority.displayName}',
                  _getPriorityColor(todo.priority),
                ),
                // 할일 유형 + 반복 유형
                _buildCompactTag(
                  '${todo.type.emoji} ${todo.type.displayName}${(todo.type == TodoType.repeat || todo.type == TodoType.habit) && todo.repeatPattern != null ? '(${todo.repeatPattern!.repeatType.displayName})' : ''}',
                  AppColors.blue700,
                ),
                // 카테고리
                _buildCompactTag(
                  '${todo.categoryEmoji} ${todo.categoryName}',
                  AppColors.purple700,
                ),
                // 난이도
                _buildCompactTag(
                  todo.difficulty.displayName,
                  _getDifficultyColor(todo.difficulty),
                ),
                // 예상 소요 시간
                if (todo.estimatedTime != null)
                  _buildCompactTag(
                    '⏱️ ${_formatEstimatedTime(todo.estimatedTime!)}',
                    AppColors.green700,
                  ),
                // 사용자 태그들
                ...todo.tags.map((tag) => _buildCompactTag('#$tag', AppColors.grey700)),
              ],
            ),
            // 처리할 수 없는 이유 안내 메시지를 맨 아래로 이동
            if (shouldShowAsDisabled) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orange400.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.orange700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _getDisabledReason(todo),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.orange700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editTodo(todo);
                break;
              case 'delete':
                _deleteTodo(todo);
                break;
              case 'uncomplete':
                _uncompleteTodo(todo);
                break;
            }
          },
          itemBuilder: (context) => todo.isCompleted 
              ? [
                  const PopupMenuItem(
                    value: 'uncomplete',
                    child: Row(
                      children: [
                        Icon(Icons.undo, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('완료 취소', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ),
                ]
              : [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('수정'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('삭제', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
        ),
        // 습관일 때 터치로 진행률 증가 기능 제거 (+ 버튼만 사용)
        onTap: null,
      ),
    );
  }

  /// 투두 Leading 위젯 빌드 (체크박스 또는 습관 버튼)
  Widget _buildTodoLeading(TodoItemModel todo) {
    if (todo.isHabit && !todo.isCompleted) {
      // 습관용 + 버튼 (isCheckableToday에서 모든 조건 처리)
      final isCheckable = todo.isCheckableToday;
      
      return GestureDetector(
        onTap: isCheckable ? () => _incrementHabitProgress(todo) : () => _showFutureTodoWarning(todo),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCheckable ? AppColors.purple600 : AppColors.grey400,
            shape: BoxShape.circle,
            boxShadow: isCheckable ? [
              BoxShadow(
                color: AppColors.purple600.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Icon(
            isCheckable ? Icons.add : (todo.isBeforeStart ? Icons.pause_circle_outline : Icons.schedule),
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    } else {
      // 원형 체크박스 (isCheckableToday에서 모든 조건 처리)
      final isCheckable = todo.isCheckableToday;
      
      return GestureDetector(
        onTap: isCheckable 
            ? (todo.isCompleted ? null : () => _completeTodo(todo))
            : () => _showFutureTodoWarning(todo),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: todo.isCompleted 
                  ? AppColors.purple600 
                  : (isCheckable ? AppColors.purple600 : AppColors.grey400),
              width: 2,
            ),
            color: todo.isCompleted 
                ? AppColors.purple600 
                : Colors.transparent,
          ),
          child: todo.isCompleted 
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 20,
                )
              : null,
        ),
      );
    }
  }

  /// 습관 진행률 표시 위젯
  Widget _buildHabitProgress(TodoItemModel todo) {
    final progress = todo.habitProgress;
    final progressText = todo.habitProgressText;
    final isCheckable = todo.isCheckableToday;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              size: 16,
              color: isCheckable ? AppColors.purple600 : AppColors.grey400,
            ),
            const SizedBox(width: 4),
            Text(
              '진행률: $progressText',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isCheckable ? AppColors.purple700 : AppColors.grey500,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCheckable ? AppColors.purple700 : AppColors.grey500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.grey200,
          valueColor: AlwaysStoppedAnimation<Color>(
            isCheckable ? AppColors.purple600 : AppColors.grey400
          ),
          minHeight: 6,
        ),
        // 체크 가능할 때만 간단한 안내 메시지 표시 (중복 제거)
        if (isCheckable) ...[
          const SizedBox(height: 4),
          Text(
            '+ 버튼으로 추가하기',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.grey500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  /// 미래 날짜 할일 경고 메시지 표시
  void _showFutureTodoWarning(TodoItemModel todo) {
    final message = _getDisabledReason(todo);
    
    SnackBarUtils.showInfo(
      context, 
      message.isEmpty ? '아직 처리할 수 없습니다' : message,
      duration: const Duration(seconds: 2),
    );
  }

  /// 빈 상태 빌드
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 플로팅 액션 버튼 빌드
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _addTodo,
      backgroundColor: AppColors.purple600,
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  // ========================================
  // 유틸리티 메서드
  // ========================================

  /// 필터링된 투두 목록 가져오기
  List<TodoItemModel> _getFilteredTodos() {
    var filtered = List<TodoItemModel>.from(_todos);
    
    // 날짜 필터
    if (_currentFilter.startDate != null && _currentFilter.endDate != null) {
      filtered = filtered.where((todo) {
        if (todo.createdAt.isAfter(_currentFilter.startDate!) && 
            todo.createdAt.isBefore(_currentFilter.endDate!)) {
          return true;
        }
        if (todo.dueDate != null) {
          return todo.dueDate!.isAfter(_currentFilter.startDate!) && 
                 todo.dueDate!.isBefore(_currentFilter.endDate!);
        }
        return false;
      }).toList();
    }
    
    // 할일 유형 필터
    if (_currentFilter.type != null) {
      filtered = filtered.where((todo) => todo.type == _currentFilter.type).toList();
    }
    
    // 카테고리 필터
    if (_currentFilter.category != null) {
      filtered = filtered.where((todo) => todo.category == _currentFilter.category).toList();
    }
    
    // 우선순위 필터
    if (_currentFilter.priority != null) {
      filtered = filtered.where((todo) => todo.priority == _currentFilter.priority).toList();
    }
    
    // 난이도 필터
    if (_currentFilter.difficulty != null) {
      filtered = filtered.where((todo) => todo.difficulty == _currentFilter.difficulty).toList();
    }
    
    // 완료 상태 필터
    if (_currentFilter.isCompleted != null) {
      filtered = filtered.where((todo) => todo.isCompleted == _currentFilter.isCompleted).toList();
    }
    
    // 태그 필터
    if (_currentFilter.tags.isNotEmpty) {
      filtered = filtered.where((todo) {
        // 선택된 태그 중 하나라도 포함하면 표시
        return _currentFilter.tags.any((filterTag) => todo.tags.contains(filterTag));
      }).toList();
    }
    
    return filtered;
  }

  // ========================================
  // 다이얼로그 및 액션
  // ========================================

  /// 투두 추가
  void _addTodo() {
    showDialog(
      context: context,
      builder: (context) => TodoAddDialog(
        userId: _currentUser.id,
        onTodoAdded: (todo) async {
          try {
            final newTodo = await TodoService.createTodo(
              userId: _currentUser.id,
              title: todo.title,
              description: todo.description,
              type: todo.type,
              category: todo.category,
              priority: todo.priority,
              difficulty: todo.difficulty,
              startDate: todo.startDate,
              dueDate: todo.dueDate,
              estimatedTime: todo.estimatedTime,
              repeatPattern: todo.repeatPattern,
              tags: todo.tags,
              targetCount: todo.targetCount,
              hasReminder: todo.hasReminder,
              reminderTime: todo.reminderTime,
              reminderMinutesBefore: todo.reminderMinutesBefore,
              showUntilCompleted: todo.showUntilCompleted,
            );

            // 목록 새로고침
            await _refreshTodos();
            
            SnackBarUtils.showSuccess(context, '할일이 추가되었습니다.');
            
            if (kDebugMode) {
              print('투두 추가 완료: ${newTodo.title}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('투두 추가 실패: $e');
            }
            SnackBarUtils.showError(context, '할일 추가에 실패했습니다.');
          }
        },
      ),
    );
  }

  /// 투두 수정
  void _editTodo(TodoItemModel todo) {
    showDialog(
      context: context,
      builder: (context) => TodoEditDialog(
        todo: todo,
        onTodoUpdated: (updatedTodo) async {
          try {
            await TodoService.updateTodo(
              userId: _currentUser.id,
              todoId: updatedTodo.id,
              title: updatedTodo.title,
              description: updatedTodo.description,
              type: updatedTodo.type,
              category: updatedTodo.category,
              priority: updatedTodo.priority,
              difficulty: updatedTodo.difficulty,
              startDate: updatedTodo.startDate,
              dueDate: updatedTodo.dueDate,
              estimatedTime: updatedTodo.estimatedTime,
              repeatPattern: updatedTodo.repeatPattern,
              tags: updatedTodo.tags,
              targetCount: updatedTodo.targetCount,
              hasReminder: updatedTodo.hasReminder,
              reminderTime: updatedTodo.reminderTime,
              reminderMinutesBefore: updatedTodo.reminderMinutesBefore,
              clearStartDate: updatedTodo.startDate == null,
              clearDueDate: updatedTodo.dueDate == null,
            );
            
            // 목록 새로고침
            await _refreshTodos();
            
            SnackBarUtils.showSuccess(context, '할일이 수정되었습니다.');
            
            if (kDebugMode) {
              print('투두 수정 완료: ${updatedTodo.title}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('투두 수정 실패: $e');
            }
            SnackBarUtils.showError(context, '할일 수정에 실패했습니다.');
          }
        },
      ),
    );
  }

  /// 필터 다이얼로그
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => TodoFilterDialog(
        initialFilter: _currentFilter,
        userId: _currentUser.id,
        onFilterApplied: (filter) {
          setState(() {
            _currentFilter = filter;
            // 필터가 변경되었으므로 캐시 무효화
            _invalidateCache();
          });
        },
      ),
    );
  }

  /// 통계 다이얼로그
  void _showStatsDialog() {
    // 현재 탭에 따라 적절한 할일 목록 전달
    List<TodoItemModel> statsTargetTodos;
    StatsPeriod initialPeriod;
    
    switch (_tabController.index) {
      case 0: // 오늘 탭
        statsTargetTodos = _todayTodos;
        initialPeriod = StatsPeriod.daily;
        break;
      case 1: // 전체 탭
        statsTargetTodos = _todos;
        initialPeriod = StatsPeriod.all;
        break;
      case 2: // 완료 탭
        statsTargetTodos = _todos.where((todo) => todo.isCompleted).toList();
        initialPeriod = StatsPeriod.all;
        break;
      default:
        statsTargetTodos = _todos;
        initialPeriod = StatsPeriod.all;
    }
    
    showDialog(
      context: context,
      builder: (context) => TodoStatsDialog(
        todos: statsTargetTodos,
        initialPeriod: initialPeriod,
      ),
    );
  }

  /// 습관 대시보드로 이동
  void _showHabitDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDashboardPage(currentUser: _currentUser),
      ),
    );
  }

  /// 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(String todoTitle) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할일 삭제'),
        content: Text('\'$todoTitle\'을(를) 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    ) ?? false;
  }

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

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppColors.green600;
      case Priority.medium:
        return AppColors.orange600;
      case Priority.high:
        return AppColors.red600;
    }
  }

  String _formatEstimatedTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0 && minutes > 0) {
      return '${hours}시간 ${minutes}분';
    } else if (hours > 0) {
      return '${hours}시간';
    } else if (minutes > 0) {
      return '${minutes}분';
    } else {
      return '< 1분';
    }
  }

  // ========================================
  // 스낵바 메서드 (레거시 - 호환성을 위해 유지하되 최적화된 유틸리티 사용)
  // ========================================

  void _showSuccessSnackBar(String message) {
    SnackBarUtils.showSuccess(context, message);
  }

  void _showErrorSnackBar(String message) {
    SnackBarUtils.showError(context, message);
  }

  void _showInfoSnackBar(String message) {
    SnackBarUtils.showInfo(context, message);
  }

  /// 태그 칩 빌드
  Widget _buildTagChip(String tag) {
    // 태그별로 다른 색상 적용 (해시코드 기반)
    final colors = [
      AppColors.blue400,
      AppColors.green400,
      AppColors.orange400,
      AppColors.purple400,
      Colors.teal.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.cyan.shade400,
    ];
    
    final colorIndex = tag.hashCode.abs() % colors.length;
    final chipColor = colors[colorIndex];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: 12,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: chipColor.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _getDisabledReason(TodoItemModel todo) {
    if (!todo.isCheckableToday && !todo.isCompleted) {
      if (todo.isBeforeStart && todo.startDate != null) {
        final startDate = todo.startDate!;
        final startDateStr = '${startDate.year}.${startDate.month.toString().padLeft(2, '0')}.${startDate.day.toString().padLeft(2, '0')}';
        return '${startDateStr}부터 처리 가능';
      } else if (todo.isRepeating && todo.repeatPattern != null) {
        // 반복 패턴으로 인해 오늘 해당하지 않는 경우를 먼저 처리
        switch (todo.repeatPattern!.repeatType) {
          case RepeatType.weekly:
            if (todo.repeatPattern!.weekdays != null) {
              final weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
              final selectedDays = todo.repeatPattern!.weekdays!
                  .map((day) => weekdayNames[day - 1])
                  .toList();
              
              // 오버플로우 방지: 최대 3개까지만 표시
              if (selectedDays.length <= 3) {
                return '${selectedDays.join(', ')}요일에만 처리 가능';
              } else {
                final displayDays = selectedDays.take(3).join(', ');
                final remainingCount = selectedDays.length - 3;
                return '$displayDays 외 ${remainingCount}개 요일에만 처리 가능';
              }
            }
            break;
          case RepeatType.monthly:
            if (todo.repeatPattern!.monthDays != null) {
              final days = todo.repeatPattern!.monthDays!
                  .map((day) => day == 99 ? '말일' : '${day}일')
                  .toList();
              
              // 오버플로우 방지: 최대 3개까지만 표시
              if (days.length <= 3) {
                return '매월 ${days.join(', ')}에만 처리 가능';
              } else {
                final displayDays = days.take(3).join(', ');
                final remainingCount = days.length - 3;
                return '매월 $displayDays 외 ${remainingCount}개 날짜에만 처리 가능';
              }
            }
            break;
          case RepeatType.custom:
            if (todo.repeatPattern!.customInterval != null) {
              return '${todo.repeatPattern!.customInterval}일마다 처리 가능';
            }
            break;
          default:
            return '지정된 날짜에만 처리 가능';
        }
        return '지정된 날짜에만 처리 가능';
      } else if (todo.isFutureTodo && todo.dueDate != null) {
        final dueDate = todo.dueDate!;
        final dueDateStr = '${dueDate.year}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.day.toString().padLeft(2, '0')}';
        return '${dueDateStr}에 처리 가능';
      } else {
        return '아직 처리할 수 없음';
      }
    }
    return '';
  }

  Widget _buildCompactTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }
} 