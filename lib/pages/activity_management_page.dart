import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_colors.dart';
import '../models/models.dart';
import '../models/activity_model.dart';
import '../services/activity_service.dart';

class ActivityManagementPage extends StatefulWidget {
  final UserModel currentUser;

  const ActivityManagementPage({
    super.key,
    required this.currentUser,
  });

  @override
  State<ActivityManagementPage> createState() => _ActivityManagementPageState();
}

class _ActivityManagementPageState extends State<ActivityManagementPage> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoading = true);
    
    try {
      // 기본 활동 초기화 (없으면 생성)
      await ActivityService.initializeDefaultActivities(widget.currentUser.id);
      
      // 모든 활동 조회
      final activities = await ActivityService.getUserActivities(widget.currentUser.id);
      
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('활동 로딩 실패: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showActivityDialog({ActivityModel? existingActivity}) async {
    final result = await showDialog<ActivityModel>(
      context: context,
      builder: (context) => _ActivityEditDialog(
        currentUser: widget.currentUser,
        existingActivity: existingActivity,
      ),
    );

    if (result != null) {
      await _loadActivities();
    }
  }

  Future<void> _deleteActivity(ActivityModel activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '활동 삭제',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${activity.name}" 활동을 삭제하시겠어요?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            if (activity.isDefault) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '기본 활동을 삭제하면 다시 생성되지 않습니다.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '⚠️ 삭제된 활동은 복구할 수 없습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '삭제',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ActivityService.deleteActivity(activity.id, activity.isDefault);
        if (success) {
          await _loadActivities();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${activity.name}" 활동이 삭제되었습니다'),
                backgroundColor: const Color(0xFFEC407A),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('삭제에 실패했습니다. 다시 시도해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('활동 삭제 중 오류: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('삭제 중 오류가 발생했습니다: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.extension,
              color: const Color(0xFFEC407A),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '활동 관리',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFDFDFD),
              Color(0xFFF8F9FA),
              Color(0xFFF0F8F5),
              Color(0xFFFFF8F3),
            ],
          ),
        ),
        child: _isLoading ? _buildLoadingWidget() : _buildActivitiesList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActivityDialog(),
        backgroundColor: const Color(0xFFEC407A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('활동 추가'),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFEC407A),
      ),
    );
  }

  Widget _buildActivitiesList() {
    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    // 기본 활동과 사용자 정의 활동 분리
    final defaultActivities = _activities.where((a) => a.isDefault).toList();
    final customActivities = _activities.where((a) => !a.isDefault).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (defaultActivities.isNotEmpty) ...[
            _buildSectionHeader('기본 활동', defaultActivities.length),
            const SizedBox(height: 12),
            _buildActivitiesGrid(defaultActivities),
            const SizedBox(height: 32),
          ],
          if (customActivities.isNotEmpty) ...[
            _buildSectionHeader('내가 만든 활동', customActivities.length),
            const SizedBox(height: 12),
            _buildActivitiesGrid(customActivities),
          ],
          const SizedBox(height: 80), // FloatingActionButton 공간
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEC407A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFEC407A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEC407A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesGrid(List<ActivityModel> activities) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showActivityDialog(existingActivity: activity),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 활동 이름
            Expanded(
              child: Text(
                activity.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 액션 버튼 (모든 활동에 대해 표시)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showActivityDialog(existingActivity: activity);
                    break;
                  case 'delete':
                    _deleteActivity(activity);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 18,
                        color: const Color(0xFFEC407A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '수정',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.more_vert,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            // 기본 활동 표시
            if (activity.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '기본',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              '활동이 없어요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 활동을 추가해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 활동 편집 다이얼로그
class _ActivityEditDialog extends StatefulWidget {
  final UserModel currentUser;
  final ActivityModel? existingActivity;

  const _ActivityEditDialog({
    required this.currentUser,
    this.existingActivity,
  });

  @override
  State<_ActivityEditDialog> createState() => _ActivityEditDialogState();
}

class _ActivityEditDialogState extends State<_ActivityEditDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingActivity != null) {
      _nameController.text = widget.existingActivity!.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveActivity() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('활동 이름을 입력해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 이름 중복 확인
      final isDuplicate = await ActivityService.isActivityNameExists(
        widget.currentUser.id,
        name,
        excludeId: widget.existingActivity?.id,
      );

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 존재하는 활동 이름입니다')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      ActivityModel activity;
      bool success = false;

      if (widget.existingActivity != null) {
        // 기존 활동 수정
        activity = widget.existingActivity!.copyWith(
          name: name,
        );
        success = await ActivityService.updateActivity(activity);
      } else {
        // 새 활동 생성
        activity = ActivityModel.create(
          userId: widget.currentUser.id,
          name: name,
        );
        success = await ActivityService.saveActivity(activity);
      }

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(activity);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.existingActivity != null ? '활동이 수정되었습니다' : '활동이 추가되었습니다'),
              backgroundColor: const Color(0xFFEC407A),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('저장에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('활동 저장 중 오류: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                    _buildNameInput(),
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
            Icons.extension,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingActivity != null ? '활동 수정' : '새 활동 추가',
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

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '활동 이름',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        if (widget.existingActivity?.isDefault == true) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '기본 활동을 수정하고 있습니다. 변경사항이 저장됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: '활동 이름을 입력하세요 (예: 피아노 연습)',
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
            onPressed: _isLoading ? null : _saveActivity,
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
                    widget.existingActivity != null ? '수정' : '추가',
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