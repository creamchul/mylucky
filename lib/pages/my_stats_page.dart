import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';
import '../services/user_service.dart';

class MyStatsPage extends StatefulWidget {
  final UserModel currentUser;
  
  const MyStatsPage({super.key, required this.currentUser});

  @override
  State<MyStatsPage> createState() => _MyStatsPageState();
}

class _MyStatsPageState extends State<MyStatsPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  UserModel? _userStats;
  bool _isLoadingStats = true;
  bool _isRefreshing = false;
  
  late UserModel _currentUser;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    _currentUser = widget.currentUser;
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadUserStats();
    _fadeController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && !_isRefreshing) {
      _refreshData();
    }
  }

  // 데이터 새로고침
  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    
    if (mounted) {
      setState(() {
        _isLoadingStats = true;
      });
    }
    
    try {
      final updatedUser = await UserService.getCurrentUser();
      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });
        
        if (kDebugMode) {
          print('내 통계 페이지: 사용자 정보 새로고침 완료');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('내 통계 페이지: 사용자 정보 새로고침 실패 - $e');
      }
    }
    
    await _loadUserStats();
    
    _isRefreshing = false;
  }

  // 사용자 통계를 불러오는 함수
  Future<void> _loadUserStats() async {
    try {
      final userStats = await UserService.getUserStats(_currentUser.id);
      
      if (mounted) {
        setState(() {
          _userStats = userStats;
          _isLoadingStats = false;
        });
      }

      if (kDebugMode) {
        print('사용자 통계 로드 완료: ${userStats.nickname}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('사용자 통계 로드 실패: $e');
      }
      
      if (mounted) {
        setState(() {
          _userStats = UserModel.createNew(
            id: _currentUser.id, 
            nickname: _currentUser.nickname
          ).copyWith(
            totalFortunes: 0,
            totalMissions: 0,
            completedMissions: 0,
            consecutiveDays: 0,
            score: 0,
          );
          _isLoadingStats = false;
        });
      }
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
            color: Colors.indigo.shade400,
          ),
          onPressed: () => Navigator.pop(context, _currentUser),
        ),
        title: Text(
          '내 통계',
          style: TextStyle(
            color: Colors.indigo.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFAFAFA),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 사용자 정보 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.indigo.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.indigo.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentUser.nickname,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Text(
                                '${_currentUser.rewardPoints} 포인트',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 통계 섹션 헤더
                      Row(
                        children: [
                          Icon(
                            Icons.analytics,
                            color: Colors.indigo.shade500,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '활동 통계',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isLoadingStats)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else ...[
                        // 통계 그리드
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                          children: [
                            _buildStatCard(
                              '총 점수',
                              '${_userStats?.score ?? 0}점',
                              Icons.star,
                              Colors.orange.shade300,
                            ),
                            _buildStatCard(
                              '연속 출석',
                              '${_userStats?.consecutiveDays ?? 0}일',
                              Icons.calendar_today,
                              Colors.green.shade300,
                            ),
                            _buildStatCard(
                              '받은 카드',
                              '${_userStats?.totalFortunes ?? 0}개',
                              Icons.favorite,
                              Colors.indigo.shade300,
                            ),
                            _buildStatCard(
                              '완료 미션',
                              '${_userStats?.completedMissions ?? 0}개',
                              Icons.check_circle,
                              Colors.blue.shade300,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // 통계 정보가 모두 0인 경우 안내 메시지 표시
                        if (_userStats != null && 
                            (_userStats!.score ?? 0) == 0 && 
                            (_userStats!.totalFortunes ?? 0) == 0 && 
                            (_userStats!.completedMissions ?? 0) == 0) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 48,
                                  color: Colors.blue.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '아직 활동 기록이 없어요',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '카드를 받고 미션을 완료해서\n멋진 통계를 만들어보세요!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade600,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // 팁 카드
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.green.shade100,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.green.shade500,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '통계 향상 팁',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildTipItem('📅', '매일 출석하여 연속 출석일수를 늘려보세요'),
                              _buildTipItem('🍀', '오늘의 카드를 받아 행운을 모아보세요'),
                              _buildTipItem('🎯', '챌린지를 완료하여 점수를 올려보세요'),
                              _buildTipItem('🌟', '꾸준한 활동으로 랭킹을 올려보세요'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 