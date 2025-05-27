import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// Models imports
import '../models/models.dart';
import '../services/user_service.dart';

class RankingPage extends StatefulWidget {
  final UserModel currentUser;
  
  const RankingPage({super.key, required this.currentUser});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<RankingModel> _rankings = [];
  bool _isLoadingRankings = true;
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
    
    _loadRankings();
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
        _isLoadingRankings = true;
      });
    }
    
    try {
      final updatedUser = await UserService.getCurrentUser();
      if (updatedUser != null && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });
        
        if (kDebugMode) {
          print('랭킹 페이지: 사용자 정보 새로고침 완료');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('랭킹 페이지: 사용자 정보 새로고침 실패 - $e');
      }
    }
    
    await _loadRankings();
    
    _isRefreshing = false;
  }

  // 랭킹 데이터를 불러오는 함수
  Future<void> _loadRankings() async {
    try {
      final rankings = await UserService.getRankings();

      if (mounted) {
        setState(() {
          _rankings = rankings;
          _isLoadingRankings = false;
        });
      }

      if (kDebugMode) {
        print('랭킹 로드 완료: ${rankings.length}명');
      }
    } catch (e) {
      if (kDebugMode) {
        print('랭킹 로드 실패: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingRankings = false;
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
            color: Colors.orange.shade400,
          ),
          onPressed: () => Navigator.pop(context, _currentUser),
        ),
        title: Text(
          '랭킹',
          style: TextStyle(
            color: Colors.orange.shade500,
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
                      // 내 순위 카드
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade100,
                              Colors.amber.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '내 순위',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentUser.nickname,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_currentUser.score ?? 0}점',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    Text(
                                      '${_currentUser.consecutiveDays ?? 0}일 연속',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 랭킹 섹션 헤더
                      Row(
                        children: [
                          Icon(
                            Icons.leaderboard,
                            color: Colors.orange.shade500,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '전체 랭킹',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      if (_isLoadingRankings)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_rankings.isNotEmpty) ...[
                        // 상위 3명 특별 표시
                        if (_rankings.length >= 3) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.amber.shade200,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '🏆 TOP 3 🏆',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade700,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    // 2등
                                    if (_rankings.length >= 2)
                                      _buildPodiumItem(_rankings[1], '🥈', Colors.grey.shade400)
                                    else
                                      const Expanded(child: SizedBox()), // 빈 공간
                                    // 1등
                                    _buildPodiumItem(_rankings[0], '🥇', Colors.amber.shade500),
                                    // 3등
                                    if (_rankings.length >= 3)
                                      _buildPodiumItem(_rankings[2], '🥉', Colors.orange.shade400)
                                    else
                                      const Expanded(child: SizedBox()), // 빈 공간
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                        ],
                        
                        // 전체 랭킹 리스트
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _rankings.length,
                          itemBuilder: (context, index) {
                            final user = _rankings[index];
                            final isCurrentUser = user.userId == _currentUser.id;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isCurrentUser 
                                    ? Colors.orange.shade50 
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCurrentUser
                                      ? Colors.orange.shade300
                                      : user.isTopThree
                                          ? Colors.amber.shade200 
                                          : Colors.grey.shade200,
                                  width: isCurrentUser ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // 순위 표시
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: user.isTopThree 
                                          ? Colors.amber.shade100 
                                          : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${user.rank}위',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: user.isTopThree 
                                              ? Colors.amber.shade700 
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(width: 16),
                                  
                                  // 닉네임
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              user.displayNickname,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: isCurrentUser 
                                                    ? Colors.orange.shade800
                                                    : Colors.grey.shade800,
                                              ),
                                            ),
                                            if (isCurrentUser) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade200,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '나',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.formattedConsecutiveDays,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // 점수
                                  Text(
                                    user.formattedScore,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrentUser 
                                          ? Colors.orange.shade700
                                          : Colors.orange.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ] else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.leaderboard_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '랭킹 정보를 불러올 수 없습니다',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '잠시 후 다시 시도해주세요',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // 랭킹 향상 팁
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.blue.shade100,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.tips_and_updates,
                                  color: Colors.blue.shade500,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '랭킹 향상 팁',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTipItem('🎯', '매일 챌린지를 완료하여 점수를 올려보세요'),
                            _buildTipItem('📅', '연속 출석으로 보너스 점수를 받아보세요'),
                            _buildTipItem('🍀', '오늘의 카드를 받아 추가 점수를 얻어보세요'),
                            _buildTipItem('🏆', '꾸준한 활동으로 상위 랭킹에 도전해보세요'),
                          ],
                        ),
                      ),
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

  Widget _buildPodiumItem(RankingModel user, String medal, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            medal,
            style: const TextStyle(fontSize: 24), // 32 → 24로 크기 축소
          ),
          const SizedBox(height: 6), // 8 → 6으로 간격 축소
          Container(
            padding: const EdgeInsets.all(6), // 8 → 6으로 패딩 축소
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              size: 16, // 20 → 16으로 크기 축소
              color: color,
            ),
          ),
          const SizedBox(height: 6), // 8 → 6으로 간격 축소
          Text(
            user.displayNickname,
            style: TextStyle(
              fontSize: 11, // 12 → 11로 크기 축소
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1, // 한 줄로 제한
            overflow: TextOverflow.ellipsis, // 긴 닉네임은 생략
          ),
          const SizedBox(height: 3), // 4 → 3으로 간격 축소
          Text(
            user.formattedScore,
            style: TextStyle(
              fontSize: 12, // 14 → 12로 크기 축소
              fontWeight: FontWeight.bold,
              color: color,
            ),
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