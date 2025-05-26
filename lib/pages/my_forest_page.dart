import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/focus_session_model.dart';
import '../../services/focus_service.dart';
import '../../widgets/tree_widget.dart';

class MyForestPage extends StatefulWidget {
  final UserModel currentUser;

  const MyForestPage({super.key, required this.currentUser});

  @override
  State<MyForestPage> createState() => _MyForestPageState();
}

class _MyForestPageState extends State<MyForestPage> with TickerProviderStateMixin {
  List<FocusSessionModel> _completedSessions = [];
  List<FocusSessionModel> _abandonedSessions = [];
  bool _isLoading = true;
  
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
    
    _loadForestData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadForestData() async {
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
            content: Text('숲 정보 로딩 실패: $e'),
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

  int _getTotalFocusTime() {
    return _completedSessions.fold(0, (sum, session) => sum + session.durationMinutesSet);
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
          '나의 숲',
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
            onPressed: _loadForestData,
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
                      '숲을 불러오는 중...',
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
                child: _buildForestContent(),
              ),
      ),
    );
  }

  Widget _buildForestContent() {
    if (_completedSessions.isEmpty && _abandonedSessions.isEmpty) {
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
                '아직 숲이 비어있어요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '집중하기를 통해 첫 번째 나무를 심어보세요!\n매일 조금씩 집중하면 아름다운 숲이 만들어집니다.',
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

    return RefreshIndicator(
      onRefresh: _loadForestData,
      color: _getThemeColor(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 통계 헤더
            _buildStatsHeader(),
            const SizedBox(height: 24),
            
            // 성공한 나무들
            if (_completedSessions.isNotEmpty) ...[
              _buildSectionHeader(
                '🌳 성장한 나무들',
                '${_completedSessions.length}그루',
                Colors.green.shade600,
              ),
              const SizedBox(height: 16),
              _buildTreeGrid(_completedSessions),
              const SizedBox(height: 32),
            ],
            
            // 시든 나무들
            if (_abandonedSessions.isNotEmpty) ...[
              _buildSectionHeader(
                '🥀 시든 나무들',
                '${_abandonedSessions.length}그루',
                Colors.brown.shade600,
              ),
              const SizedBox(height: 16),
              _buildTreeGrid(_abandonedSessions, isWithered: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getThemeColor().withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getThemeColor().withOpacity(0.1),
                      _getThemeColor().withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.forest,
                  size: 24,
                  color: _getThemeColor(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.currentUser.nickname}님의 숲',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '집중을 통해 키운 나무들의 기록',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 통계 카드들
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 나무',
                  '${_completedSessions.length + _abandonedSessions.length}그루',
                  Icons.park,
                  Colors.green.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '성공률',
                  _completedSessions.isEmpty && _abandonedSessions.isEmpty
                      ? '0%'
                      : '${((_completedSessions.length / (_completedSessions.length + _abandonedSessions.length)) * 100).round()}%',
                  Icons.trending_up,
                  Colors.blue.shade400,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '총 집중시간',
                  '${_getTotalFocusTime()}분',
                  Icons.timer,
                  Colors.orange.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              title.contains('성장') ? Icons.nature : Icons.eco,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeGrid(List<FocusSessionModel> sessions, {bool isWithered = false}) {
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
            childAspectRatio: 1.1,
          ),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            final delay = index * 0.1;
            final animationValue = Curves.easeOutBack.transform(
              (_staggerAnimation.value - delay).clamp(0.0, 1.0),
            );
            
            return Transform.scale(
              scale: animationValue,
              child: Opacity(
                opacity: animationValue,
                child: _buildTreeCard(session, isWithered),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTreeCard(FocusSessionModel session, bool isWithered) {
    final cardColor = isWithered ? Colors.brown.shade50 : Colors.green.shade50;
    final borderColor = isWithered ? Colors.brown.shade200 : Colors.green.shade200;
    
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              child: TreeWidget(session: session, size: 80),
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
                '${session.durationMinutesSet}분 집중',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isWithered ? Colors.brown.shade700 : Colors.green.shade700,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 날짜
            Text(
              '${session.createdAt.year}.${session.createdAt.month.toString().padLeft(2,'0')}.${session.createdAt.day.toString().padLeft(2,'0')}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            
            // 상태 표시
            const SizedBox(height: 4),
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