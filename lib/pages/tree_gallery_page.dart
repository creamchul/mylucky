import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/focus_session_model.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';
import '../constants/app_colors.dart';

class TreeGalleryPage extends StatefulWidget {
  final UserModel currentUser;
  final List<FocusSessionModel>? filteredSessions;
  final String? periodDescription;

  const TreeGalleryPage({
    super.key, 
    required this.currentUser,
    this.filteredSessions,
    this.periodDescription,
  });

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
      if (widget.filteredSessions != null) {
        // 필터링된 세션이 전달된 경우 그것을 사용
        setState(() {
          _completedSessions = widget.filteredSessions!.where((s) => s.status == FocusSessionStatus.completed).toList();
          _abandonedSessions = widget.filteredSessions!.where((s) => s.status == FocusSessionStatus.abandoned).toList();
          _isLoading = false;
        });
      } else {
        // 필터링된 세션이 없으면 모든 세션을 불러옴
        final allSessions = await FocusService.getUserSessions(widget.currentUser.id);
        setState(() {
          _completedSessions = allSessions.where((s) => s.status == FocusSessionStatus.completed).toList();
          _abandonedSessions = allSessions.where((s) => s.status == FocusSessionStatus.abandoned).toList();
          _isLoading = false;
        });
      }
      
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
    return AppColors.focusMint;
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
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} (${weekday})';
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

  // 날짜별로 세션들을 그룹화하는 함수 추가
  Map<String, List<FocusSessionModel>> _groupSessionsByDate(List<FocusSessionModel> sessions) {
    final Map<String, List<FocusSessionModel>> grouped = {};
    
    for (final session in sessions) {
      final dateKey = '${session.createdAt.year}-${session.createdAt.month.toString().padLeft(2, '0')}-${session.createdAt.day.toString().padLeft(2, '0')}';
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(session);
    }
    
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
          widget.periodDescription != null 
              ? '나무 갤러리 (${widget.periodDescription})'
              : '나의 나무 갤러리',
          style: TextStyle(
            color: _getThemeColor(),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
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
                  backgroundColor: AppColors.focusMint,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shadowColor: AppColors.focusMint.withOpacity(0.3),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.focusMint.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.focusMint.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.focusMint : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected ? [
              BoxShadow(
                color: AppColors.focusMint.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count그루',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.9) : Colors.grey.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTreeGrid(List<FocusSessionModel> sessions) {
    final groupedSessions = _groupSessionsByDate(sessions);
    final sortedDates = groupedSessions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 날짜부터

    return AnimatedBuilder(
      animation: _staggerAnimation,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sortedDates.asMap().entries.map((entry) {
            final index = entry.key;
            final dateKey = entry.value;
            final sessionsForDate = groupedSessions[dateKey]!;
            final delay = (index * 0.1).clamp(0.0, 0.5);
            final rawValue = (_staggerAnimation.value - delay).clamp(0.0, 1.0);
            final animationValue = Curves.easeOutBack.transform(rawValue).clamp(0.0, 1.0);
            
            return Transform.translate(
              offset: Offset(0, 30 * (1 - animationValue)),
              child: Opacity(
                opacity: animationValue.clamp(0.0, 1.0),
                child: _buildDateSection(dateKey, sessionsForDate),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDateSection(String dateKey, List<FocusSessionModel> sessions) {
    final date = DateTime.parse(dateKey);
    final dateText = _getDateText(date);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.focusMint.withOpacity(0.8),
                  AppColors.focusMint.withOpacity(0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.focusMint.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sessions.length}그루',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 해당 날짜의 나무들
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3개씩 배치하여 카드 크기 줄이기
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75, // 세로로 길게
            ),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _buildCompactTreeCard(session);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTreeCard(FocusSessionModel session) {
    final isWithered = session.status == FocusSessionStatus.abandoned;
    final cardColor = isWithered 
        ? Colors.red.shade50.withOpacity(0.7)
        : AppColors.focusMint.withOpacity(0.1);
    final borderColor = isWithered 
        ? Colors.red.shade200
        : AppColors.focusMint.withOpacity(0.3);
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isWithered 
                ? Colors.red.withOpacity(0.1)
                : AppColors.focusMint.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 나무 위젯
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 45,
                      maxHeight: 45,
                    ),
                    child: TreeWidget(session: session, size: 45),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 집중 시간
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWithered 
                    ? Colors.red.shade100
                    : AppColors.focusMint.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isWithered 
                      ? Colors.red.shade200
                      : AppColors.focusMint.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getSessionTimeText(session),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isWithered 
                      ? Colors.red.shade700
                      : AppColors.focusMint,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 6),
            
            // 상태 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isWithered 
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isWithered 
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isWithered ? Icons.close : Icons.check,
                    size: 10,
                    color: isWithered ? Colors.red.shade600 : Colors.green.shade600,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isWithered ? '포기' : '완료',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isWithered ? Colors.red.shade600 : Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 