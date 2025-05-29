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
  RepeatType? _selectedRepeatType;
  
  // 습관 설정
  int? _targetCount;
  
  // 알림 설정
  late bool _hasReminder;
  late int _reminderMinutesBefore;
  
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
    _selectedRepeatType = widget.todo.repeatPattern?.repeatType;
    
    _targetCount = widget.todo.targetCount;
    _hasReminder = widget.todo.hasReminder;
    _reminderMinutesBefore = widget.todo.reminderMinutesBefore ?? 30;
    _showUntilCompleted = widget.todo.showUntilCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
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
                      
                      // 타입 선택 (완료되지 않은 경우만 수정 가능)
                      if (!widget.todo.isCompleted)
                        _buildTypeSelector(),
                      if (!widget.todo.isCompleted)
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
                      
                      // 시작일 설정
                      _buildStartDateSelector(),
                      const SizedBox(height: 16),
                      
                      // 기한 설정
                      _buildDueDateSelector(),
                      
                      // 반복 설정 (반복 할일과 습관)
                      if ((_selectedType == TodoType.repeat || _selectedType == TodoType.habit) && !widget.todo.isCompleted) ...[
                        _buildRepeatTypeSelector(),
                        const SizedBox(height: 16),
                        if (_selectedRepeatType != null)
                          _buildRepeatDetailSettings(),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: TodoType.values.map((type) {
            final isSelected = _selectedType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedType = type;
                    // 타입 변경 시 관련 설정 초기화
                    if (type == TodoType.habit) {
                      // 습관은 기본적으로 매일 반복으로 설정
                      _selectedRepeatType = RepeatType.daily;
                    } else if (type == TodoType.repeat) {
                      // 반복 할일은 기본적으로 매일 반복으로 설정
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
                }
              },
              selectedColor: AppColors.purple600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            );
          }).toList(),
        ),
      ],
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
        DropdownButtonFormField<TodoCategory>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          items: TodoCategory.values.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Text(category.emoji),
                  const SizedBox(width: 8),
                  Text(category.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
              });
            }
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
        DropdownButtonFormField<Priority>(
          value: _selectedPriority,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          items: Priority.values.map((priority) {
            return DropdownMenuItem(
              value: priority,
              child: Row(
                children: [
                  Text(_getPriorityEmoji(priority)),
                  const SizedBox(width: 8),
                  Text(priority.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
      ],
    );
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
        DropdownButtonFormField<Difficulty>(
          value: _selectedDifficulty,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          items: Difficulty.values.map((difficulty) {
            return DropdownMenuItem(
              value: difficulty,
              child: Text(difficulty.displayName),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedDifficulty = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildStartDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '시작일',
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
              child: OutlinedButton.icon(
                onPressed: _selectStartDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedStartDate != null
                      ? '${_selectedStartDate!.year}.${_selectedStartDate!.month.toString().padLeft(2, '0')}.${_selectedStartDate!.day.toString().padLeft(2, '0')}'
                      : '날짜 선택',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedStartDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              tooltip: '시작일 제거',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '마감일',
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
              child: OutlinedButton.icon(
                onPressed: _selectDueDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _selectedDueDate != null
                      ? '${_selectedDueDate!.year}.${_selectedDueDate!.month.toString().padLeft(2, '0')}.${_selectedDueDate!.day.toString().padLeft(2, '0')}'
                      : '날짜 선택',
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _selectedDueDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              tooltip: '마감일 제거',
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        Wrap(
          spacing: 8,
          children: RepeatType.values.where((type) => type != RepeatType.yearly).map((type) {
            final isSelected = _selectedRepeatType == type;
            return ChoiceChip(
              label: Text(type.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRepeatType = type;
                  });
                }
              },
              selectedColor: AppColors.purple600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            );
          }).toList(),
        ),
      ],
    );
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
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final isSelected = _selectedWeekdays.contains(weekday);
            
            return FilterChip(
              label: Text(weekdays[index]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeekdays.add(weekday);
                  } else {
                    _selectedWeekdays.remove(weekday);
                  }
                });
              },
              selectedColor: AppColors.purple600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            );
          }),
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
          '월별 반복 일자',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(31, (index) {
            final day = index + 1;
            final isSelected = _selectedMonthDays.contains(day);
            
            return FilterChip(
              label: Text(day.toString()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedMonthDays.add(day);
                  } else {
                    _selectedMonthDays.remove(day);
                  }
                });
              },
              selectedColor: AppColors.purple600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.grey700,
              ),
            );
          }),
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
          '커스텀 간격',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _customInterval?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '간격을 일 단위로 입력하세요',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          onChanged: (value) {
            _customInterval = int.tryParse(value);
          },
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
        TextFormField(
          initialValue: _targetCount?.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '기본값: 1회',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.purple600),
            ),
          ),
          onChanged: (value) {
            _targetCount = int.tryParse(value);
          },
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
        Text(
          '태그 (선택사항)',
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
              child: TextFormField(
                controller: _tagController,
                decoration: InputDecoration(
                  hintText: '태그를 입력하고 추가 버튼을 누르세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.purple600),
                  ),
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.purple600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
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

  void _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDueDate = date;
      });
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
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
      reminderMinutesBefore: _hasReminder ? _reminderMinutesBefore : null,
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
} 