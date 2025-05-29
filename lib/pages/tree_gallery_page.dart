import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/focus_session_model.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';

class TreeGalleryPage extends StatefulWidget {
  final UserModel currentUser;

  const TreeGalleryPage({super.key, required this.currentUser});

  @override
  State<TreeGalleryPage> createState() => _TreeGalleryPageState();
}

class _TreeGalleryPageState extends State<TreeGalleryPage> with TickerProviderStateMixin {
  List<FocusSessionModel> _completedSessions = [];
  List<FocusSessionModel> _abandonedSessions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, completed, abandoned
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _staggerController;
  late Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _staggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _staggerController,
      curve: Curves.easeOutBack,
    ));
    
    _loadTreeData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadTreeData() async {
    setState(() => _isLoading = true);
    try {
      final allSessions = await FocusService.getUserSessions(widget.currentUser.id);
      setState(() {
        _completedSessions = allSessions.where((s) => s.status == FocusSessionStatus.completed).toList();
        _abandonedSessions = allSessions.where((s) => s.status == FocusSessionStatus.abandoned).toList();
        _isLoading = false;
      });
      
      // 데이터 로딩 완료 후 애니메이션 시작
      _fadeController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _staggerController.forward();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('나무 정보 로딩 실패: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getThemeColor() {
    return Colors.brown.shade600;
  }

  String _getSessionTimeText(FocusSessionModel session) {
    if (session.isStopwatchMode) {
      // 스톱워치 모드: 실제 경과 시간 표시
      final minutes = session.elapsedSeconds ~/ 60;
      final seconds = session.elapsedSeconds % 60;
      if (minutes > 0) {
        return seconds > 0 ? '${minutes}분 ${seconds}초 집중' : '${minutes}분 집중';
      } else {
        return '${seconds}초 집중';
      }
    } else {
      // 타이머 모드: 설정된 시간 표시
      return '${session.durationMinutesSet}분 집중';
    }
  }

  String _getDateText(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(sessionDate).inDays;
    
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    
    if (difference == 0) {
      return '오늘 ($weekday)';
    } else if (difference == 1) {
      return '어제 ($weekday)';
    } else if (difference <= 7) {
      return '${difference}일 전 ($weekday)';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} ($weekday)';
    }
  }

  List<FocusSessionModel> _getFilteredSessions() {
    switch (_selectedFilter) {
      case 'completed':
        return _completedSessions;
      case 'abandoned':
        return _abandonedSessions;
      default:
        return [..._completedSessions, ..._abandonedSessions]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _getThemeColor(),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🌳 나의 나무 갤러리',
          style: TextStyle(
            color: _getThemeColor(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _getThemeColor(),
            ),
            onPressed: _loadTreeData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAFAFA),
              Color(0xFFF0F8F0),
            ],
          ),
        ),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_getThemeColor()),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '나무들을 불러오는 중...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: _buildGalleryContent(),
              ),
      ),
    );
  }

  Widget _buildGalleryContent() {
    final filteredSessions = _getFilteredSessions();
    
    if (filteredSessions.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey.shade200,
                      Colors.grey.shade300,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.nature_people_outlined,
                  size: 60,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '아직 나무가 없어요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '집중하기를 통해 첫 번째 나무를 키워보세요!\n매일 조금씩 집중하면 아름다운 숲이 만들어집니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.park_outlined),
                label: const Text('집중하러 가기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getThemeColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 필터 탭
        _buildFilterTabs(),
        
        // 나무 갤러리
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTreeData,
            color: _getThemeColor(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: _buildTreeGrid(filteredSessions),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterTab('all', '전체', _completedSessions.length + _abandonedSessions.length),
          _buildFilterTab('completed', '성장한 나무', _completedSessions.length),
          _buildFilterTab('abandoned', '시든 나무', _abandonedSessions.length),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _getThemeColor() : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count그루',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeGrid(List<FocusSessionModel> sessions) {
    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85, // 세로로 더 길게 하여 날짜 정보 공간 확보
          ),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final delay = (index * 0.1).clamp(0.0, 0.5); // 최대 delay를 0.5로 제한
            final rawValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
            final animationValue = Curves.easeOutBack.transform(rawValue).clamp(0.0, 1.0);
            
            return Transform.scale(
              scale: animationValue.clamp(0.0, 1.0),
              child: Opacity(
                opacity: animationValue.clamp(0.0, 1.0),
                child: _buildTreeCard(session),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTreeCard(FocusSessionModel session) {
    final isWithered = session.status == FocusSessionStatus.abandoned;
    final cardColor = isWithered ? Colors.brown.shade50 : Colors.green.shade50;
    final borderColor = isWithered ? Colors.brown.shade200 : Colors.green.shade200;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 나무 위젯
            Expanded(
              flex: 3,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 80,
                    maxHeight: 80,
                  ),
                  child: TreeWidget(session: session, size: 80),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 집중 시간
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isWithered ? Colors.brown.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getSessionTimeText(session),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isWithered ? Colors.brown.shade700 : Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 날짜와 요일 (개선된 버전)
            Text(
              _getDateText(session.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 상태 표시
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isWithered ? Icons.close : Icons.check,
                  size: 14,
                  color: isWithered ? Colors.red.shade400 : Colors.green.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  isWithered ? '포기' : '완료',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isWithered ? Colors.red.shade400 : Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 