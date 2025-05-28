import 'package:flutter/material.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

/// 투두 필터 상태 클래스
class TodoFilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final TodoType? type;
  final TodoCategory? category;
  final Priority? priority;
  final Difficulty? difficulty;
  final bool? isCompleted;

  const TodoFilterState({
    this.startDate,
    this.endDate,
    this.type,
    this.category,
    this.priority,
    this.difficulty,
    this.isCompleted,
  });

  TodoFilterState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    TodoType? type,
    TodoCategory? category,
    Priority? priority,
    Difficulty? difficulty,
    bool? isCompleted,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearType = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearDifficulty = false,
    bool clearIsCompleted = false,
  }) {
    return TodoFilterState(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      type: clearType ? null : (type ?? this.type),
      category: clearCategory ? null : (category ?? this.category),
      priority: clearPriority ? null : (priority ?? this.priority),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      isCompleted: clearIsCompleted ? null : (isCompleted ?? this.isCompleted),
    );
  }

  bool get hasAnyFilter {
    return startDate != null ||
           endDate != null ||
           type != null ||
           category != null ||
           priority != null ||
           difficulty != null ||
           isCompleted != null;
  }

  bool get isEmpty => !hasAnyFilter;
}

class TodoFilterDialog extends StatefulWidget {
  final TodoFilterState initialFilter;
  final Function(TodoFilterState) onFilterApplied;

  const TodoFilterDialog({
    super.key,
    required this.initialFilter,
    required this.onFilterApplied,
  });

  @override
  State<TodoFilterDialog> createState() => _TodoFilterDialogState();
}

class _TodoFilterDialogState extends State<TodoFilterDialog> {
  late TodoFilterState _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
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
                  Icons.filter_list,
                  color: AppColors.purple600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '필터 설정',
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
            
            // 필터 옵션들
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 필터
                    _buildDateFilter(),
                    const SizedBox(height: 24),
                    
                    // 할일 유형 필터
                    _buildTypeFilter(),
                    const SizedBox(height: 24),
                    
                    // 카테고리 필터
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    
                    // 우선순위 필터
                    _buildPriorityFilter(),
                    const SizedBox(height: 24),
                    
                    // 난이도 필터
                    _buildDifficultyFilter(),
                    const SizedBox(height: 24),
                    
                    // 완료 상태 필터
                    _buildCompletionFilter(),
                  ],
                ),
              ),
            ),
            
            // 버튼들
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetFilters,
                    child: const Text('초기화'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('적용하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📅 날짜',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        
        // 빠른 선택 버튼들
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickDateButton('오늘', () => _setTodayFilter()),
            _buildQuickDateButton('어제', () => _setYesterdayFilter()),
            _buildQuickDateButton('이번 주', () => _setThisWeekFilter()),
            _buildQuickDateButton('지난 주', () => _setLastWeekFilter()),
            _buildQuickDateButton('이번 달', () => _setThisMonthFilter()),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // 커스텀 날짜 선택
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectStartDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _currentFilter.startDate != null
                      ? '${_currentFilter.startDate!.month}/${_currentFilter.startDate!.day}'
                      : '시작일',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('~'),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectEndDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _currentFilter.endDate != null
                      ? '${_currentFilter.endDate!.month}/${_currentFilter.endDate!.day}'
                      : '종료일',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            if (_currentFilter.startDate != null || _currentFilter.endDate != null)
              IconButton(
                onPressed: _clearDateFilter,
                icon: const Icon(Icons.clear, size: 16),
                tooltip: '날짜 필터 제거',
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    final isSelected = _isQuickDateSelected(label);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onPressed(),
      selectedColor: AppColors.purple600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.grey700,
        fontSize: 12,
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 할일 유형',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip<TodoType>(
              label: '전체',
              value: null,
              currentValue: _currentFilter.type,
              onSelected: (value) => _updateFilter(type: value, clearType: value == null),
            ),
            ...TodoType.values.map((type) => _buildFilterChip<TodoType>(
              label: '${type.emoji} ${type.displayName}',
              value: type,
              currentValue: _currentFilter.type,
              onSelected: (value) => _updateFilter(type: value),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📂 카테고리',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip<TodoCategory>(
              label: '전체',
              value: null,
              currentValue: _currentFilter.category,
              onSelected: (value) => _updateFilter(category: value, clearCategory: value == null),
            ),
            ...TodoCategory.values.map((category) => _buildFilterChip<TodoCategory>(
              label: '${category.emoji} ${category.displayName}',
              value: category,
              currentValue: _currentFilter.category,
              onSelected: (value) => _updateFilter(category: value),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '⭐ 우선순위',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip<Priority>(
              label: '전체',
              value: null,
              currentValue: _currentFilter.priority,
              onSelected: (value) => _updateFilter(priority: value, clearPriority: value == null),
            ),
            ...Priority.values.map((priority) => _buildFilterChip<Priority>(
              label: '${_getPriorityEmoji(priority)} ${priority.displayName}',
              value: priority,
              currentValue: _currentFilter.priority,
              onSelected: (value) => _updateFilter(priority: value),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎚️ 난이도',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip<Difficulty>(
              label: '전체',
              value: null,
              currentValue: _currentFilter.difficulty,
              onSelected: (value) => _updateFilter(difficulty: value, clearDifficulty: value == null),
            ),
            ...Difficulty.values.map((difficulty) => _buildFilterChip<Difficulty>(
              label: difficulty.displayName,
              value: difficulty,
              currentValue: _currentFilter.difficulty,
              onSelected: (value) => _updateFilter(difficulty: value),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '✅ 완료 상태',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip<bool>(
              label: '전체',
              value: null,
              currentValue: _currentFilter.isCompleted,
              onSelected: (value) => _updateFilter(isCompleted: value, clearIsCompleted: value == null),
            ),
            _buildFilterChip<bool>(
              label: '완료됨',
              value: true,
              currentValue: _currentFilter.isCompleted,
              onSelected: (value) => _updateFilter(isCompleted: value),
            ),
            _buildFilterChip<bool>(
              label: '미완료',
              value: false,
              currentValue: _currentFilter.isCompleted,
              onSelected: (value) => _updateFilter(isCompleted: value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required T? value,
    required T? currentValue,
    required Function(T?) onSelected,
  }) {
    final isSelected = value == currentValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.purple600,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.grey700,
        fontSize: 12,
      ),
    );
  }

  // 날짜 관련 메서드들
  void _setTodayFilter() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);
    _updateFilter(startDate: startOfDay, endDate: endOfDay);
  }

  void _setYesterdayFilter() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final endOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
    _updateFilter(startDate: startOfDay, endDate: endOfDay);
  }

  void _setThisWeekFilter() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    _updateFilter(
      startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
      endDate: DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59),
    );
  }

  void _setLastWeekFilter() {
    final now = DateTime.now();
    final startOfThisWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    final endOfLastWeek = startOfLastWeek.add(const Duration(days: 6));
    _updateFilter(
      startDate: DateTime(startOfLastWeek.year, startOfLastWeek.month, startOfLastWeek.day),
      endDate: DateTime(endOfLastWeek.year, endOfLastWeek.month, endOfLastWeek.day, 23, 59, 59),
    );
  }

  void _setThisMonthFilter() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    _updateFilter(startDate: startOfMonth, endDate: endOfMonth);
  }

  bool _isQuickDateSelected(String label) {
    if (_currentFilter.startDate == null || _currentFilter.endDate == null) return false;
    
    final now = DateTime.now();
    switch (label) {
      case '오늘':
        final today = DateTime(now.year, now.month, now.day);
        return _currentFilter.startDate!.isAtSameMomentAs(today);
      case '어제':
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        return _currentFilter.startDate!.isAtSameMomentAs(yesterday);
      // 다른 경우들도 필요하면 추가
      default:
        return false;
    }
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentFilter.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      _updateFilter(startDate: date);
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentFilter.endDate ?? DateTime.now(),
      firstDate: _currentFilter.startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      _updateFilter(endDate: endOfDay);
    }
  }

  void _clearDateFilter() {
    _updateFilter(clearStartDate: true, clearEndDate: true);
  }

  void _updateFilter({
    DateTime? startDate,
    DateTime? endDate,
    TodoType? type,
    TodoCategory? category,
    Priority? priority,
    Difficulty? difficulty,
    bool? isCompleted,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearType = false,
    bool clearCategory = false,
    bool clearPriority = false,
    bool clearDifficulty = false,
    bool clearIsCompleted = false,
  }) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(
        startDate: startDate,
        endDate: endDate,
        type: type,
        category: category,
        priority: priority,
        difficulty: difficulty,
        isCompleted: isCompleted,
        clearStartDate: clearStartDate,
        clearEndDate: clearEndDate,
        clearType: clearType,
        clearCategory: clearCategory,
        clearPriority: clearPriority,
        clearDifficulty: clearDifficulty,
        clearIsCompleted: clearIsCompleted,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      _currentFilter = const TodoFilterState();
    });
  }

  void _applyFilters() {
    widget.onFilterApplied(_currentFilter);
    Navigator.of(context).pop();
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