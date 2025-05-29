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

      // 반복 할일인 경우 다음 인스턴스 생성
      if (todo.isRepeating) {
        await TodoService.createNextRepeatInstance(result['todo'] as TodoItemModel);
      }

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
    // 오늘 할일에도 필터 적용
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
        // 선택된 태그 중 하나라도 포함하면 표시
        return _currentFilter.tags.any((filterTag) => todo.tags.contains(filterTag));
      }).toList();
    }

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
    final isFuture = todo.isFutureTodo;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      // 미래 날짜 할일은 약간 투명하게 표시
      color: isFuture && !todo.isCompleted 
          ? AppColors.grey50.withOpacity(0.7)
          : null,
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
                  decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted 
                      ? AppColors.grey600 
                      : (isFuture ? AppColors.grey500 : AppColors.grey800),
                ),
              ),
            ),
            // 미래 날짜 할일 표시 아이콘
            if (isFuture && !todo.isCompleted) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.grey500,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 미래 날짜 할일 안내 메시지
            if (isFuture && !todo.isCompleted) ...[
              const SizedBox(height: 4),
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
                      '마감일에 처리 가능',
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
            if (todo.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                todo.description,
                style: TextStyle(
                  fontSize: 14,
                  color: isFuture ? AppColors.grey400 : AppColors.grey600,
                ),
              ),
            ],
            // 습관 진행률 표시
            if (todo.isHabit && !todo.isCompleted) ...[
              const SizedBox(height: 8),
              _buildHabitProgress(todo),
            ],
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
            const SizedBox(height: 8),
            Row(
              children: [
                // 할일 유형
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blue400.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todo.type.emoji} ${todo.type.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.blue700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 카테고리
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.purple400.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todo.categoryEmoji} ${todo.categoryName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.purple700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 우선순위
                Text(
                  todo.priorityEmoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                // 난이도
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(todo.difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    todo.difficulty.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyColor(todo.difficulty),
                    ),
                  ),
                ),
              ],
            ),
            // 태그 표시
            if (todo.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: todo.tags.map((tag) => _buildTagChip(tag)).toList(),
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
        // 습관일 때 터치로 진행률 증가
        onTap: todo.isHabit && !todo.isCompleted ? () => _incrementHabitProgress(todo) : null,
      ),
    );
  }

  /// 투두 Leading 위젯 빌드 (체크박스 또는 습관 버튼)
  Widget _buildTodoLeading(TodoItemModel todo) {
    if (todo.isHabit && !todo.isCompleted) {
      // 습관용 + 버튼 (미래 날짜 체크)
      final isCheckable = todo.isCheckableToday;
      
      return GestureDetector(
        onTap: isCheckable ? () => _incrementHabitProgress(todo) : () => _showFutureTodoWarning(todo),
        child: Container(
          width: 48,
          height: 48,
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
            isCheckable ? Icons.add : Icons.schedule,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    } else {
      // 일반 체크박스 (미래 날짜 체크)
      final isCheckable = todo.isCheckableToday;
      
      return Checkbox(
        value: todo.isCompleted,
        onChanged: isCheckable 
            ? (todo.isCompleted ? null : (_) => _completeTodo(todo))
            : (_) => _showFutureTodoWarning(todo),
        activeColor: AppColors.purple600,
        // 미래 날짜 할일은 비활성화 스타일
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (!isCheckable && !todo.isCompleted) {
            return AppColors.grey400;
          }
          if (states.contains(MaterialState.selected)) {
            return AppColors.purple600;
          }
          return Colors.transparent;
        }),
      );
    }
  }

  /// 습관 진행률 표시 위젯
  Widget _buildHabitProgress(TodoItemModel todo) {
    final progress = todo.habitProgress;
    final progressText = todo.habitProgressText;
    final isFuture = todo.isFutureTodo;
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
        const SizedBox(height: 4),
        Text(
          isCheckable ? '터치해서 +1 추가하기' : '마감일에 처리 가능',
          style: TextStyle(
            fontSize: 11,
            color: isCheckable ? AppColors.grey500 : AppColors.orange600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// 미래 날짜 할일 경고 메시지 표시
  void _showFutureTodoWarning(TodoItemModel todo) {
    final dueDate = todo.dueDate;
    if (dueDate == null) return;
    
    final dueDateStr = '${dueDate.year}.${dueDate.month.toString().padLeft(2, '0')}.${dueDate.day.toString().padLeft(2, '0')}';
    
    SnackBarUtils.showInfo(
      context, 
      '${dueDateStr}에 처리할 수 있습니다',
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
              category: updatedTodo.category,
              priority: updatedTodo.priority,
              difficulty: updatedTodo.difficulty,
              startDate: updatedTodo.startDate,
              dueDate: updatedTodo.dueDate,
              estimatedTime: updatedTodo.estimatedTime,
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
} 