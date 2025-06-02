import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../models/models.dart';
import '../models/mood_entry_model.dart';
import '../models/activity_model.dart';
import '../services/mood_service.dart';
import '../services/activity_service.dart';
import '../pages/activity_management_page.dart';

class MoodEntryDialog extends StatefulWidget {
  final UserModel currentUser;
  final MoodEntryModel? existingEntry;

  const MoodEntryDialog({
    super.key,
    required this.currentUser,
    this.existingEntry,
  });

  @override
  State<MoodEntryDialog> createState() => _MoodEntryDialogState();
}

class _MoodEntryDialogState extends State<MoodEntryDialog> {
  MoodType _selectedMood = MoodType.normal;
  final TextEditingController _contentController = TextEditingController();
  List<String> _selectedActivities = [];
  List<ActivityModel> _availableActivities = [];
  List<String> _imageUrls = [];
  List<File> _selectedImages = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingActivities = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadActivities();
    if (widget.existingEntry != null) {
      _selectedMood = widget.existingEntry!.mood;
      _contentController.text = widget.existingEntry!.content;
      _selectedActivities = List.from(widget.existingEntry!.activities);
      _imageUrls = List.from(widget.existingEntry!.imageUrls);
      _selectedDate = widget.existingEntry!.createdAt;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    
    try {
      // 기본 활동 초기화 (없으면 생성)
      await ActivityService.initializeDefaultActivities(widget.currentUser.id);
      
      // 모든 활동 조회
      final activities = await ActivityService.getUserActivities(widget.currentUser.id);
      
      setState(() {
        _availableActivities = activities;
        _isLoadingActivities = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('활동 로딩 실패: $e');
      }
      setState(() => _isLoadingActivities = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // 미래 날짜 선택 불가
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFEC407A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (images.isNotEmpty) {
        setState(() {
          for (final image in images) {
            if (_selectedImages.length < 5) { // 최대 5장
              _selectedImages.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('이미지 선택 오류: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        final urlIndex = index - _selectedImages.length;
        if (urlIndex < _imageUrls.length) {
          _imageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  Future<void> _saveMoodEntry() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('일기 내용을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      MoodEntryModel entry;
      bool success = false;
      
      // TODO: 나중에 Firebase Storage에 이미지 업로드 구현
      // 현재는 로컬 이미지 경로만 저장 (실제 서비스에서는 Firebase Storage 사용)
      final allImageUrls = List<String>.from(_imageUrls);
      for (final image in _selectedImages) {
        allImageUrls.add(image.path); // 임시로 로컬 경로 저장
      }
      
      if (widget.existingEntry != null) {
        // 기존 일기 수정
        entry = widget.existingEntry!.copyWith(
          mood: _selectedMood,
          content: _contentController.text.trim(),
          activities: _selectedActivities,
          imageUrls: allImageUrls,
          createdAt: _selectedDate,
        );
        success = await MoodService.updateMoodEntry(entry);
        if (kDebugMode) {
          print('감정일기 수정 시도: ${entry.id}');
        }
      } else {
        // 새 일기 작성
        entry = MoodEntryModel.create(
          userId: widget.currentUser.id,
          mood: _selectedMood,
          content: _contentController.text.trim(),
          activities: _selectedActivities,
          imageUrls: allImageUrls,
          customDate: _selectedDate,
        );
        success = await MoodService.saveMoodEntry(entry);
        if (kDebugMode) {
          print('새 감정일기 저장 시도: ${entry.id}, 날짜: ${entry.formattedDate}');
        }
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(entry);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingEntry != null ? '감정일기가 수정되었습니다' : '감정일기가 저장되었습니다'),
              backgroundColor: const Color(0xFFEC407A),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다. 네트워크를 확인하고 다시 시도해주세요.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('감정일기 저장 중 예외 발생: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleActivity(String activityName) {
    setState(() {
      if (_selectedActivities.contains(activityName)) {
        _selectedActivities.remove(activityName);
      } else {
        if (_selectedActivities.length < 5) { // 최대 5개
          _selectedActivities.add(activityName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('최대 5개까지 선택할 수 있습니다')),
          );
        }
      }
    });
  }

  Future<void> _navigateToActivityManagement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActivityManagementPage(currentUser: widget.currentUser),
      ),
    );
    
    // 활동 관리 페이지에서 돌아오면 활동 목록 새로고침
    if (result != null) {
      await _loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateSelector(),
                    const SizedBox(height: 24),
                    _buildMoodSelector(),
                    const SizedBox(height: 24),
                    _buildContentInput(),
                    const SizedBox(height: 24),
                    _buildActivitySelector(),
                    const SizedBox(height: 24),
                    _buildImageSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEC407A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingEntry != null ? '감정일기 수정' : '감정일기 작성',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '작성 날짜',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: const Color(0xFFEC407A),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 기분은 어떠세요?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: MoodType.values.map((mood) {
            final isSelected = _selectedMood == mood;
            return GestureDetector(
              onTap: () => setState(() => _selectedMood = mood),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFEC407A).withOpacity(0.1)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFEC407A)
                        : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected 
                            ? const Color(0xFFEC407A)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘 있었던 일을 자유롭게 적어보세요',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contentController,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: '오늘 하루는 어떠셨나요? 기분, 생각, 경험 등을 자유롭게 적어보세요...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFEC407A), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '오늘의 활동',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _navigateToActivityManagement,
              icon: Icon(
                Icons.add_circle_outline,
                color: const Color(0xFFEC407A),
                size: 24,
              ),
              tooltip: '활동 관리',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '어떤 활동을 하셨나요? (최대 5개 선택)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingActivities) ...[
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFEC407A),
            ),
          ),
        ] else if (_availableActivities.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.extension_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  '활동이 없어요',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _navigateToActivityManagement,
                  child: Text(
                    '+ 버튼을 눌러 활동을 추가해보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFEC407A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableActivities.map((activity) {
              final isSelected = _selectedActivities.contains(activity.name);
              return GestureDetector(
                onTap: () => _toggleActivity(activity.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEC407A).withOpacity(0.1)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFEC407A)
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        activity.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? const Color(0xFFEC407A)
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: const Color(0xFFEC407A),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (_selectedActivities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '선택된 활동: ${_selectedActivities.length}/5',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFFEC407A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageSection() {
    final totalImages = _selectedImages.length + _imageUrls.length;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '오늘의 사진',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(width: 8),
            if (totalImages > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC407A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalImages',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '소중한 순간을 사진으로 기록해보세요 (최대 5장)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: totalImages >= 5 ? null : _pickImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: totalImages >= 5 
                  ? Colors.grey.shade100 
                  : const Color(0xFFEC407A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: totalImages >= 5 
                    ? Colors.grey.shade300 
                    : const Color(0xFFEC407A).withOpacity(0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: totalImages >= 5 
                      ? Colors.grey.shade400 
                      : const Color(0xFFEC407A),
                ),
                const SizedBox(height: 8),
                Text(
                  totalImages >= 5 ? '최대 5장까지 추가 가능' : '사진 추가하기',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: totalImages >= 5 
                        ? Colors.grey.shade500 
                        : const Color(0xFFEC407A),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (totalImages > 0) ...[
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: totalImages,
            itemBuilder: (context, index) {
              if (index < _selectedImages.length) {
                // 새로 선택한 이미지들
                return _buildImageThumbnail(
                  imageFile: _selectedImages[index],
                  index: index,
                );
              } else {
                // 기존 이미지 URL들
                final urlIndex = index - _selectedImages.length;
                return _buildImageThumbnail(
                  imageUrl: _imageUrls[urlIndex],
                  index: index,
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildImageThumbnail({
    File? imageFile,
    String? imageUrl,
    required int index,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageFile != null
                ? Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                  )
                : imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade500,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.image,
                        color: Colors.grey.shade400,
                      ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              '취소',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveMoodEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC407A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.existingEntry != null ? '수정' : '저장',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
