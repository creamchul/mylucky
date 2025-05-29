import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

class TodoEditDialog extends StatefulWidget {
  final TodoItemModel todo;
  final Function(TodoItemModel) onTodoUpdated;

  const TodoEditDialog({
    super.key,
    required this.todo,
    required this.onTodoUpdated,
  });

  @override
  State<TodoEditDialog> createState() => _TodoEditDialogState();
}

class _TodoEditDialogState extends State<TodoEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  late TodoType _selectedType;
  late TodoCategory _selectedCategory;
  late Priority _selectedPriority;
  late Difficulty _selectedDifficulty;
  
  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;
  Duration? _estimatedTime;
  
  late List<String> _tags;
  final _tagController = TextEditingController();
  
  // 반복 설정
  List<int> _selectedWeekdays = [];
  List<int> _selectedMonthDays = [];
  List<int> _selectedYearMonths = [];
  List<int> _selectedYearDays = [];
  int? _customInterval;
  final _customIntervalController = TextEditingController();
  RepeatType? _selectedRepeatType;
  
  // 습관 설정
  int? _targetCount;
  final _targetCountController = TextEditingController();
  
  // 알림 설정
  late bool _hasReminder;
  late TimeOfDay _reminderTime;
  
  // 일회성 할일 옵션
  late bool _showUntilCompleted;

  @override
  void initState() {
    super.initState();
    
    // 기존 투두 정보로 초기화
    _titleController = TextEditingController(text: widget.todo.title);
    _descriptionController = TextEditingController(text: widget.todo.description);
    
    _selectedType = widget.todo.type;
    _selectedCategory = widget.todo.category;
    _selectedPriority = widget.todo.priority;
    _selectedDifficulty = widget.todo.difficulty;
    
    _selectedStartDate = widget.todo.startDate;
    _selectedDueDate = widget.todo.dueDate;
    
    _estimatedTime = widget.todo.estimatedTime;
    _tags = List.from(widget.todo.tags);
    
    if (widget.todo.repeatPattern?.weekdays != null) {
      _selectedWeekdays = List.from(widget.todo.repeatPattern!.weekdays!);
    }
    if (widget.todo.repeatPattern?.monthDays != null) {
      _selectedMonthDays = List.from(widget.todo.repeatPattern!.monthDays!);
    }
    if (widget.todo.repeatPattern?.customInterval != null) {
      _customInterval = widget.todo.repeatPattern!.customInterval;
    }
    _customIntervalController.text = widget.todo.repeatPattern?.customInterval?.toString() ?? '';
    _selectedRepeatType = widget.todo.repeatPattern?.repeatType;
    
    _targetCount = widget.todo.targetCount;
    _targetCountController.text = widget.todo.targetCount?.toString() ?? '';
    _hasReminder = widget.todo.hasReminder;
    if (widget.todo.reminderTime != null) {
      _reminderTime = TimeOfDay(
        hour: widget.todo.reminderTime!.hour,
        minute: widget.todo.reminderTime!.minute,
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 9, minute: 0); // 기본값
    }
    _showUntilCompleted = widget.todo.showUntilCompleted;
    
    // 사용 가능한 태그 목록 로드
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _targetCountController.dispose();
    _customIntervalController.dispose();
    super.dispose();
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
                Text(
                  '할일 수정',
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
            
            // 폼
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      _buildTextField(
                        controller: _titleController,
                        label: '제목',
                        hint: '할일을 입력하세요',
                        isRequired: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // 설명
                      _buildTextField(
                        controller: _descriptionController,
                        label: '설명 (선택사항)',
                        hint: '상세 설명을 입력하세요',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      
                      // 타입 선택
                        _buildTypeSelector(),
                        const SizedBox(height: 16),
                      
                      // 반복 설정 (반복 할일과 습관)
                      if ((_selectedType == TodoType.repeat || _selectedType == TodoType.habit) && !widget.todo.isCompleted) ...[
                        _buildRepeatTypeSelector(),
                        const SizedBox(height: 16),
                        if (_selectedRepeatType != null) ...[
                          _buildRepeatDetailSettings(),
                          const SizedBox(height: 16),
                        ],
                      ],
                      
                      // 카테고리 선택
                      _buildCategorySelector(),
                      const SizedBox(height: 16),
                      
                      // 우선순위 & 난이도
                      Row(
                        children: [
                          Expanded(child: _buildPrioritySelector()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDifficultySelector()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // 시작일 설정
                      _buildStartDateSelector(),
                      const SizedBox(height: 16),
                      
                      // 기한 설정
                      _buildDueDateSelector(),
                      
                      // 일회성 할일 표시 옵션
                      if (_selectedType == TodoType.oneTime && !widget.todo.isCompleted) ...[
                        const SizedBox(height: 16),
                        _buildShowOptionSelector(),
                      ],
                      
                      // 습관 목표 설정
                      if (_selectedType == TodoType.habit && !widget.todo.isCompleted)
                        _buildHabitTargetSelector(),
                      
                      // 예상 시간
                      _buildEstimatedTimeSelector(),
                      const SizedBox(height: 16),
                      
                      // 태그
                      _buildTagsSelector(),
                      const SizedBox(height: 16),
                      
                      // 알림 설정
                      _buildReminderSelector(),
                    ],
                  ),
                ),
              ),
            ),
            
            // 버튼
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveTodo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('수정'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 여기서부터는 TodoAddDialog와 동일한 위젯 빌더 메서드들을 재사용
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          validator: isRequired ? (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label을(를) 입력해주세요';
            }
            return null;
          } : null,
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '할일 유형',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '어떤 종류의 할일인가요?',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Step-by-Step 카드 형태로 변경
        Column(
          children: [
            _buildTypeCard(
              type: TodoType.oneTime,
              icon: Icons.event_note,
              title: '일회성',
              description: '한 번만 수행하는 할일',
              color: AppColors.blue600,
        ),
        const SizedBox(height: 8),
            _buildTypeCard(
              type: TodoType.repeat,
              icon: Icons.repeat,
              title: '반복',
              description: '정기적으로 반복되는 할일',
              color: AppColors.green600,
            ),
            const SizedBox(height: 8),
            _buildTypeCard(
              type: TodoType.habit,
              icon: Icons.track_changes,
              title: '습관',
              description: '꾸준히 기르고 싶은 습관',
              color: AppColors.orange600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required TodoType type,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
            final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
                  setState(() {
                    _selectedType = type;
                    // 타입 변경 시 관련 설정 초기화
                    if (type == TodoType.habit) {
                      // 습관은 기본적으로 매일 반복으로 설정
                      _selectedRepeatType = RepeatType.daily;
                    } else if (type == TodoType.repeat) {
            // 반복 할일로 변경 시 기본값 설정
                      if (_selectedRepeatType == null) {
                        _selectedRepeatType = RepeatType.daily;
                      }
                    } else {
                      // 일회성 할일로 변경 시 반복 설정 초기화
                      _selectedRepeatType = null;
                      _selectedWeekdays.clear();
                      _selectedMonthDays.clear();
                      _selectedYearDays.clear();
                      _customInterval = null;
                    }
                  });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.grey400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : AppColors.grey400,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        
        // 카테고리 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: TodoCategory.values.length,
          itemBuilder: (context, index) {
            final category = TodoCategory.values[index];
            final isSelected = _selectedCategory == category;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.purple600.withOpacity(0.1) : AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.purple600 : AppColors.grey400,
                    width: isSelected ? 2 : 1,
            ),
          ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text(
                      category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        category.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.purple600 : AppColors.grey700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '우선순위',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        
        // 우선순위 카드들
        Column(
          children: Priority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final priorityColor = _getPriorityColor(priority);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? priorityColor.withOpacity(0.1) : AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? priorityColor : AppColors.grey400,
                      width: isSelected ? 2 : 1,
            ),
            ),
              child: Row(
                children: [
                      Text(
                        _getPriorityEmoji(priority),
                        style: const TextStyle(fontSize: 16),
                      ),
                  const SizedBox(width: 8),
                      Text(
                        priority.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? priorityColor : AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppColors.red600;
      case Priority.medium:
        return AppColors.orange600;
      case Priority.low:
        return AppColors.blue600;
    }
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '난이도',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        
        // 난이도 카드들
        Column(
          children: Difficulty.values.map((difficulty) {
            final isSelected = _selectedDifficulty == difficulty;
            final difficultyColor = _getDifficultyColor(difficulty);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDifficulty = difficulty;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? difficultyColor.withOpacity(0.1) : AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? difficultyColor : AppColors.grey400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getDifficultyEmoji(difficulty),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        difficulty.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? difficultyColor : AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getDifficultyColor(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return AppColors.green600;
      case Difficulty.medium:
        return AppColors.yellow600;
      case Difficulty.hard:
        return AppColors.red600;
    }
  }

  String _getDifficultyEmoji(Difficulty difficulty) {
    switch (difficulty) {
      case Difficulty.easy:
        return '😊';
      case Difficulty.medium:
        return '😐';
      case Difficulty.hard:
        return '😰';
    }
  }

  Widget _buildStartDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey400),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Icon(
                Icons.play_arrow,
                color: AppColors.green600,
                size: 20,
              ),
              const SizedBox(width: 8),
        Text(
          '시작일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
              const Spacer(),
              if (_selectedStartDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStartDate = null;
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.grey600,
                    size: 20,
                  ),
                  tooltip: '시작일 제거',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '언제부터 시작하나요? (선택사항)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
          
        Row(
          children: [
              // 날짜 선택
            Expanded(
                child: GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.green600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                  _selectedStartDate != null
                      ? '${_selectedStartDate!.year}.${_selectedStartDate!.month.toString().padLeft(2, '0')}.${_selectedStartDate!.day.toString().padLeft(2, '0')}'
                      : '날짜 선택',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedStartDate != null 
                                ? AppColors.grey800 
                                : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildDueDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey400),
      ),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Icon(
                Icons.flag,
                color: AppColors.red600,
                size: 20,
              ),
              const SizedBox(width: 8),
        Text(
          '마감일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
              const Spacer(),
              if (_selectedDueDate != null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDueDate = null;
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.grey600,
                    size: 20,
                  ),
                  tooltip: '마감일 제거',
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '언제까지 완료해야 하나요? (선택사항)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 12),
          
        Row(
          children: [
              // 날짜 선택
            Expanded(
                child: GestureDetector(
                  onTap: _selectDueDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.grey400),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.red600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.year}.${_selectedDueDate!.month.toString().padLeft(2, '0')}.${_selectedDueDate!.day.toString().padLeft(2, '0')}'
                      : '날짜 선택',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedDueDate != null 
                                ? AppColors.grey800 
                                : AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ),
          ],
        ),
      ],
      ),
    );
  }

  Widget _buildRepeatTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복 유형',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        
        // 반복 유형 카드들
        Column(
          children: RepeatType.values.where((type) => type != RepeatType.yearly).map((repeatType) {
            final isSelected = _selectedRepeatType == repeatType;
            final color = _getRepeatTypeColor(repeatType);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRepeatType = repeatType;
                    // 반복 유형 변경 시 관련 설정 초기화
                    _selectedWeekdays.clear();
                    _selectedMonthDays.clear();
                    _selectedYearMonths.clear();
                    _selectedYearDays.clear();
                    _customInterval = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppColors.grey400,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? color : AppColors.grey400,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          repeatType.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              repeatType.displayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? color : AppColors.grey700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              repeatType.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.grey600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getRepeatTypeColor(RepeatType repeatType) {
    switch (repeatType) {
      case RepeatType.daily:
        return AppColors.blue600;
      case RepeatType.weekly:
        return AppColors.green600;
      case RepeatType.monthly:
        return AppColors.orange600;
      case RepeatType.yearly:
        return AppColors.purple600; // 사용되지 않지만 완전성을 위해
      case RepeatType.custom:
        return AppColors.red600;
    }
  }

  Widget _buildRepeatDetailSettings() {
    if (_selectedRepeatType == RepeatType.weekly) {
      return _buildWeekdaySelector();
    } else if (_selectedRepeatType == RepeatType.monthly) {
      return _buildMonthdaySelector();
    } else if (_selectedRepeatType == RepeatType.custom) {
      return _buildCustomIntervalSelector();
    }
    return Container();
  }

  Widget _buildWeekdaySelector() {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복 요일',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '반복할 요일을 선택해주세요',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        
        // 요일 선택 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey400),
          ),
          child: Column(
            children: [
              Row(
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final isSelected = _selectedWeekdays.contains(weekday);
            
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () {
                setState(() {
                            if (isSelected) {
                    _selectedWeekdays.remove(weekday);
                            } else {
                              _selectedWeekdays.add(weekday);
                  }
                });
              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.green600.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.green600 : AppColors.grey400,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            weekdays[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.green600 : AppColors.grey700,
                            ),
                          ),
                        ),
                      ),
              ),
            );
          }),
              ),
              
              if (_selectedWeekdays.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '선택된 요일: ${_selectedWeekdays.map((w) => weekdays[w - 1]).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.green600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMonthdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복할 날짜 선택',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey400),
          ),
          child: Column(
            children: [
              // 1-31일 그리드
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 32, // 1-31일 + 마지막날
                itemBuilder: (context, index) {
                  final day = index == 31 ? 99 : index + 1; // 99는 마지막날
                  final dayText = index == 31 ? '말일' : '$day';
            final isSelected = _selectedMonthDays.contains(day);
            
                  return GestureDetector(
                    onTap: () {
                setState(() {
                        if (isSelected) {
                    _selectedMonthDays.remove(day);
                        } else {
                          _selectedMonthDays.add(day);
                  }
                });
              },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.orange600.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppColors.orange600 : AppColors.grey400,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          dayText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.orange600 : AppColors.grey700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              if (_selectedMonthDays.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange600.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '선택된 날짜: ${_selectedMonthDays.map((d) => d == 99 ? '말일' : '${d}일').join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomIntervalSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복 간격 설정',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey400),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customIntervalController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
                        hintText: '숫자 입력',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.red600),
            ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
                        setState(() {
            _customInterval = int.tryParse(value);
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '일마다 반복',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey700,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Text(
                '예: 3을 입력하면 3일마다 반복됩니다',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.grey600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHabitTargetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '목표 횟수',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '입력하지 않으면 1회로 설정됩니다',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        
        // 목표 횟수 선택 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.grey400),
          ),
          child: Column(
            children: [
              // 빠른 선택 버튼들
              Text(
                '빠른 선택',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [1, 3, 5, 10].map((count) {
                  final isSelected = _targetCount == count;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _targetCount = count;
                            _targetCountController.text = count.toString();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.orange600.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.orange600 : AppColors.grey400,
                            ),
                          ),
                          child: Text(
                            '${count}회',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? AppColors.orange600 : AppColors.grey700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 12),
              
              // 직접 입력
              Text(
                '또는 직접 입력',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
                controller: _targetCountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '기본값: 1회',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.orange600),
            ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) {
                  setState(() {
            _targetCount = int.tryParse(value);
                  });
          },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildEstimatedTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '예상 소요 시간 (선택사항)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _estimatedTime?.inHours,
                decoration: InputDecoration(
                  hintText: '시간',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.purple600),
                  ),
                ),
                items: List.generate(24, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Text('${index}시간'),
                  );
                }),
                onChanged: (hours) {
                  final minutes = _estimatedTime?.inMinutes.remainder(60) ?? 0;
                  _estimatedTime = Duration(hours: hours ?? 0, minutes: minutes);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: _estimatedTime?.inMinutes.remainder(60),
                decoration: InputDecoration(
                  hintText: '분',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.purple600),
                  ),
                ),
                items: [0, 15, 30, 45].map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('${minutes}분'),
                  );
                }).toList(),
                onChanged: (minutes) {
                  final hours = _estimatedTime?.inHours ?? 0;
                  _estimatedTime = Duration(hours: hours, minutes: minutes ?? 0);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
      children: [
        Text(
          '태그 (선택사항)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadAvailableTags,
              icon: const Icon(Icons.refresh, size: 16),
              tooltip: '태그 목록 새로고침',
              style: IconButton.styleFrom(
                foregroundColor: AppColors.grey600,
                minimumSize: const Size(24, 24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 선택된 태그들
        if (_tags.isNotEmpty) ...[
          Text(
            '선택된 태그:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _tags.map((tag) => _buildSelectedTagChip(tag)).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // 사용 가능한 태그들
        if (_availableTags.isNotEmpty) ...[
          Text(
            '사용 가능한 태그:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _availableTags
                .where((tag) => !_tags.contains(tag))
                .map((tag) => _buildAvailableTagChip(tag))
                .toList(),
          ),
        ] else ...[
          Text(
            '사용 가능한 태그가 없습니다.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey500,
              ),
            ),
          ],
      ],
    );
  }

  /// 선택된 태그 칩
  Widget _buildSelectedTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple600,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _removeTag(tag),
            child: const Icon(
              Icons.close,
              size: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 사용 가능한 태그 칩
  Widget _buildAvailableTagChip(String tag) {
    return GestureDetector(
      onTap: () => _addTagFromChip(tag),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey400,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tag,
              size: 12,
              color: AppColors.grey600,
            ),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 태그 추가 (칩에서)
  void _addTagFromChip(String tag) {
    if (!_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
  }

  /// 태그 제거
  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  /// 사용 가능한 태그 목록 로드 (추가)
  List<String> _availableTags = [];
  
  void _loadAvailableTags() async {
    try {
      // 기본 추천 태그들
      final defaultTags = [
        '업무', '개인', '공부', '운동', '건강', '취미', 
        '쇼핑', '여행', '독서', '요리', '청소', '미팅',
        '프로젝트', '중요', '긴급', '루틴'
      ];
      
      setState(() {
        _availableTags = defaultTags;
      });
    } catch (e) {
      if (kDebugMode) {
        print('태그 로드 실패: $e');
      }
    }
  }

  Widget _buildReminderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '알림 설정',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.grey700,
              ),
            ),
            const Spacer(),
            Switch(
              value: _hasReminder,
              onChanged: (value) {
                setState(() {
                  _hasReminder = value;
                });
              },
              activeColor: AppColors.purple600,
            ),
          ],
        ),
        if (_hasReminder) ...[
          const SizedBox(height: 8),
          Text(
            '오늘 할일에 표시될 때 설정한 시간에 알림이 울립니다',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 8),
          
          // 시간 선택 카드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey400),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '알림 시간',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // 시간 선택 버튼
                GestureDetector(
                  onTap: _selectReminderTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.purple600),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppColors.purple600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(_reminderTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.purple600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.purple600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 빠른 선택 버튼들
                Text(
                  '빠른 선택',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickTimeButton('오전 7:00', const TimeOfDay(hour: 7, minute: 0)),
                    _buildQuickTimeButton('오전 9:00', const TimeOfDay(hour: 9, minute: 0)),
                    _buildQuickTimeButton('오후 12:00', const TimeOfDay(hour: 12, minute: 0)),
                    _buildQuickTimeButton('오후 3:00', const TimeOfDay(hour: 15, minute: 0)),
                    _buildQuickTimeButton('오후 6:00', const TimeOfDay(hour: 18, minute: 0)),
                    _buildQuickTimeButton('오후 9:00', const TimeOfDay(hour: 21, minute: 0)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickTimeButton(String label, TimeOfDay time) {
    final isSelected = _reminderTime.hour == time.hour && _reminderTime.minute == time.minute;
    
    return GestureDetector(
      onTap: () {
                setState(() {
          _reminderTime = time;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.purple600.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.purple600 : AppColors.grey400,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.purple600 : AppColors.grey700,
          ),
        ),
      ),
    );
  }

  void _selectReminderTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.purple600,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _reminderTime = time;
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (hour == 0) {
      return '오전 12:$minute';
    } else if (hour < 12) {
      return '오전 $hour:$minute';
    } else if (hour == 12) {
      return '오후 12:$minute';
    } else {
      return '오후 ${hour - 12}:$minute';
    }
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      // 시작일이 마감일보다 뒤에 있으면 경고
      if (_selectedDueDate != null && date.isAfter(_selectedDueDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('시작일은 마감일보다 뒤에 설정할 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedStartDate = date;
      });
    }
  }

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? (_selectedStartDate ?? DateTime.now()),
      firstDate: _selectedStartDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      // 마감일이 시작일보다 앞에 있으면 경고
      if (_selectedStartDate != null && date.isBefore(_selectedStartDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('마감일은 시작일보다 앞에 설정할 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _saveTodo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 반복 패턴 생성
    RepeatPattern? repeatPattern;
    if ((_selectedType == TodoType.repeat || _selectedType == TodoType.habit) && _selectedRepeatType != null) {
      switch (_selectedRepeatType!) {
        case RepeatType.daily:
          repeatPattern = RepeatPattern(
            repeatType: RepeatType.daily,
          );
          break;
        case RepeatType.weekly:
          if (_selectedWeekdays.isNotEmpty) {
            repeatPattern = RepeatPattern(
              repeatType: RepeatType.weekly,
              weekdays: _selectedWeekdays,
            );
          }
          break;
        case RepeatType.monthly:
          if (_selectedMonthDays.isNotEmpty) {
            repeatPattern = RepeatPattern(
              repeatType: RepeatType.monthly,
              monthDays: _selectedMonthDays,
            );
          }
          break;
        case RepeatType.yearly:
          // 연간 반복은 지원하지 않음
          break;
        case RepeatType.custom:
          if (_customInterval != null && _customInterval! > 0) {
            repeatPattern = RepeatPattern(
              repeatType: RepeatType.custom,
              customInterval: _customInterval,
            );
          }
          break;
      }
    }

    // 수정된 투두 생성
    final updatedTodo = widget.todo.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      category: _selectedCategory,
      priority: _selectedPriority,
      difficulty: _selectedDifficulty,
      startDate: _selectedStartDate,
      dueDate: _selectedDueDate,
      estimatedTime: _estimatedTime,
      repeatPattern: repeatPattern,
      tags: _tags,
      targetCount: _targetCount,
      hasReminder: _hasReminder,
      reminderTime: _hasReminder ? DateTime(2024, 1, 1, _reminderTime.hour, _reminderTime.minute) : null,
      showUntilCompleted: _showUntilCompleted,
    );

    widget.onTodoUpdated(updatedTodo);
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

  Widget _buildShowOptionSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey400),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                color: AppColors.blue600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '표시 옵션',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 완료할 때까지 표시하기
          GestureDetector(
            onTap: () {
              setState(() {
                _showUntilCompleted = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _showUntilCompleted ? AppColors.blue600.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _showUntilCompleted ? AppColors.blue600 : AppColors.grey400,
                  width: _showUntilCompleted ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _showUntilCompleted ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _showUntilCompleted ? AppColors.blue600 : AppColors.grey500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '완료할 때까지 표시하기 (추천)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _showUntilCompleted ? AppColors.blue600 : AppColors.grey700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '완료될 때까지 매일 오늘 할일에 표시됩니다',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 기간 내에만 표시하기
          GestureDetector(
            onTap: () {
              setState(() {
                _showUntilCompleted = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !_showUntilCompleted ? AppColors.orange600.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: !_showUntilCompleted ? AppColors.orange600 : AppColors.grey400,
                  width: !_showUntilCompleted ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !_showUntilCompleted ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: !_showUntilCompleted ? AppColors.orange600 : AppColors.grey500,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기간 내에만 표시하기',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: !_showUntilCompleted ? AppColors.orange600 : AppColors.grey700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '시작일부터 마감일까지만 오늘 할일에 표시',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 