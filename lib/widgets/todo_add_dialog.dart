import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';

// Models imports
import '../models/models.dart';

// Services imports
import '../services/todo_service.dart';

class TodoAddDialog extends StatefulWidget {
  final Function(TodoItemModel) onTodoAdded;
  final String userId;

  const TodoAddDialog({
    super.key,
    required this.onTodoAdded,
    required this.userId,
  });

  @override
  State<TodoAddDialog> createState() => _TodoAddDialogState();
}

class _TodoAddDialogState extends State<TodoAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _habitTargetController = TextEditingController();
  
  TodoType _selectedType = TodoType.oneTime;
  TodoCategory _selectedCategory = TodoCategory.personal;
  Priority _selectedPriority = Priority.medium;
  Difficulty _selectedDifficulty = Difficulty.medium;
  
  DateTime? _selectedStartDate;
  DateTime? _selectedDueDate;
  Duration? _estimatedTime;
  
  List<String> _tags = [];
  List<String> _availableTags = [];
  bool _isLoadingTags = false;
  
  // 반복 설정
  RepeatType? _selectedRepeatType;
  List<int> _selectedWeekdays = [];
  List<int> _selectedMonthDays = [];
  List<int> _selectedYearMonths = [];
  List<int> _selectedYearDays = [];
  int? _customInterval;
  
  // 습관 설정
  int? _targetCount;
  
  // 알림 설정
  bool _hasReminder = false;
  int _reminderMinutesBefore = 30;
  
  // 일회성 할일 옵션
  bool _showUntilCompleted = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _habitTargetController.dispose();
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
                  '새 할일 추가',
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
                      const SizedBox(height: 24),
                      
                      // 유형별 상세 설정
                      _buildTypeSpecificSettings(),
                      
                      // 공통 설정
                      _buildCommonSettings(),
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
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
            _selectedRepeatType = RepeatType.daily;
          } else {
            // 일회성 할일로 변경 시 반복 설정 초기화
            _selectedRepeatType = null;
            _selectedWeekdays.clear();
            _selectedMonthDays.clear();
            _selectedYearMonths.clear();
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
            '언제부터 시작할 할일인가요? (선택사항)',
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

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedStartDate = date;
      });
    }
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

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
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
            if (_isLoadingTags)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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
        ] else if (!_isLoadingTags) ...[
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
      onTap: () => _addTag(tag),
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

  /// 태그 추가
  void _addTag(String tag) {
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
          DropdownButtonFormField<int>(
            value: _reminderMinutesBefore,
            decoration: InputDecoration(
              labelText: '알림 시간',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.purple600),
              ),
            ),
            items: [5, 10, 15, 30, 60, 120].map((minutes) {
              return DropdownMenuItem(
                value: minutes,
                child: Text('${minutes}분 전'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _reminderMinutesBefore = value;
                });
              }
            },
          ),
        ],
      ],
    );
  }

  void _saveTodo() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 반복 할일과 습관의 경우 반복 유형별 검증
    if (_selectedType == TodoType.repeat || _selectedType == TodoType.habit) {
      if (_selectedRepeatType == RepeatType.weekly && _selectedWeekdays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == TodoType.habit 
                ? '주간 반복 습관은 최소 하나의 요일을 선택해야 합니다.'
                : '주간 반복 할일은 최소 하나의 요일을 선택해야 합니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedRepeatType == RepeatType.monthly && _selectedMonthDays.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == TodoType.habit 
                ? '월간 반복 습관은 최소 하나의 날짜를 선택해야 합니다.'
                : '월간 반복 할일은 최소 하나의 날짜를 선택해야 합니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedRepeatType == RepeatType.custom && (_customInterval == null || _customInterval! <= 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_selectedType == TodoType.habit 
                ? '사용자 정의 습관은 반복 간격을 입력해야 합니다.'
                : '사용자 정의 할일은 반복 간격을 입력해야 합니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // 시작일 설정 (날짜만, 시간은 기본값 사용)
    DateTime? finalStartDate;
    if (_selectedStartDate != null) {
      finalStartDate = DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
        0, // 시작일은 하루의 시작으로 설정
        0,
      );
    }

    // 마감일 설정 (날짜만, 시간은 기본값 사용)
    DateTime? finalDueDate;
    if (_selectedDueDate != null) {
      finalDueDate = DateTime(
        _selectedDueDate!.year,
        _selectedDueDate!.month,
        _selectedDueDate!.day,
        23, // 마감일은 하루의 끝으로 설정
        59,
        59,
      );
    }

    // 시작일과 마감일 검증
    if (finalStartDate != null && finalDueDate != null) {
      if (finalStartDate.isAfter(finalDueDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('시작일은 마감일보다 이전이어야 합니다.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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

    // 투두 생성
    final todo = TodoItemModel.create(
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      category: _selectedCategory,
      priority: _selectedPriority,
      difficulty: _selectedDifficulty,
      startDate: finalStartDate,
      dueDate: finalDueDate,
      estimatedTime: _estimatedTime,
      repeatPattern: repeatPattern,
      tags: _tags,
      targetCount: _targetCount,
      hasReminder: _hasReminder,
      reminderMinutesBefore: _hasReminder ? _reminderMinutesBefore : null,
      showUntilCompleted: _showUntilCompleted,
    );

    widget.onTodoAdded(todo);
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

  /// 사용 가능한 태그 목록 로드
  void _loadAvailableTags() async {
    setState(() {
      _isLoadingTags = true;
    });
    
    try {
      final tags = await TodoService.getAllTags(widget.userId);
      if (mounted) {
        setState(() {
          _availableTags = tags;
          _isLoadingTags = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTags = false;
        });
      }
      if (kDebugMode) {
        print('태그 로드 실패: $e');
      }
    }
  }

  Widget _buildTypeSpecificSettings() {
    switch (_selectedType) {
      case TodoType.oneTime:
        return _buildOneTimeSettings();
      case TodoType.repeat:
        return _buildRepeatSettings();
      case TodoType.habit:
        return _buildHabitSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildOneTimeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일회성 할일 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '한 번만 수행하는 할일입니다',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 12),
        
        // 완료할 때까지 표시하기 옵션
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
                              '시작일부터 마감일까지만 오늘 할일에 표시됩니다\n(마감일이 없으면 시작일 이후 완료될 때까지 표시)',
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
        ),
      ],
    );
  }

  Widget _buildRepeatSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '반복 할일 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '반복 주기를 설정해주세요',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 12),
        
        // 반복 유형 선택
        _buildRepeatTypeSelector(),
        const SizedBox(height: 16),
        
        // 반복 유형별 상세 설정
        if (_selectedRepeatType != null)
          _buildRepeatDetailSettings(),
      ],
    );
  }

  Widget _buildHabitSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '습관 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '습관의 반복 주기를 설정해주세요',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey600,
          ),
        ),
        const SizedBox(height: 12),
        
        // 반복 유형 선택
        _buildRepeatTypeSelector(),
        const SizedBox(height: 16),
        
        // 반복 유형별 상세 설정
        if (_selectedRepeatType != null)
          _buildRepeatDetailSettings(),
        
        // 목표 횟수 설정
        _buildHabitTargetSelector(),
      ],
    );
  }

  Widget _buildCommonSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '추가 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 12),
        
        // 시작일 선택
        _buildStartDateSelector(),
        const SizedBox(height: 16),
        
        // 마감일 선택
        _buildDueDateSelector(),
        const SizedBox(height: 16),
        
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
        
        // 예상 시간
        _buildEstimatedTimeSelector(),
        const SizedBox(height: 16),
        
        // 태그
        _buildTagsSelector(),
        const SizedBox(height: 16),
        
        // 알림 설정
        _buildReminderSelector(),
      ],
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

  Widget _buildRepeatDetailSettings() {
    switch (_selectedRepeatType!) {
      case RepeatType.daily:
        return _buildDailySettings();
      case RepeatType.weekly:
        return _buildWeekdaySelector();
      case RepeatType.monthly:
        return _buildMonthlySettings();
      case RepeatType.yearly:
        // 연간 반복은 지원하지 않음
        return const SizedBox.shrink();
      case RepeatType.custom:
        return _buildCustomSettings();
    }
  }

  Widget _buildDailySettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey400),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.blue600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '매일 반복됩니다. 추가 설정이 필요하지 않습니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
              ),
            ),
          ),
        ],
      ),
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

  Widget _buildMonthlySettings() {
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
      ],
    );
  }

  Widget _buildCustomSettings() {
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
      ],
    );
  }
} 