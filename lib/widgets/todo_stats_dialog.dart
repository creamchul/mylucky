import 'package:flutter/material.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

/// 투두 통계 데이터 클래스
class TodoStats {
  final int totalTodos;
  final int completedTodos;
  final int pendingTodos;
  final double completionRate;
  final Map<TodoType, int> todosByType;
  final Map<TodoCategory, int> todosByCategory;
  final Map<Priority, int> todosByPriority;
  final Map<Difficulty, int> todosByDifficulty;
  final int streakDays;
  final DateTime? lastCompletedDate;

  const TodoStats({
    required this.totalTodos,
    required this.completedTodos,
    required this.pendingTodos,
    required this.completionRate,
    required this.todosByType,
    required this.todosByCategory,
    required this.todosByPriority,
    required this.todosByDifficulty,
    required this.streakDays,
    this.lastCompletedDate,
  });

  static TodoStats fromTodos(List<TodoItemModel> todos, StatsPeriod period) {
    final now = DateTime.now();
    List<TodoItemModel> filteredTodos;

    // 기간별 필터링
    switch (period) {
      case StatsPeriod.daily:
        // 일일 통계의 경우 전달받은 할일 목록을 그대로 사용
        // (이미 오늘 화면에 표시되는 할일만 전달받음)
        filteredTodos = todos;
        break;
      case StatsPeriod.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        filteredTodos = todos.where((todo) {
          return todo.createdAt.isAfter(startOfWeek) && todo.createdAt.isBefore(endOfWeek) ||
                 (todo.dueDate != null && todo.dueDate!.isAfter(startOfWeek) && todo.dueDate!.isBefore(endOfWeek));
        }).toList();
        break;
      case StatsPeriod.monthly:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        filteredTodos = todos.where((todo) {
          return todo.createdAt.isAfter(startOfMonth) && todo.createdAt.isBefore(endOfMonth) ||
                 (todo.dueDate != null && todo.dueDate!.isAfter(startOfMonth) && todo.dueDate!.isBefore(endOfMonth));
        }).toList();
        break;
      case StatsPeriod.all:
        filteredTodos = todos;
        break;
    }

    final totalTodos = filteredTodos.length;
    final completedTodos = filteredTodos.where((todo) => todo.isCompleted).length;
    final pendingTodos = totalTodos - completedTodos;
    final completionRate = totalTodos > 0 ? (completedTodos / totalTodos) * 100 : 0.0;

    // 유형별 통계
    final todosByType = <TodoType, int>{};
    for (final type in TodoType.values) {
      todosByType[type] = filteredTodos.where((todo) => todo.type == type).length;
    }

    // 카테고리별 통계
    final todosByCategory = <TodoCategory, int>{};
    for (final category in TodoCategory.values) {
      todosByCategory[category] = filteredTodos.where((todo) => todo.category == category).length;
    }

    // 우선순위별 통계
    final todosByPriority = <Priority, int>{};
    for (final priority in Priority.values) {
      todosByPriority[priority] = filteredTodos.where((todo) => todo.priority == priority).length;
    }

    // 난이도별 통계
    final todosByDifficulty = <Difficulty, int>{};
    for (final difficulty in Difficulty.values) {
      todosByDifficulty[difficulty] = filteredTodos.where((todo) => todo.difficulty == difficulty).length;
    }

    // 연속 완료 일수 계산 (간단한 버전)
    final completedDates = filteredTodos
        .where((todo) => todo.isCompleted && todo.completedAt != null)
        .map((todo) => DateTime(
              todo.completedAt!.year,
              todo.completedAt!.month,
              todo.completedAt!.day,
            ))
        .toSet()
        .toList()
      ..sort();

    int streakDays = 0;
    if (completedDates.isNotEmpty) {
      final today = DateTime(now.year, now.month, now.day);
      DateTime currentDate = today;
      
      while (completedDates.contains(currentDate)) {
        streakDays++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }

    final lastCompletedDate = filteredTodos
        .where((todo) => todo.isCompleted && todo.completedAt != null)
        .map((todo) => todo.completedAt!)
        .fold<DateTime?>(null, (latest, date) => 
            latest == null || date.isAfter(latest) ? date : latest);

    return TodoStats(
      totalTodos: totalTodos,
      completedTodos: completedTodos,
      pendingTodos: pendingTodos,
      completionRate: completionRate,
      todosByType: todosByType,
      todosByCategory: todosByCategory,
      todosByPriority: todosByPriority,
      todosByDifficulty: todosByDifficulty,
      streakDays: streakDays,
      lastCompletedDate: lastCompletedDate,
    );
  }
}

class TodoStatsDialog extends StatefulWidget {
  final List<TodoItemModel> todos;
  final StatsPeriod? initialPeriod;

  const TodoStatsDialog({
    super.key,
    required this.todos,
    this.initialPeriod,
  });

  @override
  State<TodoStatsDialog> createState() => _TodoStatsDialogState();
}

class _TodoStatsDialogState extends State<TodoStatsDialog> {
  late StatsPeriod _selectedPeriod;
  late TodoStats _currentStats;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod ?? StatsPeriod.daily;
    _updateStats();
  }

  void _updateStats() {
    setState(() {
      _currentStats = TodoStats.fromTodos(widget.todos, _selectedPeriod);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.purple600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '할일 통계',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.grey800,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 기간 선택
            _buildPeriodSelector(),
            const SizedBox(height: 24),
            
            // 통계 내용
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 전체 요약
                    _buildOverviewStats(),
                    const SizedBox(height: 24),
                    
                    // 완료율 차트
                    _buildCompletionChart(),
                    const SizedBox(height: 24),
                    
                    // 유형별 통계
                    _buildTypeStats(),
                    const SizedBox(height: 24),
                    
                    // 카테고리별 통계
                    _buildCategoryStats(),
                    const SizedBox(height: 24),
                    
                    // 우선순위별 통계
                    _buildPriorityStats(),
                    const SizedBox(height: 24),
                    
                    // 난이도별 통계
                    _buildDifficultyStats(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.grey200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPeriod = period;
                });
                _updateStats();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.grey700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 ${_selectedPeriod.description} 요약',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '전체 할일',
                value: '${_currentStats.totalTodos}개',
                icon: Icons.assignment,
                color: AppColors.blue600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '완료',
                value: '${_currentStats.completedTodos}개',
                icon: Icons.check_circle,
                color: AppColors.green600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: '미완료',
                value: '${_currentStats.pendingTodos}개',
                icon: Icons.pending,
                color: AppColors.orange600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: '완료율',
                value: '${_currentStats.completionRate.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: AppColors.purple600,
              ),
            ),
          ],
        ),
        if (_currentStats.streakDays > 0) ...[
          const SizedBox(height: 12),
          _buildStatCard(
            title: '연속 완료',
            value: '${_currentStats.streakDays}일',
            icon: Icons.local_fire_department,
            color: AppColors.red600,
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📈 완료율',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey200.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '완료: ${_currentStats.completedTodos}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.green600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '미완료: ${_currentStats.pendingTodos}개',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.orange600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _currentStats.totalTodos > 0 
                      ? _currentStats.completedTodos / _currentStats.totalTodos 
                      : 0.0,
                  backgroundColor: AppColors.orange400.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.green600),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_currentStats.completionRate.toStringAsFixed(1)}% 완료',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeStats() {
    return _buildCategorySection(
      title: '📋 할일 유형별',
      data: _currentStats.todosByType.entries
          .where((entry) => entry.value > 0)
          .map((entry) => MapEntry(
                '${entry.key.emoji} ${entry.key.displayName}',
                entry.value,
              ))
          .toList(),
    );
  }

  Widget _buildCategoryStats() {
    return _buildCategorySection(
      title: '📂 카테고리별',
      data: _currentStats.todosByCategory.entries
          .where((entry) => entry.value > 0)
          .map((entry) => MapEntry(
                '${entry.key.emoji} ${entry.key.displayName}',
                entry.value,
              ))
          .toList(),
    );
  }

  Widget _buildPriorityStats() {
    return _buildCategorySection(
      title: '⭐ 우선순위별',
      data: _currentStats.todosByPriority.entries
          .where((entry) => entry.value > 0)
          .map((entry) => MapEntry(
                '${_getPriorityEmoji(entry.key)} ${entry.key.displayName}',
                entry.value,
              ))
          .toList(),
    );
  }

  Widget _buildDifficultyStats() {
    return _buildCategorySection(
      title: '🎚️ 난이도별',
      data: _currentStats.todosByDifficulty.entries
          .where((entry) => entry.value > 0)
          .map((entry) => MapEntry(
                entry.key.displayName,
                entry.value,
              ))
          .toList(),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required List<MapEntry<String, int>> data,
  }) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = data.fold<int>(0, (sum, entry) => sum + entry.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        ...data.map((entry) {
          final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grey700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.purple600),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${entry.value}개 (${percentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getPriorityEmoji(Priority priority) {
    switch (priority) {
      case Priority.low:
        return '🟢';
      case Priority.medium:
        return '🟡';
      case Priority.high:
        return '🔴';
    }
  }
} 