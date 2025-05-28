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
        
        _showErrorSnackBar('투두 목록을 불러오는데 실패했습니다.');
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
      _showSuccessSnackBar('할일을 완료했습니다! 🎉');

      if (kDebugMode) {
        print('투두 완료 처리 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 완료 처리 실패: $e');
      }
      _showErrorSnackBar('할일 완료 처리에 실패했습니다.');
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
      _showSuccessSnackBar('할일이 삭제되었습니다.');

      if (kDebugMode) {
        print('투두 삭제 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 삭제 실패: $e');
      }
      _showErrorSnackBar('할일 삭제에 실패했습니다.');
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
      
      _showSuccessSnackBar('할일 완료가 취소되었습니다.');

      if (kDebugMode) {
        print('투두 완료 취소 완료: ${todo.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('투두 완료 취소 실패: $e');
      }
      _showErrorSnackBar('할일 완료 취소에 실패했습니다.');
    }
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: todo.isCompleted ? null : (_) => _completeTodo(todo),
          activeColor: AppColors.purple600,
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? AppColors.grey600 : AppColors.grey800,
          ),
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
                  color: AppColors.grey600,
                ),
              ),
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
      ),
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
              dueDate: todo.dueDate,
              estimatedTime: todo.estimatedTime,
              repeatPattern: todo.repeatPattern,
              tags: todo.tags,
              targetCount: todo.targetCount,
              hasReminder: todo.hasReminder,
              reminderTime: todo.reminderTime,
              reminderMinutesBefore: todo.reminderMinutesBefore,
            );

            // 목록 새로고침
            await _refreshTodos();
            
            _showSuccessSnackBar('할일이 추가되었습니다.');
            
            if (kDebugMode) {
              print('투두 추가 완료: ${newTodo.title}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('투두 추가 실패: $e');
            }
            _showErrorSnackBar('할일 추가에 실패했습니다.');
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
              dueDate: updatedTodo.dueDate,
              estimatedTime: updatedTodo.estimatedTime,
              hasReminder: updatedTodo.hasReminder,
              reminderTime: updatedTodo.reminderTime,
              reminderMinutesBefore: updatedTodo.reminderMinutesBefore,
              clearDueDate: updatedTodo.dueDate == null,
            );
            
            // 목록 새로고침
            await _refreshTodos();
            
            _showSuccessSnackBar('할일이 수정되었습니다.');
            
            if (kDebugMode) {
              print('투두 수정 완료: ${updatedTodo.title}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('투두 수정 실패: $e');
            }
            _showErrorSnackBar('할일 수정에 실패했습니다.');
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
    showDialog(
      context: context,
      builder: (context) => TodoStatsDialog(
        todos: _todos,
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

  // ========================================
  // 스낵바 메서드
  // ========================================

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.green600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.blue600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
} 