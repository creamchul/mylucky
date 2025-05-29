import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Constants imports
import '../constants/app_colors.dart';

// Services imports
import '../services/todo_service.dart';

class TagManagementDialog extends StatefulWidget {
  final String userId;
  final List<String> availableTags;
  final VoidCallback onTagsUpdated;

  const TagManagementDialog({
    super.key,
    required this.userId,
    required this.availableTags,
    required this.onTagsUpdated,
  });

  @override
  State<TagManagementDialog> createState() => _TagManagementDialogState();
}

class _TagManagementDialogState extends State<TagManagementDialog> {
  final TextEditingController _newTagController = TextEditingController();
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.availableTags);
  }

  @override
  void dispose() {
    _newTagController.dispose();
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
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 헤더
            Row(
              children: [
                Icon(
                  Icons.tag,
                  color: AppColors.purple600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '태그 관리',
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

            // 새 태그 추가
            _buildAddTagSection(),
            const SizedBox(height: 24),

            // 기존 태그 목록
            Expanded(
              child: _buildTagList(),
            ),

            // 버튼
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 새 태그 추가 섹션
  Widget _buildAddTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '새 태그 추가',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newTagController,
                decoration: InputDecoration(
                  hintText: '새 태그 이름을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.purple600),
                  ),
                ),
                onSubmitted: (_) => _addNewTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addNewTag,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.purple600,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 태그 목록
  Widget _buildTagList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tag,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              '태그가 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 태그를 추가해보세요',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기존 태그 (${_tags.length}개)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.grey700,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _tags.length,
            itemBuilder: (context, index) {
              final tag = _tags[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.tag,
                    color: AppColors.purple600,
                  ),
                  title: Text(
                    tag,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _deleteTag(tag),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '태그 삭제',
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 새 태그 추가
  void _addNewTag() {
    final newTag = _newTagController.text.trim();
    
    if (newTag.isEmpty) {
      _showMessage('태그 이름을 입력해주세요.');
      return;
    }
    
    if (_tags.contains(newTag)) {
      _showMessage('이미 존재하는 태그입니다.');
      return;
    }
    
    setState(() {
      _tags.add(newTag);
      _newTagController.clear();
    });
    
    _showMessage('태그가 추가되었습니다: $newTag');
  }

  /// 태그 삭제
  void _deleteTag(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('\'$tag\' 태그를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _tags.remove(tag);
              });
              _showMessage('태그가 삭제되었습니다: $tag');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 변경사항 저장
  void _saveChanges() {
    // 실제로는 TodoService에 태그 목록을 저장하는 기능이 필요하지만
    // 현재는 할일에서 태그를 추출하는 방식이므로 콜백만 호출
    widget.onTagsUpdated();
    Navigator.of(context).pop();
    _showMessage('태그 관리가 완료되었습니다.');
  }

  /// 메시지 표시
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 